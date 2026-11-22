import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/widgets/yb_widgets.dart';
import '../pb/data/pb_models.dart';
import '../pb/pages/level_guide.dart';
import '../pb/state/providers.dart';

const areaOptions = [
  'Surabaya Timur',
  'Surabaya Barat',
  'Surabaya Pusat',
  'Surabaya Selatan',
  'Surabaya Utara',
];

/// Pilihan level untuk pemain baru, dipetakan ke tier F–S.
const _levelChoices = <(String, Level?)>[
  ('Baru mulai', Level.f),
  ('Menengah', Level.d),
  ('Mahir', Level.b),
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
    if (save) {
      final level = _levelChoices[_levelIndex].$2;
      ref
          .read(preferencesProvider.notifier)
          .save(_draft.copyWith(level: level, clearLevel: level == null));
    }
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  Row(
                    children: [
                      if (widget.editing)
                        const YbBackButton()
                      else ...[
                        Container(
                          width: 32,
                          height: 5,
                          decoration: BoxDecoration(
                            color: YbColors.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 14,
                          height: 5,
                          decoration: BoxDecoration(
                            color: YbColors.line,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (!widget.editing)
                        OutlinedButton(
                          onPressed: () => _finish(save: false),
                          child: const Text('Lewati'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Atur preferensi mainmu',
                    style: YbText.display(size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Kami urutkan PB yang cocok dengan levelmu, areamu, dan hari kamu bisa main.',
                    style: YbText.body(color: YbColors.muted),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Level mainmu', style: YbText.label()),
                      const LevelHelpButton(),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 22),
                  Text('Area main', style: YbText.label()),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _draft.area,
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.place_outlined,
                        color: YbColors.ink,
                      ),
                    ),
                    style: YbText.body(size: 15),
                    items: [
                      for (final area in areaOptions)
                        DropdownMenuItem(value: area, child: Text(area)),
                    ],
                    onChanged: (area) =>
                        setState(() => _draft = _draft.copyWith(area: area)),
                  ),
                  const SizedBox(height: 22),
                  Text('Hari kamu bisa main', style: YbText.label()),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final day in dayShort.entries)
                        YbChoiceChip(
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
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: YbColors.surface,
                border: Border(top: BorderSide(color: YbColors.line)),
              ),
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
