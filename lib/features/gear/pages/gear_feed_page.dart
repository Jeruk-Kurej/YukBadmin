import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/tours.dart';
import '../../../core/widgets/yb_brand.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../data/gear_models.dart';
import '../state/gear_providers.dart';
import '../../../core/widgets/covers.dart';

YbTag stockTag(bool inStock) => inStock
    ? const YbTag('Tersedia', tone: YbTagTone.success)
    : const YbTag('Habis', tone: YbTagTone.warning);

/// Kartu produk untuk grid feed dan halaman toko.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.shopName});

  final Product product;
  final String? shopName;

  @override
  Widget build(BuildContext context) {
    return YbCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/produk/${product.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 1.3, child: ProductImage(product: product)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                stockTag(product.inStock),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  style: YbText.body(size: 14, weight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(product.price),
                  style: YbText.score(size: 17),
                ),
                if (shopName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 14,
                        color: YbColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shopName!,
                          style: YbText.label(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}

/// Grid dua kolom yang tingginya mengikuti isi, supaya teks panjang tidak
/// terpotong di layar kecil atau teks besar.
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, this.shopNames});

  final List<Product> products;
  final Map<String, String>? shopNames;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < products.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = i; j < i + 2; j++) ...[
                if (j > i) const SizedBox(width: 10),
                Expanded(
                  child: j < products.length
                      ? ProductCard(
                          product: products[j],
                          shopName: shopNames?[products[j].shopId],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
      rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }
}

/// P16 Perlengkapan (feed).
class GearFeedPage extends ConsumerStatefulWidget {
  const GearFeedPage({super.key});

  @override
  ConsumerState<GearFeedPage> createState() => _GearFeedPageState();
}

class _GearFeedPageState extends ConsumerState<GearFeedPage> {
  final _search = TextEditingController();
  GearCategory? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final shops = ref.watch(shopsProvider).value ?? const <Shop>[];
    final shopNames = {for (final s in shops) s.id: s.name};
    final q = _search.text.trim().toLowerCase();

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          YbSheetHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Perlengkapan',
                    style: YbText.hero(size: 32, color: YbColors.onNight),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dari toko partner di Surabaya',
                  style: YbText.body(
                    size: 14,
                    color: YbColors.onNight.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: YbText.body(size: 15, color: YbColors.onAccent),
                  decoration: InputDecoration(
                    hintText: 'Cari raket, sepatu, senar',
                    hintStyle: YbText.body(color: YbPalette.light.muted),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: YbColors.onAccent,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(YbRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(YbRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _AdvisorBanner(
                  key: TourKeys.gearAdvisor,
                  onTap: () => context.push('/saran'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final (i, (c, icon)) in <(GearCategory?, IconData)>[
                  (null, Icons.apps_rounded),
                  (GearCategory.raket, Icons.sports_tennis),
                  (GearCategory.sepatu, Icons.directions_run),
                  (GearCategory.senar, Icons.blur_circular),
                  (GearCategory.grip, Icons.back_hand_outlined),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _CategoryTile(
                      label: c?.label ?? 'Semua',
                      icon: icon,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => YbEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Produk gagal dimuat',
                message: 'Periksa koneksimu, lalu coba lagi.',
                actionLabel: 'Coba lagi',
                onAction: () => ref.invalidate(productsProvider),
              ),
              data: (all) {
                final shown =
                    all
                        .where(
                          (p) => _category == null || p.category == _category,
                        )
                        .where(
                          (p) =>
                              q.isEmpty ||
                              '${p.name} ${p.category.label} ${shopNames[p.shopId] ?? ''}'
                                  .toLowerCase()
                                  .contains(q),
                        )
                        .toList()
                      ..sort((a, b) {
                        if (a.inStock != b.inStock) return a.inStock ? -1 : 1;
                        return a.name.compareTo(b.name);
                      });
                if (shown.isEmpty) {
                  return YbEmptyState(
                    icon: Icons.search_off,
                    title: 'Produk tidak ditemukan',
                    message: 'Coba kata kunci lain atau pilih kategori Semua.',
                    actionLabel: 'Hapus pencarian',
                    onAction: () => setState(() {
                      _search.clear();
                      _category = null;
                    }),
                  );
                }
                return ProductGrid(products: shown, shopNames: shopNames);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner saran perlengkapan di kepala halaman: biru malam dengan panel
/// limau miring dan ikon raket.
class _AdvisorBanner extends StatelessWidget {
  const _AdvisorBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YbBrand.nightRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(YbRadius.lg),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _LimePanelPainter(YbColors.accent)),
            ),
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: -0.5,
                  child: const Icon(
                    Icons.sports_tennis,
                    size: 72,
                    color: YbColors.onAccent,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 120, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bingung pilih raket atau sepatu?',
                    style: YbText.hero(
                      size: 19,
                      color: YbColors.onNight,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jawab 3 pertanyaan, kami pilihkan lengkap dengan alasannya.',
                    style: YbText.body(
                      size: 13,
                      color: YbColors.onNight.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 7, 10, 7),
                    decoration: BoxDecoration(
                      color: YbColors.accent,
                      borderRadius: BorderRadius.circular(YbRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mulai',
                          style: YbText.body(
                            size: 14,
                            weight: FontWeight.w700,
                            color: YbColors.onAccent,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: YbColors.onAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimePanelPainter extends CustomPainter {
  const _LimePanelPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w - 70, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h)
        ..lineTo(w - 150, h)
        ..close(),
      Paint()..color = color,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w - 100, 0)
        ..lineTo(w - 88, 0)
        ..lineTo(w - 168, h)
        ..lineTo(w - 180, h)
        ..close(),
      Paint()..color = color.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_LimePanelPainter old) => old.color != color;
}

/// Ubin kategori berikon: kapsul dengan ikon, label di bawahnya.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(YbRadius.md),
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 48,
              decoration: BoxDecoration(
                color: selected ? YbColors.night : YbColors.surface,
                borderRadius: BorderRadius.circular(YbRadius.pill),
                border: Border.all(
                  color: selected ? YbColors.night : YbColors.line,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? YbColors.accent : YbColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: YbText.body(
                size: 12,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
