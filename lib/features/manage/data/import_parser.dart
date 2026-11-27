import '../../pb/data/pb_models.dart';
import 'manage_models.dart';

/// Mengubah catatan mentah menjadi baris member yang bisa diperiksa pengurus.
/// Layar impor hanya mengenal antarmuka ini, jadi pembaca berbasis aturan di
/// bawah bisa diganti layanan AI (untuk foto dan poster) tanpa mengubah layar.
abstract interface class NoteParser {
  Future<List<ImportRow>> parse(String text);
}

/// Pembaca berbasis aturan untuk teks yang ditempel: daftar di chat WhatsApp
/// atau salinan dari Sheets. Tidak memakai AI dan tidak mengirim data ke luar.
class RuleBasedNoteParser implements NoteParser {
  const RuleBasedNoteParser();

  static final _chatPrefix = RegExp(
    r'^\[?\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4},?\s+\d{1,2}[.:]\d{2}(?::\d{2})?\]?\s*-?\s*[^:]{1,40}:\s*',
  );
  static final _bullet = RegExp(r'^\s*(?:\d{1,3}[.)]|[-*•])\s*');
  static final _amount = RegExp(
    r'(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})+|\d+)\s*(rb|ribu|k)?',
    caseSensitive: false,
  );
  static final _paidWords = RegExp(
    r'\b(lunas|sudah bayar|sdh bayar|udah bayar|paid|done|tf|transfer)\b|✅|✔|☑',
    caseSensitive: false,
  );
  static final _unpaidWords = RegExp(
    r'\b(belum|blm|nunggak|hutang|utang)\b(?:\s+(?:bayar|lunas))?|❌|✖',
    caseSensitive: false,
  );
  static final _tetapWords = RegExp(
    r'\b(member tetap|tetap|member|bulanan)\b',
    caseSensitive: false,
  );
  static final _insidentalWords = RegExp(
    r'\b(insidental|insidentil|tamu|per sesi|harian|drop ?in)\b',
    caseSensitive: false,
  );
  static final _phone = RegExp(
    r'(?<!\d)(?:\+?62|0)[ -]?8\d(?:[ .-]?\d){6,11}(?!\d)',
  );
  static final _clock = RegExp(
    r'(?<![\d.,])(?:(?:jam|pukul)\s*)?(?:[01]?\d|2[0-3])[.:][0-5]\d(?![.,]?\d)',
    caseSensitive: false,
  );
  static final _headingWords = RegExp(
    r'\b(daftar|list|jadwal|absen|absensi|hadir|rekap|iuran|total|latihan|sparing|senin|selasa|rabu|kamis|jumat|sabtu)\b',
    caseSensitive: false,
  );
  static final _separators = RegExp(r'[|;\t,:()\[\]–—-]+');

  @override
  Future<List<ImportRow>> parse(String text) async {
    final rows = <ImportRow>[];
    final seen = <String>{};

    for (final raw in text.split('\n')) {
      var line = raw.trim();
      if (line.isEmpty) continue;
      line = line
          .replaceFirst(_chatPrefix, '')
          .replaceFirst(_bullet, '')
          // Nomor HP dan jam bukan nominal maupun bagian dari nama.
          .replaceAll(_phone, ' ')
          .replaceAll(_clock, ' ');
      if (line.isEmpty) continue;

      final unpaid = _unpaidWords.hasMatch(line);
      final paid = !unpaid && _paidWords.hasMatch(line);
      final insidental = _insidentalWords.hasMatch(line);

      int? amount;
      for (final m in _amount.allMatches(line)) {
        final value = _toRupiah(m.group(1)!, m.group(2));
        // Angka kecil tanpa satuan hampir pasti nomor urut atau jam.
        if (value >= 5000) {
          amount = value;
          break;
        }
      }

      var name = line
          .replaceAll(_amount, ' ')
          .replaceAll(_paidWords, ' ')
          .replaceAll(_unpaidWords, ' ')
          .replaceAll(_tetapWords, ' ')
          .replaceAll(_insidentalWords, ' ')
          .replaceAll(RegExp(r'\brp\b\.?', caseSensitive: false), ' ')
          .replaceAll(_separators, ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final uncertain = name.contains('?');
      name = name.replaceAll('?', '').trim();
      final letters = name.replaceAll(RegExp(r'[^A-Za-z]'), '').length;

      // Baris tanpa nama sama sekali (judul, tanggal, kalimat kosong) dilewati.
      if (letters == 0) continue;

      String? reason;
      if (uncertain) {
        reason = 'Ada tanda tanya di nama, cek dulu';
      } else if (_headingWords.hasMatch(name)) {
        reason = 'Baris ini mungkin judul, cek dulu';
      } else if (letters < 3) {
        reason = 'Nama terlalu pendek, cek dulu';
      } else if (name.split(' ').length > 4) {
        reason = 'Baris ini mungkin bukan nama member';
      } else if (!seen.add(name.toLowerCase())) {
        reason = 'Nama ini muncul lebih dari sekali';
      }

      rows.add(
        ImportRow(
          name: _titleCase(name),
          // Tanpa kata kunci, member dianggap tetap; pengurus bisa mengubahnya.
          type: insidental ? MemberType.insidental : MemberType.tetap,
          amount: amount,
          paid: paid ? true : (unpaid ? false : null),
          needsReview: reason != null,
          reason: reason,
          source: raw.trim(),
        ),
      );
    }
    return rows;
  }

  static int _toRupiah(String digits, String? unit) {
    final plain = int.parse(digits.replaceAll(RegExp(r'[.,]'), ''));
    return unit == null ? plain : plain * 1000;
  }

  static String _titleCase(String name) => name
      .split(' ')
      .map(
        (w) => w.isEmpty
            ? w
            : w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''),
      )
      .join(' ');
}
