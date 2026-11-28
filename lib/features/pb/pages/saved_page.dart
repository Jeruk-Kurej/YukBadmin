import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../data/pb_models.dart' show dayNames;
import '../state/providers.dart';
import 'pb_card.dart';

/// P7 PB tersimpan (Final Design v4): PB yang sudah dihubungi, lalu PB yang
/// disimpan untuk dibandingkan.
class SavedPage extends ConsumerWidget {
  const SavedPage({super.key});

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String _date(DateTime t) =>
      '${dayNames[t.weekday]!.substring(0, 3)}, ${t.day} ${_months[t.month - 1]}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedPbProvider);
    final contacted = ref.watch(contactedPbProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Align(alignment: Alignment.centerLeft, child: YbBackButton()),
            const SizedBox(height: 20),
            const YbPageTitle('PB tersimpan'),
            const SizedBox(height: 20),
            if (contacted.isNotEmpty) ...[
              YbSectionTitle('Sudah kamu hubungi'),
              const SizedBox(height: 10),
              YbGroup(
                children: [
                  for (final (pb, at) in contacted)
                    YbListRow(
                      title: pb.name,
                      subtitle: 'Dihubungi lewat WhatsApp · ${_date(at)}',
                      onTap: () => context.push('/pb/${pb.id}'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            ...saved.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (_, _) => [
                YbEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Daftar PB gagal dimuat',
                  message: 'Tutup lalu buka lagi halaman ini.',
                  actionLabel: 'Coba lagi',
                  onAction: () => ref.invalidate(pbListProvider),
                ),
              ],
              data: (list) => [
                if (list.isEmpty)
                  YbEmptyState(
                    icon: Icons.star_outline_rounded,
                    title: 'Belum ada PB tersimpan',
                    message: 'Ketuk bintang di kartu PB supaya gampang kamu bandingkan nanti.',
                    actionLabel: 'Cari PB',
                    onAction: () => context.go('/cari'),
                  )
                else ...[
                  if (contacted.isNotEmpty) ...[
                    YbSectionTitle('Disimpan'),
                    const SizedBox(height: 10),
                  ],
                  for (final pb in list) ...[
                    PbListCard(pb: pb),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'Mau simpan PB lain?',
                    textAlign: TextAlign.center,
                    style: YbText.body(size: 14, color: YbColors.muted),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => context.go('/cari'),
                    icon: const Icon(Icons.search_rounded, size: 20),
                    label: const Text('Cari PB'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
