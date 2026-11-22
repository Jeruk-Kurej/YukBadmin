import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../data/pb_models.dart';
import '../state/providers.dart';
import 'pb_card.dart';

/// Pusat Surabaya, dipakai kalau belum ada PB yang punya titik lokasi.
const _fallbackCenter = LatLng(-7.2900, 112.7500);

/// PB yang punya titik lokasi dan bisa ditaruh di peta.
List<Pb> pbsWithLocation(List<Pb> list) =>
    list.where((pb) => pb.latitude != null && pb.longitude != null).toList();

/// PB yang titiknya berada di dalam [bounds] (hasil "Cari di area ini").
List<Pb> pbsInBounds(List<Pb> located, LatLngBounds bounds) =>
    located.where((pb) => bounds.contains(_pointOf(pb))).toList();

LatLng _pointOf(Pb pb) => LatLng(pb.latitude!, pb.longitude!);

/// P5 Cari PB (peta). Ditampilkan di dalam tab Cari PB, di bawah kolom
/// pencarian dan chip filter yang sama dengan tampilan daftar.
class PbMapView extends ConsumerStatefulWidget {
  const PbMapView({
    super.key,
    required this.onClearFilters,
    required this.onShowList,
  });

  final VoidCallback onClearFilters;
  final VoidCallback onShowList;

  @override
  ConsumerState<PbMapView> createState() => _PbMapViewState();
}

class _PbMapViewState extends ConsumerState<PbMapView> {
  final _map = MapController();
  String? _selectedId;
  bool _tilesFailed = false;

  /// Peta sudah digeser pengguna, jadi tombol "Cari di area ini" muncul.
  bool _moved = false;

  /// Area yang dipilih lewat "Cari di area ini". Null berarti semua area.
  LatLngBounds? _area;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _fitAll(List<Pb> located) {
    if (located.isEmpty) return;
    _map.fitCamera(_fitFor(located));
  }

  CameraFit _fitFor(List<Pb> located) => located.length == 1
      ? CameraFit.coordinates(
          coordinates: [_pointOf(located.first)],
          maxZoom: 15,
        )
      : CameraFit.coordinates(
          coordinates: located.map(_pointOf).toList(),
          padding: const EdgeInsets.fromLTRB(48, 72, 48, 48),
          maxZoom: 15,
        );

  void _onTileError() {
    if (_tilesFailed || !mounted) return;
    // Galat ubin bisa datang di tengah frame, jadi tunda setState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _tilesFailed = true);
    });
  }

  void _searchThisArea() => setState(() {
    _area = _map.camera.visibleBounds;
    _moved = false;
    _selectedId = null;
  });

  void _resetArea(List<Pb> located) {
    setState(() {
      _area = null;
      _moved = false;
    });
    _fitAll(located);
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(filteredPbProvider);

    // Filter berubah: lepaskan batas area dan arahkan ulang kamera.
    ref.listen(filteredPbProvider, (_, next) {
      final located = pbsWithLocation(next.value ?? const []);
      setState(() {
        _area = null;
        _moved = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitAll(located);
      });
    });

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _Message(
        child: YbEmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Peta PB gagal dimuat',
          message: 'Periksa koneksimu, lalu coba lagi.',
          actionLabel: 'Coba lagi',
          onAction: () => ref.invalidate(pbListProvider),
        ),
      ),
      data: (list) {
        final located = pbsWithLocation(list);
        final shown = _area == null ? located : pbsInBounds(located, _area!);
        final unlocated = list.length - located.length;
        final selected = shown.where((pb) => pb.id == _selectedId).firstOrNull;

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _buildMap(located, shown, selected),
                  if (located.isEmpty)
                    _Message(
                      child: YbEmptyState(
                        icon: Icons.location_off_outlined,
                        title: list.isEmpty
                            ? 'Belum ada PB yang cocok'
                            : 'Lokasi PB belum tersedia',
                        message: list.isEmpty
                            ? 'Coba longgarkan filter supaya lebih banyak PB muncul di peta.'
                            : 'PB yang cocok belum punya titik lokasi. Lihat lewat daftar dulu.',
                        actionLabel: list.isEmpty
                            ? 'Hapus semua filter'
                            : 'Lihat daftar',
                        onAction: list.isEmpty
                            ? widget.onClearFilters
                            : widget.onShowList,
                      ),
                    ),
                  if (located.isNotEmpty && (_moved || _area != null))
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _moved
                            ? _FloatingPill(
                                icon: Icons.search,
                                label: 'Cari di area ini',
                                onTap: _searchThisArea,
                              )
                            : _FloatingPill(
                                icon: Icons.close,
                                label: '${shown.length} PB di area ini',
                                tooltip: 'Tampilkan semua area',
                                onTap: () => _resetArea(located),
                              ),
                      ),
                    ),
                  if (located.length > 1)
                    Positioned(
                      right: 12,
                      bottom: 28,
                      child: IconButton(
                        tooltip: 'Tampilkan semua PB',
                        onPressed: () => _resetArea(located),
                        style: IconButton.styleFrom(
                          backgroundColor: YbColors.surface,
                          side: BorderSide(color: YbColors.line),
                          fixedSize: const Size(44, 44),
                        ),
                        icon: Icon(
                          Icons.zoom_out_map,
                          size: 20,
                          color: YbColors.ink,
                        ),
                      ),
                    ),
                  const Positioned(left: 8, bottom: 6, child: _Attribution()),
                ],
              ),
            ),
            _BottomPanel(
              selected: selected,
              hint: located.isEmpty
                  ? null
                  : _area != null && shown.isEmpty
                  ? 'Tidak ada PB di area ini. Geser peta atau tampilkan semua area.'
                  : unlocated > 0
                  ? 'Ketuk pin untuk melihat PB. $unlocated PB lain belum punya titik lokasi, cek di daftar.'
                  : 'Ketuk pin untuk melihat PB.',
              tilesFailed: _tilesFailed,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMap(List<Pb> located, List<Pb> shown, Pb? selected) {
    final tilesEnabled = ref.watch(mapTilesEnabledProvider);
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _fallbackCenter,
        initialZoom: 12,
        initialCameraFit: located.isEmpty ? null : _fitFor(located),
        minZoom: 9,
        maxZoom: 18,
        backgroundColor: YbColors.line,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (_, _) => setState(() => _selectedId = null),
        onPositionChanged: (_, hasGesture) {
          if (hasGesture && !_moved) setState(() => _moved = true);
        },
      ),
      children: [
        if (tilesEnabled)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.oheb.yukbadmin',
            errorTileCallback: (_, _, _) => _onTileError(),
          ),
        MarkerLayer(
          markers: [
            // PB terpilih digambar terakhir supaya berada di atas pin lain.
            for (final pb in [
              ...shown.where((p) => p.id != selected?.id),
              ?selected,
            ])
              pb.id == selected?.id
                  ? Marker(
                      key: ValueKey(pb.id),
                      point: _pointOf(pb),
                      width: 200,
                      height: 84,
                      alignment: Alignment.topCenter,
                      child: _PbPin(
                        pb: pb,
                        selected: true,
                        onTap: () => setState(() => _selectedId = pb.id),
                      ),
                    )
                  : Marker(
                      key: ValueKey(pb.id),
                      point: _pointOf(pb),
                      width: 44,
                      height: 44,
                      child: _PbPin(
                        pb: pb,
                        selected: false,
                        onTap: () => setState(() => _selectedId = pb.id),
                      ),
                    ),
          ],
        ),
      ],
    );
  }
}

/// Pin PB berbentuk lingkaran berikon kok. Pin terpilih lebih besar,
/// berwarna merah, dan menampilkan nama PB di atasnya.
class _PbPin extends StatelessWidget {
  const _PbPin({required this.pb, required this.selected, required this.onTap});

  final Pb pb;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 44.0 : 34.0;
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? YbColors.primary : YbColors.night,
        shape: BoxShape.circle,
        border: Border.all(color: YbColors.surface, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.sports_tennis,
        size: selected ? 22 : 16,
        color: selected ? Colors.white : YbColors.accent,
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: pb.name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: selected
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: YbColors.night,
                      borderRadius: BorderRadius.circular(YbRadius.sm),
                    ),
                    child: Text(
                      pb.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YbText.body(
                        size: 12,
                        color: Colors.white,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  dot,
                ],
              )
            : dot,
      ),
    );
  }
}

/// Tombol pil yang mengambang di atas peta.
class _FloatingPill extends StatelessWidget {
  const _FloatingPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final pill = Material(
      color: YbColors.surface,
      shape: StadiumBorder(side: BorderSide(color: YbColors.line)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: YbColors.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: YbText.body(
                      size: 13,
                      color: YbColors.primary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip, child: pill);
  }
}

/// Panel di bawah peta: kartu PB terpilih, atau petunjuk cara memakai peta.
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.selected,
    required this.hint,
    required this.tilesFailed,
  });

  final Pb? selected;
  final String? hint;
  final bool tilesFailed;

  @override
  Widget build(BuildContext context) {
    if (selected == null && hint == null && !tilesFailed) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tilesFailed) ...[
            Row(
              children: [
                Icon(Icons.wifi_off, size: 16, color: YbColors.primaryDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Gambar peta tidak termuat. Periksa koneksimu; pin PB tetap bisa diketuk.',
                    style: YbText.body(size: 12, color: YbColors.primaryDark),
                  ),
                ),
              ],
            ),
            if (selected != null || hint != null) const SizedBox(height: 10),
          ],
          if (selected != null)
            PbListCard(pb: selected!)
          else if (hint != null)
            Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 18, color: YbColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hint!,
                    style: YbText.body(size: 13, color: YbColors.muted),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Atribusi wajib untuk ubin OpenStreetMap.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: YbColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '© kontributor OpenStreetMap',
        style: YbText.body(size: 10, color: YbColors.muted),
      ),
    );
  }
}

/// Membungkus keadaan kosong atau galat supaya berada di tengah area peta.
class _Message extends StatelessWidget {
  const _Message({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}
