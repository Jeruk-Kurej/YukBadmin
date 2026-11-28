import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_page.dart';
import '../features/account/activity_pages.dart';
import '../features/account/help_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/preferences_page.dart';
import '../features/club/pages/club_pages.dart';
import '../features/gear/pages/advisor_page.dart';
import '../features/gear/pages/gear_feed_page.dart';
import '../features/gear/pages/product_detail_page.dart';
import '../features/gear/pages/shop_detail_page.dart';
import '../features/gear/state/gear_providers.dart';
import '../features/home/home_page.dart';
import '../features/home/home_shell.dart';
import '../features/manage/pages/dues_page.dart';
import '../features/manage/pages/dues_system_page.dart';
import '../features/manage/pages/import_page.dart';
import '../features/manage/pages/manage_shell.dart';
import '../features/manage/pages/managers_page.dart';
import '../features/manage/pages/members_page.dart';
import '../features/manage/pages/profile_page.dart';
import '../features/manage/pages/refunds_page.dart';
import '../features/manage/pages/register_pb_page.dart';
import '../features/manage/pages/sessions_page.dart';
import '../features/manage/pages/usage_page.dart';
import '../features/manage/state/manage_providers.dart';
import '../features/pb/pages/detail_page.dart';
import '../features/pb/pages/saved_page.dart';
import '../features/pb/pages/search_page.dart';
import '../features/pb/state/providers.dart';
import '../features/shop/pages/shop_form.dart';
import '../features/shop/pages/shop_pages.dart';

/// Rute yang hanya boleh dibuka pengguna yang sudah mendaftarkan PB.
const _managerPrefixes = ['/kelola', '/member', '/sesi', '/impor'];

/// Rute yang hanya boleh dibuka pengguna yang sudah mendaftarkan toko.
const _shopPrefix = '/toko-saya';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/beranda',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final signedIn = ref.read(sessionProvider) != null;
      final atLogin = location.startsWith('/masuk');
      if (!signedIn) return atLogin ? null : '/masuk';
      if (atLogin) return '/beranda';

      final hasPb = ref.read(manageProvider).hasPb;
      if (!hasPb && _managerPrefixes.any(location.startsWith)) {
        return '/daftar-pb';
      }
      if (hasPb && location == '/daftar-pb') return '/kelola/beranda';

      final hasShop = ref.read(ownShopProvider).hasShop;
      if (!hasShop && location.startsWith(_shopPrefix)) return '/daftar-toko';
      if (hasShop && location == '/daftar-toko') return '/toko-saya/produk';
      return null;
    },
    routes: [
      GoRoute(
        path: '/masuk',
        builder: (_, _) => const LoginPage(),
        routes: [
          GoRoute(path: 'email', builder: (_, _) => const EmailSignInPage()),
        ],
      ),
      GoRoute(
        path: '/preferensi',
        builder: (_, _) => const PreferencesPage(),
        routes: [
          GoRoute(
            path: 'ubah',
            builder: (_, _) => const PreferencesPage(editing: true),
          ),
        ],
      ),
      GoRoute(path: '/tersimpan', builder: (_, _) => const SavedPage()),
      GoRoute(path: '/bantuan', builder: (_, _) => const HelpPage()),
      GoRoute(path: '/riwayat', builder: (_, _) => const TransactionsPage()),
      GoRoute(
        path: '/notifikasi',
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/pb-ku',
        builder: (_, _) => const ClubListPage(),
        routes: [
          GoRoute(
            path: ':pbId',
            builder: (_, state) =>
                ClubDetailPage(pbId: state.pathParameters['pbId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/pb/:id',
        builder: (_, state) => PbDetailPage(pbId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/beranda', builder: (_, _) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/cari', builder: (_, _) => const SearchPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/perlengkapan',
                builder: (_, _) => const GearFeedPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/akun', builder: (_, _) => const AccountPage()),
            ],
          ),
        ],
      ),

      // Perlengkapan dan toko, dilihat pemain.
      GoRoute(path: '/saran', builder: (_, _) => const AdvisorPage()),
      GoRoute(
        path: '/produk/:id',
        builder: (_, state) =>
            ProductDetailPage(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/toko/:id',
        builder: (_, state) =>
            ShopDetailPage(shopId: state.pathParameters['id']!),
      ),

      // Toko partner.
      GoRoute(
        path: '/daftar-toko',
        builder: (_, _) => const RegisterShopPage(),
      ),
      GoRoute(
        path: '/toko-saya/produk/baru',
        builder: (_, _) => const ProductFormPage(),
      ),
      GoRoute(
        path: '/toko-saya/produk/:id',
        builder: (_, state) =>
            ProductFormPage(productId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/toko-saya/profil',
        builder: (_, _) => const ShopProfilePage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShopShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/toko-saya/produk',
                builder: (_, _) => const ShopProductsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/toko-saya/akun',
                builder: (_, _) => const AccountPage(mode: AccountMode.shop),
              ),
            ],
          ),
        ],
      ),

      // Pengurus PB.
      GoRoute(path: '/daftar-pb', builder: (_, _) => const RegisterPbPage()),
      GoRoute(path: '/impor', builder: (_, _) => const ImportPage()),
      GoRoute(
        path: '/kelola/pengurus',
        builder: (_, _) => const ManagersPage(),
      ),
      GoRoute(path: '/kelola/profil', builder: (_, _) => const PbProfilePage()),
      GoRoute(
        path: '/kelola/sistem-iuran',
        builder: (_, _) => const DuesSystemPage(),
      ),
      GoRoute(
        path: '/kelola/pembatalan',
        builder: (_, _) => const RefundsPage(),
      ),
      GoRoute(
        path: '/sesi/:id/pemakaian',
        builder: (_, state) => UsagePage(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/sesi/:id/tagihan',
        builder: (_, state) =>
            BillSummaryPage(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/kelola/lihat-member',
        builder: (_, _) => const MemberPreviewPickPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                MemberPreviewPage(memberId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/member/baru', builder: (_, _) => const MemberFormPage()),
      GoRoute(
        path: '/member/:id',
        builder: (_, state) =>
            MemberFormPage(memberId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/sesi/:id/kehadiran',
        builder: (_, state) =>
            AttendancePage(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/sesi/:id/iuran',
        builder: (_, state) =>
            SessionDuesPage(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/sesi/:id/pengingat',
        builder: (_, state) =>
            ReminderPage(eventId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ManageShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/kelola/beranda',
                builder: (_, _) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/kelola/member',
                builder: (_, _) => const MembersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/kelola/jadwal',
                builder: (_, _) => const SchedulePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/kelola/iuran',
                builder: (_, _) => const DuesTabPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/kelola/akun',
                builder: (_, _) => const AccountPage(mode: AccountMode.manager),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // Masuk atau keluar memicu pengecekan ulang redirect.
  ref.listen(sessionProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});
