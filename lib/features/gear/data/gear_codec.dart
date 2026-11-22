import 'gear_models.dart';

/// Konversi toko dan produk ke dan dari JSON untuk cache lokal.

Map<String, Object?> shopToJson(Shop s) => {
  'id': s.id,
  'name': s.name,
  'address': s.address,
  'district': s.district,
  'whatsapp': s.whatsapp,
  'hours': s.hours,
  'description': s.description,
  'mapsUrl': s.mapsUrl,
  'logoPath': s.logoPath,
  'coverPath': s.coverPath,
};

Shop shopFromJson(Object? json) {
  final m = json! as Map<String, Object?>;
  return Shop(
    id: m['id']! as String,
    name: m['name']! as String,
    address: m['address']! as String,
    district: m['district']! as String,
    whatsapp: m['whatsapp']! as String,
    hours: m['hours']! as String,
    description: m['description']! as String,
    mapsUrl: m['mapsUrl'] as String?,
    logoPath: m['logoPath'] as String?,
    coverPath: m['coverPath'] as String?,
  );
}

Map<String, Object?> productToJson(Product p) => {
  'id': p.id,
  'shopId': p.shopId,
  'name': p.name,
  'category': p.category.name,
  'price': p.price,
  'inStock': p.inStock,
  'description': p.description,
  'racket': p.racket == null
      ? null
      : {
          'weight': p.racket!.weight.name,
          'balance': p.racket!.balance.name,
          'flex': p.racket!.flex.name,
        },
  'shoeSizes': p.shoeSizes,
  'stringType': p.stringType?.name,
  'photoPath': p.photoPath,
};

Product productFromJson(Object? json) {
  final m = json! as Map<String, Object?>;
  final racket = m['racket'] as Map<String, Object?>?;
  final stringType = m['stringType'] as String?;
  return Product(
    id: m['id']! as String,
    shopId: m['shopId']! as String,
    name: m['name']! as String,
    category: GearCategory.values.byName(m['category']! as String),
    price: m['price']! as int,
    inStock: m['inStock']! as bool,
    description: m['description']! as String,
    racket: racket == null
        ? null
        : RacketSpec(
            weight: RacketWeight.values.byName(racket['weight']! as String),
            balance: RacketBalance.values.byName(racket['balance']! as String),
            flex: RacketFlex.values.byName(racket['flex']! as String),
          ),
    shoeSizes: [for (final s in m['shoeSizes']! as List) s as int],
    stringType: stringType == null
        ? null
        : StringType.values.byName(stringType),
    photoPath: m['photoPath'] as String?,
  );
}
