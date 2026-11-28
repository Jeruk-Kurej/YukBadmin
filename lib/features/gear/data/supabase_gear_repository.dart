import 'package:supabase_flutter/supabase_flutter.dart';

import 'gear_models.dart';
import 'gear_repository.dart';

/// Toko partner dan produk dari Supabase. Bisa dibaca tanpa masuk.
class SupabaseGearRepository implements GearRepository {
  const SupabaseGearRepository(this.client);
  final SupabaseClient client;

  @override
  Future<List<Shop>> fetchShops() async {
    final rows = await client.from('shops').select().order('name');
    return [for (final r in rows) shopFromRow(r)];
  }

  @override
  Future<List<Product>> fetchProducts() async {
    final rows = await client.from('products').select().order('name');
    return [for (final r in rows) productFromRow(r)];
  }
}

Shop shopFromRow(Map<String, dynamic> r) => Shop(
  id: r['id'] as String,
  name: r['name'] as String,
  address: r['address'] as String,
  district: r['district'] as String,
  whatsapp: r['whatsapp'] as String,
  hours: r['hours'] as String,
  description: r['description'] as String? ?? '',
  mapsUrl: r['maps_url'] as String?,
  logoPath: r['logo_url'] as String?,
  coverPath: r['cover_url'] as String?,
);

Product productFromRow(Map<String, dynamic> r) {
  final weight = r['racket_weight'] as String?;
  final balance = r['racket_balance'] as String?;
  final flex = r['racket_flex'] as String?;
  final string = r['string_type'] as String?;
  return Product(
    id: r['id'] as String,
    shopId: r['shop_id'] as String,
    name: r['name'] as String,
    category: GearCategory.values.byName(r['category'] as String),
    price: r['price'] as int,
    inStock: r['in_stock'] as bool,
    description: r['description'] as String? ?? '',
    racket: weight != null && balance != null && flex != null
        ? RacketSpec(
            weight: RacketWeight.values.byName(weight),
            balance: RacketBalance.values.byName(balance),
            flex: RacketFlex.values.byName(flex),
          )
        : null,
    shoeSizes: [
      for (final x in (r['shoe_sizes'] as List? ?? const [])) x as int,
    ],
    stringType: string == null ? null : StringType.values.byName(string),
    photoPath: r['photo_url'] as String?,
  );
}
