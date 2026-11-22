import 'gear_models.dart';

/// Sumber data toko dan produk. Implementasi contoh di bawah bisa diganti
/// Supabase tanpa mengubah layar.
abstract interface class GearRepository {
  Future<List<Shop>> fetchShops();
  Future<List<Product>> fetchProducts();
}

/// Data contoh. Nama toko, alamat, nomor, dan produk di sini fiktif.
class SeedGearRepository implements GearRepository {
  const SeedGearRepository();

  @override
  Future<List<Shop>> fetchShops() async => _shops;

  @override
  Future<List<Product>> fetchProducts() async => _products;
}

const _shops = [
  Shop(
    id: 'toko-gesit',
    name: 'Toko Gesit Sport',
    address: 'Jl. Raya Nginden No. 12, Nginden Jangkungan, Sukolilo, Surabaya',
    district: 'Sukolilo',
    whatsapp: '6282155550101',
    hours: 'Senin–Sabtu 09.00–20.00',
    description: 'Jual raket, sepatu, senar, dan grip. Bisa pasang senar di tempat, tunggu sekitar 30 menit.',
  ),
  Shop(
    id: 'toko-smash-corner',
    name: 'Smash Corner',
    address: 'Jl. Kertajaya Indah Timur No. 8, Manyar Sabrangan, Mulyorejo, Surabaya',
    district: 'Mulyorejo',
    whatsapp: '6282155550202',
    hours: 'Setiap hari 10.00–21.00',
    description: 'Spesialis raket dan senar. Melayani konsultasi pilih raket untuk pemula.',
  ),
];

const _products = [
  Product(
    id: 'p-falcon-80',
    shopId: 'toko-gesit',
    name: 'Raket Falcon 80',
    category: GearCategory.raket,
    price: 1250000,
    inStock: true,
    description: 'Ringan dan mudah dikontrol. Batang lentur membantu pukulan jauh tanpa tenaga besar.',
    racket: RacketSpec(
      weight: RacketWeight.u5,
      balance: RacketBalance.even,
      flex: RacketFlex.flexible,
    ),
  ),
  Product(
    id: 'p-garuda-lite-75',
    shopId: 'toko-gesit',
    name: 'Raket Garuda Lite 75',
    category: GearCategory.raket,
    price: 890000,
    inStock: true,
    description: 'Berat sedikit di kepala, membantu smash tanpa cepat capek.',
    racket: RacketSpec(
      weight: RacketWeight.u4,
      balance: RacketBalance.headHeavy,
      flex: RacketFlex.medium,
    ),
  ),
  Product(
    id: 'p-kilat-defender',
    shopId: 'toko-smash-corner',
    name: 'Raket Kilat Defender',
    category: GearCategory.raket,
    price: 720000,
    inStock: true,
    description:
        'Kepala ringan untuk reaksi cepat saat bertahan dan main di depan net.',
    racket: RacketSpec(
      weight: RacketWeight.u5,
      balance: RacketBalance.headLight,
      flex: RacketFlex.medium,
    ),
  ),
  Product(
    id: 'p-titan-pro',
    shopId: 'toko-smash-corner',
    name: 'Raket Titan Pro',
    category: GearCategory.raket,
    price: 2150000,
    inStock: false,
    description: 'Batang kaku dan kepala berat untuk smash keras. Butuh teknik dan tenaga.',
    racket: RacketSpec(
      weight: RacketWeight.u3,
      balance: RacketBalance.headHeavy,
      flex: RacketFlex.stiff,
    ),
  ),
  Product(
    id: 'p-gesit-court-pro',
    shopId: 'toko-gesit',
    name: 'Sepatu Gesit Court Pro',
    category: GearCategory.sepatu,
    price: 780000,
    inStock: true,
    description: 'Sol karet tidak licin di lapangan karpet atau kayu. Bantalan tumit empuk.',
    shoeSizes: [38, 39, 40, 41, 42, 43, 44],
  ),
  Product(
    id: 'p-langkah-lite',
    shopId: 'toko-smash-corner',
    name: 'Sepatu Langkah Lite',
    category: GearCategory.sepatu,
    price: 450000,
    inStock: true,
    description:
        'Ringan untuk main santai. Cocok untuk yang baru mulai rutin main.',
    shoeSizes: [36, 37, 38, 39, 40, 41],
  ),
  Product(
    id: 'p-lincah-66',
    shopId: 'toko-gesit',
    name: 'Senar Lincah 66',
    category: GearCategory.senar,
    price: 95000,
    inStock: false,
    description:
        'Senar tipis dengan pantulan tinggi. Harga sudah termasuk pasang.',
    stringType: StringType.tipis,
  ),
  Product(
    id: 'p-awet-70',
    shopId: 'toko-smash-corner',
    name: 'Senar Awet 70',
    category: GearCategory.senar,
    price: 80000,
    inStock: true,
    description: 'Senar tebal yang tahan lama, cocok untuk yang sering main. Harga sudah termasuk pasang.',
    stringType: StringType.tebal,
  ),
  Product(
    id: 'p-grip-keringat',
    shopId: 'toko-gesit',
    name: 'Grip Tahan Keringat',
    category: GearCategory.grip,
    price: 25000,
    inStock: true,
    description: 'Pegangan tetap kesat walau tangan berkeringat.',
  ),
];
