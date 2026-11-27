import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../data/pb_models.dart';
import '../state/providers.dart';
import '../../../core/widgets/covers.dart';

YbTag memberTypeTag(MemberType type) => YbTag(
  type.label,
  tone: type == MemberType.tetap ? YbTagTone.primarySoft : YbTagTone.accent,
);

/// Tombol bintang untuk menyimpan PB.
class SaveStar extends ConsumerWidget {
  const SaveStar({super.key, required this.pb, this.boxed = false});

  final Pb pb;

  /// Tampil sebagai tombol kotak bergaris (di bar aksi detail PB).
  final bool boxed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedProvider.select((s) => s.contains(pb.id)));
    return IconButton(
      tooltip: saved ? 'Hapus dari tersimpan' : 'Simpan PB',
      style: boxed
          ? IconButton.styleFrom(
              backgroundColor: YbColors.surface,
              fixedSize: const Size(52, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(YbRadius.sm),
                side: BorderSide(color: YbColors.ink, width: 1.5),
              ),
            )
          : null,
      onPressed: () {
        final nowSaved = ref.read(savedProvider.notifier).toggle(pb.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                nowSaved
                    ? '${pb.name} disimpan'
                    : '${pb.name} dihapus dari tersimpan',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
      },
      icon: Icon(
        saved ? Icons.star_rounded : Icons.star_outline_rounded,
        color: saved ? YbColors.accent : YbColors.ink,
        size: 26,
      ),
    );
  }
}

/// Kartu PB berfoto (Final Design v4): nama di atas foto, level di pojok
/// kanan atas, lalu jadwal, iuran, dan jumlah member di bawah foto.
class PbPhotoCard extends StatelessWidget {
  const PbPhotoCard({
    super.key,
    required this.pb,
    this.width,
    this.photoHeight = 190,
  });

  final Pb pb;

  /// Lebar tetap untuk deretan mendatar. Kosong = selebar induknya.
  final double? width;
  final double photoHeight;

  String? get _tag {
    final left = pb.quota - pb.memberCount;
    if (!pb.openForNewMembers) return 'Kuota penuh';
    if (left > 0 && left <= 8) return '$left tempat lagi';
    if (pb.minLevel.index <= Level.e.index) return 'Ramah pemula';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = pb.firstSession;
    final tag = _tag;
    final card = YbCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/pb/${pb.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: photoHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Tanpa lampu: posisinya bertabrakan dengan lencana dan level.
                PbCover(pb: pb, showLamps: false),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x3313283F),
                        Color(0x0013283F),
                        Color(0xE613283F),
                      ],
                      stops: [0, 0.35, 1],
                    ),
                  ),
                ),
                if (tag != null)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: tag == 'Ramah pemula'
                            ? YbColors.accent
                            : const Color(0xB313283F),
                        borderRadius: BorderRadius.circular(YbRadius.sm),
                      ),
                      child: Text(
                        tag,
                        style: YbText.body(
                          size: 12,
                          weight: FontWeight.w600,
                          color: tag == 'Ramah pemula'
                              ? YbColors.onAccent
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 14,
                  top: 10,
                  child: Semantics(
                    label: 'Level ${pb.levelRange}',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Level',
                          style: YbText.body(size: 12, color: Colors.white70),
                        ),
                        Text(
                          pb.levelRange,
                          style: YbText.display(size: 30, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pb.name,
                        style: YbText.display(size: 22, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${pb.district} · ${pb.area}',
                        style: YbText.body(size: 13, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        '${s.dayName} ${s.start}',
                        style: YbText.body(size: 14, weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatRupiahShort(pb.feePerSession),
                      style: YbText.body(size: 17, weight: FontWeight.w700),
                    ),
                    Text(
                      ' /sesi',
                      style: YbText.body(size: 12, color: YbColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${pb.memberCount} member · ${pb.primaryType.label}',
                  style: YbText.body(size: 13, color: YbColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return width == null ? card : SizedBox(width: width, child: card);
  }
}

/// Baris PB ringkas untuk PB tersimpan (P7): foto kecil, nama, info, dan
/// level di kanan.
class PbListCard extends StatelessWidget {
  const PbListCard({super.key, required this.pb});

  final Pb pb;

  @override
  Widget build(BuildContext context) {
    final s = pb.firstSession;
    return YbCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/pb/${pb.id}'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(YbRadius.md),
            child: SizedBox(width: 64, height: 64, child: PbCover(pb: pb)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pb.name,
                  style: YbText.body(size: 16, weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${pb.district} · ${pb.memberCount} member · ${pb.primaryType == MemberType.tetap ? 'Tetap' : 'Insidental'}',
                  style: YbText.body(size: 13, color: YbColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.dayName} ${s.start} · ${formatRupiahShort(pb.feePerSession)}/sesi',
                  style: YbText.body(size: 13, weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            pb.levelRange,
            style: YbText.display(size: 22),
            semanticsLabel: 'Level ${pb.levelRange}',
          ),
        ],
      ),
    );
  }
}

/// Kartu PB untuk deretan "PB dekat kamu" di beranda.
class PbTallCard extends StatelessWidget {
  const PbTallCard({super.key, required this.pb});

  final Pb pb;

  @override
  Widget build(BuildContext context) =>
      PbPhotoCard(pb: pb, width: 280, photoHeight: 180);
}
