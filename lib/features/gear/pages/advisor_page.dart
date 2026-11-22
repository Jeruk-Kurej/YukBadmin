import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../manage/pages/manage_widgets.dart';
import '../../pb/data/pb_models.dart';
import '../../pb/state/providers.dart';
import '../data/advisor.dart';
import '../data/gear_models.dart';
import '../state/gear_providers.dart';
import 'gear_feed_page.dart' show stockTag;
import '../../../core/widgets/covers.dart';

enum _Need { raket, sepatu }

SkillGroup skillFromLevel(Level? level) {
  if (level == null || level.index <= Level.e.index) return SkillGroup.pemula;
  if (level.index <= Level.c.index) return SkillGroup.menengah;
  return SkillGroup.mahir;
}

/// P11 Saran perlengkapan dan P12 Hasil saran.
///
/// Masukan UAT yang diterapkan: cara kerja saran dijelaskan, tiap saran
/// punya alasan per kriteria, sepatu ditanya ukuran (bukan tinggi dan
/// berat), ada pilihan "belum tahu" untuk gaya main, dan raket disertai
/// saran senar dan tarikan.
class AdvisorPage extends ConsumerStatefulWidget {
  const AdvisorPage({super.key});

  @override
  ConsumerState<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends ConsumerState<AdvisorPage> {
  var _need = _Need.raket;
  late var _skill = skillFromLevel(ref.read(preferencesProvider).level);
  var _style = PlayStyle.belumTahu;
  var _position = CourtPosition.belumTahu;
  int? _shoeSize;
  String? _sizeError;
  var _showResult = false;

  void _submit() {
    if (_need == _Need.sepatu && _shoeSize == null) {
      setState(() => _sizeError = 'Pilih ukuran sepatumu dulu.');
      return;
    }
    setState(() => _showResult = true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showResult,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _showResult = false);
      },
      child: Scaffold(
        body: SafeArea(bottom: false, child: _showResult ? _result() : _form()),
      ),
    );
  }

  Widget _form() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              const PageHeader(title: 'Saran perlengkapan'),
              const SizedBox(height: 12),
              Text(
                'Jawab beberapa pertanyaan singkat. Kami carikan yang cocok dari toko partner, lengkap dengan alasannya. Fitur ini opsional, kamu tetap bisa lihat semua produk sendiri.',
                style: YbText.body(color: YbColors.muted),
              ),
              const SizedBox(height: 20),
              _Question(
                title: 'Kamu cari apa?',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    YbChoiceChip(
                      icon: Icons.sports_tennis,
                      label: 'Raket',
                      selected: _need == _Need.raket,
                      onTap: () => setState(() => _need = _Need.raket),
                    ),
                    YbChoiceChip(
                      icon: Icons.directions_run,
                      label: 'Sepatu',
                      selected: _need == _Need.sepatu,
                      onTap: () => setState(() => _need = _Need.sepatu),
                    ),
                  ],
                ),
              ),
              if (_need == _Need.raket) ...[
                _Question(
                  title: 'Levelmu sekarang',
                  child: Column(
                    children: [
                      for (final s in SkillGroup.values)
                        _OptionTile(
                          title: s.label,
                          subtitle: s.tiers,
                          selected: _skill == s,
                          onTap: () => setState(() => _skill = s),
                        ),
                    ],
                  ),
                ),
                _Question(
                  title: 'Gaya mainmu',
                  child: Column(
                    children: [
                      for (final s in PlayStyle.values)
                        _OptionTile(
                          title: s.label,
                          subtitle: s.hint,
                          selected: _style == s,
                          onTap: () => setState(() => _style = s),
                        ),
                    ],
                  ),
                ),
                _Question(
                  title: 'Posisi yang paling sering (opsional)',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in CourtPosition.values)
                        YbChoiceChip(
                          label: p.label,
                          selected: _position == p,
                          onTap: () => setState(() => _position = p),
                        ),
                    ],
                  ),
                ),
              ] else
                _Question(
                  title: 'Ukuran sepatumu (EU)',
                  subtitle:
                      'Lihat label di dalam sepatu yang biasa kamu pakai.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var size = 36; size <= 46; size++)
                            YbChoiceChip(
                              round: true,
                              label: '$size',
                              selected: _shoeSize == size,
                              onTap: () => setState(() {
                                _shoeSize = size;
                                _sizeError = null;
                              }),
                            ),
                        ],
                      ),
                      if (_sizeError != null) FieldError(_sizeError!),
                    ],
                  ),
                ),
              _MethodLink(
                rules: _need == _Need.raket ? racketMethod : shoeMethod,
              ),
            ],
          ),
        ),
        BottomActionBar(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.tips_and_updates_outlined, size: 20),
                label: const Text('Lihat saran'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _result() {
    final products = ref.watch(productsProvider).value ?? const <Product>[];
    final shops = ref.watch(shopsProvider).value ?? const <Shop>[];
    final shopNames = {for (final s in shops) s.id: s.name};
    const advisor = GearAdvisor();
    final suggestions = _need == _Need.raket
        ? advisor.rackets(
            products,
            skill: _skill,
            style: _style,
            position: _position,
          )
        : advisor.shoes(products, size: _shoeSize!);
    final tip = suggestions.firstOrNull?.stringTip;

    final summary = _need == _Need.raket
        ? [
            'Raket',
            _skill.label,
            _style.label,
            if (_position != CourtPosition.belumTahu) _position.label,
          ]
        : ['Sepatu', 'Ukuran $_shoeSize'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        PageHeader(
          title: 'Hasil saran',
          trailing: OutlinedButton.icon(
            onPressed: () => setState(() => _showResult = false),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Ubah'),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Berdasarkan', style: YbText.label()),
            for (final item in summary) YbTag(item, tone: YbTagTone.accent),
          ],
        ),
        const SizedBox(height: 10),
        _MethodLink(rules: _need == _Need.raket ? racketMethod : shoeMethod),
        const SizedBox(height: 14),
        if (suggestions.isEmpty)
          YbEmptyState(
            icon: Icons.search_off,
            title: _need == _Need.sepatu
                ? 'Belum ada sepatu ukuran $_shoeSize'
                : 'Belum ada raket di toko partner',
            message: _need == _Need.sepatu
                ? 'Coba ukuran yang berdekatan, atau tanya toko partner apakah bisa pesan.'
                : 'Coba lagi nanti setelah toko menambahkan produk.',
            actionLabel: 'Lihat semua perlengkapan',
            onAction: () => context.go('/perlengkapan'),
          ),
        for (final (i, s) in suggestions.indexed) ...[
          _SuggestionCard(
            suggestion: s,
            best: i == 0 && s.matched == s.total,
            shopName: shopNames[s.product.shopId],
          ),
          const SizedBox(height: 10),
        ],
        if (tip != null) ...[
          const SizedBox(height: 4),
          _StringTipCard(tip: tip, shopName: shopNames[tip.product?.shopId]),
        ],
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: YbText.display(size: 17)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: YbText.label()),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: '$title, $subtitle',
        excludeSemantics: true,
        child: Material(
          color: selected ? YbColors.primarySoft : YbColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(YbRadius.md),
            side: BorderSide(
              color: selected ? YbColors.primary : YbColors.line,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? YbColors.primary : YbColors.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: YbText.body(weight: FontWeight.w700),
                        ),
                        Text(subtitle, style: YbText.label()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Penjelasan cara saran dibuat, diringkas jadi satu baris. Isinya dibuka
/// di sheet supaya halaman hasil tidak penuh teks. Sengaja tidak menyebut
/// AI: saran dihitung dari aturan yang bisa dibaca pemain.
class _MethodLink extends StatelessWidget {
  const _MethodLink({required this.rules});

  final List<({String title, String body})> rules;

  @override
  Widget build(BuildContext context) {
    return YbCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _MethodSheet(rules: rules),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: YbColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kenapa saran ini?',
              style: YbText.body(weight: FontWeight.w700),
            ),
          ),
          Icon(Icons.chevron_right, color: YbColors.muted),
        ],
      ),
    );
  }
}

class _MethodSheet extends StatelessWidget {
  const _MethodSheet({required this.rules});

  final List<({String title, String body})> rules;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cara saran ini dibuat', style: YbText.display(size: 20)),
            const SizedBox(height: 12),
            for (final (i, rule) in rules.indexed) ...[
              if (i > 0) Divider(height: 24, color: YbColors.line),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: YbColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: YbText.body(
                        size: 13,
                        color: YbColors.primaryDark,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.title,
                          style: YbText.body(size: 15, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rule.body,
                          style: YbText.body(color: YbColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: YbColors.accentSoft,
                borderRadius: BorderRadius.circular(YbRadius.md),
              ),
              child: Text(
                'Saran ini panduan awal. Coba pegang langsung di toko sebelum membeli.',
                style: YbText.label(color: YbColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.best,
    this.shopName,
  });

  final Suggestion suggestion;
  final bool best;
  final String? shopName;

  @override
  Widget build(BuildContext context) {
    final p = suggestion.product;
    return YbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(YbRadius.sm),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: ProductImage(product: p),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        YbTag(
                          'Cocok ${suggestion.matched} dari ${suggestion.total}',
                          tone: suggestion.matched == suggestion.total
                              ? YbTagTone.success
                              : YbTagTone.neutral,
                        ),
                        if (best)
                          const YbTag('Paling cocok', tone: YbTagTone.primary),
                        stockTag(p.inStock),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(p.name, style: YbText.display(size: 16)),
                    Text(
                      [formatRupiah(p.price), ?shopName].join(' · '),
                      style: YbText.label(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Alasannya',
            style: YbText.body(size: 13, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          for (final r in suggestion.reasons)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    r.matched
                        ? Icons.check_circle
                        : Icons.remove_circle_outline,
                    size: 18,
                    color: r.matched ? YbColors.success : YbColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.text, style: YbText.body(size: 13))),
                ],
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push('/produk/${p.id}'),
            child: const Text('Lihat produk dan toko'),
          ),
        ],
      ),
    );
  }
}

class _StringTipCard extends StatelessWidget {
  const _StringTipCard({required this.tip, this.shopName});

  final StringTip tip;
  final String? shopName;

  @override
  Widget build(BuildContext context) {
    final product = tip.product;
    return YbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Senar dan tarikan untuk raketmu',
            style: YbText.display(size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Senar ${tip.type.label.toLowerCase()}, tarikan ${tip.tension}.',
            style: YbText.body(weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(tip.why, style: YbText.body(size: 13, color: YbColors.muted)),
          if (product != null) ...[
            const SizedBox(height: 10),
            YbCard(
              padding: const EdgeInsets.all(10),
              onTap: () => context.push('/produk/${product.id}'),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(YbRadius.sm),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: ProductImage(product: product),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: YbText.body(weight: FontWeight.w700),
                        ),
                        Text(
                          [formatRupiah(product.price), ?shopName].join(' · '),
                          style: YbText.label(),
                        ),
                      ],
                    ),
                  ),
                  stockTag(product.inStock),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
