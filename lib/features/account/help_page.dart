import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/yb_widgets.dart';
import '../manage/pages/manage_widgets.dart';

/// P26 Bantuan: pertanyaan umum dan kontak tim.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faq = [
    (
      'Apakah YukBadmin bisa sewa lapangan?',
      'Tidak. YukBadmin untuk mencari PB dan mengelola member, jadwal, dan iuran.',
    ),
    (
      'Bagaimana cara bergabung ke PB?',
      'Hubungi pengurus dari halaman PB. Kamu jadi member setelah pengurus menambahkanmu.',
    ),
    (
      'Kenapa bukti transferku ditolak?',
      'Alasan dari pengurus tertulis di tagihan. Kirim bukti baru dari sana.',
    ),
    (
      'Bagaimana kalau batal ikut?',
      'Tergantung aturan PB. Lihat bagian Cara bayar di halaman PB.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const PageHeader(title: 'Bantuan'),
            const SizedBox(height: 12),
            YbSectionTitle('Pertanyaan umum'),
            const SizedBox(height: 10),
            YbGroup(
              children: [
                for (final (q, a) in _faq)
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      iconColor: YbColors.ink,
                      collapsedIconColor: YbColors.muted,
                      title: Text(
                        q,
                        style: YbText.body(size: 16, weight: FontWeight.w600),
                      ),
                      children: [
                        Text(a, style: YbText.body(color: YbColors.muted)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            YbSectionTitle('Masih bingung?'),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              // Belum ada nomor resmi tim; jangan arahkan ke nomor karangan.
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Kontak tim YukBadmin menyusul saat app dirilis. Untuk urusan PB, hubungi pengurusnya.',
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: const Text('Hubungi tim YukBadmin'),
            ),
          ],
        ),
      ),
    );
  }
}
