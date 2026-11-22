import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/tours.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../data/pb_models.dart';
import '../state/providers.dart';
import 'filter_sheet.dart';
import 'map_page.dart';
import 'pb_card.dart';

/// P4 Cari PB (daftar) dan P5 Cari PB (peta). Keduanya memakai pencarian
/// dan filter yang sama, jadi hasilnya selalu sama.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final _query = TextEditingController(
    text: ref.read(filterProvider).query,
  );
  bool _mapView = false;

  void _clearAll() {
    _query.clear();
    ref.read(filterProvider.notifier).set(const PbFilter());
  }

  /// Kolom pencarian dan chip filter, dipakai di tampilan daftar dan peta.
  List<Widget> _controls(PbFilter filter, bool nightOnly) => [
    TextField(
      controller: _query,
      textInputAction: TextInputAction.search,
      onChanged: ref.read(filterProvider.notifier).setQuery,
      style: YbText.body(size: 15),
      decoration: InputDecoration(
        hintText: 'Cari nama PB atau area',
        prefixIcon: Icon(Icons.search, color: YbColors.ink),
        suffixIcon: filter.query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  _query.clear();
                  ref.read(filterProvider.notifier).setQuery('');
                },
              ),
      ),
    ),
    const SizedBox(height: 12),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        YbChoiceChip(
          key: TourKeys.searchFilter,
          icon: Icons.tune,
          label: filter.activeCount > 0
              ? 'Filter (${filter.activeCount})'
              : 'Filter',
          selected: filter.activeCount > 0,
          onTap: () => showFilterSheet(context),
        ),
        YbChoiceChip(
          label: 'Main malam',
          selected: nightOnly,
          onTap: () => ref
              .read(filterProvider.notifier)
              .set(
                filter.copyWith(
                  dayParts: nightOnly ? const {} : const {DayPart.malam},
                ),
              ),
        ),
        YbChoiceChip(
          label: 'Akhir pekan',
          selected: filter.weekendOnly,
          onTap: () => ref
              .read(filterProvider.notifier)
              .set(
                filter.copyWith(
                  weekendOnly: !filter.weekendOnly,
                  weekdaysOnly: false,
                ),
              ),
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterProvider);
    final results = ref.watch(filteredPbProvider);
    final count = results.value?.length;
    final filtering = filter.activeCount > 0 || filter.query.trim().isNotEmpty;
    final nightOnly =
        filter.dayParts.length == 1 && filter.dayParts.contains(DayPart.malam);

    if (_mapView) {
      return SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Peta PB',
                            style: YbText.display(size: 30),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _mapView = false),
                        icon: const Icon(Icons.list, size: 18),
                        label: const Text('Daftar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._controls(filter, nightOnly),
                ],
              ),
            ),
            Expanded(
              child: PbMapView(
                onClearFilters: _clearAll,
                onShowList: () => setState(() => _mapView = false),
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text('Cari PB', style: YbText.display(size: 30)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/tersimpan'),
                      icon: const Icon(Icons.star_outline_rounded, size: 18),
                      label: const Text('Tersimpan'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      count?.toString() ?? '–',
                      style: YbText.display(
                        size: 40,
                        color: YbColors.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          filtering ? 'PB sesuai pencarianmu' : 'PB terdaftar',
                          style: YbText.body(color: YbColors.muted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _mapView = true),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Peta'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ..._controls(filter, nightOnly),
                const SizedBox(height: 14),
              ],
            ),
          ),
          results.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: YbEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Daftar PB gagal dimuat',
                  message: 'Periksa koneksimu, lalu coba lagi.',
                  actionLabel: 'Coba lagi',
                  onAction: () => ref.invalidate(pbListProvider),
                ),
              ),
            ),
            data: (list) => list.isEmpty
                ? SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverToBoxAdapter(
                      child: YbEmptyState(
                        icon: Icons.search_off,
                        title: 'Belum ada PB yang cocok',
                        message: 'Coba longgarkan filter atau pakai kata kunci lain, misalnya nama kecamatan.',
                        actionLabel: 'Hapus semua filter',
                        onAction: _clearAll,
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => PbListCard(pb: list[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
