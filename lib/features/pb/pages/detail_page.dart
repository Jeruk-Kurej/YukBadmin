import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../data/pb_models.dart';
import '../state/providers.dart';
import 'contact_sheet.dart';
import 'level_guide.dart';
import 'pb_card.dart';
import '../../../core/widgets/covers.dart';
import '../../manage/data/manage_models.dart' show initialsOf;
import '../../../core/widgets/photo.dart';

/// P8 dan P9 Detail PB, digabung jadi satu halaman gulir.
class PbDetailPage extends ConsumerWidget {
  const PbDetailPage({super.key, required this.pbId});

  final String pbId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pb = ref.watch(pbByIdProvider(pbId));
    return pb.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const _NotFound(),
      data: (pb) => pb == null ? const _NotFound() : _Detail(pb: pb),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const YbBackButton(),
              const SizedBox(height: 20),
              YbEmptyState(
                icon: Icons.search_off,
                title: 'PB ini tidak ditemukan',
                message:
                    'Mungkin sudah dihapus pengurusnya. Coba cari PB lain.',
                actionLabel: 'Cari PB',
                onAction: () => context.go('/cari'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatefulWidget {
  const _Detail({required this.pb});

  final Pb pb;

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  static const _heroHeight = 200.0;

  /// True setelah gambar hero tergulir habis, sehingga status bar berada di
  /// atas latar terang dan ikonnya harus gelap.
  var _collapsed = false;

  Pb get pb => widget.pb;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    final threshold =
        _heroHeight - kToolbarHeight - MediaQuery.paddingOf(context).top;
    final collapsed = n.metrics.pixels > threshold;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    return false;
  }

  Future<void> _openMaps(BuildContext context) async {
    final query = Uri.encodeComponent('${pb.venue}, ${pb.district}, Surabaya');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Maps tidak bisa dibuka di perangkat ini.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = pb.firstSession;
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: _heroHeight,
              backgroundColor: YbColors.bg,
              surfaceTintColor: Colors.transparent,
              // Gambar hero gelap, jadi ikon status bar dibuat terang.
              systemOverlayStyle: _collapsed
                  ? SystemUiOverlayStyle.dark
                  : SystemUiOverlayStyle.light,
              automaticallyImplyLeading: false,
              leadingWidth: 68,
              leading: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Center(child: YbBackButton()),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: PbCover(pb: pb, showLamps: false),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      if (pb.logoPath != null) ...[
                        YbAvatar(
                          initialsOf(pb.name),
                          size: 48,
                          photoPath: pb.logoPath,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(pb.name, style: YbText.display(size: 26)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pb.venue}, ${pb.district}, Surabaya',
                    style: YbText.body(color: YbColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Semantics(
                        button: true,
                        label:
                            'Level ${pb.levelRange}. Ketuk untuk penjelasan level.',
                        excludeSemantics: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(YbRadius.pill),
                          onTap: () =>
                              showLevelGuide(context, highlight: pb.minLevel),
                          child: YbTag(
                            'Level ${pb.levelRange}',
                            tone: YbTagTone.primary,
                            icon: Icons.help_outline,
                          ),
                        ),
                      ),
                      for (final type in pb.memberTypes) memberTypeTag(type),
                      pb.openForNewMembers
                          ? const YbTag(
                              'Buka pendaftaran',
                              tone: YbTagTone.success,
                              icon: Icons.check,
                            )
                          : const YbTag('Kuota penuh', tone: YbTagTone.neutral),
                      if (pb.levelTest)
                        const YbTag(
                          'Ada tes level',
                          tone: YbTagTone.accent,
                          icon: Icons.sports_tennis,
                        ),
                      if (pb.foundedYear != null)
                        YbTag(
                          'Sejak ${pb.foundedYear}',
                          tone: YbTagTone.neutral,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          value: '${pb.memberCount}',
                          label: 'dari ${pb.quota} member',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Stat(
                          value: formatRupiahShort(pb.feePerSession),
                          label: 'per sesi',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Stat(
                          value: '${dayShort[s.weekday]} ${s.start}',
                          label: 'jadwal',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FitCard(pb: pb),
                  const _Heading('Tentang'),
                  Text(
                    pb.about,
                    style: YbText.body(color: YbColors.muted, height: 1.5),
                  ),
                  if (pb.photoPaths.isNotEmpty) ...[
                    const _Heading('Galeri'),
                    PhotoGallery(paths: pb.photoPaths),
                  ],
                  const _Heading('Jadwal'),
                  for (final session in pb.sessions) ...[
                    YbCard(
                      child: Row(
                        children: [
                          YbTag(session.dayName, tone: YbTagTone.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${session.timeRange} · ${session.venue}',
                              style: YbText.body(weight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const _Heading('Iuran'),
                  if (pb.monthlyFee != null &&
                      pb.memberTypes.contains(MemberType.tetap)) ...[
                    _FeeCard(
                      type: MemberType.tetap,
                      amount: pb.monthlyFee!,
                      unit: 'per bulan',
                    ),
                    const SizedBox(height: 8),
                  ],
                  _FeeCard(
                    type: pb.memberTypes.contains(MemberType.insidental)
                        ? MemberType.insidental
                        : MemberType.tetap,
                    amount: pb.feePerSession,
                    unit: 'per sesi',
                  ),
                  const _Heading('Lokasi'),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => _openMaps(context),
                    icon: const Icon(Icons.place_outlined, size: 20),
                    label: const Text('Buka di Google Maps'),
                  ),
                  const _Heading('Aturan main'),
                  for (final rule in pb.rules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: YbColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(rule, style: YbText.body())),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  YbCard(
                    child: Row(
                      children: [
                        YbAvatar(pb.manager.initials),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pb.manager.name,
                                style: YbText.body(
                                  size: 15,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text('Pengurus PB', style: YbText.label()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: YbColors.surface,
          border: Border(top: BorderSide(color: YbColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                SaveStar(pb: pb, boxed: true),
                const SizedBox(width: 10),
                Expanded(
                  // Warna gelap, bukan merah: hasil UAT menyebut tombol merah
                  // terlalu mendesak untuk orang yang baru mau bertanya.
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: YbColors.night,
                    ),
                    onPressed: () => showContactSheet(context, pb),
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: const Text('Tanya pengurus'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(text, style: YbText.display(size: 17)),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return YbCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: YbText.display(size: 17)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: YbText.label(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  const _FeeCard({
    required this.type,
    required this.amount,
    required this.unit,
  });

  final MemberType type;
  final int amount;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return YbCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                memberTypeTag(type),
                const SizedBox(height: 8),
                Text('Sewa lapangan dibayar sendiri', style: YbText.label()),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatRupiah(amount), style: YbText.display(size: 19)),
              Text(unit, style: YbText.label()),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ringkasan "cocok untukmu?" dari preferensi pemain, supaya pemain bisa
/// menilai PB sebelum menghubungi pengurus.
class _FitCard extends ConsumerWidget {
  const _FitCard({required this.pb});

  final Pb pb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final level = prefs.level;
    final matchingDays = pb.sessions
        .where((s) => prefs.weekdays.contains(s.weekday))
        .map((s) => s.dayName)
        .toList();

    final checks = <(bool?, String)>[
      if (level == null)
        (null, 'Level kamu belum diisi. Rentang di PB ini ${pb.levelRange}.')
      else if (pb.acceptsLevel(level))
        (true, 'Levelmu (${level.label}) masuk rentang PB ini.')
      else if (level.index < pb.minLevel.index)
        (
          false,
          'PB ini mulai dari level ${pb.minLevel.label}, di atas levelmu (${level.label}).',
        )
      else
        (
          false,
          'PB ini sampai level ${pb.maxLevel.label}, di bawah levelmu (${level.label}).',
        ),
      if (prefs.weekdays.isEmpty)
        (null, 'Hari mainmu belum diisi.')
      else if (matchingDays.isNotEmpty)
        (true, 'Ada sesi di hari yang kamu pilih: ${matchingDays.join(', ')}.')
      else
        (false, 'Belum ada sesi di hari yang kamu pilih.'),
      pb.openForNewMembers
          ? (
              true,
              'Sedang menerima member baru (${pb.memberCount} dari ${pb.quota} terisi).',
            )
          : (
              false,
              'Kuota sedang penuh. Kamu tetap bisa bertanya ke pengurus.',
            ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: YbColors.surface,
        borderRadius: BorderRadius.circular(YbRadius.md),
        border: Border.all(color: YbColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cocok untukmu?', style: YbText.display(size: 17)),
          const SizedBox(height: 10),
          for (final (ok, text) in checks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    ok == null
                        ? Icons.help_outline
                        : ok
                        ? Icons.check_circle
                        : Icons.info_outline,
                    size: 20,
                    color: ok == null
                        ? YbColors.muted
                        : ok
                        ? YbColors.success
                        : YbColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(text, style: YbText.body())),
                ],
              ),
            ),
          if (level == null || prefs.weekdays.isEmpty)
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 44),
              ),
              onPressed: () => context.push('/preferensi/ubah'),
              child: Text(
                'Isi preferensi main',
                style: YbText.body(
                  color: YbColors.primaryDark,
                  weight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
