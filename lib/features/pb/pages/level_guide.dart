import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../data/pb_models.dart';

/// Penjelasan singkat tiap tier level. Dipakai di mana pun level muncul,
/// karena pengguna baru belum tentu paham arti "D–B".
const levelDescriptions = {
  Level.f: 'Baru mulai. Masih belajar pegang raket dan servis.',
  Level.e: 'Sudah bisa rally pendek, pukulan belum konsisten.',
  Level.d: 'Rally lancar, mulai paham posisi main ganda.',
  Level.c: 'Main rutin, bisa smash dan drop dengan cukup terarah.',
  Level.b: 'Kuat dan konsisten, sering menang di main bareng.',
  Level.a: 'Pernah ikut turnamen antar-PB atau antar-kampus.',
  Level.s: 'Setara atlet klub atau pernah juara turnamen.',
};

/// Tombol kecil "Apa arti level?" yang membuka penjelasan.
class LevelHelpButton extends StatelessWidget {
  const LevelHelpButton({super.key, this.label = 'Apa arti level?'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 44),
        foregroundColor: YbColors.primaryDark,
      ),
      onPressed: () => showLevelGuide(context),
      icon: const Icon(Icons.help_outline, size: 18),
      label: Text(
        label,
        style: YbText.body(
          size: 13,
          color: YbColors.primaryDark,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

Future<void> showLevelGuide(
  BuildContext context, {
  Level? highlight,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Arti level F sampai S',
                  style: YbText.display(size: 21),
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'PB menulis rentang level yang biasa main di sana. "D–B" berarti '
            'pemainnya kebanyakan level D sampai B. Kalau ragu, pilih PB '
            'yang rentangnya dimulai dari F atau E.',
            style: YbText.body(color: YbColors.muted),
          ),
          const SizedBox(height: 14),
          for (final level in Level.values) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: level == highlight
                    ? YbColors.primarySoft
                    : YbColors.surface,
                borderRadius: BorderRadius.circular(YbRadius.md),
                border: Border.all(
                  color: level == highlight ? YbColors.primary : YbColors.line,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: YbColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      level.label,
                      style: YbText.display(size: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      levelDescriptions[level]!,
                      style: YbText.body(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          const YbTag(
            'Level diisi sendiri oleh pengurus PB',
            tone: YbTagTone.neutral,
            icon: Icons.info_outline,
          ),
        ],
      ),
    ),
  ),
);
