import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/photo.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../gear/data/gear_models.dart';
import '../../gear/state/gear_providers.dart';
import '../../manage/data/manage_models.dart';
import '../../manage/pages/manage_widgets.dart';

/// Kolom-kolom profil toko, dipakai bersama oleh T1 (daftar) dan T2 (profil).
class ShopFields extends ConsumerStatefulWidget {
  const ShopFields({super.key, required this.formKey, this.initial});

  final GlobalKey<FormState> formKey;
  final Shop? initial;

  @override
  ConsumerState<ShopFields> createState() => ShopFieldsState();
}

class ShopFieldsState extends ConsumerState<ShopFields> {
  late String? _logoPath = widget.initial?.logoPath;
  late String? _coverPath = widget.initial?.coverPath;

  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _whatsapp = TextEditingController(
    text: widget.initial == null
        ? ''
        : displayWhatsapp(widget.initial!.whatsapp),
  );
  late final _address = TextEditingController(
    text: widget.initial?.address ?? '',
  );
  late final _district = TextEditingController(
    text: widget.initial?.district ?? '',
  );
  late final _hours = TextEditingController(text: widget.initial?.hours ?? '');
  late final _description = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late final _maps = TextEditingController(text: widget.initial?.mapsUrl ?? '');

  /// Membaca isian sebagai [Shop]. Panggil setelah form lolos validasi.
  Shop read(String id) => Shop(
    id: id,
    name: _name.text.trim(),
    address: _address.text.trim(),
    district: _district.text.trim(),
    whatsapp: normalizeWhatsapp(_whatsapp.text)!,
    hours: _hours.text.trim(),
    description: _description.text.trim(),
    mapsUrl: _maps.text.trim().isEmpty ? null : _maps.text.trim(),
    logoPath: _logoPath,
    coverPath: _coverPath,
  );

  Future<void> _pickLogo() async {
    final change = await changePhoto(
      context,
      ref,
      title: 'Logo toko',
      hasPhoto: _logoPath != null,
    );
    if (change != null) setState(() => _logoPath = change.path);
  }

  Future<void> _pickCover() async {
    final change = await changePhoto(
      context,
      ref,
      title: 'Foto sampul toko',
      hasPhoto: _coverPath != null,
    );
    if (change != null) setState(() => _coverPath = change.path);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _whatsapp,
      _address,
      _district,
      _hours,
      _description,
      _maps,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String message) =>
      (v ?? '').trim().isEmpty ? message : null;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShopCoverHeader(
            coverPath: _coverPath,
            logoPath: _logoPath,
            initials: _name.text.isEmpty ? '?' : initialsOf(_name.text),
            onPickCover: _pickCover,
            onPickLogo: _pickLogo,
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Nama toko',
            child: TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'Toko Gesit Sport'),
              validator: (v) => (v ?? '').trim().length < 3
                  ? 'Isi nama toko, minimal 3 huruf.'
                  : null,
            ),
          ),
          LabeledField(
            label: 'Nomor WhatsApp toko',
            helper: 'Pemain menghubungi nomor ini untuk bertanya stok.',
            child: TextFormField(
              controller: _whatsapp,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ -]')),
              ],
              decoration: const InputDecoration(hintText: '0821 5555 0101'),
              validator: (v) => normalizeWhatsapp(v ?? '') == null
                  ? 'Isi nomor ponsel yang benar, misalnya 0821 5555 0101.'
                  : null,
            ),
          ),
          LabeledField(
            label: 'Alamat lengkap',
            helper: 'Tulis nama jalan, nomor, dan kota supaya pemain mudah menemukan.',
            child: TextFormField(
              controller: _address,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Jl. Raya Nginden No. 12, Surabaya',
                prefixIcon: Icon(Icons.place_outlined, color: YbColors.ink),
              ),
              validator: (v) => (v ?? '').trim().length < 10
                  ? 'Isi alamat lengkap, termasuk nama jalan dan nomor.'
                  : null,
            ),
          ),
          LabeledField(
            label: 'Kecamatan',
            child: TextFormField(
              controller: _district,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Sukolilo'),
              validator: (v) => _required(v, 'Isi kecamatan.'),
            ),
          ),
          LabeledField(
            label: 'Jam buka',
            child: TextFormField(
              controller: _hours,
              decoration: const InputDecoration(
                hintText: 'Senin–Sabtu 09.00–20.00',
              ),
              validator: (v) => _required(v, 'Isi jam buka toko.'),
            ),
          ),
          LabeledField(
            label: 'Deskripsi toko',
            child: TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Jual raket, sepatu, senar, dan grip. Bisa pasang senar di tempat.',
              ),
            ),
          ),
          LabeledField(
            label: 'Link Google Maps (opsional)',
            helper: 'Kalau kosong, peta dicari dari alamat.',
            child: TextFormField(
              controller: _maps,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'maps.app.goo.gl/...',
                prefixIcon: Icon(Icons.map_outlined, color: YbColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// T1 Daftarkan toko.
class RegisterShopPage extends ConsumerStatefulWidget {
  const RegisterShopPage({super.key});

  @override
  ConsumerState<RegisterShopPage> createState() => _RegisterShopPageState();
}

class _RegisterShopPageState extends ConsumerState<RegisterShopPage> {
  final _form = GlobalKey<FormState>();
  final _fields = GlobalKey<ShopFieldsState>();

  void _submit() {
    if (!_form.currentState!.validate()) return;
    ref
        .read(ownShopProvider.notifier)
        .register(_fields.currentState!.read('toko-milikku'));
    context.go('/toko-saya/produk');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  const PageHeader(title: 'Daftarkan toko'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: YbColors.accentSoft,
                      borderRadius: BorderRadius.circular(YbRadius.md),
                    ),
                    child: Text(
                      'Untuk toko perlengkapan badminton. Setelah terdaftar, produkmu muncul di tab Perlengkapan dan bisa disarankan ke pemain.',
                      style: YbText.body(size: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShopFields(key: _fields, formKey: _form),
                ],
              ),
            ),
            BottomActionBar(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Daftarkan toko'),
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

/// Sampul dan logo toko yang bisa diubah (T1, T2). Tanpa foto, sampul
/// memakai warna kuning dan logo memakai inisial toko.
class ShopCoverHeader extends StatelessWidget {
  const ShopCoverHeader({
    super.key,
    required this.coverPath,
    required this.logoPath,
    required this.initials,
    required this.onPickCover,
    required this.onPickLogo,
  });

  final String? coverPath;
  final String? logoPath;
  final String initials;
  final VoidCallback onPickCover;
  final VoidCallback onPickLogo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(YbRadius.md),
              child: YbPhoto(
                path: coverPath,
                fallback: ColoredBox(color: YbColors.accentSoft),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: YbColors.surface,
                foregroundColor: YbColors.ink,
                minimumSize: const Size(0, 36),
              ),
              onPressed: onPickCover,
              icon: const Icon(Icons.photo_camera_outlined, size: 16),
              label: Text(coverPath == null ? 'Tambah sampul' : 'Ubah sampul'),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: YbColors.surface,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: PhotoCircle(
                  path: logoPath,
                  size: 64,
                  tooltip: 'Ubah logo toko',
                  fallback: YbAvatar(initials, size: 64, accent: true),
                  onTap: onPickLogo,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
