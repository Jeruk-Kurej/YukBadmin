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

/// Kartu PB mendatar untuk daftar hasil pencarian dan PB tersimpan.
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(YbRadius.sm),
            child: SizedBox(width: 76, height: 92, child: PbCover(pb: pb)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pb.name,
                  style: YbText.display(size: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${pb.district} · ${pb.memberCount} member',
                  style: YbText.label(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${s.dayName} ${s.start} · ${formatRupiah(pb.feePerSession)}/sesi',
                  style: YbText.label(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: memberTypeTag(pb.primaryType),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pb.levelRange,
                      style: YbText.display(size: 16, color: YbColors.primary),
                      semanticsLabel: 'Level ${pb.levelRange}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          SaveStar(pb: pb),
        ],
      ),
    );
  }
}

/// Kartu PB tegak untuk deretan "PB terdekat" di beranda.
class PbTallCard extends StatelessWidget {
  const PbTallCard({super.key, required this.pb});

  final Pb pb;

  @override
  Widget build(BuildContext context) {
    final s = pb.firstSession;
    return SizedBox(
      width: 196,
      child: YbCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push('/pb/${pb.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 104,
              width: double.infinity,
              child: PbCover(pb: pb),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pb.name,
                    style: YbText.display(size: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pb.district} · ${s.dayName} ${s.start}',
                    style: YbText.label(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: memberTypeTag(pb.primaryType),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pb.levelRange,
                        style: YbText.display(
                          size: 15,
                          color: YbColors.primary,
                        ),
                        semanticsLabel: 'Level ${pb.levelRange}',
                      ),
                    ],
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
