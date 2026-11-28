import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/widgets/yb_widgets.dart';
import '../pb/data/pb_models.dart';
import '../pb/pages/level_guide.dart';
import '../pb/state/providers.dart';
import 'state/auth_providers.dart';

const areaOptions = [
  'Surabaya Timur',
  'Surabaya Barat',
  'Surabaya Pusat',
  'Surabaya Selatan',
  'Surabaya Utara',
];

/// Pilihan level untuk pemain baru, dipetakan ke tier F–S.
const _levelChoices = <(String, Level?)>[
  ('Baru mulai · F–E', Level.f),
  ('Menengah · D–C', Level.d),
  ('Mahir · B–S', Level.b),
  ('Belum tahu', null),
];

/// P2 Preferensi. Dipakai saat pertama masuk dan saat mengubah dari Akun.
class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key, this.editing = false});

  /// True kalau dibuka dari Akun: tombol kembali, tanpa "Lewati".
  final bool editing;

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  late PlayerPreferences _draft = ref.read(preferencesProvider);
  late int _levelIndex = _draft.level == null
      ? (widget.editing ? 3 : 0)
      : _levelChoices.indexWhere((c) => c.$2 == _closest(_draft.level!));

  static Level _closest(Level level) => level.index <= Level.e.index
      ? Level.f
      : level.index <= Level.c.index
      ? Level.d
      : Level.b;

  void _finish({required bool save}) {
    final prefs = ref.read(preferencesProvider.notifier);
    if (save) {
      final level = _levelChoices[_levelIndex].$2;
      prefs.save(_draft.copyWith(level: level, clearLevel: level == null));
    }
    // Disimpan ke akun (Supabase: tabel profiles) supaya halaman ini hanya
    // muncul sekali, juga di HP lain. Kegagalan jaringan tidak menahan
    // pengguna; preferensi tetap tersimpan di HP.
    ref
        .read(authServiceProvider)
        .completePreferences(ref.read(preferencesProvider))
        .catchError((Object _) {});
    if (widget.editing) {
      context.pop();
    } else {
      context.go('/beranda');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Bar aksi putih di bawah diteruskan sampai tepi layar.
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        if (widget.editing) const YbBackButton(),
                        const Spacer(),
                        if (!widget.editing)
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: YbColors.ink,
                            ),
                            onPressed: () => _finish(save: false),
                            child: const Text('Lewati'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      widget.editing
                          ? 'Ubah preferensi main'
                          : 'Atur preferensi mainmu',
                      style: YbText.display(size: 32),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Untuk mengurutkan PB yang cocok.',
                    style: YbText.body(color: YbColors.muted),
                  ),
                  const SizedBox(height: 24),
                  const _Section('Level mainmu'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (i, choice) in _levelChoices.indexed)
                        YbChoiceChip(
                          label: choice.$1,
                          selected: _levelIndex == i,
                          onTap: () => setState(() => _levelIndex = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: YbColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'F baru mulai, S paling mahir.',
                        style: YbText.body(size: 13, color: YbColors.muted),
                      ),
                      const LevelHelpButton(),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _Section('Area main'),
                  DropdownButtonFormField<String>(
                    initialValue: _draft.area,
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.place_outlined,
                        color: YbColors.ink,
                      ),
                    ),
                    style: YbText.body(size: 16, color: YbColors.ink),
                    items: [
                      for (final area in areaOptions)
                        DropdownMenuItem(value: area, child: Text(area)),
                    ],
                    onChanged: (area) =>
                        setState(() => _draft = _draft.copyWith(area: area)),
                  ),
                  const SizedBox(height: 24),
                  const _Section('Hari kamu bisa main'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final day in dayShort.entries)
                        YbChoiceChip(
                          round: true,
                          label: day.value,
                          selected: _draft.weekdays.contains(day.key),
                          onTap: () => setState(() {
                            final days = {..._draft.weekdays};
                            if (!days.add(day.key)) days.remove(day.key);
                            _draft = _draft.copyWith(weekdays: days);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Boleh lebih dari satu.',
                    style: YbText.body(size: 13, color: YbColors.muted),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                12 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              color: YbColors.bg,
              child: FilledButton(
                onPressed: () => _finish(save: true),
                child: Text(widget.editing ? 'Simpan' : 'Lanjut'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Judul kecil tiap bagian preferensi.
class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      header: true,
      child: Text(text, style: YbText.body(size: 18, weight: FontWeight.w600)),
    ),
  );
}
