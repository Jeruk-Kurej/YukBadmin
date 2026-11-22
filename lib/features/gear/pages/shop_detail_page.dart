import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/photo.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../manage/pages/manage_widgets.dart';
import '../data/gear_models.dart';
import '../state/gear_providers.dart';
import 'gear_feed_page.dart' show ProductGrid;
import 'product_detail_page.dart' show MissingGear, contactShop;

/// Membuka lokasi toko di Google Maps: tautan dari toko kalau ada, kalau
/// tidak ada dicari dari alamatnya.
Future<void> openShopMap(BuildContext context, Shop shop) async {
  final link = shop.mapsUrl;
  final uri = link != null && link.isNotEmpty
      ? Uri.parse(link.startsWith('http') ? link : 'https://$link')
      : Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': '${shop.name}, ${shop.address}',
        });
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            PageHeader(title: shop.name),
            if (shop.coverPath != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(YbRadius.md),
                child: SizedBox(
                  height: 140,
                  child: YbPhoto(
                    path: shop.coverPath,
                    fallback: ColoredBox(color: YbColors.accentSoft),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                YbAvatar(
                  shop.initials,
                  size: 56,
                  accent: true,
                  photoPath: shop.logoPath,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop.name, style: YbText.display(size: 20)),
                      Text(
                        'Toko partner · ${shop.district}',
                        style: YbText.label(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Hasil UAT: alamat toko diminta lebih jelas, jadi alamat lengkap,
            // jam buka, dan tombol peta ditampilkan terpisah.
            YbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoLine(icon: Icons.place_outlined, text: shop.address),
                  const SizedBox(height: 10),
                  _InfoLine(icon: Icons.schedule, text: shop.hours),
                  const SizedBox(height: 10),
                  _InfoLine(
                    icon: Icons.storefront_outlined,
                    text: shop.description,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => openShopMap(context, shop),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Buka di Google Maps'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Produk (${all.length})', style: YbText.display(size: 17)),
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
      bottomNavigationBar: BottomActionBar(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => contactShop(
                context,
                shop,
                'Halo ${shop.name}, saya lihat toko kamu di YukBadmin. Mau tanya soal perlengkapan badminton.',
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: const Text('Hubungi toko lewat WhatsApp'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: YbColors.ink),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: YbText.body())),
      ],
    );
  }
}
