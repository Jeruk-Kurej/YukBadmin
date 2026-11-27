import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../data/manage_models.dart';
import '../state/manage_providers.dart';
import 'manage_widgets.dart';

/// K22 Sistem iuran: cara bayar (sebelum main, setelah main harga tetap,
/// atau dihitung per orang), harga, batas pembatalan, dan pengingat.
class DuesSystemPage extends ConsumerStatefulWidget {
  const DuesSystemPage({super.key});

  @override
  ConsumerState<DuesSystemPage> createState() => _DuesSystemPageState();
}

class _DuesSystemPageState extends ConsumerState<DuesSystemPage> {
  late DuesSystem _sys = ref.read(manageProvider).duesSystem;
  late int _fee = ref.read(manageProvider).pb?.feePerSession ?? 0;

  void _save() {
    final notifier = ref.read(manageProvider.notifier);
    final pb = ref.read(manageProvider).pb;
    notifier.setDuesSystem(_sys);
    if (pb != null && pb.feePerSession != _fee) {
      notifier.updatePb(copyPb(pb, feePerSession: _fee));
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Sistem iuran disimpan')));
    context.pop();
  }

  Future<int?> _editNumber({
    required String title,
    required int value,
    String? suffix,
    bool rupiah = true,
    int min = 0,
    int max = 100000000,
  }) => showDialog<int>(
    context: context,
    builder: (context) => _NumberDialog(
      title: title,
      value: value,
      suffix: suffix,
      rupiah: rupiah,
      min: min,
      max: max,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final sys = _sys;
    final range = sys.courtShareRange;

    Widget valueRow(
      String title,
      String value, {
      String? subtitle,
      required VoidCallback onTap,
    }) => YbListRow(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Text(value, style: YbText.body(size: 16)),
    );

    Widget switchRow(
      String title,
      String subtitle,
      bool value,
      ValueChanged<bool> onChanged,
    ) => SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      value: value,
      onChanged: onChanged,
      title: Text(title, style: YbText.body(size: 16, weight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: YbText.body(size: 13, color: YbColors.muted),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            PageHeader(
              title: 'Sistem iuran',
              trailing: TextButton(
                onPressed: _save,
                child: const Text('Simpan'),
              ),
            ),
            const SizedBox(height: 12),
            YbSectionTitle('Cara bayar'),
            const SizedBox(height: 10),
            YbGroup(
              children: [
                for (final t in DuesTiming.values)
                  _RadioRow(
                    title: t.label,
                    subtitle: t.hint,
                    selected: sys.timing == t,
                    onTap: () => setState(() => _sys = sys.copyWith(timing: t)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (sys.timing == DuesTiming.perOrang) ...[
              YbSectionTitle('Cara mencatat'),
              const SizedBox(height: 10),
              YbSegmented<UsageMode>(
                options: [for (final m in UsageMode.values) (m, m.label, null)],
                selected: sys.usageMode,
                onChanged: (m) =>
                    setState(() => _sys = sys.copyWith(usageMode: m)),
              ),
              const SizedBox(height: 8),
              Text(
                'Per orang: catat match dan kok tiap pemain. Per match: catat 4 pemain tiap match.',
                style: YbText.body(size: 13, color: YbColors.muted),
              ),
              const SizedBox(height: 24),
              YbSectionTitle('Daftar harga'),
              const SizedBox(height: 10),
              YbGroup(
                children: [
                  valueRow(
                    'Match',
                    formatRupiah(sys.matchPrice),
                    onTap: () async {
                      final v = await _editNumber(
                        title: 'Harga per match',
                        value: sys.matchPrice,
                      );
                      if (v != null) {
                        setState(() => _sys = sys.copyWith(matchPrice: v));
                      }
                    },
                  ),
                  valueRow(
                    'Kok',
                    '${formatRupiah(sys.shuttlePrice)} / buah',
                    onTap: () async {
                      final v = await _editNumber(
                        title: 'Harga per kok',
                        value: sys.shuttlePrice,
                      );
                      if (v != null) {
                        setState(() => _sys = sys.copyWith(shuttlePrice: v));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              YbSectionTitle('Lapangan (untuk kisaran harga)'),
              const SizedBox(height: 10),
              YbGroup(
                children: [
                  valueRow(
                    'Sewa per lapangan',
                    formatRupiah(sys.courtPrice),
                    onTap: () async {
                      final v = await _editNumber(
                        title: 'Sewa per lapangan',
                        value: sys.courtPrice,
                      );
                      if (v != null) {
                        setState(() => _sys = sys.copyWith(courtPrice: v));
                      }
                    },
                  ),
                  valueRow(
                    'Kapasitas',
                    '${sys.courtCapacity} orang',
                    onTap: () async {
                      final v = await _editNumber(
                        title: 'Kapasitas per lapangan',
                        value: sys.courtCapacity,
                        rupiah: false,
                        suffix: 'orang',
                        min: 2,
                        max: 20,
                      );
                      if (v != null) {
                        setState(() => _sys = sys.copyWith(courtCapacity: v));
                      }
                    },
                  ),
                  valueRow(
                    'Jumlah lapangan',
                    sys.minCourts == sys.maxCourts
                        ? '${sys.minCourts}'
                        : '${sys.minCourts}–${sys.maxCourts}',
                    onTap: () async {
                      final v = await _editNumber(
                        title: 'Lapangan paling banyak',
                        value: sys.maxCourts,
                        rupiah: false,
                        suffix: 'lapangan',
                        min: 1,
                        max: 10,
                      );
                      if (v != null) {
                        setState(
                          () => _sys = sys.copyWith(
                            maxCourts: v,
                            minCourts: sys.minCourts.clamp(1, v),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pemain melihat: ${formatRupiahShort(range.$1 ~/ 1000 * 1000)}–${formatRupiahShort(range.$2 ~/ 1000 * 1000).replaceFirst('Rp', '')} per orang, ditambah match dan kok.',
                style: YbText.body(size: 13, color: YbColors.muted),
              ),
            ] else ...[
              YbSectionTitle('Harga'),
              const SizedBox(height: 10),
              YbGroup(
                children: [
                  valueRow(
                    'Harga per sesi',
                    formatRupiah(_fee),
                    onTap: () async {
                      final v = await _editNumber(
                        title: 'Harga per sesi',
                        value: _fee,
                        min: 1000,
                      );
                      if (v != null) setState(() => _fee = v);
                    },
                  ),
                  if (sys.timing == DuesTiming.sebelum)
                    valueRow(
                      'Batas pembatalan',
                      '${sys.cancelHours} jam',
                      subtitle: 'Batal ≥${sys.cancelHours} jam: uang kembali.',
                      onTap: () async {
                        final v = await _editNumber(
                          title: 'Batas pembatalan',
                          value: sys.cancelHours,
                          rupiah: false,
                          suffix: 'jam',
                          min: 1,
                          max: 168,
                        );
                        if (v != null) {
                          setState(() => _sys = sys.copyWith(cancelHours: v));
                        }
                      },
                    )
                  else
                    switchRow(
                      'Kirim tagihan otomatis',
                      'Setelah kehadiran sesi disimpan, ke semua yang hadir',
                      sys.autoBill,
                      (v) => setState(() => _sys = sys.copyWith(autoBill: v)),
                    ),
                  switchRow(
                    'Ingatkan yang belum bayar',
                    sys.timing == DuesTiming.sebelum
                        ? 'H-1 pukul 18.00 lewat notifikasi'
                        : 'H+1 pukul 18.00 lewat notifikasi',
                    sys.remindUnpaid,
                    (v) => setState(() => _sys = sys.copyWith(remindUnpaid: v)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pengingat otomatis baru berjalan setelah app tersambung ke server. Sekarang kirim pengingat dari halaman Iuran.',
                style: YbText.body(size: 13, color: YbColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: YbListRow(
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        chevron: false,
        leading: Icon(
          selected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: selected ? YbColors.primary : YbColors.control,
          size: 26,
        ),
      ),
    );
  }
}

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.value,
    required this.rupiah,
    required this.min,
    required this.max,
    this.suffix,
  });

  final String title;
  final int value;
  final bool rupiah;
  final int min;
  final int max;
  final String? suffix;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final _c = TextEditingController(text: '${widget.value}');
  String? _error;

  void _submit() {
    final v = int.tryParse(_c.text.trim());
    if (v == null || v < widget.min || v > widget.max) {
      setState(
        () => _error = widget.rupiah
            ? 'Isi angka antara ${formatRupiah(widget.min)} dan ${formatRupiah(widget.max)}.'
            : 'Isi angka antara ${widget.min} dan ${widget.max}.',
      );
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          prefixText: widget.rupiah ? 'Rp ' : null,
          suffixText: widget.suffix,
          errorText: _error,
          errorMaxLines: 3,
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: YbColors.ink),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
