import 'package:flutter/material.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:kaisel/kaisel.dart';
import 'core/config/env_config.dart';
import 'core/network/blogger_data_service.dart';
import 'core/utils/schema_resolver.dart';
import 'core/utils/area_served_matcher.dart';
import 'features/catalog/domain/product_entity.dart';
import 'features/catalog/domain/label_query_parser.dart';
import 'features/cart_wishlist/data/app_database.dart';
import 'features/cart_wishlist/data/cart_reverification_service.dart';
import 'features/checkout/data/checkout_client.dart';
import 'shared/i18n/schema_i18n_resolver.dart';
import 'package:dio/dio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BlogStoreApp());
}

class BlogStoreApp extends StatefulWidget {
  const BlogStoreApp({super.key});

  @override
  State<BlogStoreApp> createState() => _BlogStoreAppState();
}

class _BlogStoreAppState extends State<BlogStoreApp> {
  late final Dio _dio;
  late final BloggerDataService _bloggerDataService;
  late final SchemaResolver _schemaResolver;
  late final AppDatabase _database;
  late final CartReverificationService _reverificationService;
  late final CheckoutClient _checkoutClient;

  // Signals for reactive state management
  final Signal<List<ProductEntity>> _productsSignal = Signal([]);
  final Signal<bool> _isLoadingSignal = Signal(false);
  final Signal<String?> _errorSignal = Signal(null);
  final Signal<String> _searchQuerySignal = Signal('');
  final Signal<String> _userLocationCitySignal = Signal('');
  final Signal<List<CartItem>> _cartItemsSignal = Signal([]);
  final Signal<List<WishlistItem>> _wishlistItemsSignal = Signal([]);

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    _bloggerDataService = BloggerDataService(dio: _dio);
    _schemaResolver = SchemaResolver(
      defaultBlogId: EnvConfig.defaultBlogId,
      fetchPostSchema: (blogId, postId) async {
        final post = await _bloggerDataService.fetchPostById(blogId: blogId, postId: postId);
        return post?['schema'] as Map<String, dynamic>?;
      },
    );
    _database = AppDatabase();
    _reverificationService = CartReverificationService(
      bloggerDataService: _bloggerDataService,
      schemaResolver: _schemaResolver,
      database: _database,
    );
    _checkoutClient = CheckoutClient(dio: _dio);

    _loadCartAndWishlist();
    _loadProducts();
  }

  Future<void> _loadCartAndWishlist() async {
    final cart = await _database.select(_database.cartItems).get();
    final wishlist = await _database.select(_database.wishlistItems).get();
    _cartItemsSignal.value = cart;
    _wishlistItemsSignal.value = wishlist;
  }

  Future<void> _loadProducts() async {
    _isLoadingSignal.value = true;
    _errorSignal.value = null;

    try {
      final posts = await _bloggerDataService.fetchPosts(blogId: EnvConfig.defaultBlogId);
      final List<ProductEntity> loadedProducts = [];

      for (final post in posts) {
        final rawSchema = Map<String, dynamic>.from(post['schema'] as Map? ?? {});
        final resolvedSchema = await _schemaResolver.resolve(rawSchema);

        final product = ProductEntity.fromPostMap(
          postMap: post,
          blogId: EnvConfig.defaultBlogId,
          resolvedSchema: resolvedSchema,
        );
        loadedProducts.add(product);
      }

      _productsSignal.value = loadedProducts;
    } catch (e) {
      _errorSignal.value = 'Failed to load products: $e';
    } finally {
      _isLoadingSignal.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blog Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: KaiselRouter(
        routes: {
          '/': (context, state) => CatalogScreen(
                productsSignal: _productsSignal,
                isLoadingSignal: _isLoadingSignal,
                errorSignal: _errorSignal,
                searchQuerySignal: _searchQuerySignal,
                userLocationCitySignal: _userLocationCitySignal,
                cartItemsSignal: _cartItemsSignal,
                wishlistItemsSignal: _wishlistItemsSignal,
                onRefresh: _loadProducts,
                onAddToCart: _addToCart,
                onToggleWishlist: _toggleWishlist,
              ),
          '/cart': (context, state) => CartScreen(
                cartItemsSignal: _cartItemsSignal,
                reverificationService: _reverificationService,
                checkoutClient: _checkoutClient,
                database: _database,
                onCartUpdated: _loadCartAndWishlist,
              ),
        },
      ),
    );
  }

  Future<void> _addToCart(ProductEntity product) async {
    final existing = await (_database.select(_database.cartItems)
          ..where((tbl) => tbl.postId.equals(product.id)))
        .getSingleOrNull();

    if (existing != null) {
      await (_database.update(_database.cartItems)..where((tbl) => tbl.id.equals(existing.id))).write(
        CartItemsCompanion(quantity: Value(existing.quantity + 1)),
      );
    } else {
      await _database.into(_database.cartItems).insert(
            CartItemsCompanion.insert(
              id: 'cart_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
              postId: product.id,
              blogId: product.blogId,
              title: product.title,
              price: product.price,
              currency: Value(product.currency),
              imageUrl: Value(product.imageUrl),
              schemaJson: product.resolvedSchema.toString(),
            ),
          );
    }
    await _loadCartAndWishlist();
  }

  Future<void> _toggleWishlist(ProductEntity product) async {
    final existing = await (_database.select(_database.wishlistItems)
          ..where((tbl) => tbl.postId.equals(product.id)))
        .getSingleOrNull();

    if (existing != null) {
      await (_database.delete(_database.wishlistItems)..where((tbl) => tbl.id.equals(existing.id))).go();
    } else {
      await _database.into(_database.wishlistItems).insert(
            WishlistItemsCompanion.insert(
              id: 'wish_${product.id}',
              postId: product.id,
              blogId: product.blogId,
              title: product.title,
              price: product.price,
              currency: Value(product.currency),
              imageUrl: Value(product.imageUrl),
              schemaJson: product.resolvedSchema.toString(),
            ),
          );
    }
    await _loadCartAndWishlist();
  }
}

class CatalogScreen extends StatelessWidget {
  final Signal<List<ProductEntity>> productsSignal;
  final Signal<bool> isLoadingSignal;
  final Signal<String?> errorSignal;
  final Signal<String> searchQuerySignal;
  final Signal<String> userLocationCitySignal;
  final Signal<List<CartItem>> cartItemsSignal;
  final Signal<List<WishlistItem>> wishlistItemsSignal;
  final Future<void> Function() onRefresh;
  final Function(ProductEntity) onAddToCart;
  final Function(ProductEntity) onToggleWishlist;

  const CatalogScreen({
    super.key,
    required this.productsSignal,
    required this.isLoadingSignal,
    required this.errorSignal,
    required this.searchQuerySignal,
    required this.userLocationCitySignal,
    required this.cartItemsSignal,
    required this.wishlistItemsSignal,
    required this.onRefresh,
    required this.onAddToCart,
    required this.onToggleWishlist,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Store'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () => _showLocationDialog(context),
          ),
          BlocSignalBuilder<List<CartItem>>(
            signal: cartItemsSignal,
            builder: (context, cartItems) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () => KaiselRouter.of(context).push('/cart'),
                  ),
                  if (cartItems.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.red,
                        child: Text(
                          '${cartItems.length}',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search or label:... (e.g., label:electronics | mobile)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => searchQuerySignal.value = val,
            ),
          ),
          Expanded(
            child: BlocSignalBuilder<bool>(
              signal: isLoadingSignal,
              builder: (context, isLoading) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return BlocSignalBuilder<String?>(
                  signal: errorSignal,
                  builder: (context, error) {
                    if (error != null) {
                      return Center(child: Text(error));
                    }

                    return BlocSignalBuilder<List<ProductEntity>>(
                      signal: productsSignal,
                      builder: (context, products) {
                        return BlocSignalBuilder<String>(
                          signal: searchQuerySignal,
                          builder: (context, query) {
                            return BlocSignalBuilder<String>(
                              signal: userLocationCitySignal,
                              builder: (context, city) {
                                final filtered = products.where((p) {
                                  // 1. Label/Query match
                                  bool matchesQuery = true;
                                  if (query.isNotEmpty) {
                                    if (query.contains('label:')) {
                                      matchesQuery = LabelQueryParser.matches(p.labels, query);
                                    } else {
                                      matchesQuery = p.title.toLowerCase().contains(query.toLowerCase()) ||
                                          (p.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
                                    }
                                  }

                                  // 2. areaServed match
                                  bool matchesArea = AreaServedMatcher.matches(
                                    areaServed: p.areaServed,
                                    city: city,
                                  );

                                  return matchesQuery && matchesArea;
                                }).toList();

                                if (filtered.isEmpty) {
                                  return const Center(child: Text('No products found matching criteria.'));
                                }

                                return RefreshIndicator(
                                  onRefresh: onRefresh,
                                  child: GridView.builder(
                                    padding: const EdgeInsets.all(12),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.75,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final product = filtered[index];
                                      return ProductCard(
                                        product: product,
                                        onAddToCart: () => onAddToCart(product),
                                        onToggleWishlist: () => onToggleWishlist(product),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    final controller = TextEditingController(text: userLocationCitySignal.value);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Geolocation Filter'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Enter City or Postal Code'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              userLocationCitySignal.value = controller.text;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleWishlist;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onToggleWishlist,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime = SchemaI18nResolver.formatLocalTimestamp(product.publishedAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.grey.shade200,
                image: product.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(product.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.imageUrl == null
                  ? const Center(child: Icon(Icons.image, size: 48, color: Colors.grey))
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${product.price.toStringAsFixed(2)} ${product.currency}',
                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                ),
                Text(
                  formattedTime,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border, size: 20),
                      onPressed: onToggleWishlist,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      onPressed: onAddToCart,
                      child: const Text('Add', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  final Signal<List<CartItem>> cartItemsSignal;
  final CartReverificationService reverificationService;
  final CheckoutClient checkoutClient;
  final AppDatabase database;
  final VoidCallback onCartUpdated;

  const CartScreen({
    super.key,
    required this.cartItemsSignal,
    required this.reverificationService,
    required this.checkoutClient,
    required this.database,
    required this.onCartUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: BlocSignalBuilder<List<CartItem>>(
        signal: cartItemsSignal,
        builder: (context, items) {
          if (items.isEmpty) {
            return const Center(child: Text('Your cart is empty.'));
          }

          final total = items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.title),
                      subtitle: Text('\$${item.price} x ${item.quantity}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await (database.delete(database.cartItems)..where((tbl) => tbl.id.equals(item.id))).go();
                          onCartUpdated();
                        },
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () => _handleCheckout(context, items, total),
                        child: const Text('Re-verify & Checkout', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context, List<CartItem> items, double total) async {
    // 1. Live price re-verification
    final verificationResults = await reverificationService.reverifyCart();
    onCartUpdated();

    final invalidResults = verificationResults.where((r) => !r.isValid).toList();
    if (invalidResults.isNotEmpty) {
      final msg = invalidResults.map((r) => r.message).join('\n');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Price Notice'),
            content: Text('Prices have been updated from live Blogger schema:\n\n$msg'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 2. Submit order to api.antinna.in Hono worker
    final payload = CheckoutPayload(
      userId: 'user_123',
      items: items.map((i) => OrderItem(id: i.postId, title: i.title, price: i.price, quantity: i.quantity)).toList(),
      totalAmount: total,
      paymentMethod: PaymentMethod.upi,
      shippingAddress: {'city': 'New York', 'country': 'USA'},
    );

    final response = await checkoutClient.processOrder(payload);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(response.success ? 'Order Placed!' : 'Checkout Failed'),
          content: Text(response.message ?? 'Order processed successfully.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (response.success) {
                  await database.delete(database.cartItems).go();
                  onCartUpdated();
                  KaiselRouter.of(context).pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
