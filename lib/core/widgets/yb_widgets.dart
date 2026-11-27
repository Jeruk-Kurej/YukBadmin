import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import 'photo.dart';

final _rupiah = NumberFormat.decimalPattern('id_ID');

/// "Rp150.000"
String formatRupiah(int amount) => 'Rp${_rupiah.format(amount)}';

/// "Rp150rb" untuk ruang sempit.
String formatRupiahShort(int amount) => amount >= 1000 && amount % 1000 == 0
    ? 'Rp${_rupiah.format(amount ~/ 1000)}rb'
    : formatRupiah(amount);

enum YbTagTone {
  primary,
  primarySoft,
  accent,
  success,
  neutral,
  warning,
  error,
  pending,
}

/// Label kecil berbentuk pil, misalnya "Member tetap", "Lunas", "Belum bayar".
class YbTag extends StatelessWidget {
  const YbTag(
    this.text, {
    super.key,
    this.tone = YbTagTone.primarySoft,
    this.icon,
  });

  final String text;
  final YbTagTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      YbTagTone.primary => (YbColors.primary, YbColors.onPrimary),
      YbTagTone.primarySoft => (YbColors.primarySoft, YbColors.primaryDark),
      YbTagTone.accent => (YbColors.accentSoft, YbColors.ink),
      YbTagTone.success => (YbColors.successSoft, YbColors.success),
      YbTagTone.neutral => (YbColors.pendingSoft, YbColors.pending),
      YbTagTone.warning => (YbColors.warningSoft, YbColors.warning),
      YbTagTone.error => (YbColors.errorSoft, YbColors.error),
      YbTagTone.pending => (YbColors.pendingSoft, YbColors.pending),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(YbRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: YbText.body(size: 12, color: fg, weight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip pilihan yang bisa dinyalakan dan dimatikan. Yang dipilih: latar
/// selection, garis primary, dan tanda centang supaya tidak hanya
/// mengandalkan warna.
class YbChoiceChip extends StatelessWidget {
  const YbChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.round = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Kotak persegi untuk label satu huruf seperti tier level F–S.
  final bool round;

  @override
  Widget build(BuildContext context) {
    if (round) return _square();
    final fg = selected ? YbColors.primaryDark : YbColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? YbColors.primarySoft : YbColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? YbColors.primary : YbColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(Icons.check_rounded, size: 18, color: fg),
                    const SizedBox(width: 6),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: YbText.body(
                        size: 14,
                        color: fg,
                        weight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _square() {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? YbColors.primary : YbColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(YbRadius.md),
          side: BorderSide(color: selected ? YbColors.primary : YbColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 44),
            // widthFactor membuat kotak selebar isinya di dalam Wrap; di dalam
            // Expanded lebarnya tetap mengikuti induk.
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  style: YbText.body(
                    size: 17,
                    weight: FontWeight.w600,
                    color: selected ? YbColors.onPrimary : YbColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu putih bersudut besar, wadah dasar hampir semua isi.
class YbCard extends StatelessWidget {
  const YbCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Garis tepi biru untuk kartu yang perlu diperhatikan, misalnya sesi hari ini.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YbColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(YbRadius.lg),
        side: highlight
            ? BorderSide(color: YbColors.primary, width: 1.5)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Kelompok baris seperti daftar pengaturan iOS: satu kartu, baris dipisah
/// garis tipis.
class YbGroup extends StatelessWidget {
  const YbGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YbColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(YbRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: YbColors.line,
              ),
            child,
          ],
        ],
      ),
    );
  }
}

/// Satu baris di [YbGroup]: ikon atau avatar, judul, keterangan, dan ujung
/// kanan (panah, label, atau tombol).
class YbListRow extends StatelessWidget {
  const YbListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.chevron,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Panah ke kanan. Bawaan: tampil kalau baris bisa diketuk dan tidak ada
  /// [trailing].
  final bool? chevron;

  @override
  Widget build(BuildContext context) {
    final showChevron = chevron ?? (onTap != null && trailing == null);
    final lead =
        leading ??
        (icon == null
            ? null
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: YbColors.bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: YbColors.ink),
              ));
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (lead != null) ...[lead, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: YbText.body(size: 16, weight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: YbText.body(size: 13, color: YbColors.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              if (showChevron) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, color: YbColors.muted, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Judul besar di atas layar utama, misalnya "Beranda" atau "Iuran sesi".
class YbPageTitle extends StatelessWidget {
  const YbPageTitle(this.text, {super.key, this.subtitle, this.trailing});

  final String text;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(text, style: YbText.display(size: 32)),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: YbText.body(color: YbColors.muted)),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Judul seksi 20 px, dengan tautan opsional di kanan ("Lihat semua").
class YbSectionTitle extends StatelessWidget {
  const YbSectionTitle(this.text, {super.key, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Garis limau kecil sebagai aksen sporty di tiap judul seksi.
        ExcludeSemantics(
          child: Container(
            width: 4,
            height: 18,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: YbColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(text, style: YbText.display(size: 20)),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: YbColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(44, 44),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(action!),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
      ],
    );
  }
}

/// Kontrol segmen untuk 2–3 pilihan tetap, misalnya "Ikut / Tidak ikut".
class YbSegmented<T> extends StatelessWidget {
  const YbSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String, IconData?)> options;
  final T? selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: YbColors.isDark ? YbColors.bg : YbColors.pendingSoft,
        borderRadius: BorderRadius.circular(YbRadius.pill),
      ),
      child: Row(
        children: [
          for (final (value, label, icon) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                label: label,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    constraints: const BoxConstraints(minHeight: 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: value == selected
                          ? YbColors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(YbRadius.pill),
                      boxShadow: value == selected
                          ? const [
                              BoxShadow(
                                color: Color(0x1A13283F),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: YbColors.ink),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: YbText.body(
                              size: 14,
                              weight: value == selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tab bar mengambang dengan latar buram, dipakai pemain, pengurus, dan toko.
class YbTabBar extends StatelessWidget {
  const YbTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.itemKeys = const {},
  });

  final List<(IconData, IconData, String)> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Kunci per tab (indeks → kunci), misalnya untuk disorot tur.
  final Map<int, Key> itemKeys;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: YbColors.bg,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(YbRadius.pill),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: YbColors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(YbRadius.pill),
                  border: Border.all(color: YbColors.line),
                ),
                child: Row(
                  children: [
                    for (final (i, (icon, activeIcon, label)) in tabs.indexed)
                      Expanded(
                        child: _TabItem(
                          key: itemKeys[i],
                          icon: i == currentIndex ? activeIcon : icon,
                          label: label,
                          selected: i == currentIndex,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            // Tab aktif: kapsul biru malam dengan ikon limau, seperti
            // papan skor; tab lain tetap netral.
            color: selected ? YbColors.night : Colors.transparent,
            borderRadius: BorderRadius.circular(YbRadius.pill),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? YbColors.accent : YbColors.ink,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: YbText.body(
                  size: 11,
                  color: selected ? YbColors.onNight : YbColors.ink,
                  weight: selected ? FontWeight.w600 : FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol bulat untuk kembali di pojok kiri atas.
class YbBackButton extends StatelessWidget {
  const YbBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Kembali',
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      style: IconButton.styleFrom(
        backgroundColor: YbColors.surface,
        fixedSize: const Size(44, 44),
      ),
      icon: Icon(Icons.chevron_left_rounded, size: 26, color: YbColors.ink),
    );
  }
}

/// Avatar inisial berbentuk lingkaran.
class YbAvatar extends StatelessWidget {
  const YbAvatar(
    this.initials, {
    super.key,
    this.size = 44,
    this.accent = false,
    this.photoPath,
  });

  final String initials;
  final double size;
  final bool accent;

  /// Foto di perangkat. Kalau ada, inisial diganti foto.
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final initialsCircle = _initialsCircle();
    if (photoPath == null) return initialsCircle;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: YbPhoto(path: photoPath, fallback: initialsCircle),
      ),
    );
  }

  Widget _initialsCircle() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent ? YbColors.accent : YbColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: YbText.body(
          size: size * 0.32,
          weight: FontWeight.w700,
          color: accent ? YbColors.onAccent : YbColors.primaryDark,
        ),
      ),
    );
  }
}

/// Tampilan kosong atau galat di tengah layar, dengan satu aksi lanjutan.
class YbEmptyState extends StatelessWidget {
  const YbEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return YbCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: YbColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: YbColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: YbText.display(size: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: YbText.body(color: YbColors.muted),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
