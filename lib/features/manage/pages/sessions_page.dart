import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/tours.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../pb/data/pb_models.dart' show dayNames;
import '../data/manage_models.dart';
import '../state/manage_providers.dart';
import 'manage_shell.dart' show formatSessionDate, rsvpSummary;
import 'manage_widgets.dart';

/// K7 Jadwal sesi.
class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  var _showPast = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manageProvider);
    final now = ref.watch(nowProvider)();
    final list = _showPast ? state.past(now) : state.upcoming(now);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          YbPageTitle(
            'Jadwal',
            subtitle: '${state.upcoming(now).length} sesi mendatang',
            trailing: IconButton(
              key: TourKeys.scheduleCreate,
              tooltip: 'Buat sesi',
              onPressed: () => showCreateSessionSheet(context),
              style: IconButton.styleFrom(
                backgroundColor: YbColors.primary,
                fixedSize: const Size(44, 44),
              ),
              icon: Icon(Icons.add_rounded, color: YbColors.onPrimary),
            ),
          ),
          const SizedBox(height: 16),
          YbSegmented<bool>(
            options: const [
              (false, 'Mendatang', null),
              (true, 'Riwayat', null),
            ],
            selected: _showPast,
            onChanged: (v) => setState(() => _showPast = v),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            YbEmptyState(
              icon: Icons.calendar_today_outlined,
              title: _showPast
                  ? 'Belum ada sesi yang lewat'
                  : 'Belum ada sesi mendatang',
              message: _showPast
                  ? 'Sesi yang sudah selesai akan muncul di sini.'
                  : 'Buat sesi supaya kehadiran dan iurannya bisa dicatat.',
              actionLabel: _showPast ? null : 'Buat sesi',
              onAction: () => showCreateSessionSheet(context),
            ),
          for (final (i, e) in list.indexed) ...[
            _SessionCard(
              event: e,
              memberCount: state.members.length,
              now: now,
              tourTarget: i == 0 && !_showPast,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard({
    required this.event,
    required this.memberCount,
    required this.now,
    this.tourTarget = false,
  });

  /// Kartu pertama disorot tur pengurus.
  final bool tourTarget;
  final SessionEvent event;
  final int memberCount;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = formatSessionDate(event.start, now);
    final today = label == 'Hari ini';
    final perOrang = ref.watch(
      manageProvider.select((s) => s.duesSystem.timing == DuesTiming.perOrang),
    );
    final status = event.attendanceSaved
        ? '${event.attendees.length} dari $memberCount member hadir'
        : event.rsvps.isNotEmpty
        ? 'Konfirmasi: ${rsvpSummary(event)}'
        : 'Kehadiran belum dicatat';

    return YbCard(
      highlight: today,
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateTile(date: event.start),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      today ? 'Hari ini · ${event.title}' : event.title,
                      style: YbText.body(size: 16, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${event.timeRange} · ${event.venue}',
                      style: YbText.body(size: 14, color: YbColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status,
                      style: YbText.body(size: 13, weight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Hapus sesi',
                onPressed: () async {
                  final ok = await confirmDestructive(
                    context,
                    title: 'Hapus sesi ini?',
                    message: event.attendanceSaved || event.dues.isNotEmpty
                        ? 'Catatan kehadiran dan iuran sesi ini, termasuk yang sudah dibayar, ikut terhapus dan tidak bisa dikembalikan.'
                        : 'Sesi ${event.title} akan dihapus dari jadwal.',
                    confirmLabel: 'Hapus sesi',
                  );
                  if (ok) {
                    ref.read(manageProvider.notifier).removeEvent(event.id);
                  }
                },
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: YbColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: tourTarget ? TourKeys.firstSessionAttendance : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      // Bantalan bawaan terlalu lebar untuk setengah kartu.
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () =>
                        context.push('/sesi/${event.id}/kehadiran'),
                    child: Text(
                      event.attendanceSaved
                          ? 'Ubah kehadiran'
                          : 'Catat kehadiran',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      perOrang && event.attendanceSaved && !event.billsSent
                          ? '/sesi/${event.id}/pemakaian'
                          : '/sesi/${event.id}/iuran',
                    ),
                    child: Text(
                      perOrang && event.attendanceSaved && !event.billsSent
                          ? 'Pemakaian'
                          : 'Iuran',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kotak tanggal hijau limau seperti di kartu sesi Beranda.
class _DateTile extends StatelessWidget {
  const _DateTile({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: YbColors.accent,
        borderRadius: BorderRadius.circular(YbRadius.md),
      ),
      child: Column(
        children: [
          Text(
            dayNames[date.weekday]!.substring(0, 3).toUpperCase(),
            style: YbText.body(
              size: 11,
              weight: FontWeight.w700,
              color: YbColors.onAccent,
            ),
          ),
          Text(
            '${date.day}',
            style: YbText.score(size: 22, color: YbColors.onAccent),
          ),
        ],
      ),
    );
  }
}

/// Jenis sesi yang umum di PB. Nama sesi tetap bisa ditulis bebas.
const sessionKinds = ['Latihan rutin', 'Sparing', 'Main bareng'];

/// K15 Buat sesi.
Future<void> showCreateSessionSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => const _CreateSessionSheet(),
    );

class _CreateSessionSheet extends ConsumerStatefulWidget {
  const _CreateSessionSheet();

  @override
  ConsumerState<_CreateSessionSheet> createState() =>
      _CreateSessionSheetState();
}

class _CreateSessionSheetState extends ConsumerState<_CreateSessionSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(text: 'Latihan rutin');
  late final _venue = TextEditingController(
    text: ref.read(manageProvider).pb?.venue ?? '',
  );
  late DateTime _date = _today.add(const Duration(days: 1));
  var _start = const TimeOfDay(hour: 19, minute: 0);
  var _end = const TimeOfDay(hour: 21, minute: 0);
  String? _timeError;

  DateTime get _today {
    final n = ref.read(nowProvider)();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void dispose() {
    _title.dispose();
    _venue.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _today.subtract(const Duration(days: 60)),
      lastDate: _today.add(const Duration(days: 365)),
      helpText: 'Tanggal sesi',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
      helpText: start ? 'Jam mulai' : 'Jam selesai',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
      _timeError = null;
    });
  }

  void _save() {
    final minutes =
        (_end.hour * 60 + _end.minute) - (_start.hour * 60 + _start.minute);
    setState(
      () => _timeError = minutes > 0
          ? null
          : 'Jam selesai harus setelah jam mulai.',
    );
    if (!_form.currentState!.validate() || _timeError != null) return;
    ref
        .read(manageProvider.notifier)
        .addEvent(
          title: _title.text,
          start: DateTime(
            _date.year,
            _date.month,
            _date.day,
            _start.hour,
            _start.minute,
          ),
          durationMinutes: minutes,
          venue: _venue.text,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Buat sesi', style: YbText.display(size: 22)),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Jenis sesi',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final kind in sessionKinds)
                      YbChoiceChip(
                        label: kind,
                        selected: _title.text.trim() == kind,
                        onTap: () => setState(() => _title.text = kind),
                      ),
                  ],
                ),
              ),
              LabeledField(
                label: 'Nama sesi',
                helper: 'Pilih jenis di atas, atau tulis nama sendiri.',
                child: TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Isi nama sesi.' : null,
                ),
              ),
              LabeledField(
                label: 'Tanggal',
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text('${formatDate(_date)} ${_date.year}'),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: LabeledField(
                      label: 'Mulai',
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () => _pickTime(start: true),
                        child: Text(formatTimeOfDay(_start)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LabeledField(
                      label: 'Selesai',
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () => _pickTime(start: false),
                        child: Text(formatTimeOfDay(_end)),
                      ),
                    ),
                  ),
                ],
              ),
              if (_timeError != null) FieldError(_timeError!),
              LabeledField(
                label: 'Tempat',
                child: TextFormField(
                  controller: _venue,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Isi tempat sesi.' : null,
                ),
              ),
              FilledButton(onPressed: _save, child: const Text('Simpan sesi')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tampilan saat sesi yang dibuka sudah tidak ada.
class MissingSession extends StatelessWidget {
  const MissingSession({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const PageHeader(title: 'Sesi'),
              const SizedBox(height: 20),
              YbEmptyState(
                icon: Icons.event_busy_outlined,
                title: 'Sesi ini sudah tidak ada',
                message: 'Mungkin sudah dihapus. Kembali ke jadwal.',
                actionLabel: 'Kembali',
                onAction: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// K8 Kehadiran sesi.
class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  late final SessionEvent? _initial = ref
      .read(manageProvider)
      .eventById(widget.eventId);

  /// Sebelum kehadiran pertama kali disimpan, member yang konfirmasi ikut
  /// sudah dicentang. Pengurus tinggal menyesuaikan yang batal datang.
  late final bool _prefilled =
      _initial != null && !_initial.attendanceSaved && _initial.goingCount > 0;
  late final Set<String> _present = {
    ...?_initial?.attendees,
    if (_prefilled)
      for (final r in _initial!.rsvps.entries)
        if (r.value == Rsvp.ikut) r.key,
  };
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manageProvider);
    final event = state.eventById(widget.eventId);
    if (event == null) return const MissingSession();

    final q = _search.text.trim().toLowerCase();
    final members =
        state.members
            .where((m) => q.isEmpty || m.name.toLowerCase().contains(q))
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    final allSelected =
        state.members.isNotEmpty && _present.length == state.members.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: YbBackButton(),
                  ),
                  const SizedBox(height: 16),
                  YbPageTitle(
                    'Kehadiran',
                    subtitle: '${event.title} · ${event.shortLabel}',
                  ),
                  const SizedBox(height: 16),
                  if (state.members.isEmpty)
                    YbEmptyState(
                      icon: Icons.people_outline,
                      title: 'Belum ada member untuk dicatat',
                      message: 'Tambah member dulu, lalu kembali ke sini untuk mencatat siapa yang hadir.',
                      actionLabel: 'Tambah member',
                      onAction: () => context.push('/member/baru'),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: YbColors.surface,
                        borderRadius: BorderRadius.circular(YbRadius.lg),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _Count('${_present.length}', 'Dicek hadir'),
                            VerticalDivider(width: 1, color: YbColors.line),
                            _Count('${event.goingCount}', 'Bilang ikut'),
                            VerticalDivider(width: 1, color: YbColors.line),
                            _Count('${state.members.length}', 'Member'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: YbColors.muted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _prefilled
                                ? 'Yang bilang ikut sudah dicentang. Hapus centang kalau ternyata tidak datang.'
                                : 'Ketuk nama saat pemain datang.',
                            style: YbText.body(size: 13, color: YbColors.muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: YbText.body(size: 15),
                      decoration: InputDecoration(
                        hintText: 'Cari nama member',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: YbColors.muted,
                        ),
                        filled: true,
                        fillColor: YbColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(YbRadius.pill),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(YbRadius.pill),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Member',
                            style: YbText.body(size: 14, color: YbColors.muted),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            if (allSelected) {
                              _present.clear();
                            } else {
                              _present.addAll(state.members.map((m) => m.id));
                            }
                          }),
                          child: Text(
                            allSelected ? 'Kosongkan' : 'Pilih semua',
                          ),
                        ),
                      ],
                    ),
                    if (members.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Tidak ada member dengan nama itu.',
                          textAlign: TextAlign.center,
                          style: YbText.body(color: YbColors.muted),
                        ),
                      )
                    else
                      YbGroup(
                        children: [
                          for (final m in members)
                            _AttendanceRow(
                              member: m,
                              rsvp: event.rsvps[m.id],
                              present: _present.contains(m.id),
                              onChanged: (v) => setState(() {
                                if (v) {
                                  _present.add(m.id);
                                } else {
                                  _present.remove(m.id);
                                }
                              }),
                            ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/member/baru'),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Tambah pemain baru'),
                    ),
                  ],
                ],
              ),
            ),
            if (state.members.isNotEmpty)
              BottomActionBar(
                children: [
                  Expanded(
                    child: FilledButton(
                      // Kehadiran yang sudah tersimpan boleh dikosongkan.
                      onPressed: _present.isEmpty && !event.attendanceSaved
                          ? null
                          : () {
                              // Member yang dihapus saat layar ini terbuka dibuang.
                              final valid = state.members
                                  .map((m) => m.id)
                                  .toSet();
                              ref
                                  .read(manageProvider.notifier)
                                  .saveAttendance(
                                    event.id,
                                    _present.intersection(valid),
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kehadiran disimpan'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              context.pushReplacement(
                                '/sesi/${event.id}/iuran',
                              );
                            },
                      child: Text('Simpan ${_present.length} hadir'),
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

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.member,
    required this.present,
    required this.onChanged,
    this.rsvp,
  });

  final Member member;
  final Rsvp? rsvp;
  final bool present;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final details = [
      member.typeShort,
      if (member.level != null) 'Level ${member.level!.label}',
      if (rsvp == Rsvp.ikut) 'bilang ikut',
      if (rsvp == Rsvp.tidak) 'bilang tidak ikut',
    ].join(' · ');
    return Semantics(
      checked: present,
      label: '${member.name}, $details',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(!present),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 16, 6),
          child: Row(
            children: [
              Checkbox(value: present, onChanged: (v) => onChanged(v ?? false)),
              YbAvatar(member.initials, photoPath: member.photoPath, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: YbText.body(size: 16, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      details,
                      style: YbText.body(size: 13, color: YbColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satu angka di kartu ringkasan kehadiran.
class _Count extends StatelessWidget {
  const _Count(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: YbText.display(size: 22)),
        Text(
          label,
          style: YbText.body(size: 13, color: YbColors.muted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
