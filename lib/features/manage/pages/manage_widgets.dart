import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';

/// Membaca isian nominal. Null kalau kosong atau bukan angka.
int? parseRupiah(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? null : int.tryParse(digits);
}

/// "19.00"
String formatTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

/// Membuka WhatsApp ke [number] (format 62...) dengan pesan terisi.
/// Mengembalikan false kalau WhatsApp tidak bisa dibuka.
Future<bool> openWhatsApp(String number, String message) async {
  try {
    return await launchUrl(
      Uri.https('wa.me', '/$number', {'text': message}),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    // Sebagian perangkat melempar galat kalau tidak ada app yang bisa
    // membuka tautan; perlakukan sama seperti gagal dibuka.
    return false;
  }
}

/// Bar tombol di bawah layar, putih sampai tepi bawah.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(children: children),
    );
  }
}

/// Label di atas kolom isian, dengan keterangan opsional di bawahnya.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.helper,
  });

  final String label;
  final Widget child;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: YbText.label()),
          const SizedBox(height: 6),
          child,
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(helper!, style: YbText.label()),
          ],
        ],
      ),
    );
  }
}

/// Pesan galat untuk pilihan yang bukan kolom teks (chip, jadwal).
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: YbColors.primaryDark),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: YbText.body(size: 12, color: YbColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// Judul halaman dengan tombol kembali dan aksi opsional di kanan.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.trailing,
    this.back = true,
  });

  final String title;
  final Widget? trailing;
  final bool back;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (back) ...[const YbBackButton(), const SizedBox(width: 12)],
        Expanded(
          child: Text(
            title,
            style: YbText.display(size: back ? 22 : 30),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Di layar sempit atau teks besar, tombol kanan ikut menyempit
        // (teksnya turun baris) supaya tidak meluber.
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Flexible(child: trailing!),
        ],
      ],
    );
  }
}

/// Kotak angka ringkasan, misalnya "24 Member".
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return YbCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: YbText.display(size: 22)),
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

/// Kotak ringkasan berwarna untuk nominal iuran.
class AmountTile extends StatelessWidget {
  const AmountTile({
    super.key,
    required this.amount,
    required this.label,
    required this.positive,
  });

  final int amount;
  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final fg = positive ? YbColors.success : YbColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: positive ? YbColors.successSoft : YbColors.warningSoft,
        borderRadius: BorderRadius.circular(YbRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRupiah(amount),
              style: YbText.display(size: 20, color: fg),
            ),
          ),
          Text(label, style: YbText.label(color: fg)),
        ],
      ),
    );
  }
}

/// Tanya ulang sebelum tindakan yang tidak bisa dibatalkan.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: YbColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(title, style: YbText.display(size: 19)),
      content: Text(message, style: YbText.body(color: YbColors.muted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Batal', style: YbText.body(weight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: YbText.body(
              color: YbColors.primary,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Tombol beralih antara mode pemain dan mode pengurus. Satu akun bisa
/// keduanya, jadi tombol ini muncul di beranda masing-masing mode.
class RoleSwitchButton extends StatelessWidget {
  const RoleSwitchButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.onDark = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : YbColors.ink;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        backgroundColor: onDark
            ? Colors.white.withValues(alpha: 0.08)
            : YbColors.surface,
        side: BorderSide(
          color: onDark ? Colors.white.withValues(alpha: 0.5) : YbColors.line,
          width: 1.5,
        ),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 44),
      ),
      onPressed: onPressed,
      icon: Icon(Icons.swap_horiz, size: 18, color: fg),
      label: Text(
        label,
        style: YbText.body(color: fg, weight: FontWeight.w700),
      ),
    );
  }
}

/// Memeriksa isian tahun berdiri. Kosong boleh; kalau diisi harus tahun
/// yang masuk akal dan tidak melewati [thisYear].
String? foundedYearError(String input, int thisYear) {
  final text = input.trim();
  if (text.isEmpty) return null;
  final year = int.tryParse(text);
  if (year == null || year < 1950 || year > thisYear) {
    return 'Isi tahun antara 1950 dan $thisYear, atau kosongkan.';
  }
  return null;
}
