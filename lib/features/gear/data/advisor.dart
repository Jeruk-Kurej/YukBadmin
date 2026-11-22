import 'gear_models.dart';

/// Kelompok level untuk saran perlengkapan. Lebih sederhana dari tier F–S
/// supaya pemula bisa menjawab.
enum SkillGroup {
  pemula('Baru mulai', 'level F–E'),
  menengah('Menengah', 'level D–C'),
  mahir('Mahir', 'level B–S');

  const SkillGroup(this.label, this.tiers);
  final String label;
  final String tiers;
}

enum PlayStyle {
  menyerang('Suka menyerang', 'sering smash dari belakang'),
  seimbang('Seimbang', 'menyerang dan bertahan sama seringnya'),
  bertahan('Lebih bertahan', 'banyak mengembalikan bola dan main di depan net'),
  belumTahu('Belum tahu', 'pilih ini kalau belum yakin');

  const PlayStyle(this.label, this.hint);
  final String label;
  final String hint;
}

enum CourtPosition {
  depan('Depan net (ganda)'),
  belakang('Belakang (ganda)'),
  tunggal('Main tunggal'),
  belumTahu('Belum tahu');

  const CourtPosition(this.label);
  final String label;
}

class Reason {
  const Reason(this.matched, this.text);

  final bool matched;
  final String text;
}

class Suggestion {
  const Suggestion({
    required this.product,
    required this.reasons,
    this.stringTip,
  });

  final Product product;
  final List<Reason> reasons;

  /// Saran senar dan tarikan, hanya untuk raket.
  final StringTip? stringTip;

  int get matched => reasons.where((r) => r.matched).length;
  int get total => reasons.length;
}

class StringTip {
  const StringTip({
    required this.type,
    required this.tension,
    required this.why,
    this.product,
  });

  final StringType type;

  /// Rentang tarikan, misalnya "20–22 lbs".
  final String tension;
  final String why;

  /// Senar yang ada stoknya di toko partner, kalau ada.
  final Product? product;
}

/// Cara saran dibuat, ditampilkan ke pemain. Hasil UAT: pemain baru percaya
/// saran kalau alasannya jelas.
const racketMethod = <({String title, String body})>[
  (
    title: 'Berat',
    body: 'Ikut level. Makin baru mulai, makin ringan (5U) supaya mudah dikontrol.',
  ),
  (
    title: 'Titik berat',
    body: 'Ikut gaya main. Berat di kepala untuk smash, ringan untuk reaksi cepat.',
  ),
  (
    title: 'Kelenturan',
    body: 'Ikut level. Batang lentur membantu pukulan jauh tanpa tenaga besar.',
  ),
  (title: 'Posisi main', body: 'Ikut dihitung kalau kamu memilihnya.'),
];

const shoeMethod = <({String title, String body})>[
  (title: 'Ukuran', body: 'Hanya sepatu yang punya ukuranmu yang ditampilkan.'),
  (title: 'Stok', body: 'Sepatu yang stoknya ada diutamakan.'),
  (
    title: 'Coba dulu',
    body: 'Ukuran tiap merek bisa sedikit beda, jadi coba di toko sebelum membeli.',
  ),
];

/// Penasihat perlengkapan berbasis aturan. Tidak memakai AI: setiap saran
/// bisa ditelusuri ke aturan di [racketMethod] dan [shoeMethod].
class GearAdvisor {
  const GearAdvisor();

  List<Suggestion> rackets(
    List<Product> products, {
    required SkillGroup skill,
    required PlayStyle style,
    required CourtPosition position,
  }) {
    final strings = products.where(
      (p) => p.category == GearCategory.senar && p.stringType != null,
    );
    final tip = _stringTip(skill, style, strings);

    final result = <Suggestion>[];
    for (final p in products) {
      final spec = p.racket;
      if (p.category != GearCategory.raket || spec == null) continue;
      result.add(
        Suggestion(
          product: p,
          reasons: [
            _weightReason(spec.weight, skill),
            _balanceReason(spec.balance, style),
            _flexReason(spec.flex, skill),
            if (position != CourtPosition.belumTahu)
              _positionReason(spec.balance, position),
          ],
          stringTip: tip,
        ),
      );
    }
    return _rank(result);
  }

  List<Suggestion> shoes(List<Product> products, {required int size}) {
    final result = <Suggestion>[];
    for (final p in products) {
      if (p.category != GearCategory.sepatu) continue;
      if (!p.shoeSizes.contains(size)) continue;
      result.add(
        Suggestion(
          product: p,
          reasons: [
            Reason(true, 'Ukuran $size tersedia (ukuran ${p.sizeRange}).'),
            Reason(
              p.inStock,
              p.inStock
                  ? 'Stoknya ada di toko.'
                  : 'Sedang habis. Tanya toko kapan datang lagi.',
            ),
          ],
        ),
      );
    }
    return _rank(result);
  }

  /// Urut dari kriteria paling cocok, lalu yang stoknya ada, lalu termurah.
  static List<Suggestion> _rank(List<Suggestion> list) => list
    ..sort((a, b) {
      final byScore = (b.matched / b.total).compareTo(a.matched / a.total);
      if (byScore != 0) return byScore;
      if (a.product.inStock != b.product.inStock) {
        return a.product.inStock ? -1 : 1;
      }
      return a.product.price.compareTo(b.product.price);
    });

  static Reason _weightReason(RacketWeight w, SkillGroup skill) {
    final ideal = switch (skill) {
      SkillGroup.pemula => {RacketWeight.u5},
      SkillGroup.menengah => {RacketWeight.u4, RacketWeight.u5},
      SkillGroup.mahir => {RacketWeight.u3, RacketWeight.u4},
    };
    final ok = ideal.contains(w);
    return Reason(
      ok,
      ok
          ? 'Berat ${w.label} (${w.grams}) pas untuk ${skill.label.toLowerCase()}.'
          : w == RacketWeight.u3
          ? 'Berat ${w.label} (${w.grams}) terasa berat untuk ${skill.label.toLowerCase()}, tangan cepat capek.'
          : 'Berat ${w.label} (${w.grams}) lebih ringan dari yang biasa dipakai pemain ${skill.label.toLowerCase()}.',
    );
  }

  static Reason _balanceReason(RacketBalance b, PlayStyle style) {
    final ideal = switch (style) {
      PlayStyle.menyerang => RacketBalance.headHeavy,
      PlayStyle.bertahan => RacketBalance.headLight,
      PlayStyle.seimbang || PlayStyle.belumTahu => RacketBalance.even,
    };
    final why = switch (b) {
      RacketBalance.headHeavy => 'membantu smash lebih bertenaga',
      RacketBalance.headLight => 'membantu reaksi cepat saat bertahan',
      RacketBalance.even => 'aman untuk mencoba semua gaya main',
    };
    final ok = b == ideal;
    final styleText = style == PlayStyle.belumTahu
        ? 'kamu yang belum tahu gaya mainnya'
        : 'gaya ${style.label.toLowerCase()}';
    return Reason(
      ok,
      ok
          ? '${b.label}: $why, cocok untuk $styleText.'
          : '${b.label}: $why, kurang pas untuk $styleText.',
    );
  }

  static Reason _flexReason(RacketFlex f, SkillGroup skill) {
    final ok = switch (skill) {
      SkillGroup.pemula => f != RacketFlex.stiff,
      SkillGroup.menengah => true,
      SkillGroup.mahir => f != RacketFlex.flexible,
    };
    return Reason(
      ok,
      ok
          ? 'Batang ${f.label.toLowerCase()} sesuai untuk ${skill.label.toLowerCase()}.'
          : f == RacketFlex.stiff
          ? 'Batang kaku butuh teknik dan tenaga lebih, berat untuk ${skill.label.toLowerCase()}.'
          : 'Batang lentur kurang responsif untuk pemain mahir.',
    );
  }

  static Reason _positionReason(RacketBalance b, CourtPosition pos) {
    final ideal = switch (pos) {
      CourtPosition.depan => RacketBalance.headLight,
      CourtPosition.belakang => RacketBalance.headHeavy,
      _ => RacketBalance.even,
    };
    final ok = b == ideal;
    final why = switch (pos) {
      CourtPosition.depan => 'pemain depan net butuh raket yang cepat diayun',
      CourtPosition.belakang => 'pemain belakang banyak smash dan lob jauh',
      _ => 'main tunggal butuh raket serbaguna untuk serang dan bertahan',
    };
    return Reason(
      ok,
      ok ? 'Cocok di posisimu: $why.' : 'Kurang pas di posisimu: $why.',
    );
  }

  static StringTip _stringTip(
    SkillGroup skill,
    PlayStyle style,
    Iterable<Product> strings,
  ) {
    final type = style == PlayStyle.menyerang && skill != SkillGroup.pemula
        ? StringType.tipis
        : StringType.tebal;
    final tension = switch (skill) {
      SkillGroup.pemula => '20–22 lbs',
      SkillGroup.menengah => '22–25 lbs',
      SkillGroup.mahir => '25–28 lbs',
    };
    final why = skill == SkillGroup.pemula
        ? 'Tarikan rendah membuat bola lebih mudah melambung jauh, dan senar tebal tidak cepat putus.'
        : type == StringType.tipis
        ? 'Senar tipis memberi pantulan dan rasa pukulan yang tajam untuk menyerang.'
        : 'Senar tebal lebih awet untuk yang sering main.';
    final candidates = strings.where((s) => s.stringType == type).toList()
      ..sort((a, b) {
        if (a.inStock != b.inStock) return a.inStock ? -1 : 1;
        return a.price.compareTo(b.price);
      });
    return StringTip(
      type: type,
      tension: tension,
      why: why,
      product: candidates.firstOrNull,
    );
  }
}
