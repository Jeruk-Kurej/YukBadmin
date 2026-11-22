import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../manage/data/manage_models.dart' show displayWhatsapp;
import '../../manage/pages/manage_widgets.dart';
import '../data/gear_models.dart';
import '../state/gear_providers.dart';
import 'gear_feed_page.dart' show stockTag;
import '../../../core/widgets/covers.dart';

/// Tampilan saat produk atau toko yang dibuka sudah tidak ada.
class MissingGear extends StatelessWidget {
  const MissingGear({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              PageHeader(title: title),
              const SizedBox(height: 20),
              YbEmptyState(
                icon: Icons.search_off,
                title: '$title tidak ditemukan',
                message: 'Mungkin sudah dihapus tokonya.',
                actionLabel: 'Lihat perlengkapan lain',
                onAction: () => context.go('/perlengkapan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu toko yang bisa diketuk, dipakai di detail produk dan hasil saran.
class ShopTile extends StatelessWidget {
  const ShopTile({super.key, required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return YbCard(
      onTap: () => context.push('/toko/${shop.id}'),
      child: Row(
        children: [
          YbAvatar(shop.initials, accent: true, photoPath: shop.logoPath),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.name, style: YbText.display(size: 16)),
                Text(
                  shop.address,
                  style: YbText.label(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: YbColors.muted),
        ],
      ),
    );
  }
}

/// Membuka WhatsApp toko, atau memberi tahu kalau gagal.
Future<void> contactShop(
  BuildContext context,
  Shop shop,
  String message,
) async {
  final ok = await openWhatsApp(shop.whatsapp, message);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'WhatsApp tidak bisa dibuka. Hubungi ${shop.name} di ${displayWhatsapp(shop.whatsapp)}.',
        ),
      ),
    );
  }
}

/// P17 Detail produk.
class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByIdProvider(productId)).value;
    final loading = ref.watch(productsProvider).isLoading;
    if (product == null) {
      return loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : const MissingGear(title: 'Produk');
    }
    final shop = ref.watch(shopByIdProvider(product.shopId)).value;
    final spec = product.racket;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const PageHeader(title: 'Detail produk'),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(YbRadius.md),
              child: AspectRatio(
                aspectRatio: 1.4,
                child: ProductImage(product: product),
              ),
            ),
            const SizedBox(height: 16),
            Text(product.name, style: YbText.display(size: 24)),
            const SizedBox(height: 4),
            Text(
              formatRupiah(product.price),
              style: YbText.body(
                size: 20,
                color: YbColors.primary,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                stockTag(product.inStock),
                YbTag(product.category.label, tone: YbTagTone.neutral),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              product.description,
              style: YbText.body(color: YbColors.muted, height: 1.5),
            ),
            if (spec != null ||
                product.shoeSizes.isNotEmpty ||
                product.stringType != null) ...[
              const SizedBox(height: 18),
              Text('Spesifikasi', style: YbText.display(size: 17)),
              const SizedBox(height: 8),
              YbCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    if (spec != null) ...[
                      _SpecRow(
                        'Berat',
                        '${spec.weight.label} (${spec.weight.grams})',
                      ),
                      _SpecRow('Titik berat', spec.balance.label),
                      _SpecRow('Batang', spec.flex.label, last: true),
                    ],
                    if (product.shoeSizes.isNotEmpty)
                      _SpecRow(
                        'Ukuran tersedia',
                        'EU ${product.shoeSizes.join(', ')}',
                        last: true,
                      ),
                    if (product.stringType != null)
                      _SpecRow(
                        'Jenis senar',
                        product.stringType!.label,
                        last: true,
                      ),
                  ],
                ),
              ),
            ],
            if (shop != null) ...[
              const SizedBox(height: 18),
              Text('Dijual oleh', style: YbText.display(size: 17)),
              const SizedBox(height: 8),
              ShopTile(shop: shop),
            ],
          ],
        ),
      ),
      bottomNavigationBar: shop == null
          ? null
          : BottomActionBar(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => contactShop(
                      context,
                      shop,
                      product.inStock
                          ? 'Halo ${shop.name}, saya lihat ${product.name} di YukBadmin. Apakah masih tersedia?'
                          : 'Halo ${shop.name}, saya lihat ${product.name} di YukBadmin sedang habis. Kira-kira kapan ada lagi?',
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: Text(
                      product.inStock
                          ? 'Tanya toko lewat WhatsApp'
                          : 'Tanya kapan ada lagi',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow(this.label, this.value, {this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: YbColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: YbText.body(color: YbColors.muted)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: YbText.body(weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
