import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../data/pb_models.dart';
import '../state/providers.dart';
import 'level_guide.dart';

/// P6 Filter (sheet).
Future<void> showFilterSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Sheet menutupi tab bar, bukan muncul di atasnya.
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => const _FilterSheet(),
    );

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late PbFilter _draft = ref.read(filterProvider);

  Set<T> _toggled<T>(Set<T> set, T value) {
    final next = {...set};
    if (!next.add(value)) next.remove(value);
    return next;
  }

  Widget _label(String text) =>
      Text(text, style: YbText.body(size: 14, color: YbColors.muted));

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(pbListProvider).value ?? const <Pb>[];
    final matchCount = all.where(_draft.matches).length;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            'Filter PB',
                            style: YbText.display(size: 22),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(
                          () => _draft = PbFilter(query: _draft.query),
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [_label('Level'), const LevelHelpButton()],
                  ),
                  const SizedBox(height: 6),
                  // Tujuh kotak level sama lebar dalam satu baris.
                  Row(
                    children: [
                      for (final (i, level) in Level.values.indexed) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: YbChoiceChip(
                            round: true,
                            label: level.label,
                            selected: _draft.levels.contains(level),
                            onTap: () => setState(
                              () => _draft = _draft.copyWith(
                                levels: _toggled(_draft.levels, level),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label('Jenis member'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final (i, type) in <MemberType?>[
                        null,
                        ...MemberType.values,
                      ].indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: YbChoiceChip(
                            label: switch (type) {
                              null => 'Semua',
                              MemberType.tetap => 'Tetap',
                              MemberType.insidental => 'Insidental',
                            },
                            selected: _draft.memberType == type,
                            onTap: () => setState(
                              () => _draft = type == null
                                  ? _draft.copyWith(clearMemberType: true)
                                  : _draft.copyWith(memberType: type),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _label('Biaya per sesi')),
                      Text(
                        '${formatRupiahShort(_draft.minFee)} – ${formatRupiahShort(_draft.maxFee)}',
                        style: YbText.body(size: 14, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                  RangeSlider(
                    min: PbFilter.feeFloor.toDouble(),
                    max: PbFilter.feeCeiling.toDouble(),
                    divisions: PbFilter.feeCeiling ~/ 25000,
                    activeColor: YbColors.primary,
                    inactiveColor: YbColors.line,
                    labels: RangeLabels(
                      formatRupiahShort(_draft.minFee),
                      formatRupiahShort(_draft.maxFee),
                    ),
                    values: RangeValues(
                      _draft.minFee.toDouble(),
                      _draft.maxFee.toDouble(),
                    ),
                    onChanged: (v) => setState(
                      () => _draft = _draft.copyWith(
                        minFee: v.start.round(),
                        maxFee: v.end.round(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _label('Waktu dan hari'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final part in DayPart.values)
                        YbChoiceChip(
                          label: part.label,
                          selected: _draft.dayParts.contains(part),
                          onTap: () => setState(
                            () => _draft = _draft.copyWith(
                              dayParts: _toggled(_draft.dayParts, part),
                            ),
                          ),
                        ),
                      YbChoiceChip(
                        label: 'Hari kerja',
                        selected: _draft.weekdaysOnly,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(
                            weekdaysOnly: !_draft.weekdaysOnly,
                          ),
                        ),
                      ),
                      YbChoiceChip(
                        label: 'Akhir pekan',
                        selected: _draft.weekendOnly,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(
                            weekendOnly: !_draft.weekendOnly,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: FilledButton(
                onPressed: () {
                  ref.read(filterProvider.notifier).set(_draft);
                  Navigator.of(context).pop();
                },
                child: Text(
                  matchCount == 0
                      ? 'Tidak ada PB yang cocok'
                      : 'Tampilkan $matchCount PB',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
