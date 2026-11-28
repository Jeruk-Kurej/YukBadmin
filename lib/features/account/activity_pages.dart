import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/widgets/yb_brand.dart';
import '../../core/widgets/yb_widgets.dart';
import '../club/state/club_providers.dart';
import '../manage/data/manage_models.dart';
import '../manage/state/manage_providers.dart' show nowProvider;
import '../pb/data/pb_models.dart' show Pb;
import 'data/activity_feed.dart';
import '../pb/state/providers.dart';

/// Kepala halaman biru malam dengan tombol kembali dan judul (Final Design V5).
class _NightPageHeader extends StatelessWidget {
  const _NightPageHeader({required this.title, this.bottom});

  final String title;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return YbSheetHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              YbNightIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Kembali',
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: YbText.display(size: 22, color: YbColors.onNight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          if (bottom != null) ...[const SizedBox(height: 16), bottom!],
        ],
      ),
    );
  }
}

/// Riwayat transaksi pemain: iuran per sesi dari semua PB-ku.
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

enum _TxFilter { all, open, paid }

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  _TxFilter _filter = _TxFilter.all;

  @override
  Widget build(BuildContext context) {
    final entries = dueEntries(ref.watch(membershipProvider));
    final names = {
      for (final pb in ref.watch(pbListProvider).value ?? const <Pb>[])
        pb.id: pb.name,
    };
    final paidTotal = entries
        .where((e) => e.state == DueState.paid)
        .fold(0, (sum, e) => sum + e.due.amount);
    final openTotal = entries
        .where((e) => e.state.open && e.due.billable)
        .fold(0, (sum, e) => sum + e.due.amount);
    final shown = entries
        .where(
          (e) => switch (_filter) {
            _TxFilter.all => true,
            _TxFilter.open => e.state.open,
            _TxFilter.paid => e.state == DueState.paid,
          },
        )
        .toList();

    final groups = <String, List<DueEntry>>{};
    for (final e in shown) {
      final key =
          '${monthNames[e.event.start.month - 1]} ${e.event.start.year}';
      groups.putIfAbsent(key, () => []).add(e);
    }

    return Scaffold(
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: ListView(
          padding: EdgeInsets.only(
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _NightPageHeader(
              title: 'Riwayat transaksi',
              bottom: _NightSegmented<_TxFilter>(
                options: const [
                  (_TxFilter.all, 'Semua'),
                  (_TxFilter.open, 'Belum lunas'),
                  (_TxFilter.paid, 'Lunas'),
                ],
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SumCard(
                          label: 'Sudah dibayar',
                          value: formatRupiahShort(paidTotal),
                          background: YbColors.accentSoft,
                          foreground: YbColors.ink,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SumCard(
                          label: 'Belum lunas',
                          value: formatRupiahShort(openTotal),
                          background: YbColors.warningSoft,
                          foreground: YbColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (shown.isEmpty)
                    YbEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: entries.isEmpty
                          ? 'Belum ada transaksi'
                          : 'Tidak ada iuran di pilihan ini',
                      message: entries.isEmpty
                          ? 'Iuran dari PB-ku muncul di sini setelah kamu ikut sesi.'
                          : 'Pilih "Semua" untuk melihat seluruh iuranmu.',
                      actionLabel: entries.isEmpty ? 'Cari PB' : 'Lihat semua',
                      onAction: entries.isEmpty
                          ? () => context.go('/cari')
                          : () => setState(() => _filter = _TxFilter.all),
                    )
                  else
                    for (final MapEntry(key: month, value: items)
                        in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Text(
                          month,
                          style: YbText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: YbColors.muted,
                          ),
                        ),
                      ),
                      YbGroup(
                        children: [
                          for (final e in items)
                            _DueRow(entry: e, pbName: names[e.pbId] ?? 'PB'),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  _InfoNote(
                    icon: Icons.storefront_outlined,
                    text: 'Belanja perlengkapan dibayar langsung ke toko partner, jadi tidak tercatat di sini.',
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

class _SumCard extends StatelessWidget {
  const _SumCard({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(YbRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: YbText.body(size: 12, color: foreground)),
            Text(value, style: YbText.score(size: 22, color: foreground)),
          ],
        ),
      ),
    );
  }
}

class _DueRow extends StatelessWidget {
  const _DueRow({required this.entry, required this.pbName});

  final DueEntry entry;
  final String pbName;

  @override
  Widget build(BuildContext context) {
    final state = entry.state;
    final (icon, bg, fg) = switch (state) {
      DueState.paid => (
        Icons.check_rounded,
        YbColors.successSoft,
        YbColors.success,
      ),
      DueState.checking => (
        Icons.schedule,
        YbColors.pendingSoft,
        YbColors.pending,
      ),
      DueState.rejected => (
        Icons.error_outline,
        YbColors.errorSoft,
        YbColors.error,
      ),
      DueState.unpaid => (
        Icons.receipt_long_outlined,
        YbColors.warningSoft,
        YbColors.warning,
      ),
      DueState.cancelled || DueState.refund => (
        Icons.undo_rounded,
        YbColors.pendingSoft,
        YbColors.pending,
      ),
    };
    return InkWell(
      onTap: () => context.push('/pb-ku/${entry.pbId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Iuran $pbName',
                    style: YbText.body(size: 14, weight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${entry.event.title} · ${formatDate(entry.event.start)}',
                    style: YbText.body(size: 12, color: YbColors.muted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(YbRadius.sm),
                    ),
                    child: Text(
                      state.label,
                      style: YbText.body(
                        size: 11,
                        weight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatRupiahShort(entry.due.amount),
              style: YbText.body(size: 14, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: YbColors.primarySoft,
        borderRadius: BorderRadius.circular(YbRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: YbColors.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: YbText.body(size: 13, color: YbColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pilihan segmen di atas kepala halaman biru malam.
class _NightSegmented<T> extends StatelessWidget {
  const _NightSegmented({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(YbRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          for (final (value, label) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                label: label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    constraints: const BoxConstraints(minHeight: 40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == selected
                          ? YbColors.accent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(YbRadius.pill),
                    ),
                    child: Text(
                      label,
                      style: YbText.body(
                        size: 13,
                        weight: value == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: value == selected
                            ? YbColors.onAccent
                            : YbColors.onNight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Notifikasi pemain. Selama belum ada server, notifikasi hanya tampil di
/// halaman ini, belum dikirim sebagai notifikasi HP.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _actionOnly = false;

  @override
  Widget build(BuildContext context) {
    final names = {
      for (final pb in ref.watch(pbListProvider).value ?? const <Pb>[])
        pb.id: pb.name,
    };
    final all = playerNotices(
      ref.watch(membershipProvider),
      ref.watch(nowProvider)(),
      names,
    );
    final shown = _actionOnly ? all.where((n) => n.needsAction).toList() : all;
    final action = shown.where((n) => n.needsAction).toList();
    final info = shown.where((n) => !n.needsAction).toList();

    return Scaffold(
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: ListView(
          padding: EdgeInsets.only(
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _NightPageHeader(
              title: 'Notifikasi',
              bottom: _NightSegmented<bool>(
                options: const [(false, 'Semua'), (true, 'Perlu tindakan')],
                selected: _actionOnly,
                onChanged: (v) => setState(() => _actionOnly = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (shown.isEmpty)
                    YbEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: _actionOnly
                          ? 'Tidak ada yang perlu ditindaklanjuti'
                          : 'Belum ada notifikasi',
                      message: 'Pengingat sesi dan kabar iuran dari PB-ku muncul di sini.',
                    ),
                  for (final (title, items) in [
                    ('Perlu tindakan', action),
                    ('Info', info),
                  ])
                    if (items.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Text(
                          title,
                          style: YbText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: YbColors.muted,
                          ),
                        ),
                      ),
                      YbGroup(
                        children: [
                          for (final n in items) _NoticeRow(notice: n),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  const _InfoNote(
                    icon: Icons.info_outline,
                    text: 'Notifikasi ke HP menyusul setelah app tersambung ke server. Untuk sekarang, cek halaman ini.',
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

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.notice});

  final PlayerNotice notice;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (notice.kind) {
      NoticeKind.session => (
        Icons.event_outlined,
        YbColors.accentSoft,
        YbColors.ink,
      ),
      NoticeKind.rejected => (
        Icons.error_outline,
        YbColors.errorSoft,
        YbColors.error,
      ),
      NoticeKind.unpaid => (
        Icons.receipt_long_outlined,
        YbColors.warningSoft,
        YbColors.warning,
      ),
      NoticeKind.paid => (
        Icons.check_rounded,
        YbColors.successSoft,
        YbColors.success,
      ),
    };
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: YbText.body(size: 14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  notice.message,
                  style: YbText.body(size: 13, color: YbColors.muted),
                ),
                if (notice.action != null) ...[
                  const SizedBox(height: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: YbColors.night,
                      foregroundColor: YbColors.onNight,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: YbText.body(size: 13, weight: FontWeight.w700),
                    ),
                    onPressed: () => context.push('/pb-ku/${notice.pbId}'),
                    child: Text(notice.action!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
