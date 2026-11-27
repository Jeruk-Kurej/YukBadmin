import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../auth/preferences_page.dart' show areaOptions;
import '../../pb/data/pb_models.dart';
import '../../pb/state/providers.dart';
import '../data/manage_models.dart';
import '../state/manage_providers.dart';
import 'manage_widgets.dart';
import '../../pb/pages/pb_card.dart' show PbPhotoCard;
import '../../../core/widgets/photo.dart';

/// K1–K3 Daftarkan PB: data dasar, jadwal dan biaya, lalu periksa.
class RegisterPbPage extends ConsumerStatefulWidget {
  const RegisterPbPage({super.key});

  @override
  ConsumerState<RegisterPbPage> createState() => _RegisterPbPageState();
}

class _ScheduleDraft {
  int weekday = 3;
  TimeOfDay start = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 22, minute: 0);

  bool get valid => end.hour * 60 + end.minute > start.hour * 60 + start.minute;
}

class _RegisterPbPageState extends ConsumerState<RegisterPbPage> {
  static const _stepHints = [
    'Isi data yang dilihat calon member di Cari PB. Nomor WhatsApp dipakai pemain untuk bertanya, jadi pakai nomor yang aktif.',
    'Tulis jadwal rutin dan iuran yang biasa kamu tagih. Semua bisa diubah lagi nanti di Profil PB.',
    'Cek sekali lagi. Ketuk baris untuk mengubah. Setelah didaftarkan, PB-mu langsung muncul di Cari PB.',
  ];

  final _basicForm = GlobalKey<FormState>();
  final _feeForm = GlobalKey<FormState>();
  var _step = 0;

  final _name = TextEditingController();
  final _venue = TextEditingController();
  final _district = TextEditingController();
  final _whatsapp = TextEditingController();
  final _sessionFee = TextEditingController();
  final _monthlyFee = TextEditingController();
  final _foundedYear = TextEditingController();
  late String _area = ref.read(preferencesProvider).area;

  final _levels = <Level>{};
  String? _levelError;
  final _schedules = [_ScheduleDraft()];
  String? _scheduleError;
  final _types = <MemberType>{MemberType.tetap, MemberType.insidental};
  double _quota = 30;
  bool _open = true;
  bool _levelTest = false;
  String? _logoPath;

  Future<void> _pickLogo() async {
    final change = await changePhoto(
      context,
      ref,
      title: 'Logo PB',
      hasPhoto: _logoPath != null,
    );
    if (change != null) setState(() => _logoPath = change.path);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _venue,
      _district,
      _whatsapp,
      _sessionFee,
      _monthlyFee,
      _foundedYear,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _fee => parseRupiah(_sessionFee.text) ?? 0;
  int? get _monthly => parseRupiah(_monthlyFee.text);

  void _next() {
    if (_step == 0) {
      if (!_basicForm.currentState!.validate()) return;
    } else if (_step == 1) {
      final feesOk = _feeForm.currentState!.validate();
      setState(() {
        _levelError = _levels.isEmpty ? 'Pilih minimal satu level.' : null;
        _scheduleError = _schedules.every((s) => s.valid)
            ? null
            : 'Jam selesai harus setelah jam mulai.';
      });
      if (!feesOk || _levelError != null || _scheduleError != null) return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  Pb _build() {
    final user = ref.read(sessionProvider);
    final sorted = _levels.toList()..sort((a, b) => a.index.compareTo(b.index));
    final venue = _venue.text.trim();
    return Pb(
      id: 'pb-milikku',
      name: _name.text.trim(),
      venue: venue,
      district: _district.text.trim(),
      area: _area,
      memberCount: 0,
      quota: _quota.round(),
      minLevel: sorted.first,
      maxLevel: sorted.last,
      memberTypes: {..._types},
      feePerSession: _fee,
      monthlyFee: _types.contains(MemberType.tetap) ? _monthly : null,
      sessions: [
        for (final s in _schedules)
          PbSession(
            weekday: s.weekday,
            startHour: s.start.hour,
            startMinute: s.start.minute,
            endHour: s.end.hour,
            endMinute: s.end.minute,
            venue: venue,
          ),
      ],
      about: '',
      rules: const [],
      manager: PbManager(
        name: user?.name ?? 'Pengurus',
        whatsapp: normalizeWhatsapp(_whatsapp.text)!,
      ),
      openForNewMembers: _open,
      artSeed: _name.text.trim().length,
      foundedYear: int.tryParse(_foundedYear.text.trim()),
      levelTest: _levelTest,
      logoPath: _logoPath,
    );
  }

  void _submit() {
    ref.read(manageProvider.notifier).registerPb(_build());
    context.go('/kelola/beranda');
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Daftarkan PB', 'Jadwal dan biaya', 'Periksa data PB'];
    const steps = ['Profil PB', 'Jadwal dan biaya', 'Periksa'];
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: YbBackButton(onPressed: _back),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(
                        titles[_step],
                        style: YbText.display(size: 32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Langkah ${_step + 1} dari 3',
                      excludeSemantics: true,
                      child: Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i <= _step
                                      ? YbColors.night
                                      : YbColors.line,
                                  borderRadius: BorderRadius.circular(
                                    YbRadius.pill,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Langkah ${_step + 1} dari 3 · ${steps[_step]}',
                      style: YbText.body(
                        size: 13,
                        color: YbColors.muted,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _step,
                  children: [_basicStep(), _scheduleStep(), _reviewStep()],
                ),
              ),
              BottomActionBar(
                children: [
                  if (_step == 1) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: _back,
                        child: const Text('Kembali'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _step == 2 ? _submit : _next,
                      child: Text(_step == 2 ? 'Daftarkan PB' : 'Lanjut'),
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

  Widget _basicStep() {
    final user = ref.watch(sessionProvider);
    return Form(
      key: _basicForm,
      child: SingleChildScrollView(
        // Bukan ListView: kolom yang belum terlihat harus tetap dibangun
        // supaya ikut divalidasi.
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepHint(_stepHints[0]),
            const SizedBox(height: 16),
            Row(
              children: [
                PhotoCircle(
                  path: _logoPath,
                  fallback: const PhotoPlaceholder(),
                  tooltip: 'Unggah logo PB',
                  onTap: _pickLogo,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _logoPath == null ? 'Unggah logo PB' : 'Logo PB',
                        style: YbText.body(size: 15, weight: FontWeight.w700),
                      ),
                      Text(
                        'Opsional. Logo membantu calon member mengenali PB-mu.',
                        style: YbText.label(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            YbCard(
              child: Row(
                children: [
                  YbAvatar(user?.initials ?? '?'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '-',
                          style: YbText.body(size: 15, weight: FontWeight.w700),
                        ),
                        Text('Masuk sebagai pengurus', style: YbText.label()),
                      ],
                    ),
                  ),
                  const YbTag(
                    'Terhubung',
                    tone: YbTagTone.success,
                    icon: Icons.check,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: 'Nama PB',
              child: TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'PB Smash Surabaya',
                ),
                validator: (v) => (v ?? '').trim().length < 3
                    ? 'Isi nama PB, minimal 3 huruf.'
                    : null,
              ),
            ),
            LabeledField(
              label: 'Nama GOR atau lapangan',
              child: TextFormField(
                controller: _venue,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'GOR Kertajaya',
                  prefixIcon: Icon(Icons.place_outlined, color: YbColors.ink),
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Isi tempat PB biasa main.'
                    : null,
              ),
            ),
            LabeledField(
              label: 'Kecamatan',
              child: TextFormField(
                controller: _district,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Gubeng'),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Isi kecamatan supaya pemain bisa mencari per area.'
                    : null,
              ),
            ),
            LabeledField(
              label: 'Area',
              child: DropdownButtonFormField<String>(
                initialValue: areaOptions.contains(_area) ? _area : null,
                isExpanded: true,
                style: YbText.body(size: 15),
                items: [
                  for (final a in areaOptions)
                    DropdownMenuItem(value: a, child: Text(a)),
                ],
                onChanged: (a) => setState(() => _area = a ?? _area),
              ),
            ),
            LabeledField(
              label: 'Nomor WhatsApp pengurus',
              helper: 'Pemain menghubungi nomor ini untuk bergabung.',
              child: TextFormField(
                controller: _whatsapp,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ -]')),
                ],
                decoration: const InputDecoration(hintText: '0812 3456 7890'),
                validator: (v) => normalizeWhatsapp(v ?? '') == null
                    ? 'Isi nomor ponsel yang benar, misalnya 0812 3456 7890.'
                    : null,
              ),
            ),
            LabeledField(
              label: 'Tahun berdiri (opsional)',
              child: TextFormField(
                controller: _foundedYear,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(hintText: '2019'),
                validator: (v) =>
                    foundedYearError(v ?? '', DateTime.now().year),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleStep() {
    return Form(
      key: _feeForm,
      child: SingleChildScrollView(
        // Bukan ListView: kolom yang belum terlihat harus tetap dibangun
        // supaya ikut divalidasi.
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepHint(_stepHints[1]),
            const SizedBox(height: 16),
            Text('Level pemain di PB', style: YbText.label()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in Level.values)
                  YbChoiceChip(
                    round: true,
                    label: level.label,
                    selected: _levels.contains(level),
                    onTap: () => setState(() {
                      if (!_levels.add(level)) _levels.remove(level);
                      _levelError = null;
                    }),
                  ),
              ],
            ),
            if (_levelError != null) FieldError(_levelError!),
            const SizedBox(height: 6),
            Text(
              'Pilih level terendah dan tertinggi. F untuk yang baru mulai, S paling mahir.',
              style: YbText.label(),
            ),
            const SizedBox(height: 18),
            Text('Jadwal rutin', style: YbText.display(size: 17)),
            const SizedBox(height: 10),
            for (final (i, s) in _schedules.indexed) ...[
              _ScheduleRow(
                draft: s,
                onChanged: () => setState(() => _scheduleError = null),
                onRemove: _schedules.length == 1
                    ? null
                    : () => setState(() => _schedules.removeAt(i)),
              ),
              const SizedBox(height: 8),
            ],
            if (_scheduleError != null) FieldError(_scheduleError!),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _schedules.length >= 7
                  ? null
                  : () => setState(() => _schedules.add(_ScheduleDraft())),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Tambah jadwal lain'),
            ),
            const SizedBox(height: 18),
            Text('Biaya', style: YbText.display(size: 17)),
            const SizedBox(height: 10),
            Text('Jenis member yang diterima', style: YbText.label()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in MemberType.values)
                  YbChoiceChip(
                    label: type.label,
                    selected: _types.contains(type),
                    onTap: () => setState(() {
                      // Minimal satu jenis harus tetap terpilih.
                      if (_types.contains(type)) {
                        if (_types.length > 1) _types.remove(type);
                      } else {
                        _types.add(type);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Iuran per sesi',
              helper: 'Di luar sewa lapangan dan shuttlecock.',
              child: TextFormField(
                controller: _sessionFee,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '150000',
                ),
                validator: (v) {
                  final amount = parseRupiah(v ?? '');
                  if (amount == null) {
                    return 'Isi iuran per sesi. Tulis 0 kalau gratis.';
                  }
                  if (amount > 5000000) {
                    return 'Nominal terlalu besar, cek lagi.';
                  }
                  return null;
                },
              ),
            ),
            if (_types.contains(MemberType.tetap))
              LabeledField(
                label: 'Iuran bulanan member tetap (opsional)',
                child: TextFormField(
                  controller: _monthlyFee,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    hintText: '300000',
                  ),
                  validator: (v) => (parseRupiah(v ?? '') ?? 0) > 50000000
                      ? 'Nominal terlalu besar, cek lagi.'
                      : null,
                ),
              ),
            Row(
              children: [
                Expanded(child: Text('Kuota member', style: YbText.label())),
                Text(
                  '${_quota.round()} orang',
                  style: YbText.body(
                    size: 13,
                    color: YbColors.primary,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Slider(
              min: 6,
              max: 80,
              divisions: 37,
              activeColor: YbColors.primary,
              inactiveColor: YbColors.line,
              label: '${_quota.round()} orang',
              value: _quota,
              onChanged: (v) => setState(() => _quota = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: YbColors.primary,
              title: Text(
                'Terima member baru',
                style: YbText.body(size: 15, weight: FontWeight.w700),
              ),
              subtitle: Text(
                'Matikan kalau kuota sedang penuh.',
                style: YbText.label(),
              ),
              value: _open,
              onChanged: (v) => setState(() => _open = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: YbColors.primary,
              title: Text(
                'Pakai tes level',
                style: YbText.body(size: 15, weight: FontWeight.w700),
              ),
              subtitle: Text(
                'Calon member main sekali dulu supaya levelnya cocok.',
                style: YbText.label(),
              ),
              value: _levelTest,
              onChanged: (v) => setState(() => _levelTest = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewStep() {
    // Langkah ini baru dibangun setelah dua langkah sebelumnya lolos validasi.
    if (_step < 2) return const SizedBox.shrink();
    final pb = _build();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _StepHint(_stepHints[2]),
        const SizedBox(height: 20),
        YbSectionTitle('Pratinjau di Cari PB'),
        const SizedBox(height: 10),
        // Kartu sama dengan di Cari PB; belum bisa dibuka sebelum didaftarkan.
        IgnorePointer(child: PbPhotoCard(pb: pb)),
        const SizedBox(height: 24),
        YbSectionTitle('Ringkasan'),
        const SizedBox(height: 10),
        YbGroup(
          children: [
            _ReviewRow(
              label: 'Lokasi',
              value: '${pb.venue}, ${pb.district}',
              onEdit: () => setState(() => _step = 0),
            ),
            _ReviewRow(
              label: 'Level dan kuota',
              value: 'Level ${pb.levelRange} · kuota ${pb.quota} member',
              onEdit: () => setState(() => _step = 1),
            ),
            _ReviewRow(
              label: 'Jadwal',
              value: pb.sessions
                  .map((s) => '${s.dayName} · ${s.timeRange}')
                  .join('\n'),
              onEdit: () => setState(() => _step = 1),
            ),
            _ReviewRow(
              label: 'Biaya',
              value: [
                '${formatRupiah(pb.feePerSession)} per sesi',
                if (pb.monthlyFee != null)
                  '${formatRupiah(pb.monthlyFee!)} per bulan (member tetap)',
              ].join('\n'),
              onEdit: () => setState(() => _step = 1),
            ),
            _ReviewRow(
              label: 'Lainnya',
              value: [
                if (pb.foundedYear != null) 'Berdiri sejak ${pb.foundedYear}',
                pb.levelTest ? 'Pakai tes level' : 'Tanpa tes level',
              ].join('\n'),
              onEdit: () => setState(() => _step = 1),
            ),
            _ReviewRow(
              label: 'Kontak',
              value: displayWhatsapp(pb.manager.whatsapp),
              onEdit: () => setState(() => _step = 0),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: YbColors.surface,
            borderRadius: BorderRadius.circular(YbRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tampil di Cari PB',
                      style: YbText.body(weight: FontWeight.w700),
                    ),
                    Text(
                      'Setelah didaftarkan, pemain bisa menemukan PB-mu.',
                      style: YbText.body(size: 13, color: YbColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              YbTag(
                pb.openForNewMembers ? 'Buka' : 'Kuota penuh',
                tone: pb.openForNewMembers
                    ? YbTagTone.success
                    : YbTagTone.neutral,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.draft,
    required this.onChanged,
    this.onRemove,
  });

  final _ScheduleDraft draft;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  Future<void> _pick(BuildContext context, {required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? draft.start : draft.end,
      helpText: start ? 'Jam mulai' : 'Jam selesai',
    );
    if (picked == null) return;
    if (start) {
      draft.start = picked;
    } else {
      draft.end = picked;
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return YbCard(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: DropdownButtonFormField<int>(
              initialValue: draft.weekday,
              isExpanded: true,
              style: YbText.body(size: 15, weight: FontWeight.w600),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              items: [
                for (final d in dayNames.entries)
                  DropdownMenuItem(value: d.key, child: Text(d.value)),
              ],
              onChanged: (d) {
                draft.weekday = d ?? draft.weekday;
                onChanged();
              },
            ),
          ),
          TextButton(
            onPressed: () => _pick(context, start: true),
            child: Text(
              formatTimeOfDay(draft.start),
              style: YbText.body(size: 15, weight: FontWeight.w700),
              semanticsLabel: 'Jam mulai ${formatTimeOfDay(draft.start)}',
            ),
          ),
          Text('–', style: YbText.body(color: YbColors.muted)),
          TextButton(
            onPressed: () => _pick(context, start: false),
            child: Text(
              formatTimeOfDay(draft.end),
              style: YbText.body(size: 15, weight: FontWeight.w700),
              semanticsLabel: 'Jam selesai ${formatTimeOfDay(draft.end)}',
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Hapus jadwal ini',
              onPressed: onRemove,
              icon: Icon(Icons.close, size: 20, color: YbColors.muted),
            ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      hint: 'Ketuk untuk mengubah $label',
      child: YbListRow(title: label, subtitle: value, onTap: onEdit),
    );
  }
}

/// Petunjuk singkat di awal tiap langkah. Hasil UAT: pendaftaran PB adalah
/// task yang paling butuh bantuan. Ditaruh di dalam area gulir supaya tidak
/// memakan ruang form saat keyboard terbuka.
class _StepHint extends StatelessWidget {
  const _StepHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: YbColors.surface,
        borderRadius: BorderRadius.circular(YbRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: YbColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: YbText.body(size: 13, color: YbColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
