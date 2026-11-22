import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_store.dart';
import '../data/gear_codec.dart';
import '../data/gear_models.dart';
import '../data/gear_repository.dart';

final gearRepositoryProvider = Provider<GearRepository>(
  (ref) => const SeedGearRepository(),
);

/// Toko milik pengguna (peran toko partner) beserta produknya. Masih di
/// memori; akan dipindah ke Supabase.
class OwnShopState {
  const OwnShopState({this.shop, this.products = const []});

  final Shop? shop;
  final List<Product> products;

  bool get hasShop => shop != null;
}

class OwnShopNotifier extends Notifier<OwnShopState> {
  var _seq = 0;

  @override
  OwnShopState build() {
    final store = ref.watch(localStoreProvider);
    listenSelf(
      (_, next) => writeCached(
        store,
        CacheKeys.ownShop,
        next.shop == null
            ? null
            : {
                'shop': shopToJson(next.shop!),
                'products': [for (final p in next.products) productToJson(p)],
              },
      ),
    );
    final restored = readCached(store, CacheKeys.ownShop, (json) {
      final m = json! as Map<String, Object?>;
      return OwnShopState(
        shop: shopFromJson(m['shop']),
        products: [for (final p in m['products']! as List) productFromJson(p)],
      );
    }, const OwnShopState());
    _seq = maxIdSeq(restored.products.map((p) => p.id));
    return restored;
  }

  void register(Shop shop) => state = OwnShopState(shop: shop);

  void updateShop(Shop shop) =>
      state = OwnShopState(shop: shop, products: state.products);

  Product saveProduct(Product product) {
    final exists = state.products.any((p) => p.id == product.id);
    final saved = exists
        ? product
        : Product(
            id: 'pm-${++_seq}',
            shopId: state.shop!.id,
            name: product.name,
            category: product.category,
            price: product.price,
            inStock: product.inStock,
            description: product.description,
            racket: product.racket,
            shoeSizes: product.shoeSizes,
            stringType: product.stringType,
            photoPath: product.photoPath,
          );
    state = OwnShopState(
      shop: state.shop,
      products: exists
          ? [for (final p in state.products) p.id == saved.id ? saved : p]
          : [...state.products, saved],
    );
    return saved;
  }

  void setStock(String productId, bool inStock) => state = OwnShopState(
    shop: state.shop,
    products: [
      for (final p in state.products)
        p.id == productId ? p.copyWith(inStock: inStock) : p,
    ],
  );

  void removeProduct(String productId) => state = OwnShopState(
    shop: state.shop,
    products: state.products.where((p) => p.id != productId).toList(),
  );

  void clear() => state = const OwnShopState();
}

final ownShopProvider = NotifierProvider<OwnShopNotifier, OwnShopState>(
  OwnShopNotifier.new,
);

/// Semua toko, termasuk toko milik pengguna.
final shopsProvider = FutureProvider<List<Shop>>((ref) async {
  final own = ref.watch(ownShopProvider.select((s) => s.shop));
  final list = await ref.watch(gearRepositoryProvider).fetchShops();
  return [...list, ?own];
});

/// Semua produk, termasuk produk toko milik pengguna.
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final own = ref.watch(ownShopProvider.select((s) => s.products));
  final list = await ref.watch(gearRepositoryProvider).fetchProducts();
  return [...list, ...own];
});

final shopByIdProvider = Provider.family<AsyncValue<Shop?>, String>(
  (ref, id) => ref
      .watch(shopsProvider)
      .whenData((list) => list.where((s) => s.id == id).firstOrNull),
);

final productByIdProvider = Provider.family<AsyncValue<Product?>, String>(
  (ref, id) => ref
      .watch(productsProvider)
      .whenData((list) => list.where((p) => p.id == id).firstOrNull),
);
