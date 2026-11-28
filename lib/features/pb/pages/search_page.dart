import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/tours.dart';
import '../../../core/widgets/yb_brand.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../data/pb_models.dart';
import '../state/providers.dart';
import 'filter_sheet.dart';
import 'level_guide.dart';
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

  /// Kolom pencarian, pilihan level, dan chip filter, dipakai di tampilan
  /// daftar dan peta.
  List<Widget> _controls(
    PbFilter filter,
    bool nightOnly, {
    bool levels = true,
    bool onNight = false,
  }) {
    final myLevel = ref.watch(preferencesProvider).level;
    return [
      TextField(
        controller: _query,
        textInputAction: TextInputAction.search,
        onChanged: ref.read(filterProvider.notifier).setQuery,
        style: YbText.body(size: 16, color: onNight ? YbColors.onAccent : null),
        decoration: InputDecoration(
          hintText: 'Cari nama PB, GOR, atau area',
          hintStyle: onNight ? YbText.body(color: YbPalette.light.muted) : null,
          filled: true,
          fillColor: onNight
              ? Colors.white
              : YbColors.isDark
              ? YbColors.surface
              : YbColors.pendingSoft,
          prefixIcon: Icon(
            Icons.search,
            color: onNight ? YbColors.onAccent : YbColors.muted,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(YbRadius.pill),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(YbRadius.pill),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(YbRadius.pill),
            borderSide: BorderSide(color: YbColors.primary, width: 1.5),
          ),
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
      if (levels) ...[
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Level',
              style: YbText.body(
                size: 13,
                color: onNight
                    ? YbColors.onNight.withValues(alpha: 0.75)
                    : YbColors.muted,
              ),
            ),
            const Spacer(),
            Flexible(
              child: InkWell(
                onTap: () => showLevelGuide(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    myLevel == null
                        ? 'Panduan level ›'
                        : 'Levelmu ${myLevel.label} · Panduan level ›',
                    style: YbText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: onNight ? YbColors.accent : YbColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final (i, l) in Level.values.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _LevelSquare(
                  level: l,
                  selected: filter.levels.contains(l),
                  mine: l == myLevel,
                  onNight: onNight,
                  onTap: () {
                    final next = {...filter.levels};
                    if (!next.remove(l)) next.add(l);
                    ref
                        .read(filterProvider.notifier)
                        .set(filter.copyWith(levels: next));
                  },
                ),
              ),
            ],
          ],
        ),
      ],
      const SizedBox(height: 14),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            _FilterButton(
              key: TourKeys.searchFilter,
              count: filter.activeCount,
              onTap: () => showFilterSheet(context),
            ),
            const SizedBox(width: 8),
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
            const SizedBox(width: 8),
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
      ),
    ];
  }

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  YbPageTitle(
                    'Peta PB',
                    trailing: _RoundIcon(
                      icon: Icons.list,
                      tooltip: 'Tampilkan daftar',
                      onTap: () => setState(() => _mapView = false),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._controls(filter, nightOnly, levels: false),
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

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: YbSheetHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            'Cari PB',
                            style: YbText.hero(
                              size: 32,
                              color: YbColors.onNight,
                            ),
                          ),
                        ),
                      ),
                      YbNightIconButton(
                        icon: Icons.star_outline_rounded,
                        tooltip: 'PB tersimpan',
                        onPressed: () => context.push('/tersimpan'),
                      ),
                      const SizedBox(width: 8),
                      YbNightIconButton(
                        icon: Icons.map_outlined,
                        tooltip: 'Tampilkan peta',
                        onPressed: () => setState(() => _mapView = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ..._controls(filter, nightOnly, onNight: true),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverList.list(
              children: [
                Text(
                  count == null
                      ? 'Memuat PB…'
                      : filtering
                      ? '$count PB cocok'
                      : '$count PB terdaftar',
                  style: YbText.display(size: 20),
                ),
                const SizedBox(height: 12),
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => PbPhotoCard(pb: list[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tombol ikon bulat putih di kanan judul.
class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    style: IconButton.styleFrom(
      backgroundColor: YbColors.surface,
      fixedSize: const Size(44, 44),
    ),
    icon: Icon(icon, size: 22, color: YbColors.ink),
  );
}

/// Kotak level F–S. Yang dipilih biru tua; level pemain ditandai titik.
class _LevelSquare extends StatelessWidget {
  const _LevelSquare({
    required this.level,
    required this.selected,
    required this.mine,
    required this.onTap,
    this.onNight = false,
  });

  final Level level;
  final bool selected;
  final bool mine;
  final VoidCallback onTap;

  /// Tampil di atas kepala halaman biru malam.
  final bool onNight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Level ${level.label}${mine ? ', levelmu' : ''}',
      excludeSemantics: true,
      child: Material(
        color: onNight
            ? (selected
                  ? YbColors.accent
                  : Colors.white.withValues(alpha: 0.12))
            : (selected ? YbColors.primary : YbColors.surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(YbRadius.md),
          side: onNight
              ? BorderSide(
                  color: mine
                      ? YbColors.accent
                      : Colors.white.withValues(alpha: 0.16),
                )
              : BorderSide(color: selected ? YbColors.primary : YbColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                level.label,
                style: YbText.body(
                  size: 18,
                  weight: FontWeight.w700,
                  color: onNight
                      ? (selected ? YbColors.onAccent : YbColors.onNight)
                      : (selected ? YbColors.onPrimary : YbColors.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol "Filter · n" biru tua.
class _FilterButton extends StatelessWidget {
  const _FilterButton({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Material(
      color: active ? YbColors.night : YbColors.surface,
      shape: StadiumBorder(
        side: active ? BorderSide.none : BorderSide(color: YbColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune,
                  size: 18,
                  color: active ? Colors.white : YbColors.ink,
                ),
                const SizedBox(width: 6),
                Text(
                  active ? 'Filter · $count' : 'Filter',
                  style: YbText.body(
                    size: 14,
                    weight: FontWeight.w600,
                    color: active ? Colors.white : YbColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
