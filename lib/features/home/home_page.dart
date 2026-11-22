import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/tours.dart';
import '../../core/widgets/tour.dart';
import '../../core/widgets/yb_widgets.dart';
import '../club/pages/club_pages.dart' show ClubHomeCard;
import '../pb/pages/pb_card.dart';
import '../manage/pages/manage_widgets.dart' show RoleSwitchButton;
import '../manage/state/manage_providers.dart';
import '../pb/state/providers.dart';

/// P3 Beranda.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final hasPb = ref.watch(manageProvider.select((s) => s.hasPb));
    final prefs = ref.watch(preferencesProvider);
    final nearby = ref.watch(nearbyPbProvider);
    final recommended = ref.watch(recommendedPbProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      color: YbColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        prefs.area,
                        style: YbText.body(size: 15, weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Semantics(
                      button: true,
                      label: 'Buka akun',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.go('/akun'),
                        child: YbAvatar(
                          user?.initials ?? '?',
                          size: 40,
                          accent: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Halo, ${user?.firstName ?? 'pemain'}',
                  style: YbText.label(),
                ),
                const SizedBox(height: 2),
                Text('Siap main di mana?', style: YbText.display(size: 24)),
                if (hasPb) ...[
                  const SizedBox(height: 12),
                  RoleSwitchButton(
                    label: 'Beralih ke Kelola PB',
                    onPressed: () => context.go('/kelola/beranda'),
                  ),
                ],
                const SizedBox(height: 18),
                if (!ref.watch(playerTourSeenProvider)) ...[
                  TourBanner(
                    title: 'Baru di YukBadmin?',
                    message: 'Kenalan dengan fitur utamanya dalam 1 menit.',
                    onStart: () => startPlayerTour(context, ref),
                    onClose: () =>
                        ref.read(playerTourSeenProvider.notifier).markSeen(),
                  ),
                  const SizedBox(height: 14),
                ],
                // Kolom cari di beranda hanya pintu masuk ke tab Cari PB.
                Semantics(
                  key: TourKeys.homeSearch,
                  button: true,
                  label: 'Cari nama PB atau area',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(YbRadius.sm),
                    onTap: () => context.go('/cari'),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: YbColors.surface,
                        borderRadius: BorderRadius.circular(YbRadius.sm),
                        border: Border.all(color: YbColors.line),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: YbColors.ink, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cari nama PB atau area',
                              style: YbText.body(color: YbColors.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const ClubHomeCard(),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'PB terdekat',
            actionLabel: 'Lihat semua',
            onAction: () => context.go('/cari'),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120),
            child: nearby.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const _LoadError(),
              data: (list) => list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Belum ada PB terdaftar di ${prefs.area}. Coba ubah area di Akun.',
                          style: YbText.body(color: YbColors.muted),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final (i, pb) in list.indexed) ...[
                              if (i > 0) const SizedBox(width: 12),
                              PbTallCard(pb: pb),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 22),
          const _SectionHeader(title: 'Cocok untuk kamu'),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: recommended.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const _LoadError(),
              data: (list) => Column(
                children: [
                  for (final pb in list) ...[
                    PbListCard(pb: pb),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Material(
              color: YbColors.night,
              borderRadius: BorderRadius.circular(YbRadius.md),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: YbColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 20,
                        color: YbColors.onAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bingung pilih raket?',
                            style: YbText.display(
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Dapat saran sesuai gaya mainmu',
                            style: YbText.label(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: YbColors.accent,
                        foregroundColor: YbColors.onAccent,
                        minimumSize: const Size(64, 44),
                      ),
                      onPressed: () => context.push('/saran'),
                      child: const Text('Coba'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: YbText.display(size: 18))),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: YbText.body(
                  color: YbColors.primary,
                  weight: FontWeight.w700,
                ),
              ),
            )
          else
            const SizedBox(width: 12, height: 48),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'Daftar PB gagal dimuat. Tutup lalu buka lagi aplikasinya.',
      style: YbText.body(color: YbColors.muted),
    ),
  );
}
