import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../pb/data/pb_models.dart';
import '../data/manage_models.dart';
import '../state/manage_providers.dart';
import 'manage_widgets.dart';

enum _Source { chat, foto }

/// K11–K13 Impor catatan: tempel catatan, baca, lalu periksa sebelum disimpan.
/// Tidak ada yang tersimpan sebelum pengurus menekan "Simpan ke PB".
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  final _text = TextEditingController();
  var _source = _Source.chat;
  String? _inputError;
  var _reading = false;

  /// Null berarti masih di langkah menempel catatan.
  List<ImportRow>? _rows;
  var _onlyReview = false;

  static const _example =
      '1. Andi Pratama - tetap - 300rb lunas\n'
      '2. Bella Kusuma - tetap - 300rb belum\n'
      '3. Cahyo Wibowo (insidental) 150.000\n'
      '4. Eko S.?\n'
      '5. Dewi Anggraini tetap lunas';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _read() async {
    if (_text.text.trim().isEmpty) {
      setState(
        () => _inputError = 'Tempel catatanmu dulu, satu nama per baris.',
      );
      return;
    }
    setState(() {
      _reading = true;
      _inputError = null;
    });
    final rows = await ref.read(noteParserProvider).parse(_text.text);
    if (!mounted) return;
    setState(() {
      _reading = false;
      if (rows.isEmpty) {
        _inputError = 'Tidak ada nama yang terbaca. Pastikan tiap baris berisi satu nama.';
      } else {
        _rows = rows;
        _onlyReview = false;
      }
    });
  }

  Future<void> _editRow(int index) async {
    final row = _rows![index];
    var type = row.type;
    final result = await showModalBottomSheet<ImportRow>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TextControllerScope(
        initialText: row.name,
        builder: (_, controller) => StatefulBuilder(
          builder: (context, setSheet) => SafeArea(
            child: Padding(
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
                  Text('Perbaiki baris', style: YbText.display(size: 20)),
                  const SizedBox(height: 6),
                  Text('Catatan asli: ${row.source}', style: YbText.label()),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nama member'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final t in MemberType.values)
                        YbChoiceChip(
                          label: t == MemberType.tetap ? 'Tetap' : 'Insidental',
                          selected: type == t,
                          onTap: () => setSheet(() => type = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.length < 2) return;
                      Navigator.of(context).pop(
                        row.copyWith(
                          name: name,
                          type: type,
                          needsReview: false,
                          clearReason: true,
                        ),
                      );
                    },
                    child: const Text('Pakai nama ini'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (result != null) setState(() => _rows![index] = result);
  }

  void _save() {
    final added = ref.read(manageProvider.notifier).importRows(_rows!);
    final skipped = _rows!.length - added;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          skipped == 0
              ? '$added member ditambahkan'
              : '$added member ditambahkan, $skipped dilewati karena namanya sudah ada',
        ),
      ),
    );
    context.go('/kelola/member');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _rows == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _rows = null);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: _rows == null ? _inputStep() : _reviewStep(),
        ),
      ),
    );
  }

  Widget _inputStep() {
    return Column(
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
              const YbPageTitle(
                'Impor catatan',
                subtitle: 'Pindahkan daftar member lama.',
              ),
              const SizedBox(height: 16),
              YbSegmented<_Source>(
                options: const [
                  (_Source.chat, 'Chat atau teks', Icons.chat_bubble_outline),
                  (_Source.foto, 'Foto (segera)', Icons.photo_camera_outlined),
                ],
                selected: _source,
                onChanged: (v) => setState(() => _source = v),
              ),
              const SizedBox(height: 8),
              _Note(
                icon: Icons.info_outline_rounded,
                text: 'Baca foto segera hadir. Tempel teks dulu.',
              ),
              const SizedBox(height: 16),
              if (_source == _Source.foto)
                YbEmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Baca foto catatan belum tersedia',
                  message: 'Fitur ini butuh layanan AI yang belum tersambung. Untuk sekarang, ketik atau tempel isinya lewat "Chat atau teks".',
                  actionLabel: 'Pakai chat atau teks',
                  onAction: () => setState(() => _source = _Source.chat),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Daftar member',
                        style: YbText.body(size: 14, color: YbColors.muted),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _text.text = _example;
                        _inputError = null;
                      }),
                      child: const Text('Isi dengan contoh'),
                    ),
                  ],
                ),
                TextField(
                  controller: _text,
                  minLines: 7,
                  maxLines: 12,
                  style: YbText.body(height: 1.5),
                  onChanged: (_) {
                    if (_inputError != null) setState(() => _inputError = null);
                  },
                  decoration: InputDecoration(
                    hintText: 'Tempel daftar member dari grup WhatsApp atau Sheets di sini',
                    hintMaxLines: 3,
                    errorText: _inputError,
                    errorMaxLines: 3,
                    filled: true,
                    fillColor: YbColors.surface,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: YbColors.surface,
                    borderRadius: BorderRadius.circular(YbRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supaya terbaca jelas',
                        style: YbText.body(weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      for (final tip in const [
                        'Satu nama per baris',
                        'Tulis "tetap" atau "insidental" kalau ada',
                        'Nominal dan "lunas" atau "belum" ikut terbaca',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: YbColors.success,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(tip, style: YbText.body(size: 14)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Note(
                  icon: Icons.lock_outline_rounded,
                  text: 'Dibaca di HP ini saja, tidak dikirim ke mana pun.',
                ),
              ],
            ],
          ),
        ),
        if (_source == _Source.chat)
          BottomActionBar(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _reading ? null : _read,
                  icon: _reading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: YbColors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_outlined, size: 20),
                  label: Text(_reading ? 'Membaca catatan' : 'Baca catatan'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _reviewStep() {
    final rows = _rows!;
    final reviewCount = rows.where((r) => r.needsReview).length;
    final shown = [
      for (final (i, r) in rows.indexed)
        if (!_onlyReview || r.needsReview) (i, r),
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: YbBackButton(
                  onPressed: () => setState(() => _rows = null),
                ),
              ),
              const SizedBox(height: 16),
              YbPageTitle(
                'Periksa hasil',
                subtitle: '${rows.length} nama terbaca dari catatanmu.',
              ),
              const SizedBox(height: 16),
              YbSegmented<bool>(
                options: [
                  (false, 'Semua ${rows.length}', null),
                  (true, 'Perlu dicek $reviewCount', null),
                ],
                selected: _onlyReview,
                onChanged: (v) => setState(() => _onlyReview = v),
              ),
              const SizedBox(height: 16),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Tidak ada baris yang perlu dicek.',
                    textAlign: TextAlign.center,
                    style: YbText.body(color: YbColors.muted),
                  ),
                )
              else
                YbGroup(
                  children: [
                    for (final (i, row) in shown)
                      _ImportRowCard(
                        row: row,
                        onEdit: () => _editRow(i),
                        onRemove: () => setState(() {
                          rows.removeAt(i);
                          if (rows.isEmpty) _rows = null;
                        }),
                      ),
                  ],
                ),
              const SizedBox(height: 4),
              Text(
                'Yang disimpan hanya nama dan jenis member. Nominal dan status bayar ditampilkan untuk kamu cocokkan, lalu dicatat per sesi di menu Iuran.',
                style: YbText.body(size: 13, color: YbColors.muted),
              ),
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: YbColors.ink),
                onPressed: () => setState(() => _rows = null),
                child: const Text('Ulangi dari awal'),
              ),
            ],
          ),
        ),
        BottomActionBar(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: reviewCount > 0 ? null : _save,
                child: Text(
                  reviewCount > 0
                      ? 'Cek $reviewCount baris dulu'
                      : 'Simpan ${rows.length} member ke PB',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ImportRowCard extends StatelessWidget {
  const _ImportRowCard({
    required this.row,
    required this.onEdit,
    required this.onRemove,
  });

  final ImportRow row;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final details = [
      row.type == MemberType.tetap ? 'Tetap' : 'Insidental',
      if (row.amount != null) formatRupiah(row.amount!),
      if (row.paid != null) row.paid! ? 'Lunas' : 'Belum bayar',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
      child: Row(
        children: [
          if (row.needsReview) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: YbColors.warningSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.priority_high_rounded,
                size: 20,
                color: YbColors.warning,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  style: YbText.body(size: 16, weight: FontWeight.w600),
                ),
                Text(
                  row.needsReview ? row.reason ?? 'Perlu dicek' : details,
                  style: YbText.body(
                    size: 13,
                    color: row.needsReview ? YbColors.warning : YbColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Perbaiki ${row.name}',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'Buang ${row.name}',
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, size: 20, color: YbColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Keterangan kecil berikon di bawah kontrol.
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(icon, size: 16, color: YbColors.muted),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text, style: YbText.body(size: 13, color: YbColors.muted)),
      ),
    ],
  );
}
