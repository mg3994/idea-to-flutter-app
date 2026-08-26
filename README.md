# Blog Store - Flutter E-Commerce Backend on Blogger

Blog Store is a production-grade, highly extendable Flutter application built using **Clean Architecture**, **SOLID**, and **DRY** principles. It utilizes Blogger as a content backend with true DRY master-variant JSON-LD schema inheritance via `@base` and `@id` context anchors.

---

## 🌟 Key Architecture & Highlights

### 1. Schema Inheritance Architecture (`@base` & `@id`)
- **Master Post (`@id`)**: Canonical blueprint containing core product specifications (e.g. brand, dimensions, screen size, base descriptions).
- **Override Post (`@base`)**: Variant-specific post containing context link formatted as `blogId/postId` (e.g. `1774904866501098696/5522904867501094455`). Overlays localized titles, regional price delta, currency, or color specs.
- **Deep Merge Engine (`SchemaOverride.deepMerge`)**: Recursively overlays variant schema key-value pairs onto the master blueprint schema.

### 2. Dual-Mode Blogger Fetching (`BloggerDataService`)
- **Authenticated REST API v3**: Activated when OAuth `authToken` or `apiKey` is provided.
- **Unauthenticated Feeds JSON API**: Public fallback endpoints (`/feeds/posts/default?alt=json`) with regex-based HTML `<script type="application/ld+json">` extraction.

### 3. Cross-Platform Local Storage & Live Reverification (Drift DB)
- **Drift DB**: SQLite on native platforms and IndexedDB/Wasm on Web.
- **`CartReverificationService`**: Re-verifies local cart prices against live Blogger schema before checkout navigation to prevent stale pricing.
- **`ProductCacheManager`**: Persists fetched schema products locally for offline browsing.
- **`OfflineOrderSyncManager`**: Queues orders when offline and syncs them automatically or on-demand.
- **`DataBackupUtility`**: Supports structured JSON export and import of Cart and Wishlist state.

### 4. Multi-Currency & Internationalization
- Dynamic `priceCurrency` extraction (`INR`, `USD`, `EUR`, `GBP`).
- Real-time `CurrencyConverter` with rate conversion and formatting.
- `SchemaI18nResolver` for resolving dynamic Schema.org `@value` / `@language` locale arrays and local timestamp normalization.

### 5. Geolocation & Power Search
- `AreaServedMatcher` filters products matching schema `areaServed` (City, State, Country, Postal Code) against selected user location.
- `LabelQueryParser` parses complex query expressions with `space` or `|` (OR) operators (e.g. `label:electronics | mobile`).
- Quick-filter action chips bar on main Catalog.

### 6. Firebase Auth & Hono Checkout Worker
- **Firebase Auth**: Google Sign-In with optional Phone Auth credential linking.
- **Cloudflare Worker Checkout (`CheckoutClient`)**: Order payload routing to `https://api.antinna.in/api/orders` supporting Apple Pay, Google Pay, UPI, and Cash on Delivery (COD).

---

## 📁 Directory Structure

```
lib/
├── app.dart                          # App entry configuration
├── main.dart                         # Entry point, Kaisel router & signal states
├── core/
│   ├── config/                       # EnvConfig (Blog ID: 1774904866501098696), SampleCatalogLoader
│   ├── network/                      # BloggerDataService (Dio HTTP client)
│   └── utils/                        # BaseContext, SchemaOverride, SchemaResolver, AreaServedMatcher, SchemaAuditUtility
├── shared/
│   └── i18n/                         # SchemaI18nResolver, CurrencyConverter
└── features/
    ├── auth/                         # FirebaseAuthService, FirebaseMessagingService, ProfileScreen
    ├── catalog/                      # ProductEntity, LabelQueryParser, CatalogSorter, ProductDetailScreen, SchemaShareUtility
    ├── cart_wishlist/                # AppDatabase (Drift), CartReverificationService, ProductCacheManager, OfflineOrderSyncManager, DataBackupUtility, WishlistScreen
    └── checkout/                     # CheckoutClient, PromoCodeEngine
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.11.0+)
- Dart SDK (3.11.0+)

### Dependencies Installation
```bash
flutter pub get
```

### Code Generation (Drift DB)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run Tests
```bash
flutter test
```

### Run Static Analysis
```bash
flutter analyze
```

### Run Application
```bash
flutter run
```
