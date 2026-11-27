import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/tours.dart';
import '../../pb/data/pb_models.dart';
import '../data/manage_models.dart';
import '../state/manage_providers.dart';
import 'manage_widgets.dart';
import '../../../core/widgets/covers.dart';
import '../../../core/widgets/photo.dart';
import '../../../core/widgets/yb_widgets.dart';

/// K14 Edit profil PB.
class PbProfilePage extends ConsumerStatefulWidget {
  const PbProfilePage({super.key});

  @override
  ConsumerState<PbProfilePage> createState() => _PbProfilePageState();
}

class _PbProfilePageState extends ConsumerState<PbProfilePage> {
  final _form = GlobalKey<FormState>();
  late final Pb _pb = ref.read(manageProvider).pb!;
  late final _name = TextEditingController(text: _pb.name);
  late final _venue = TextEditingController(text: _pb.venue);
  late final _district = TextEditingController(text: _pb.district);
  late final _about = TextEditingController(text: _pb.about);
  late final _rules = TextEditingController(text: _pb.rules.join('\n'));
  late final _fee = TextEditingController(text: '${_pb.feePerSession}');
  late final _whatsapp = TextEditingController(
    text: displayWhatsapp(_pb.manager.whatsapp),
  );
  late bool _open = _pb.openForNewMembers;
  late bool _levelTest = _pb.levelTest;
  late String? _logoPath = _pb.logoPath;
  late List<String> _photos = _pb.photoPaths;
  late final _foundedYear = TextEditingController(
    text: _pb.foundedYear?.toString() ?? '',
  );
  late final _paymentInfo = TextEditingController(text: _pb.paymentInfo ?? '');

  @override
  void dispose() {
    for (final c in [
      _name,
      _venue,
      _district,
      _about,
      _rules,
      _fee,
      _whatsapp,
      _foundedYear,
      _paymentInfo,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final current = ref.read(manageProvider).pb!;
    final venue = _venue.text.trim();
    ref
        .read(manageProvider.notifier)
        .updatePb(
          copyPb(
            current,
            name: _name.text.trim(),
            venue: venue,
            district: _district.text.trim(),
            about: _about.text.trim(),
            rules: _rules.text
                .split('\n')
                .map((r) => r.trim())
                .where((r) => r.isNotEmpty)
                .toList(),
            feePerSession: parseRupiah(_fee.text) ?? current.feePerSession,
            manager: PbManager(
              name: current.manager.name,
              whatsapp: normalizeWhatsapp(_whatsapp.text)!,
            ),
            openForNewMembers: _open,
            levelTest: _levelTest,
            logoPath: _logoPath,
            clearLogo: _logoPath == null,
            photoPaths: _photos,
            foundedYear: int.tryParse(_foundedYear.text.trim()),
            clearFoundedYear: _foundedYear.text.trim().isEmpty,
            paymentInfo: _paymentInfo.text.trim(),
            clearPaymentInfo: _paymentInfo.text.trim().isEmpty,
            sessions: [
              for (final s in current.sessions)
                PbSession(
                  weekday: s.weekday,
                  startHour: s.startHour,
                  startMinute: s.startMinute,
                  endHour: s.endHour,
                  endMinute: s.endMinute,
                  venue: venue,
                ),
            ],
          ),
        );
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil PB disimpan'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pb = ref.watch(manageProvider.select((s) => s.pb));
    if (pb == null) return const SizedBox.shrink();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _form,
          // Bukan ListView, supaya bagian bawah sudah dibangun dan bisa
          // disorot tur pengurus.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Profil PB',
                  trailing: TextButton(
                    key: TourKeys.profilePreview,
                    onPressed: () => context.push('/pb/${pb.id}'),
                    child: const Text('Lihat'),
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(YbRadius.md),
                  child: SizedBox(
                    height: 110,
                    child: PbCover(pb: copyPb(pb, photoPaths: _photos)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    PhotoCircle(
                      path: _logoPath,
                      size: 64,
                      fallback: const PhotoPlaceholder(),
                      tooltip: 'Ubah logo PB',
                      onTap: () async {
                        final change = await changePhoto(
                          context,
                          ref,
                          title: 'Logo PB',
                          hasPhoto: _logoPath != null,
                        );
                        if (change != null) {
                          setState(() => _logoPath = change.path);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Logo PB tampil di halaman PB.',
                        style: YbText.label(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Foto PB',
                  helper:
                      'Foto pertama dipakai sebagai sampul. Maksimal 6 foto.',
                  child: PhotoStrip(
                    paths: _photos,
                    onChanged: (paths) => setState(() => _photos = paths),
                  ),
                ),
                LabeledField(
                  label: 'Nama PB',
                  child: TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
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
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.place_outlined,
                        color: YbColors.ink,
                      ),
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
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Isi kecamatan.' : null,
                  ),
                ),
                LabeledField(
                  label: 'Deskripsi',
                  helper: 'Ceritakan suasana dan cara mainnya. Ini dibaca calon member.',
                  child: TextFormField(
                    controller: _about,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                LabeledField(
                  label: 'Aturan main',
                  helper: 'Satu aturan per baris.',
                  child: TextFormField(
                    controller: _rules,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText:
                          'Bawa raket sendiri\nDatang 10 menit sebelum sesi',
                    ),
                  ),
                ),
                LabeledField(
                  label: 'Iuran per sesi',
                  child: TextFormField(
                    controller: _fee,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(prefixText: 'Rp '),
                    validator: (v) {
                      final amount = parseRupiah(v ?? '');
                      if (amount == null) return 'Isi iuran per sesi.';
                      if (amount > 5000000) {
                        return 'Nominal terlalu besar, cek lagi.';
                      }
                      return null;
                    },
                  ),
                ),
                LabeledField(
                  label: 'Cara bayar iuran (opsional)',
                  helper: 'Hanya tampil untuk member, di halaman iuran mereka. Pembayaran tetap di luar app.',
                  child: TextFormField(
                    controller: _paymentInfo,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Transfer BCA 1234567890 a.n. Bryan, atau tunai saat sesi',
                    ),
                  ),
                ),
                LabeledField(
                  label: 'Nomor WhatsApp pengurus',
                  child: TextFormField(
                    controller: _whatsapp,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ -]')),
                    ],
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: YbColors.primary,
                  title: Text(
                    'Terima member baru',
                    style: YbText.body(size: 15, weight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Kalau dimatikan, halaman PB menampilkan "Kuota penuh".',
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
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final count = ref.watch(
                      manageProvider.select((s) => s.coManagers.length),
                    );
                    return YbCard(
                      key: TourKeys.profileManagers,
                      onTap: () => context.push('/kelola/pengurus'),
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            color: YbColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pengurus PB',
                                  style: YbText.body(
                                    size: 15,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  count == 0
                                      ? 'Hanya kamu. Undang pengurus lain.'
                                      : 'Kamu dan $count pengurus lain',
                                  style: YbText.label(),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: YbColors.muted),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Simpan perubahan'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => context.go('/beranda'),
                  icon: const Icon(Icons.swap_horiz, size: 20),
                  label: const Text('Kembali ke mode pemain'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
