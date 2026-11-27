import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../pb/data/pb_models.dart' show dayNames;
import '../data/manage_models.dart';
import '../state/manage_providers.dart';
import 'manage_widgets.dart';

/// K23 Catat pemakaian (per orang) dan K23b Catat per match, untuk PB yang
/// iurannya dihitung per orang setelah main.
class UsagePage extends ConsumerWidget {
  const UsagePage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(manageProvider);
    final event = state.eventById(eventId);
    final sys = state.duesSystem;
    if (event == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const PageHeader(title: 'Catat pemakaian'),
                const SizedBox(height: 24),
                YbEmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'Sesi tidak ditemukan',
                  message: 'Sesi ini mungkin sudah dihapus.',
                  actionLabel: 'Kembali',
                  onAction: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final players = [for (final id in event.attendees) ?state.memberById(id)]
      ..sort((a, b) => a.name.compareTo(b.name));
    final total = players.fold(
      0,
      (sum, m) => sum + sys.billFor(event.usage[m.id] ?? const Usage()),
    );
    final perMatch = sys.usageMode == UsageMode.perMatch;
    final date =
        '${dayNames[event.start.weekday]}, ${event.start.day} ${monthNames[event.start.month - 1].substring(0, 3)}';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            PageHeader(title: date),
            const SizedBox(height: 12),
            YbPageTitle(
              perMatch ? 'Catat per match' : 'Catat pemakaian',
              subtitle: perMatch
                  ? 'Pilih 4 pemain dan jumlah kok.'
                  : 'Match ${formatRupiah(sys.matchPrice)} · Kok ${formatRupiah(sys.shuttlePrice)}',
            ),
            const SizedBox(height: 16),
            if (players.isEmpty)
              YbEmptyState(
                icon: Icons.how_to_reg_outlined,
                title: 'Kehadiran belum dicatat',
                message: 'Catat siapa yang hadir dulu, lalu pemakaiannya bisa diisi.',
                actionLabel: 'Catat kehadiran',
                onAction: () => context.push('/sesi/$eventId/kehadiran'),
              )
            else if (perMatch)
              _MatchList(event: event, players: players)
            else ...[
              Text(
                '${players.length} hadir',
                style: YbText.body(size: 13, color: YbColors.muted),
              ),
              const SizedBox(height: 8),
              YbGroup(
                children: [
                  for (final m in players)
                    _UsageRow(
                      member: m,
                      usage: event.usage[m.id] ?? const Usage(),
                      bill: sys.billFor(event.usage[m.id] ?? const Usage()),
                      onChanged: (u) => ref
                          .read(manageProvider.notifier)
                          .setUsage(eventId, m.id, u),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: players.isEmpty
          ? null
          : BottomActionBar(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total ${players.length} pemain',
                        style: YbText.body(size: 13, color: YbColors.muted),
                      ),
                      Text(
                        formatRupiah(total),
                        style: YbText.display(size: 22),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(150, 52),
                  ),
                  onPressed: () => context.push('/sesi/$eventId/tagihan'),
                  child: const Text('Lihat tagihan'),
                ),
              ],
            ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.member,
    required this.usage,
    required this.bill,
    required this.onChanged,
  });

  final Member member;
  final Usage usage;
  final int bill;
  final ValueChanged<Usage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              YbAvatar(member.initials, size: 36, photoPath: member.photoPath),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  member.name,
                  style: YbText.body(size: 16, weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatRupiah(bill),
                style: YbText.body(size: 16, weight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Stepper(
                label: 'Match',
                value: usage.matches,
                onChanged: (v) => onChanged(usage.copyWith(matches: v)),
              ),
              _Stepper(
                label: 'Kok',
                value: usage.shuttles,
                onChanged: (v) => onChanged(usage.copyWith(shuttles: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Penambah/pengurang angka kecil: "Match − 3 +".
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, String tip, VoidCallback? onTap) => IconButton(
      tooltip: tip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: YbColors.bg,
        fixedSize: const Size(36, 36),
        minimumSize: const Size(36, 36),
      ),
      icon: Icon(icon, size: 18, color: YbColors.ink),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: YbText.body(size: 14, color: YbColors.muted),
          ),
        ),
        btn(
          Icons.remove,
          'Kurangi $label',
          value > 0 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: YbText.body(size: 16, weight: FontWeight.w600),
          ),
        ),
        btn(Icons.add, 'Tambah $label', () => onChanged(value + 1)),
      ],
    );
  }
}

/// K23b: daftar match, tiap match empat pemain dan jumlah kok.
class _MatchList extends ConsumerWidget {
  const _MatchList({required this.event, required this.players});

  final SessionEvent event;
  final List<Member> players;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(manageProvider.notifier);
    String first(String id) =>
        players.where((m) => m.id == id).firstOrNull?.name.split(' ').first ??
        '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${event.matches.length} match',
          style: YbText.body(size: 13, color: YbColors.muted),
        ),
        const SizedBox(height: 8),
        if (event.matches.isNotEmpty)
          YbGroup(
            children: [
              for (final (i, m) in event.matches.indexed)
                YbListRow(
                  title: 'Match ${i + 1} · Lapangan ${m.court}',
                  subtitle: m.players.map(first).join(', '),
                  trailing: Text(
                    '${m.shuttles} kok',
                    style: YbText.body(size: 14, color: YbColors.muted),
                  ),
                  onTap: () async {
                    final edited = await _editMatch(context, players, m);
                    if (edited == null) return;
                    final list = [...event.matches];
                    if (edited.players.isEmpty) {
                      list.removeAt(i);
                    } else {
                      list[i] = edited;
                    }
                    notifier.setMatches(event.id, list);
                  },
                ),
            ],
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () async {
            final next = event.matches.isEmpty
                ? 1
                : event.matches.last.court % event.courts + 1;
            final m = await _editMatch(
              context,
              players,
              MatchRecord(court: next, players: const []),
            );
            if (m == null || m.players.isEmpty) return;
            notifier.setMatches(event.id, [...event.matches, m]);
          },
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Tambah match'),
        ),
      ],
    );
  }
}

Future<MatchRecord?> _editMatch(
  BuildContext context,
  List<Member> players,
  MatchRecord initial,
) => showModalBottomSheet<MatchRecord>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _MatchSheet(players: players, initial: initial),
);

class _MatchSheet extends StatefulWidget {
  const _MatchSheet({required this.players, required this.initial});

  final List<Member> players;
  final MatchRecord initial;

  @override
  State<_MatchSheet> createState() => _MatchSheetState();
}

class _MatchSheetState extends State<_MatchSheet> {
  late final _picked = {...widget.initial.players};
  late int _shuttles = widget.initial.shuttles;
  late int _court = widget.initial.court;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pilih 4 pemain', style: YbText.display(size: 20)),
              const SizedBox(height: 4),
              Text(
                '${_picked.length} dari 4 dipilih',
                style: YbText.body(size: 13, color: YbColors.muted),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in widget.players)
                        YbChoiceChip(
                          label: m.name.split(' ').first,
                          selected: _picked.contains(m.id),
                          onTap: () => setState(() {
                            _error = null;
                            if (!_picked.remove(m.id)) {
                              if (_picked.length >= 4) {
                                _error = 'Satu match berisi 4 pemain. Lepas satu dulu.';
                              } else {
                                _picked.add(m.id);
                              }
                            }
                          }),
                        ),
                    ],
                  ),
                ),
              ),
              if (_error != null) FieldError(_error!),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Stepper(
                    label: 'Kok',
                    value: _shuttles,
                    onChanged: (v) => setState(() => _shuttles = v),
                  ),
                  const Spacer(),
                  _Stepper(
                    label: 'Lap.',
                    value: _court,
                    onChanged: (v) => setState(() => _court = v.clamp(1, 20)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.initial.players.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: YbColors.error,
                          minimumSize: const Size(0, 52),
                        ),
                        onPressed: () => Navigator.of(context)
                            .pop(MatchRecord(court: _court, players: const [])),
                        child: const Text('Hapus match'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (_picked.length < 2) {
                          setState(
                            () => _error = 'Pilih minimal 2 pemain (tunggal) atau 4 (ganda).',
                          );
                          return;
                        }
                        Navigator.of(context).pop(
                          MatchRecord(
                            court: _court,
                            players: _picked.toList(),
                            shuttles: _shuttles,
                          ),
                        );
                      },
                      child: const Text('Simpan match'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// K23c Ringkasan tagihan sesi, lalu kirim ke semua pemain.
class BillSummaryPage extends ConsumerWidget {
  const BillSummaryPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(manageProvider);
    final event = state.eventById(eventId);
    final sys = state.duesSystem;
    if (event == null) return const Scaffold(body: SizedBox.shrink());
    final rows = [
      for (final u in event.chargeableUsage)
        if (state.memberById(u.key) case final m? when sys.billFor(u.value) > 0)
          (m, u.value, sys.billFor(u.value)),
    ]..sort((a, b) => a.$1.name.compareTo(b.$1.name));
    final total = rows.fold(0, (s, r) => s + r.$3);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const PageHeader(title: 'Ringkasan'),
            const SizedBox(height: 12),
            YbPageTitle(
              'Tagihan sesi',
              subtitle: '${rows.length} pemain · ${formatRupiah(total)}',
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              YbEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada pemakaian',
                message: 'Isi match dan kok tiap pemain dulu.',
                actionLabel: 'Kembali',
                onAction: () => context.pop(),
              )
            else
              YbGroup(
                children: [
                  for (final (m, u, bill) in rows)
                    YbListRow(
                      leading: YbAvatar(
                        m.initials,
                        size: 40,
                        photoPath: m.photoPath,
                      ),
                      title: m.name,
                      subtitle: '${u.matches} match · ${u.shuttles} kok',
                      trailing: Text(
                        formatRupiah(bill),
                        style: YbText.body(size: 16, weight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            if (event.billsSent) ...[
              const SizedBox(height: 12),
              const YbTag(
                'Tagihan sudah dikirim',
                tone: YbTagTone.success,
                icon: Icons.check,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: rows.isEmpty
          ? null
          : BottomActionBar(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        onPressed: () {
                          ref.read(manageProvider.notifier).sendBills(eventId);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tagihan dikirim ke ${rows.length} pemain',
                                ),
                              ),
                            );
                          context.go('/kelola/iuran');
                        },
                        child: Text(
                          event.billsSent
                              ? 'Kirim ulang tagihan'
                              : 'Kirim tagihan ke ${rows.length} pemain',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => context.pop(),
                        child: const Text('Ubah pemakaian'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
