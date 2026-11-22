enum GearCategory {
  raket('Raket'),
  sepatu('Sepatu'),
  senar('Senar'),
  grip('Grip');

  const GearCategory(this.label);
  final String label;
}

/// Berat raket. Makin besar angkanya, makin ringan raketnya.
enum RacketWeight {
  u3('3U', '85–89 gram'),
  u4('4U', '80–84 gram'),
  u5('5U', '75–79 gram');

  const RacketWeight(this.label, this.grams);
  final String label;
  final String grams;
}

/// Letak titik berat raket.
enum RacketBalance {
  headLight('Ringan di kepala'),
  even('Seimbang'),
  headHeavy('Berat di kepala');

  const RacketBalance(this.label);
  final String label;
}

/// Kelenturan batang raket.
enum RacketFlex {
  flexible('Lentur'),
  medium('Sedang'),
  stiff('Kaku');

  const RacketFlex(this.label);
  final String label;
}

/// Jenis senar, untuk mencocokkan senar dengan gaya main.
enum StringType {
  tipis('Tipis, pantulan tinggi'),
  tebal('Tebal, tahan lama');

  const StringType(this.label);
  final String label;
}

/// Spesifikasi khusus raket. Diisi toko saat menambah produk raket.
class RacketSpec {
  const RacketSpec({
    required this.weight,
    required this.balance,
    required this.flex,
  });

  final RacketWeight weight;
  final RacketBalance balance;
  final RacketFlex flex;
}

class Product {
  const Product({
    required this.id,
    required this.shopId,
    required this.name,
    required this.category,
    required this.price,
    required this.inStock,
    required this.description,
    this.racket,
    this.shoeSizes = const [],
    this.stringType,
    this.photoPath,
  });

  final String id;
  final String shopId;
  final String name;
  final GearCategory category;
  final int price;
  final bool inStock;
  final String description;

  /// Hanya untuk raket.
  final RacketSpec? racket;

  /// Ukuran EU yang tersedia, hanya untuk sepatu.
  final List<int> shoeSizes;

  /// Hanya untuk senar.
  final StringType? stringType;

  /// Path foto produk di perangkat. Tanpa foto, ilustrasi bawaan dipakai.
  final String? photoPath;

  String get sizeRange => shoeSizes.isEmpty
      ? ''
      : shoeSizes.length == 1
      ? '${shoeSizes.first}'
      : '${shoeSizes.first}–${shoeSizes.last}';

  Product copyWith({
    String? name,
    GearCategory? category,
    int? price,
    bool? inStock,
    String? description,
    RacketSpec? racket,
    bool clearRacket = false,
    List<int>? shoeSizes,
    StringType? stringType,
    bool clearStringType = false,
    String? photoPath,
    bool clearPhoto = false,
  }) => Product(
    id: id,
    shopId: shopId,
    name: name ?? this.name,
    category: category ?? this.category,
    price: price ?? this.price,
    inStock: inStock ?? this.inStock,
    description: description ?? this.description,
    racket: clearRacket ? null : (racket ?? this.racket),
    shoeSizes: shoeSizes ?? this.shoeSizes,
    stringType: clearStringType ? null : (stringType ?? this.stringType),
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
  );
}

class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    required this.whatsapp,
    required this.hours,
    required this.description,
    this.mapsUrl,
    this.logoPath,
    this.coverPath,
  });

  final String id;
  final String name;

  /// Alamat lengkap: jalan, nomor, kota. Hasil UAT minta alamat diperjelas.
  final String address;
  final String district;

  /// Nomor ternormalisasi (62...).
  final String whatsapp;
  final String hours;
  final String description;
  final String? mapsUrl;

  /// Path logo dan foto sampul toko di perangkat.
  final String? logoPath;
  final String? coverPath;

  String get initials {
    final words = name
        .replaceFirst(RegExp(r'^Toko\s+', caseSensitive: false), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length < 2 ? words.first.length : 2)
          .toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  Shop copyWith({
    String? name,
    String? address,
    String? district,
    String? whatsapp,
    String? hours,
    String? description,
    String? mapsUrl,
    String? logoPath,
    bool clearLogo = false,
    String? coverPath,
    bool clearCover = false,
  }) => Shop(
    id: id,
    name: name ?? this.name,
    address: address ?? this.address,
    district: district ?? this.district,
    whatsapp: whatsapp ?? this.whatsapp,
    hours: hours ?? this.hours,
    description: description ?? this.description,
    mapsUrl: mapsUrl ?? this.mapsUrl,
    logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
    coverPath: clearCover ? null : (coverPath ?? this.coverPath),
  );
}
