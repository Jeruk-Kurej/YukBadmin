import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/tours.dart';
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
                Text(
                  product.name,
                  style: YbText.body(size: 14, weight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(product.price),
                  style: YbText.display(size: 17),
                ),
                if (shopName != null)
                  Text(
                    shopName!,
                    style: YbText.label(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                stockTag(product.inStock),
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

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const YbPageTitle(
            'Perlengkapan',
            subtitle: 'Dari toko partner di Surabaya',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: YbText.body(size: 15),
            decoration: InputDecoration(
              hintText: 'Cari raket, sepatu, senar',
              prefixIcon: Icon(Icons.search_rounded, color: YbColors.muted),
              filled: true,
              fillColor: YbColors.surface,
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
          Material(
            key: TourKeys.gearAdvisor,
            color: YbColors.night,
            borderRadius: BorderRadius.circular(YbRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/saran'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: YbColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.tips_and_updates_outlined,
                        color: YbColors.onAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bingung pilih raket atau sepatu?',
                            style: YbText.body(
                              size: 16,
                              weight: FontWeight.w600,
                              color: YbColors.onNight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Jawab 3 pertanyaan, kami pilihkan lengkap dengan alasannya.',
                            style: YbText.body(
                              size: 13,
                              color: YbColors.onNight.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: YbColors.onNight.withValues(alpha: 0.75),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              YbChoiceChip(
                label: 'Semua',
                selected: _category == null,
                onTap: () => setState(() => _category = null),
              ),
              for (final c in GearCategory.values)
                YbChoiceChip(
                  label: c.label,
                  selected: _category == c,
                  onTap: () => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 14),
          products.when(
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
        ],
      ),
    );
  }
}
