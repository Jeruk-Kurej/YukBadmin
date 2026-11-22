import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/theme_mode.dart';
import '../../app/tours.dart';
import '../../core/widgets/yb_widgets.dart';
import '../pb/data/pb_models.dart';
import '../club/state/club_providers.dart';
import '../gear/state/gear_providers.dart';
import '../manage/state/manage_providers.dart';
import '../pb/state/providers.dart';

/// P14 Akun.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final prefs = ref.watch(preferencesProvider);
    final savedCount = ref.watch(savedProvider).length;
    final clubCount = ref.watch(membershipProvider).length;
    final hasPb = ref.watch(manageProvider.select((s) => s.hasPb));
    final hasShop = ref.watch(ownShopProvider.select((s) => s.hasShop));
    final themeMode = ref.watch(themeModeProvider);

    final days = prefs.weekdays.toList()..sort();
    final dayText = days.isEmpty
        ? 'Belum dipilih'
        : days.map((d) => dayShort[d]).join(', ');

    return SafeArea(
      bottom: false,
      // Bukan ListView, supaya semua bagian sudah dibangun dan bisa disorot tur.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Akun', style: YbText.display(size: 30)),
            const SizedBox(height: 16),
            Row(
              children: [
                YbAvatar(user?.initials ?? '?', size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '-', style: YbText.display(size: 20)),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '-', style: YbText.label()),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _MenuTile(
              key: TourKeys.accountClub,
              icon: Icons.groups_outlined,
              title: 'PB-ku',
              subtitle: clubCount == 0
                  ? 'PB tempat kamu jadi member'
                  : 'Jadwal dan iuran di $clubCount PB',
              onTap: () => context.push('/pb-ku'),
            ),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.star_outline_rounded,
              title: 'PB tersimpan',
              subtitle: savedCount == 0
                  ? 'Lihat PB yang kamu simpan'
                  : '$savedCount PB kamu simpan',
              onTap: () => context.push('/tersimpan'),
            ),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.tune,
              title: 'Preferensi main',
              subtitle:
                  'Level ${prefs.level?.label ?? 'belum tahu'} · ${prefs.area} · $dayText',
              onTap: () => context.push('/preferensi/ubah'),
            ),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.play_circle_outline,
              title: 'Tur aplikasi',
              subtitle: 'Lihat lagi cara memakai YukBadmin',
              onTap: () => startPlayerTour(context, ref),
            ),
            const SizedBox(height: 22),
            Text('Tampilan', style: YbText.display(size: 17)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (mode, label) in [
                  (ThemeMode.system, 'Ikuti sistem'),
                  (ThemeMode.light, 'Terang'),
                  (ThemeMode.dark, 'Gelap'),
                ])
                  YbChoiceChip(
                    label: label,
                    selected: themeMode == mode,
                    onTap: () => ref.read(themeModeProvider.notifier).set(mode),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text('Peran lain', style: YbText.display(size: 17)),
            const SizedBox(height: 4),
            Text(
              'Satu akun bisa dipakai sebagai pemain, pengurus PB, dan toko.',
              style: YbText.label(),
            ),
            const SizedBox(height: 10),
            const _RoleTile(
              title: 'Pemain',
              subtitle: 'Cari dan simpan PB',
              active: true,
            ),
            const SizedBox(height: 8),
            _RoleTile(
              key: TourKeys.accountManagerRole,
              title: 'Pengurus PB',
              subtitle: hasPb
                  ? 'Kelola member, jadwal, dan iuran'
                  : 'Punya PB? Daftarkan dan kelola member di sini',
              actionLabel: hasPb ? 'Beralih' : 'Daftarkan PB',
              onAction: () => hasPb
                  ? context.go('/kelola/beranda')
                  : context.push('/daftar-pb'),
            ),
            const SizedBox(height: 8),
            _RoleTile(
              title: 'Toko partner',
              subtitle: hasShop
                  ? 'Kelola profil dan produk toko'
                  : 'Punya toko perlengkapan? Tampilkan produkmu',
              actionLabel: hasShop ? 'Masuk' : 'Daftarkan toko',
              onAction: () => hasShop
                  ? context.go('/toko-saya/produk')
                  : context.push('/daftar-toko'),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () {
                // Data PB contoh ikut dihapus supaya akun berikutnya mulai bersih.
                ref.read(manageProvider.notifier).clear();
                ref.read(ownShopProvider.notifier).clear();
                ref.read(sessionProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Keluar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris peran di bagian "Peran lain": status aktif atau tombol masuk.
class _RoleTile extends StatelessWidget {
  const _RoleTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.active = false,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final bool active;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return YbCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: YbText.body(size: 15, weight: FontWeight.w700),
                ),
                Text(subtitle, style: YbText.label()),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (active)
            const YbTag(
              'Sedang aktif',
              tone: YbTagTone.success,
              icon: Icons.check,
            )
          else if (actionLabel != null)
            // Lebar tombol sama di semua baris dan rata kanan, seperti Figma.
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96, maxWidth: 150),
              child: OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!, textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return YbCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: YbColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: YbColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: YbText.body(size: 15, weight: FontWeight.w700),
                ),
                Text(subtitle, style: YbText.label()),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: YbColors.muted),
        ],
      ),
    );
  }
}
