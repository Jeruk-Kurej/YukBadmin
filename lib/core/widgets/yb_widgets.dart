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

enum YbTagTone { primary, primarySoft, accent, success, neutral }

/// Label kecil berbentuk pil, misalnya "Member tetap" atau "Level D–B".
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
      YbTagTone.primary => (YbColors.primary, Colors.white),
      YbTagTone.primarySoft => (YbColors.primarySoft, YbColors.primaryDark),
      YbTagTone.accent => (YbColors.accentSoft, YbColors.ink),
      YbTagTone.success => (YbColors.successSoft, YbColors.success),
      YbTagTone.neutral => (YbColors.bg, YbColors.muted),
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
            Icon(icon, size: 13, color: fg),
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

/// Chip pilihan yang bisa dinyalakan dan dimatikan.
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

  /// Bentuk lingkaran untuk label satu huruf seperti tier level.
  final bool round;

  @override
  Widget build(BuildContext context) {
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
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 44,
              minWidth: round ? 44 : 0,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: round ? 0 : 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: YbText.body(color: fg, weight: FontWeight.w600),
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
}

/// Kartu putih bergaris tipis, wadah dasar hampir semua isi.
class YbCard extends StatelessWidget {
  const YbCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Garis tepi merah untuk kartu yang perlu diperhatikan, misalnya sesi hari ini.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YbColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(YbRadius.md),
        side: highlight
            ? BorderSide(color: YbColors.primary, width: 1.5)
            : BorderSide(color: YbColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
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
        side: BorderSide(color: YbColors.line),
        fixedSize: const Size(44, 44),
      ),
      icon: Icon(Icons.arrow_back, size: 20, color: YbColors.ink),
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
          size: size * 0.34,
          weight: FontWeight.w800,
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: YbColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: YbColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: YbText.display(size: 17),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: YbText.body(color: YbColors.muted),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
