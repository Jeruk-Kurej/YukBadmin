import 'package:flutter/material.dart';

import '../../features/gear/data/gear_models.dart';
import '../../features/gear/pages/product_art.dart';
import '../../features/pb/data/pb_models.dart';
import 'court_art.dart';
import 'photo.dart';

/// Sampul PB: foto pertama dari pengurus, atau ilustrasi lapangan.
class PbCover extends StatelessWidget {
  const PbCover({super.key, required this.pb, this.showLamps = true});

  final Pb pb;
  final bool showLamps;

  @override
  Widget build(BuildContext context) => YbPhoto(
    path: pb.photoPaths.firstOrNull,
    fallback: CourtArt(seed: pb.artSeed, showLamps: showLamps),
  );
}

/// Gambar produk: foto dari toko, atau ilustrasi sesuai kategori.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) => YbPhoto(
    path: product.photoPath,
    fallback: ProductArt(category: product.category, seed: product.name.length),
  );
}
