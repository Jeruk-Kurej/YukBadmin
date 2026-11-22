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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filter PB',
                          style: YbText.display(size: 22),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => setState(
                          () => _draft = PbFilter(query: _draft.query),
                        ),
                        child: const Text('Reset'),
                      ),
                      IconButton(
                        tooltip: 'Tutup filter',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Level', style: YbText.label()),
                      const LevelHelpButton(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final level in Level.values)
                        YbChoiceChip(
                          round: true,
                          label: level.label,
                          selected: _draft.levels.contains(level),
                          onTap: () => setState(
                            () => _draft = _draft.copyWith(
                              levels: _toggled(_draft.levels, level),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Jenis member', style: YbText.label()),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      YbChoiceChip(
                        label: 'Semua',
                        selected: _draft.memberType == null,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(clearMemberType: true),
                        ),
                      ),
                      for (final type in MemberType.values)
                        YbChoiceChip(
                          label: type == MemberType.tetap
                              ? 'Tetap'
                              : 'Insidental',
                          selected: _draft.memberType == type,
                          onTap: () => setState(
                            () => _draft = _draft.copyWith(memberType: type),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Biaya per sesi', style: YbText.label()),
                      ),
                      Text(
                        '${formatRupiahShort(_draft.minFee)} – ${formatRupiahShort(_draft.maxFee)}',
                        style: YbText.body(
                          size: 13,
                          color: YbColors.primary,
                          weight: FontWeight.w700,
                        ),
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
                  Text('Waktu', style: YbText.label()),
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
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Hari', style: YbText.label()),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
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
