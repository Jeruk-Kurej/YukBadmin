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

/// Membuka tautan di app lain. False kalau tautan tidak sah atau tidak ada app
/// yang bisa membukanya.
Future<bool> openExternal(Uri? uri) async {
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Alamat web dari isian pengguna. Null kalau bukan alamat http atau https.
Uri? webUri(String input) {
  final text = input.trim();
  final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
  if (uri == null ||
      !(uri.scheme == 'https' || uri.scheme == 'http') ||
      !uri.host.contains('.') ||
      text.contains(' ')) {
    return null;
  }
  return uri;
}

/// Membuka WhatsApp ke [number] (format 62...) dengan pesan terisi.
/// Mengembalikan false kalau WhatsApp tidak bisa dibuka.
Future<bool> openWhatsApp(String number, String message) =>
    openExternal(Uri.https('wa.me', '/$number', {'text': message}));

/// Bar tombol di bawah layar, putih sampai tepi bawah.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      color: YbColors.bg,
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
          Text(label, style: YbText.body(size: 14, weight: FontWeight.w600)),
          const SizedBox(height: 8),
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
          Icon(Icons.error_outline, size: 16, color: YbColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: YbText.body(size: 13, color: YbColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bar atas halaman (Final Design v4): tombol kembali bulat di kiri, judul
/// kecil di tengah, aksi opsional di kanan. Tanpa tombol kembali, judul
/// tampil besar di kiri.
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
    if (!back) return YbPageTitle(title, trailing: trailing);
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const YbBackButton(),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: YbText.body(size: 17, weight: FontWeight.w600),
                textAlign: trailing == null
                    ? TextAlign.center
                    : TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Di layar sempit atau teks besar, tombol kanan ikut menyempit.
          if (trailing != null)
            Flexible(child: trailing!)
          else
            const SizedBox(width: 44),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: YbText.display(size: 24)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: YbText.body(size: 13, color: YbColors.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: YbColors.ink),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: YbColors.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
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

/// Memegang satu [TextEditingController] untuk dialog atau sheet. Controller
/// baru dibuang setelah animasi tutupnya selesai; membuangnya tepat setelah
/// `showDialog` kembali membuat app galat.
class TextControllerScope extends StatefulWidget {
  const TextControllerScope({
    super.key,
    required this.initialText,
    required this.builder,
  });

  final String initialText;
  final Widget Function(BuildContext context, TextEditingController controller)
  builder;

  @override
  State<TextControllerScope> createState() => _TextControllerScopeState();
}

class _TextControllerScopeState extends State<TextControllerScope> {
  late final _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
