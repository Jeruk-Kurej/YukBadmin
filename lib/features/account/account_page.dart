import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/theme_mode.dart';
import '../../app/tours.dart';
import '../../core/widgets/yb_widgets.dart';
import '../shop/data/partner_invite.dart';
import '../club/state/club_providers.dart';
import '../gear/state/gear_providers.dart';
import '../manage/data/manage_models.dart' show DuesSystemLabel;
import '../manage/state/manage_providers.dart';
import '../pb/data/pb_models.dart';
import '../pb/state/providers.dart';

/// Mode akun yang sedang dipakai. Halaman Akun sama untuk ketiganya, hanya
/// bagian atas dan menunya yang berbeda (P14, K25, T5 di Final Design v4).
enum AccountMode { player, manager, shop }

/// P14 Akun pemain, K25 Akun pengurus, T5 Akun toko.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key, this.mode = AccountMode.player});

  final AccountMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final prefs = ref.watch(preferencesProvider);
    final savedCount = ref.watch(savedProvider).length;
    final clubCount = ref.watch(membershipProvider).length;
    final manage = ref.watch(manageProvider);
    final shop = ref.watch(ownShopProvider);
    final themeMode = ref.watch(themeModeProvider);
    final profilePublic = ref.watch(profilePublicProvider);

    final days = prefs.weekdays.toList()..sort();
    final dayText = days.isEmpty
        ? 'hari belum dipilih'
        : days.map((d) => dayShort[d]).join(', ');
    final levelText = prefs.level == null
        ? 'Level belum tahu'
        : 'Level ${prefs.level!.label}';

    final modeLine = switch (mode) {
      AccountMode.player => 'Mode pemain · $levelText',
      AccountMode.manager => 'Mode pengurus · ${manage.pb?.name ?? '-'}',
      AccountMode.shop => 'Mode toko · ${shop.shop?.name ?? '-'}',
    };

    void switchTo(AccountMode target) => switch (target) {
      AccountMode.player => context.go('/beranda'),
      AccountMode.manager =>
        manage.hasPb
            ? context.go('/kelola/beranda')
            : context.push('/daftar-pb'),
      AccountMode.shop =>
        shop.hasShop
            ? context.go('/toko-saya/produk')
            : context.push('/daftar-toko'),
    };

    Widget role({
      Key? key,
      required AccountMode target,
      required String title,
      required String subtitle,
      required bool registered,
      required String registerLabel,
    }) {
      final active = target == mode;
      return YbListRow(
        key: key,
        title: title,
        subtitle: subtitle,
        trailing: SizedBox(
          width: 104,
          child: active
              ? Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: YbColors.successSoft,
                    borderRadius: BorderRadius.circular(YbRadius.pill),
                  ),
                  child: Text(
                    'Aktif',
                    style: YbText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: YbColors.success,
                    ),
                  ),
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(104, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => switchTo(target),
                  child: Text(
                    registered ? 'Beralih' : registerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      // Bukan ListView, supaya semua bagian sudah dibangun dan bisa disorot tur.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            YbPageTitle(
              'Akun',
              trailing: IconButton(
                tooltip: 'Bantuan',
                onPressed: () => context.push('/bantuan'),
                style: IconButton.styleFrom(
                  backgroundColor: YbColors.surface,
                  fixedSize: const Size(44, 44),
                ),
                icon: Icon(Icons.help_outline, color: YbColors.ink),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: YbColors.night,
                borderRadius: BorderRadius.circular(YbRadius.lg),
              ),
              child: Row(
                children: [
                  YbAvatar(user?.initials ?? '?', size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '-',
                          style: YbText.display(
                            size: 20,
                            color: YbColors.onNight,
                          ),
                        ),
                        Text(
                          user?.email ?? '-',
                          style: YbText.body(size: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          modeLine,
                          style: YbText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: YbColors.onNight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (mode == AccountMode.player &&
                user != null &&
                !user.emailVerified) ...[
              const SizedBox(height: 12),
              _VerifyBanner(email: user.email),
            ],
            const SizedBox(height: 24),
            ...switch (mode) {
              AccountMode.player => [
                YbSectionTitle('Aktivitas'),
                const SizedBox(height: 10),
                YbGroup(
                  children: [
                    YbListRow(
                      key: TourKeys.accountClub,
                      icon: Icons.calendar_today_outlined,
                      title: 'PB-ku',
                      subtitle: clubCount == 0
                          ? 'PB tempat kamu jadi member'
                          : 'Jadwal dan iuran di $clubCount PB',
                      onTap: () => context.push('/pb-ku'),
                    ),
                    YbListRow(
                      icon: Icons.star_outline_rounded,
                      title: 'PB tersimpan',
                      subtitle: savedCount == 0
                          ? 'Lihat PB yang kamu simpan'
                          : '$savedCount PB kamu simpan',
                      onTap: () => context.push('/tersimpan'),
                    ),
                    YbListRow(
                      icon: Icons.tune,
                      title: 'Preferensi main',
                      subtitle: '$levelText · ${prefs.area} · $dayText',
                      onTap: () => context.push('/preferensi/ubah'),
                    ),
                    YbListRow(
                      icon: Icons.play_circle_outline,
                      title: 'Tur aplikasi',
                      subtitle: 'Lihat lagi cara memakai YukBadmin',
                      onTap: () => startPlayerTour(context, ref),
                    ),
                    YbListRow(
                      icon: Icons.chat_bubble_outline,
                      title: 'Bantuan',
                      subtitle: 'Pertanyaan umum dan kontak',
                      onTap: () => context.push('/bantuan'),
                    ),
                  ],
                ),
              ],
              AccountMode.manager => [
                YbSectionTitle(manage.pb?.name ?? 'PB-mu'),
                const SizedBox(height: 10),
                YbGroup(
                  children: [
                    YbListRow(
                      key: TourKeys.profileManagers,
                      icon: Icons.storefront_outlined,
                      title: 'Profil PB',
                      subtitle: 'Nama, lokasi, jadwal, foto',
                      onTap: () => context.push('/kelola/profil'),
                    ),
                    YbListRow(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Sistem iuran',
                      subtitle: manage.duesSystem.summary(
                        manage.pb?.feePerSession ?? 0,
                      ),
                      onTap: () => context.push('/kelola/sistem-iuran'),
                    ),
                    YbListRow(
                      icon: Icons.groups_outlined,
                      title: 'Pengurus PB',
                      subtitle: manage.coManagers.isEmpty
                          ? 'Baru kamu sendiri'
                          : 'Kamu dan ${manage.coManagers.length} pengurus lain',
                      onTap: () => context.push('/kelola/pengurus'),
                    ),
                    YbListRow(
                      icon: Icons.visibility_outlined,
                      title: 'Lihat sebagai member',
                      subtitle: 'Coba tampilan member PB-mu',
                      onTap: () => context.push('/kelola/lihat-member'),
                    ),
                    YbListRow(
                      icon: Icons.play_circle_outline,
                      title: 'Tur pengurus',
                      subtitle: 'Lihat lagi cara mengelola PB',
                      onTap: () {
                        context.go('/kelola/beranda');
                        startManagerTour(context, ref);
                      },
                    ),
                    YbListRow(
                      icon: Icons.chat_bubble_outline,
                      title: 'Bantuan',
                      subtitle: 'Pertanyaan umum dan kontak',
                      onTap: () => context.push('/bantuan'),
                    ),
                  ],
                ),
              ],
              AccountMode.shop => [
                YbSectionTitle(shop.shop?.name ?? 'Tokomu'),
                const SizedBox(height: 10),
                YbGroup(
                  children: [
                    YbListRow(
                      icon: Icons.storefront_outlined,
                      title: 'Profil toko',
                      subtitle: 'Alamat, jam buka, WhatsApp',
                      onTap: () => context.push('/toko-saya/profil'),
                    ),
                    YbListRow(
                      icon: Icons.chat_bubble_outline,
                      title: 'Bantuan',
                      subtitle: 'Pertanyaan umum dan kontak',
                      onTap: () => context.push('/bantuan'),
                    ),
                  ],
                ),
              ],
            },
            const SizedBox(height: 24),
            YbSectionTitle('Peran lain'),
            const SizedBox(height: 10),
            YbGroup(
              children: [
                role(
                  target: AccountMode.player,
                  title: 'Pemain',
                  subtitle: 'Cari dan simpan PB',
                  registered: true,
                  registerLabel: 'Beralih',
                ),
                role(
                  key: TourKeys.accountManagerRole,
                  target: AccountMode.manager,
                  title: 'Pengurus PB',
                  subtitle: 'Kelola PB-mu',
                  registered: manage.hasPb,
                  registerLabel: 'Daftarkan',
                ),
                // Toko partner hanya untuk toko yang diundang tim, jadi
                // peran ini baru muncul setelah toko terdaftar.
                if (shop.hasShop)
                  role(
                    target: AccountMode.shop,
                    title: 'Toko partner',
                    subtitle: 'Tampilkan produk tokomu',
                    registered: true,
                    registerLabel: 'Beralih',
                  ),
              ],
            ),
            if (!shop.hasShop) ...[
              const SizedBox(height: 10),
              YbGroup(
                children: [
                  YbListRow(
                    icon: Icons.storefront_outlined,
                    title: 'Punya toko perlengkapan?',
                    subtitle: 'Jadi toko partner lewat undangan tim YukBadmin',
                    onTap: () => showPartnerInviteSheet(context),
                  ),
                ],
              ),
            ],
            if (mode == AccountMode.player) ...[
              const SizedBox(height: 24),
              YbSectionTitle('Privasi'),
              const SizedBox(height: 10),
              YbGroup(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    value: profilePublic,
                    onChanged: (v) =>
                        ref.read(profilePublicProvider.notifier).set(v),
                    title: Text(
                      'Tampilkan profilku ke sesama member',
                      style: YbText.body(size: 16, weight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Nama, level, dan area main. Kontak tidak pernah tampil.',
                      style: YbText.body(size: 13, color: YbColors.muted),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            YbSectionTitle('Tampilan'),
            const SizedBox(height: 10),
            YbSegmented<ThemeMode>(
              options: const [
                (ThemeMode.system, 'Sistem', Icons.phone_iphone),
                (ThemeMode.light, 'Terang', Icons.light_mode_outlined),
                (ThemeMode.dark, 'Gelap', Icons.dark_mode_outlined),
              ],
              selected: themeMode,
              onChanged: (m) => ref.read(themeModeProvider.notifier).set(m),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: YbColors.error,
                side: BorderSide(color: YbColors.line),
              ),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Keluar dari YukBadmin?'),
                    content: const Text(
                      'PB, toko, dan simpananmu tetap ada di HP ini. Semuanya muncul lagi saat kamu masuk dengan akun yang sama.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: YbColors.error,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
                // Data tiap akun disimpan terpisah, jadi akun berikutnya tetap
                // mulai bersih tanpa menghapus apa pun.
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

/// P14b: email belum diverifikasi. Belum ada server pengirim email, jadi
/// banner ini hanya memberi tahu, tanpa tombol "Kirim ulang" yang tidak
/// benar-benar mengirim apa pun.
class _VerifyBanner extends StatelessWidget {
  const _VerifyBanner({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: YbColors.warningSoft,
        borderRadius: BorderRadius.circular(YbRadius.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.mark_email_unread_outlined, color: YbColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email belum diverifikasi',
                  style: YbText.body(
                    size: 15,
                    weight: FontWeight.w600,
                    color: YbColors.warning,
                  ),
                ),
                Text(
                  'Tautan verifikasi ke $email dikirim setelah app tersambung ke server.',
                  style: YbText.body(size: 13, color: YbColors.warning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lembar kode undangan toko partner. Kode didapat setelah tim YukBadmin
/// menghubungi toko; tanpa kode, pendaftaran toko tidak dibuka.
Future<void> showPartnerInviteSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => const _PartnerInviteSheet(),
    );

class _PartnerInviteSheet extends StatefulWidget {
  const _PartnerInviteSheet();

  @override
  State<_PartnerInviteSheet> createState() => _PartnerInviteSheetState();
}

class _PartnerInviteSheetState extends State<_PartnerInviteSheet> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Isi kode undangan dari tim YukBadmin.');
      return;
    }
    if (!isValidPartnerCode(_code.text)) {
      setState(
        () => _error = 'Kode tidak dikenal. Cek lagi huruf dan tandanya, atau minta kode baru ke tim.',
      );
      return;
    }
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push('/daftar-toko');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Jadi toko partner', style: YbText.display(size: 22)),
            const SizedBox(height: 6),
            Text(
              'Toko partner dipilih bersama tim YukBadmin supaya produk di Perlengkapan tetap terpercaya. Setelah sepakat, tim memberimu kode undangan.',
              style: YbText.body(size: 14, color: YbColors.muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Kode undangan',
                hintText: 'Contoh: MITRA-XX-0000',
                errorText: _error,
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: const Text('Lanjut daftarkan toko'),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum punya kode? Kontak tim menyusul saat app dirilis.',
              textAlign: TextAlign.center,
              style: YbText.body(size: 13, color: YbColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
