import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../state/providers.dart';
import 'pb_card.dart';

/// P7 PB tersimpan.
class SavedPage extends ConsumerWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedPbProvider).value ?? const [];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                const YbBackButton(),
                const SizedBox(width: 12),
                Text('PB tersimpan', style: YbText.display(size: 22)),
              ],
            ),
            const SizedBox(height: 16),
            if (saved.isNotEmpty) ...[
              Text(
                '${saved.length} PB yang kamu simpan',
                style: YbText.body(color: YbColors.muted),
              ),
              const SizedBox(height: 10),
              for (final pb in saved) ...[
                PbListCard(pb: pb),
                const SizedBox(height: 10),
              ],
            ],
            YbEmptyState(
              icon: Icons.star_outline_rounded,
              title: saved.isEmpty
                  ? 'Belum ada PB tersimpan'
                  : 'Mau simpan PB lain?',
              message: saved.isEmpty
                  ? 'Ketuk bintang di kartu PB supaya gampang kamu bandingkan nanti.'
                  : 'Bandingkan beberapa PB dulu sebelum menghubungi pengurusnya.',
              actionLabel: 'Cari PB',
              onAction: () => context.go('/cari'),
            ),
          ],
        ),
      ),
    );
  }
}
