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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: YbBackButton(),
              ),
              const SizedBox(height: 16),
              const YbPageTitle(
                'Saran perlengkapan',
                subtitle: 'Jawab beberapa pertanyaan, kami carikan dari toko partner.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: YbColors.primarySoft,
                  borderRadius: BorderRadius.circular(YbRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: YbColors.primaryDark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Dicocokkan dari level dan gaya main, lengkap dengan alasannya. Kamu tetap bisa lihat semua produk sendiri.',
                        style: YbText.body(
                          size: 14,
                          color: YbColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Question(
                number: 1,
                title: 'Kamu cari apa?',
                child: Row(
                  children: [
                    Expanded(
                      child: YbChoiceChip(
                        icon: Icons.sports_tennis,
                        label: 'Raket',
                        selected: _need == _Need.raket,
                        onTap: () => setState(() => _need = _Need.raket),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: YbChoiceChip(
                        icon: Icons.directions_run,
                        label: 'Sepatu',
                        selected: _need == _Need.sepatu,
                        onTap: () => setState(() => _need = _Need.sepatu),
                      ),
                    ),
                  ],
                ),
              ),
              if (_need == _Need.raket) ...[
                _Question(
                  number: 2,
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
                  number: 3,
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
                  number: 4,
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
                  number: 2,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            YbBackButton(onPressed: () => setState(() => _showResult = false)),
            const Spacer(),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: YbColors.surface,
                foregroundColor: YbColors.ink,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () => setState(() => _showResult = false),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Ubah'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const YbPageTitle('Hasil saran'),
        const SizedBox(height: 16),
        YbSectionTitle('Berdasarkan'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final item in summary) YbTag(item)],
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
          if (i == 1) ...[
            const SizedBox(height: 14),
            YbSectionTitle('Pilihan lain'),
            const SizedBox(height: 10),
          ],
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
  const _Question({
    required this.number,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final int number;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: YbColors.night,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: YbText.body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: YbColors.onNight,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: YbText.body(size: 17, weight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: YbText.body(size: 13, color: YbColors.muted),
            ),
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
    final score = Semantics(
      label: 'Cocok ${suggestion.matched} dari ${suggestion.total}',
      excludeSemantics: true,
      child: Text(
        '${suggestion.matched}/${suggestion.total}',
        style: YbText.score(size: best ? 30 : 22),
      ),
    );
    final reasons = [
      Text('Alasannya', style: YbText.body(size: 13, color: YbColors.muted)),
      for (final r in suggestion.reasons)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                r.matched ? Icons.check_rounded : Icons.info_outline_rounded,
                size: 18,
                color: r.matched ? YbColors.success : YbColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(r.text, style: YbText.body(size: 14))),
            ],
          ),
        ),
    ];
    final title = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                style: YbText.body(size: 16, weight: FontWeight.w600),
              ),
              Text(
                [?shopName, if (!p.inStock) 'stok habis'].join(' · '),
                style: YbText.body(size: 13, color: YbColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(formatRupiahShort(p.price), style: YbText.display(size: 17)),
      ],
    );

    return YbCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (best)
            Container(
              height: 150,
              color: YbColors.accentSoft,
              child: Stack(
                children: [
                  Positioned.fill(child: ProductImage(product: p)),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: YbColors.accent,
                        borderRadius: BorderRadius.circular(YbRadius.sm),
                      ),
                      child: Text(
                        'Paling cocok',
                        style: YbText.body(
                          size: 13,
                          weight: FontWeight.w600,
                          color: YbColors.onAccent,
                        ),
                      ),
                    ),
                  ),
                  Positioned(right: 14, top: 8, child: score),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (best)
                  title
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(YbRadius.md),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: ProductImage(product: p),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: title),
                      const SizedBox(width: 8),
                      score,
                    ],
                  ),
                const SizedBox(height: 12),
                ...reasons,
                const SizedBox(height: 14),
                if (best)
                  FilledButton(
                    onPressed: () => context.push('/produk/${p.id}'),
                    child: const Text('Lihat produk dan toko'),
                  )
                else
                  OutlinedButton(
                    onPressed: () => context.push('/produk/${p.id}'),
                    child: const Text('Lihat produk dan toko'),
                  ),
              ],
            ),
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
