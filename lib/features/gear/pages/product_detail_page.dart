import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../manage/data/manage_models.dart' show displayWhatsapp;
import '../../manage/pages/manage_widgets.dart';
import '../data/gear_models.dart';
import '../state/gear_providers.dart';
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
    return YbGroup(
      children: [
        YbListRow(
          leading: YbAvatar(shop.initials, size: 40, photoPath: shop.logoPath),
          title: shop.name,
          subtitle: shop.address,
          onTap: () => context.push('/toko/${shop.id}'),
        ),
      ],
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

    final top = MediaQuery.viewPaddingOf(context).top;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 300 + top,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Semantics(
                    label: 'Foto ${product.name}',
                    image: true,
                    child: ProductImage(product: product),
                  ),
                ),
                Positioned(left: 16, top: top + 8, child: const YbBackButton()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _StockPill(inStock: product.inStock),
                ),
                const SizedBox(height: 10),
                Semantics(
                  header: true,
                  child: Text(product.name, style: YbText.display(size: 28)),
                ),
                const SizedBox(height: 6),
                Text(
                  formatRupiah(product.price),
                  style: YbText.display(size: 26, color: YbColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  product.category.label,
                  style: YbText.body(size: 13, color: YbColors.muted),
                ),
                const SizedBox(height: 12),
                Text(product.description, style: YbText.body(height: 1.5)),
                if (spec != null ||
                    product.shoeSizes.isNotEmpty ||
                    product.stringType != null) ...[
                  const SizedBox(height: 24),
                  YbSectionTitle('Spesifikasi'),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 24),
                  YbSectionTitle('Dijual oleh'),
                  const SizedBox(height: 10),
                  ShopTile(shop: shop),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: YbColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Beli dan cek stok lewat WhatsApp toko.',
                          style: YbText.body(size: 13, color: YbColors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
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
                          ? 'Tanya stok via WhatsApp'
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

/// Label stok. Disebut "menurut toko" karena stok diisi toko sendiri dan
/// bisa terlambat diperbarui.
class _StockPill extends StatelessWidget {
  const _StockPill({required this.inStock});

  final bool inStock;

  @override
  Widget build(BuildContext context) {
    final fg = inStock ? YbColors.success : YbColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: inStock ? YbColors.successSoft : YbColors.warningSoft,
        borderRadius: BorderRadius.circular(YbRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              inStock ? 'Tersedia menurut toko' : 'Habis menurut toko',
              style: YbText.body(size: 13, weight: FontWeight.w600, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
