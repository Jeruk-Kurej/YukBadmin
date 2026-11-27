import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/photo.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../data/manage_models.dart';
import '../state/manage_providers.dart';
import 'manage_shell.dart' show formatSessionDate;
import 'manage_widgets.dart';
import 'sessions_page.dart' show MissingSession;

/// Tab Iuran (Final Design v4): ringkasan uang masuk, hal yang perlu
/// ditindak, lalu daftar sesi yang iurannya sudah tercatat.
class DuesTabPage extends ConsumerWidget {
  const DuesTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(manageProvider);
    final now = ref.watch(nowProvider)();
    final sys = state.duesSystem;
    final sessions = state.events.where((e) => e.dues.isNotEmpty).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    final collected = sessions.fold(0, (sum, e) => sum + e.collected);
    final outstanding = sessions.fold(0, (sum, e) => sum + e.outstanding);
    final refunds = state.refundsToHandle;
    // Sistem per orang: sesi yang sudah lewat dan belum ditagih.
    final toBill = sys.timing == DuesTiming.perOrang
        ? state
              .past(now)
              .where((e) => !e.billsSent && e.attendees.isNotEmpty)
              .toList()
        : const <SessionEvent>[];
    // Setelah main harga tetap: yang hadir tapi belum ditagih.
    final unbilled = sys.timing == DuesTiming.setelahTetap
        ? state.events
              .where((e) => e.attendanceSaved && e.unbilledAttendees.isNotEmpty)
              .toList()
        : const <SessionEvent>[];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          YbPageTitle(
            'Iuran',
            subtitle: sys.summary(state.pb?.feePerSession ?? 0),
            trailing: IconButton(
              tooltip: 'Sistem iuran',
              onPressed: () => context.push('/kelola/sistem-iuran'),
              style: IconButton.styleFrom(
                backgroundColor: YbColors.surface,
                fixedSize: const Size(44, 44),
              ),
              icon: Icon(Icons.tune_rounded, color: YbColors.ink, size: 22),
            ),
          ),
          const SizedBox(height: 16),
          if (sessions.isEmpty && toBill.isEmpty && unbilled.isEmpty)
            YbEmptyState(
              icon: Icons.payments_outlined,
              title: 'Belum ada iuran tercatat',
              message: sys.timing == DuesTiming.sebelum
                  ? 'Iuran muncul saat member konfirmasi ikut atau setelah kamu mencatat kehadiran.'
                  : 'Iuran muncul setelah kamu mencatat kehadiran sebuah sesi.',
              actionLabel: 'Buka jadwal',
              onAction: () => context.go('/kelola/jadwal'),
            )
          else ...[
            _DuesSummary(collected: collected, outstanding: outstanding),
            if (toBill.isNotEmpty || unbilled.isNotEmpty || refunds > 0) ...[
              const SizedBox(height: 24),
              YbSectionTitle('Perlu ditindak'),
              const SizedBox(height: 10),
              YbGroup(
                children: [
                  for (final e in toBill)
                    YbListRow(
                      icon: Icons.edit_note_rounded,
                      title: 'Catat pemakaian ${e.title.toLowerCase()}',
                      subtitle:
                          '${formatSessionDate(e.start, now)} · ${e.attendees.length} hadir, belum ditagih',
                      onTap: () => context.push('/sesi/${e.id}/pemakaian'),
                    ),
                  for (final e in unbilled)
                    YbListRow(
                      icon: Icons.receipt_long_outlined,
                      title: 'Tagih ${e.title.toLowerCase()}',
                      subtitle:
                          '${formatSessionDate(e.start, now)} · ${e.unbilledAttendees.length} hadir, belum ditagih',
                      onTap: () => context.push('/sesi/${e.id}/iuran'),
                    ),
                  if (refunds > 0)
                    YbListRow(
                      icon: Icons.undo_rounded,
                      title: '$refunds pembatalan perlu diurus',
                      subtitle: 'Kembalikan uang atau putuskan pengajuan',
                      onTap: () => context.push('/kelola/pembatalan'),
                    ),
                ],
              ),
            ],
            if (sessions.isNotEmpty) ...[
              const SizedBox(height: 24),
              YbSectionTitle('Per sesi'),
              const SizedBox(height: 10),
              YbGroup(
                children: [
                  for (final e in sessions)
                    YbListRow(
                      title: e.title,
                      subtitle:
                          '${formatSessionDate(e.start, now)} · ${e.timeRange}',
                      onTap: () => context.push('/sesi/${e.id}/iuran'),
                      chevron: true,
                      trailing: e.proofsToCheck > 0
                          ? YbTag(
                              '${e.proofsToCheck} bukti baru',
                              tone: YbTagTone.pending,
                            )
                          : e.unpaidCount == 0
                          ? const YbTag(
                              'Lunas',
                              tone: YbTagTone.success,
                              icon: Icons.check,
                            )
                          : YbTag(
                              '${e.unpaidCount} belum',
                              tone: YbTagTone.warning,
                            ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Kartu ringkasan: uang terkumpul, yang belum masuk, dan bilah kemajuan.
class _DuesSummary extends StatelessWidget {
  const _DuesSummary({required this.collected, required this.outstanding});

  final int collected;
  final int outstanding;

  @override
  Widget build(BuildContext context) {
    final total = collected + outstanding;
    final ratio = total == 0 ? 0.0 : collected / total;
    Widget amount(String label, int value, Color dot) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: YbText.body(size: 13, color: YbColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatRupiah(value), style: YbText.display(size: 24)),
          ),
        ],
      ),
    );

    return YbCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              amount('Terkumpul', collected, YbColors.success),
              const SizedBox(width: 16),
              amount('Belum masuk', outstanding, YbColors.warning),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: '${(ratio * 100).round()} persen iuran sudah masuk',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(YbRadius.pill),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                color: YbColors.success,
                backgroundColor: YbColors.warningSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// K9 Iuran sesi.
class SessionDuesPage extends ConsumerWidget {
  const SessionDuesPage({super.key, required this.eventId});

  final String eventId;

  Future<void> _editAmount(
    BuildContext context,
    WidgetRef ref,
    SessionEvent event,
    Member member,
    Due due,
  ) async {
    final formKey = GlobalKey<FormState>();
    final amount = await showDialog<int>(
      context: context,
      builder: (_) => TextControllerScope(
        initialText: '${due.amount}',
        builder: (context, controller) => AlertDialog(
          backgroundColor: YbColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text('Iuran ${member.name}', style: YbText.display(size: 18)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                helperText: 'Termasuk shuttlecock yang dipakai, kalau ada.',
                helperMaxLines: 2,
              ),
              validator: (v) {
                final value = parseRupiah(v ?? '');
                if (value == null) return 'Isi nominal iuran.';
                if (value > 5000000) return 'Nominal terlalu besar, cek lagi.';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal', style: YbText.body(weight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(parseRupiah(controller.text));
                }
              },
              child: Text(
                'Simpan',
                style: YbText.body(
                  color: YbColors.primary,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (amount != null) {
      ref
          .read(manageProvider.notifier)
          .setDue(event.id, member.id, due.copyWith(amount: amount));
    }
  }

  void _markPaid(
    BuildContext context,
    WidgetRef ref,
    SessionEvent event,
    Member member,
    Due? previous,
  ) {
    final pb = ref.read(manageProvider).pb;
    final notifier = ref.read(manageProvider.notifier);
    notifier.setDue(
      event.id,
      member.id,
      (previous ?? Due(amount: pb?.feePerSession ?? 0)).copyWith(
        paid: true,
        paidAt: ref.read(nowProvider)(),
      ),
    );
    // Salah pencet bisa langsung dibatalkan dari snackbar.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${member.name} ditandai lunas'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Batalkan',
            textColor: YbColors.accent,
            onPressed: () {
              if (previous == null) {
                notifier.removeDue(event.id, member.id);
              } else {
                notifier.setDue(event.id, member.id, previous);
              }
            },
          ),
        ),
      );
  }

  Future<void> _unmarkPaid(
    BuildContext context,
    WidgetRef ref,
    SessionEvent event,
    Member member,
    Due due,
  ) async {
    final ok = await confirmDestructive(
      context,
      title: 'Batalkan status lunas?',
      message:
          '${member.name} akan kembali tercatat belum bayar ${formatRupiah(due.amount)}.',
      confirmLabel: 'Ya, belum bayar',
    );
    if (ok) {
      ref.read(manageProvider.notifier).setPaid(event.id, member.id, false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(manageProvider);
    final event = state.eventById(eventId);
    if (event == null) return const MissingSession();

    int byName((Member, Object?) a, (Member, Object?) b) =>
        a.$1.name.toLowerCase().compareTo(b.$1.name.toLowerCase());

    final rows = [
      for (final entry in event.dues.entries)
        if (state.memberById(entry.key) case final member?)
          (member, entry.value),
    ]..sort(byName);

    // Sebelum kehadiran dicatat, member lain bisa dicatat sudah bayar di muka.
    final prepayCandidates = event.attendanceSaved
        ? <Member>[]
        : (state.members.where((m) => !event.dues.containsKey(m.id)).toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            ));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  PageHeader(
                    title: 'Iuran sesi',
                    trailing: YbTag(
                      event.shortLabel,
                      tone: YbTagTone.accent,
                      icon: Icons.schedule,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.members.isEmpty)
                    YbEmptyState(
                      icon: Icons.people_outline,
                      title: 'Belum ada member',
                      message:
                          'Tambah member dulu, lalu catat iurannya di sini.',
                      actionLabel: 'Tambah member',
                      onAction: () => context.push('/member/baru'),
                    )
                  else ...[
                    if (!event.attendanceSaved) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: YbColors.warningSoft,
                          borderRadius: BorderRadius.circular(YbRadius.lg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Kehadiran belum dicatat',
                              style: YbText.body(weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Catat yang sudah bayar di muka sekarang. Setelah sesi, catat kehadiran supaya yang datang tanpa bayar ikut tertagih.',
                              style: YbText.label(color: YbColors.ink),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () => context.pushReplacement(
                                '/sesi/${event.id}/kehadiran',
                              ),
                              child: const Text('Catat kehadiran'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _DuesSummary(
                      collected: event.collected,
                      outstanding: event.outstanding,
                    ),
                    if (state.duesSystem.timing == DuesTiming.perOrang &&
                        event.attendanceSaved) ...[
                      const SizedBox(height: 10),
                      YbGroup(
                        children: [
                          YbListRow(
                            icon: Icons.edit_note_rounded,
                            title: event.billsSent
                                ? 'Ubah pemakaian'
                                : 'Catat pemakaian',
                            subtitle: event.billsSent
                                ? 'Tagihan sudah dikirim ke pemain'
                                : 'Match dan kok tiap pemain, lalu kirim tagihan',
                            onTap: () =>
                                context.push('/sesi/${event.id}/pemakaian'),
                          ),
                        ],
                      ),
                    ],
                    if (state.duesSystem.timing == DuesTiming.setelahTetap &&
                        event.attendanceSaved &&
                        event.unbilledAttendees.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () => ref
                            .read(manageProvider.notifier)
                            .billAttendees(event.id),
                        icon: const Icon(Icons.receipt_long_outlined, size: 20),
                        label: Text(
                          'Tagih ${event.unbilledAttendees.length} yang hadir',
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (rows.isNotEmpty) ...[
                      Text(
                        'Ketuk nominal untuk mengubahnya per orang.',
                        style: YbText.label(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    for (final (member, due) in rows) ...[
                      YbCard(
                        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: YbText.body(
                                      size: 15,
                                      weight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  InkWell(
                                    onTap: () => _editAmount(
                                      context,
                                      ref,
                                      event,
                                      member,
                                      due,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              [
                                                member.typeShort,
                                                formatRupiah(due.amount),
                                                if (due.cancelledAt != null ||
                                                    due.refund != null)
                                                  'batal ikut'
                                                else if (due.paid &&
                                                    !event.attendees.contains(
                                                      member.id,
                                                    ))
                                                  'bayar di muka',
                                                if (due.awaitingCheck)
                                                  'bukti dikirim',
                                                if (!due.paid &&
                                                    due.proof?.status ==
                                                        ProofStatus.ditolak)
                                                  'bukti ditolak',
                                              ].join(' · '),
                                              style: YbText.label(),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 14,
                                            color: YbColors.muted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (due.refund != null)
                              TextButton(
                                onPressed: () =>
                                    context.push('/kelola/pembatalan'),
                                child: Text(switch (due.refund!.status) {
                                  RefundStatus.selesai => 'Dikembalikan',
                                  RefundStatus.tidakKembali => 'Tidak kembali',
                                  _ => 'Pengembalian',
                                }),
                              )
                            else if (due.paid)
                              TextButton.icon(
                                onPressed: () => _unmarkPaid(
                                  context,
                                  ref,
                                  event,
                                  member,
                                  due,
                                ),
                                icon: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: YbColors.success,
                                ),
                                label: Text(
                                  'Lunas',
                                  style: YbText.body(
                                    size: 13,
                                    color: YbColors.success,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              )
                            else if (due.awaitingCheck)
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                ),
                                onPressed: () => showProofReviewSheet(
                                  context,
                                  event: event,
                                  member: member,
                                ),
                                child: const Text('Cek bukti'),
                              )
                            else
                              OutlinedButton(
                                onPressed: () =>
                                    _markPaid(context, ref, event, member, due),
                                child: const Text('Tandai lunas'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (prepayCandidates.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('Bayar di muka', style: YbText.display(size: 17)),
                      const SizedBox(height: 4),
                      Text(
                        'Member yang sudah transfer sebelum sesi. Nominal awal ${formatRupiah(state.pb?.feePerSession ?? 0)}, bisa diubah.',
                        style: YbText.label(),
                      ),
                      const SizedBox(height: 8),
                      for (final member in prepayCandidates) ...[
                        YbCard(
                          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  member.name,
                                  style: YbText.body(
                                    size: 15,
                                    weight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => _markPaid(
                                  context,
                                  ref,
                                  event,
                                  member,
                                  null,
                                ),
                                child: const Text('Sudah bayar'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ],
                ],
              ),
            ),
            if (event.remindableCount > 0)
              BottomActionBar(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.push('/sesi/${event.id}/pengingat'),
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: Text('Kirim pengingat (${event.remindableCount})'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// K10 Kirim pengingat. WhatsApp dibuka per orang, karena satu pesan hanya
/// bisa dikirim ke satu nomor.
class ReminderPage extends ConsumerStatefulWidget {
  const ReminderPage({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends ConsumerState<ReminderPage> {
  late final _message = TextEditingController(text: _defaultMessage());
  final _sent = <String>{};

  String _defaultMessage() {
    final state = ref.read(manageProvider);
    final event = state.eventById(widget.eventId);
    final pb = state.pb;
    if (event == null || pb == null) return '';
    return 'Halo {nama}, iuran ${pb.name} untuk sesi ${formatDate(event.start)} '
        'sebesar {nominal} belum kami terima. Mohon dibayar ya. Terima kasih.';
  }

  String _fill(Member member, Due due) => _message.text
      .replaceAll('{nama}', member.name.split(' ').first)
      .replaceAll('{nominal}', formatRupiah(due.amount));

  Future<void> _send(Member member, Due due) async {
    final ok = await openWhatsApp(member.whatsapp!, _fill(member, due));
    if (!mounted) return;
    if (ok) {
      setState(() => _sent.add(member.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp tidak bisa dibuka. Salin pesannya lalu kirim manual.',
          ),
        ),
      );
    }
  }

  Future<void> _copy(Member member, Due due) async {
    await Clipboard.setData(ClipboardData(text: _fill(member, due)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pesan untuk ${member.name} disalin')),
    );
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manageProvider);
    final event = state.eventById(widget.eventId);
    if (event == null) return const MissingSession();

    final unpaid = [
      for (final entry in event.dues.entries)
        // Yang sudah mengirim bukti tidak perlu diingatkan.
        if (entry.value.billable &&
            !entry.value.paid &&
            !entry.value.awaitingCheck)
          if (state.memberById(entry.key) case final member?)
            (member, entry.value),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const PageHeader(title: 'Kirim pengingat'),
            const SizedBox(height: 16),
            if (unpaid.isEmpty)
              YbEmptyState(
                icon: Icons.check_circle_outline,
                title: 'Semua iuran sesi ini sudah lunas',
                message: 'Tidak ada yang perlu diingatkan.',
                actionLabel: 'Kembali',
                onAction: () => context.pop(),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Isi pesan',
                      style: YbText.body(weight: FontWeight.w700),
                    ),
                  ),
                  const YbTag('Bisa diubah', tone: YbTagTone.accent),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _message,
                minLines: 3,
                maxLines: 6,
                onChanged: (_) => setState(() {}),
                style: YbText.body(height: 1.5),
              ),
              const SizedBox(height: 6),
              Text(
                '{nama} dan {nominal} diganti otomatis untuk tiap penerima.',
                style: YbText.label(),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text('Penerima', style: YbText.display(size: 17)),
                  ),
                  YbTag('${unpaid.length} orang', tone: YbTagTone.primary),
                ],
              ),
              const SizedBox(height: 10),
              for (final (member, due) in unpaid) ...[
                YbCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          YbAvatar(
                            member.initials,
                            size: 40,
                            photoPath: member.photoPath,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: YbText.body(
                                    size: 15,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  member.whatsapp == null
                                      ? '${formatRupiah(due.amount)} · nomor belum diisi'
                                      : '${formatRupiah(due.amount)} · ${displayWhatsapp(member.whatsapp!)}',
                                  style: YbText.label(),
                                ),
                              ],
                            ),
                          ),
                          if (_sent.contains(member.id))
                            const YbTag(
                              'Dibuka',
                              tone: YbTagTone.success,
                              icon: Icons.check,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: member.whatsapp == null
                                ? OutlinedButton(
                                    onPressed: () =>
                                        context.push('/member/${member.id}'),
                                    child: const Text('Isi nomor'),
                                  )
                                : FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(44),
                                    ),
                                    onPressed: () => _send(member, due),
                                    icon: const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 18,
                                    ),
                                    label: const Text('WhatsApp'),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _copy(member, due),
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Salin pesan'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// K19 Cek bukti transfer dari member.
Future<void> showProofReviewSheet(
  BuildContext context, {
  required SessionEvent event,
  required Member member,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  showDragHandle: true,
  builder: (_) => _ProofReviewSheet(eventId: event.id, memberId: member.id),
);

/// Alasan yang paling sering, supaya pengurus tidak perlu mengetik.
const proofRejectReasons = [
  'Nominal tidak sesuai',
  'Foto tidak terbaca',
  'Transfer belum masuk',
];

class _ProofReviewSheet extends ConsumerStatefulWidget {
  const _ProofReviewSheet({required this.eventId, required this.memberId});

  final String eventId;
  final String memberId;

  @override
  ConsumerState<_ProofReviewSheet> createState() => _ProofReviewSheetState();
}

class _ProofReviewSheetState extends ConsumerState<_ProofReviewSheet> {
  final _reason = TextEditingController();
  var _rejecting = false;
  String? _reasonError;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _approve(Member member, Due previous) {
    final notifier = ref.read(manageProvider.notifier);
    notifier.approveProof(widget.eventId, member.id);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Bukti ${member.name} disetujui, iuran lunas'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Batalkan',
            textColor: YbColors.accent,
            onPressed: () =>
                notifier.setDue(widget.eventId, member.id, previous),
          ),
        ),
      );
  }

  void _reject(Member member) {
    final reason = _reason.text.trim();
    if (reason.length < 4) {
      setState(
        () => _reasonError =
            'Tulis alasannya supaya member tahu apa yang perlu diperbaiki.',
      );
      return;
    }
    ref
        .read(manageProvider.notifier)
        .rejectProof(widget.eventId, member.id, reason);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Bukti ${member.name} ditolak. Dia bisa mengirim bukti baru.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manageProvider);
    final event = state.eventById(widget.eventId);
    final member = state.memberById(widget.memberId);
    final due = event?.dues[widget.memberId];
    final proof = due?.proof;

    if (event == null || member == null || due == null || proof == null) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: YbEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Bukti ini sudah tidak ada',
            message: 'Mungkin sesi atau membernya sudah dihapus.',
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cek bukti transfer', style: YbText.display(size: 22)),
            const SizedBox(height: 4),
            Text(
              '${member.name} · ${event.title}, ${formatSessionDate(event.start, ref.read(nowProvider)())}',
              style: YbText.label(),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(YbRadius.md),
              child: SizedBox(
                height: 220,
                child: YbPhoto(
                  path: proof.path,
                  fit: BoxFit.contain,
                  fallback: const PhotoPlaceholder(
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Iuran yang harus dibayar',
                    style: YbText.label(),
                  ),
                ),
                Text(formatRupiah(due.amount), style: YbText.display(size: 18)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Cocokkan nominal dan nama pengirim dengan mutasi rekeningmu sebelum menyetujui.',
              style: YbText.label(),
            ),
            const SizedBox(height: 16),
            if (_rejecting) ...[
              Text('Alasan menolak', style: YbText.label()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in proofRejectReasons)
                    YbChoiceChip(
                      label: r,
                      selected: _reason.text == r,
                      onTap: () => setState(() {
                        _reason.text = r;
                        _reasonError = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reason,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() => _reasonError = null),
                decoration: InputDecoration(
                  hintText: 'Atau tulis alasan sendiri',
                  errorText: _reasonError,
                  errorMaxLines: 2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _rejecting = false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _reject(member),
                      child: const Text('Tolak bukti'),
                    ),
                  ),
                ],
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _rejecting = true),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => _approve(member, due),
                      child: const Text('Setujui, lunas'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
