import 'package:flutter/material.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:kaisel/kaisel.dart';
import 'core/config/env_config.dart';
import 'core/network/blogger_data_service.dart';
import 'core/utils/schema_resolver.dart';
import 'core/utils/area_served_matcher.dart';
import 'features/catalog/domain/product_entity.dart';
import 'features/catalog/domain/label_query_parser.dart';
import 'features/catalog/domain/catalog_sorter.dart';
import 'features/catalog/presentation/product_detail_screen.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/presentation/profile_screen.dart';
import 'features/cart_wishlist/presentation/wishlist_screen.dart';
import 'features/cart_wishlist/data/app_database.dart';
import 'features/cart_wishlist/data/cart_reverification_service.dart';
import 'features/cart_wishlist/data/product_cache_manager.dart';
import 'features/checkout/data/checkout_client.dart';
import 'features/checkout/domain/promo_code_engine.dart';
import 'shared/i18n/schema_i18n_resolver.dart';
import 'shared/i18n/currency_converter.dart';
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
  late final ProductCacheManager _cacheManager;
  late final CartReverificationService _reverificationService;
  late final CheckoutClient _checkoutClient;

  // Signals for reactive state management
  final Signal<List<ProductEntity>> _productsSignal = Signal([]);
  final Signal<bool> _isLoadingSignal = Signal(false);
  final Signal<String?> _errorSignal = Signal(null);
  final Signal<String> _searchQuerySignal = Signal('');
  final Signal<String> _userLocationCitySignal = Signal('');
  final Signal<SortOption> _sortOptionSignal = Signal(SortOption.featured);
  final Signal<String> _selectedCurrencySignal = Signal('USD');
  final Signal<ThemeMode> _themeModeSignal = Signal(ThemeMode.light);
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
    _cacheManager = ProductCacheManager(database: _database);
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
      await _cacheManager.cacheProducts(loadedProducts);
    } catch (e) {
      // Fallback to local offline cache
      final cached = await _cacheManager.getCachedProducts();
      if (cached.isNotEmpty) {
        _productsSignal.value = cached;
      } else {
        _errorSignal.value = 'Failed to load products and no offline cache available: $e';
      }
    } finally {
      _isLoadingSignal.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSignalBuilder<ThemeMode>(
      signal: _themeModeSignal,
      builder: (context, themeMode) {
        return MaterialApp(
          title: 'Blog Store',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
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
                    sortOptionSignal: _sortOptionSignal,
                    selectedCurrencySignal: _selectedCurrencySignal,
                    themeModeSignal: _themeModeSignal,
                    cartItemsSignal: _cartItemsSignal,
                    wishlistItemsSignal: _wishlistItemsSignal,
                    onRefresh: _loadProducts,
                    onAddToCart: _addToCart,
                    onToggleWishlist: _toggleWishlist,
                  ),
              '/profile': (context, state) => ProfileScreen(
                    authService: FirebaseAuthService(),
                    database: _database,
                  ),
              '/wishlist': (context, state) => WishlistScreen(
                    wishlistItemsSignal: _wishlistItemsSignal,
                    database: _database,
                    onWishlistUpdated: _loadCartAndWishlist,
                    onMoveToCart: (postId, title, price, imageUrl, schemaJson) async {
                      await _database.into(_database.cartItems).insert(
                            CartItemsCompanion.insert(
                              id: 'cart_${postId}_${DateTime.now().millisecondsSinceEpoch}',
                              postId: postId,
                              blogId: EnvConfig.defaultBlogId,
                              title: title,
                              price: price,
                              imageUrl: Value(imageUrl),
                              schemaJson: schemaJson,
                            ),
                          );
                      _loadCartAndWishlist();
                    },
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
      },
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
              schemaJson: jsonEncode(product.resolvedSchema),
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
              schemaJson: jsonEncode(product.resolvedSchema),
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
  final Signal<SortOption> sortOptionSignal;
  final Signal<String> selectedCurrencySignal;
  final Signal<ThemeMode> themeModeSignal;
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
    required this.sortOptionSignal,
    required this.selectedCurrencySignal,
    required this.themeModeSignal,
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
          BlocSignalBuilder<String>(
            signal: selectedCurrencySignal,
            builder: (context, currency) {
              return DropdownButton<String>(
                value: currency,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.currency_exchange, size: 20),
                items: CurrencyConverter.currencySymbols.keys.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedCurrencySignal.value = val;
                },
              );
            },
          ),
          BlocSignalBuilder<ThemeMode>(
            signal: themeModeSignal,
            builder: (context, currentMode) {
              return IconButton(
                icon: Icon(currentMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeModeSignal.value = currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => KaiselRouter.of(context).push('/profile'),
          ),
          BlocSignalBuilder<List<WishlistItem>>(
            signal: wishlistItemsSignal,
            builder: (context, wishItems) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () => KaiselRouter.of(context).push('/wishlist'),
                  ),
                  if (wishItems.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          '${wishItems.length}',
                          style: const TextStyle(fontSize: 9, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search or label:... (e.g., label:electronics | mobile)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) => searchQuerySignal.value = val,
                  ),
                ),
                const SizedBox(width: 8),
                BlocSignalBuilder<SortOption>(
                  signal: sortOptionSignal,
                  builder: (context, currentSort) {
                    return PopupMenuButton<SortOption>(
                      icon: const Icon(Icons.sort),
                      onSelected: (option) => sortOptionSignal.value = option,
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: SortOption.featured, child: Text('Featured')),
                        PopupMenuItem(value: SortOption.priceLowToHigh, child: Text('Price: Low to High')),
                        PopupMenuItem(value: SortOption.priceHighToLow, child: Text('Price: High to Low')),
                        PopupMenuItem(value: SortOption.newest, child: Text('Newest')),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: BlocSignalBuilder<List<ProductEntity>>(
              signal: productsSignal,
              builder: (context, products) {
                final allLabels = products.expand((p) => p.labels).toSet().toList();
                if (allLabels.isEmpty) return const SizedBox.shrink();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: allLabels.map((lbl) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ActionChip(
                          avatar: const Icon(Icons.label_outline, size: 14),
                          label: Text(lbl, style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            searchQuerySignal.value = 'label:$lbl';
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
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

                                return BlocSignalBuilder<SortOption>(
                                  signal: sortOptionSignal,
                                  builder: (context, sortOpt) {
                                    return BlocSignalBuilder<String>(
                                      signal: selectedCurrencySignal,
                                      builder: (context, targetCurrency) {
                                        final sorted = CatalogSorter.sort(filtered, sortOpt);

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
                                            itemCount: sorted.length,
                                            itemBuilder: (context, index) {
                                              final product = sorted[index];
                                              return ProductCard(
                                                product: product,
                                                targetCurrency: targetCurrency,
                                                onAddToCart: () => onAddToCart(product),
                                                onToggleWishlist: () => onToggleWishlist(product),
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => ProductDetailScreen(
                                                        product: product,
                                                        onAddToCart: onAddToCart,
                                                        onToggleWishlist: onToggleWishlist,
                                                      ),
                                                    ),
                                                  );
                                                },
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
  final String targetCurrency;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleWishlist;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.targetCurrency = 'USD',
    required this.onAddToCart,
    required this.onToggleWishlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime = SchemaI18nResolver.formatLocalTimestamp(product.publishedAt);
    final formattedPrice = CurrencyConverter.format(
      price: product.price,
      fromCurrency: product.currency,
      targetCurrency: targetCurrency,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
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
                    formattedPrice,
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
    ),
    );
  }
}

class CartScreen extends StatefulWidget {
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
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  PaymentMethod _selectedPayment = PaymentMethod.upi;
  final _cityController = TextEditingController(text: 'New York');
  final _countryController = TextEditingController(text: 'USA');
  final _promoController = TextEditingController();
  double _appliedDiscount = 0.0;
  String? _promoMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Cart',
            onPressed: () async {
              await widget.database.delete(widget.database.cartItems).go();
              widget.onCartUpdated();
            },
          ),
        ],
      ),
      body: BlocSignalBuilder<List<CartItem>>(
        signal: widget.cartItemsSignal,
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
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: item.imageUrl != null
                            ? Image.network(item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.shopping_bag),
                        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('\$${item.price.toStringAsFixed(2)} x ${item.quantity} = \$${(item.price * item.quantity).toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () async {
                                if (item.quantity > 1) {
                                  await (widget.database.update(widget.database.cartItems)
                                        ..where((tbl) => tbl.id.equals(item.id)))
                                      .write(CartItemsCompanion(quantity: Value(item.quantity - 1)));
                                } else {
                                  await (widget.database.delete(widget.database.cartItems)
                                        ..where((tbl) => tbl.id.equals(item.id)))
                                      .go();
                                }
                                widget.onCartUpdated();
                              },
                            ),
                            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              onPressed: () async {
                                await (widget.database.update(widget.database.cartItems)
                                      ..where((tbl) => tbl.id.equals(item.id)))
                                    .write(CartItemsCompanion(quantity: Value(item.quantity + 1)));
                                widget.onCartUpdated();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: PaymentMethod.values.map((method) {
                        return ChoiceChip(
                          label: Text(method.name.toUpperCase()),
                          selected: _selectedPayment == method,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedPayment = method);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cityController,
                            decoration: const InputDecoration(labelText: 'City', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _countryController,
                            decoration: const InputDecoration(labelText: 'Country', isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoController,
                            decoration: InputDecoration(
                              labelText: 'Promo Code (e.g. SAVE10)',
                              isDense: true,
                              errorText: _promoMessage != null && _appliedDiscount == 0 ? _promoMessage : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final res = PromoCodeEngine.evaluate(
                              code: _promoController.text,
                              cartTotal: total,
                            );
                            setState(() {
                              _appliedDiscount = res.discountAmount;
                              _promoMessage = res.message;
                            });
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    if (_appliedDiscount > 0) ...[
                      const SizedBox(height: 4),
                      Text('Discount: -\$${_appliedDiscount.toStringAsFixed(2)} (${_promoMessage ?? ''})',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Final Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('\$${(total - _appliedDiscount).clamp(0.0, double.infinity).toStringAsFixed(2)}',
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
    final verificationResults = await widget.reverificationService.reverifyCart();
    widget.onCartUpdated();

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
      paymentMethod: _selectedPayment,
      shippingAddress: {'city': _cityController.text, 'country': _countryController.text},
    );

    final response = await widget.checkoutClient.processOrder(payload);

    if (response.success) {
      // Record order locally in Drift DB
      await widget.database.into(widget.database.orderRecords).insert(
            OrderRecordsCompanion.insert(
              orderId: response.orderId ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}',
              userId: payload.userId,
              totalAmount: payload.totalAmount,
              paymentMethod: payload.paymentMethod.name,
              itemsJson: jsonEncode(payload.items.map((i) => i.toJson()).toList()),
              shippingAddressJson: jsonEncode(payload.shippingAddress),
            ),
          );
    }

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
                  await widget.database.delete(widget.database.cartItems).go();
                  widget.onCartUpdated();
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
