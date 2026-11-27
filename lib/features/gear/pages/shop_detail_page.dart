import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/photo.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../data/gear_models.dart';
import '../state/gear_providers.dart';
import 'gear_feed_page.dart' show ProductGrid;
import '../../manage/pages/manage_widgets.dart' show openExternal, webUri;
import 'product_detail_page.dart' show MissingGear, contactShop;

/// Membuka lokasi toko di Google Maps: tautan dari toko kalau ada, kalau
/// tidak ada dicari dari alamatnya.
Future<void> openShopMap(BuildContext context, Shop shop) async {
  final link = shop.mapsUrl;
  final uri = link != null && link.isNotEmpty
      ? webUri(link)
      : Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': '${shop.name}, ${shop.address}',
        });
  final ok = await openExternal(uri);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Maps tidak bisa dibuka di perangkat ini.'),
      ),
    );
  }
}

/// P13 Detail toko.
class ShopDetailPage extends ConsumerStatefulWidget {
  const ShopDetailPage({super.key, required this.shopId});

  final String shopId;

  @override
  ConsumerState<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends ConsumerState<ShopDetailPage> {
  GearCategory? _category;

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(shopByIdProvider(widget.shopId)).value;
    if (shop == null) {
      return ref.watch(shopsProvider).isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : const MissingGear(title: 'Toko');
    }
    final all = (ref.watch(productsProvider).value ?? const <Product>[])
        .where((p) => p.shopId == shop.id)
        .toList();
    final categories = GearCategory.values
        .where((c) => all.any((p) => p.category == c))
        .toList();
    final shown = all
        .where((p) => _category == null || p.category == _category)
        .toList();

    final top = MediaQuery.viewPaddingOf(context).top;
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header gelap: sampul toko (kalau ada) diredupkan di belakang.
            Container(
              color: YbColors.night,
              child: Stack(
                children: [
                  if (shop.coverPath != null)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.25,
                        child: YbPhoto(
                          path: shop.coverPath,
                          fallback: const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, top + 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const YbBackButton(),
                        const SizedBox(height: 16),
                        YbAvatar(
                          shop.initials,
                          size: 64,
                          photoPath: shop.logoPath,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          shop.name,
                          style: YbText.display(
                            size: 30,
                            color: YbColors.onNight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: YbColors.onNight.withValues(alpha: 0.75),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Toko partner · ${shop.district}',
                                style: YbText.body(
                                  size: 14,
                                  color: YbColors.onNight.withValues(
                                    alpha: 0.75,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => contactShop(
                      context,
                      shop,
                      'Halo ${shop.name}, saya lihat toko kamu di YukBadmin. Mau tanya soal perlengkapan badminton.',
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: const Text('Tanya stok via WhatsApp'),
                  ),
                  const SizedBox(height: 16),
                  // Hasil UAT: alamat toko diminta lebih jelas, jadi alamat
                  // lengkap, jam buka, dan peta ditampilkan terpisah.
                  YbGroup(
                    children: [
                      YbListRow(
                        icon: Icons.map_outlined,
                        title: 'Buka di Google Maps',
                        subtitle: shop.address,
                        onTap: () => openShopMap(context, shop),
                      ),
                      YbListRow(
                        icon: Icons.schedule_rounded,
                        title: shop.hours,
                        subtitle: shop.description,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  YbSectionTitle('Produk (${all.length})'),
                  const SizedBox(height: 10),
                  if (all.isEmpty)
                    const YbEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Belum ada produk',
                      message: 'Toko ini belum menambahkan produk. Tanya langsung lewat WhatsApp.',
                    )
                  else ...[
                    if (categories.length > 1) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          YbChoiceChip(
                            label: 'Semua',
                            selected: _category == null,
                            onTap: () => setState(() => _category = null),
                          ),
                          for (final c in categories)
                            YbChoiceChip(
                              label: c.label,
                              selected: _category == c,
                              onTap: () => setState(() => _category = c),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    ProductGrid(products: shown),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
