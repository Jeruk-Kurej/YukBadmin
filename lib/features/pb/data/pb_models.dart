/// Tier level pemain, dari F (baru mulai) sampai S (paling mahir).
enum Level {
  f('F'),
  e('E'),
  d('D'),
  c('C'),
  b('B'),
  a('A'),
  s('S');

  const Level(this.label);
  final String label;
}

/// Jenis keanggotaan yang diterima sebuah PB.
enum MemberType {
  tetap('Member tetap'),
  insidental('Insidental');

  const MemberType(this.label);
  final String label;
}

enum DayPart {
  pagi('Pagi'),
  siang('Siang'),
  malam('Malam');

  const DayPart(this.label);
  final String label;
}

/// Hari dalam seminggu, 1 = Senin sampai 7 = Minggu (sama dengan DateTime).
const dayNames = {
  1: 'Senin',
  2: 'Selasa',
  3: 'Rabu',
  4: 'Kamis',
  5: 'Jumat',
  6: 'Sabtu',
  7: 'Minggu',
};

const dayShort = {
  1: 'Sen',
  2: 'Sel',
  3: 'Rab',
  4: 'Kam',
  5: 'Jum',
  6: 'Sab',
  7: 'Min',
};

class PbSession {
  const PbSession({
    required this.weekday,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.venue,
  });

  final int weekday;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final String venue;

  String get dayName => dayNames[weekday]!;

  String get start => _hm(startHour, startMinute);
  String get end => _hm(endHour, endMinute);
  String get timeRange => '$start–$end';

  DayPart get dayPart => startHour < 11
      ? DayPart.pagi
      : startHour < 17
      ? DayPart.siang
      : DayPart.malam;

  bool get isWeekend => weekday >= 6;

  static String _hm(int h, int m) =>
      '${h.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}';
}

class PbManager {
  const PbManager({required this.name, required this.whatsapp});

  final String name;

  /// Nomor WhatsApp format internasional tanpa tanda plus, misalnya 6281311112222.
  final String whatsapp;

  String get initials {
    final parts = name
        .replaceFirst(RegExp(r'^(Pak|Bu|Mas|Mbak|Kak)\s+'), '')
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length.clamp(0, 2))
          .toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class Pb {
  const Pb({
    required this.id,
    required this.name,
    required this.venue,
    required this.district,
    required this.area,
    required this.memberCount,
    required this.quota,
    required this.minLevel,
    required this.maxLevel,
    required this.memberTypes,
    required this.feePerSession,
    required this.sessions,
    required this.about,
    required this.rules,
    required this.manager,
    required this.openForNewMembers,
    required this.artSeed,
    this.monthlyFee,
    this.latitude,
    this.longitude,
    this.foundedYear,
    this.levelTest = false,
    this.logoPath,
    this.photoPaths = const [],
    this.paymentInfo,
  });

  final String id;
  final String name;
  final String venue;
  final String district;
  final String area;
  final int memberCount;
  final int quota;
  final Level minLevel;
  final Level maxLevel;
  final Set<MemberType> memberTypes;

  /// Iuran per sesi dalam rupiah (untuk member insidental).
  final int feePerSession;

  /// Iuran bulanan member tetap dalam rupiah, kalau PB punya.
  final int? monthlyFee;
  final List<PbSession> sessions;
  final String about;
  final List<String> rules;
  final PbManager manager;
  final bool openForNewMembers;

  /// Menentukan variasi ilustrasi lapangan selama PB belum punya foto.
  final int artSeed;
  final double? latitude;
  final double? longitude;

  /// Tahun PB mulai berjalan, kalau diisi pengurus.
  final int? foundedYear;

  /// Calon member diminta ikut tes level sebelum bergabung.
  final bool levelTest;

  /// Path berkas logo di perangkat. Nanti diganti URL Supabase Storage.
  final String? logoPath;

  /// Path berkas foto PB di perangkat, untuk sampul dan galeri.
  final List<String> photoPaths;

  /// Cara bayar iuran yang ditulis pengurus, misalnya nomor rekening atau
  /// "tunai saat sesi". Hanya tampil untuk member.
  final String? paymentInfo;

  String get levelRange => minLevel == maxLevel
      ? minLevel.label
      : '${minLevel.label}–${maxLevel.label}';

  /// Jenis keanggotaan utama yang ditampilkan di kartu.
  MemberType get primaryType => memberTypes.contains(MemberType.tetap)
      ? MemberType.tetap
      : MemberType.insidental;

  PbSession get firstSession => sessions.first;

  bool acceptsLevel(Level level) =>
      level.index >= minLevel.index && level.index <= maxLevel.index;
}

/// Pilihan filter di layar Cari PB. Nilai kosong berarti tidak disaring.
class PbFilter {
  const PbFilter({
    this.query = '',
    this.levels = const {},
    this.memberType,
    this.minFee = feeFloor,
    this.maxFee = feeCeiling,
    this.dayParts = const {},
    this.weekdaysOnly = false,
    this.weekendOnly = false,
  });

  static const feeFloor = 0;
  static const feeCeiling = 300000;

  final String query;
  final Set<Level> levels;
  final MemberType? memberType;
  final int minFee;
  final int maxFee;
  final Set<DayPart> dayParts;
  final bool weekdaysOnly;
  final bool weekendOnly;

  /// Jumlah kelompok filter yang aktif, tidak termasuk kata kunci pencarian.
  int get activeCount =>
      (levels.isNotEmpty ? 1 : 0) +
      (memberType != null ? 1 : 0) +
      (minFee > feeFloor || maxFee < feeCeiling ? 1 : 0) +
      (dayParts.isNotEmpty ? 1 : 0) +
      (weekdaysOnly || weekendOnly ? 1 : 0);

  bool matches(Pb pb) {
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final haystack = '${pb.name} ${pb.venue} ${pb.district} ${pb.area}'
          .toLowerCase();
      if (!haystack.contains(q)) return false;
    }
    if (levels.isNotEmpty && !levels.any(pb.acceptsLevel)) return false;
    if (memberType != null && !pb.memberTypes.contains(memberType)) {
      return false;
    }
    if (pb.feePerSession < minFee || pb.feePerSession > maxFee) return false;
    if (dayParts.isNotEmpty &&
        !pb.sessions.any((s) => dayParts.contains(s.dayPart))) {
      return false;
    }
    if (weekdaysOnly != weekendOnly) {
      final wantWeekend = weekendOnly;
      if (!pb.sessions.any((s) => s.isWeekend == wantWeekend)) return false;
    }
    return true;
  }

  PbFilter copyWith({
    String? query,
    Set<Level>? levels,
    MemberType? memberType,
    bool clearMemberType = false,
    int? minFee,
    int? maxFee,
    Set<DayPart>? dayParts,
    bool? weekdaysOnly,
    bool? weekendOnly,
  }) => PbFilter(
    query: query ?? this.query,
    levels: levels ?? this.levels,
    memberType: clearMemberType ? null : (memberType ?? this.memberType),
    minFee: minFee ?? this.minFee,
    maxFee: maxFee ?? this.maxFee,
    dayParts: dayParts ?? this.dayParts,
    weekdaysOnly: weekdaysOnly ?? this.weekdaysOnly,
    weekendOnly: weekendOnly ?? this.weekendOnly,
  );
}

/// Preferensi main yang diisi pemain setelah masuk.
class PlayerPreferences {
  const PlayerPreferences({
    this.level,
    this.area = 'Surabaya Timur',
    this.weekdays = const {},
  });

  /// Null berarti pemain memilih "Belum tahu".
  final Level? level;
  final String area;
  final Set<int> weekdays;

  PlayerPreferences copyWith({
    Level? level,
    bool clearLevel = false,
    String? area,
    Set<int>? weekdays,
  }) => PlayerPreferences(
    level: clearLevel ? null : (level ?? this.level),
    area: area ?? this.area,
    weekdays: weekdays ?? this.weekdays,
  );

  /// Skor kecocokan sederhana: level masuk rentang PB dan ada sesi di hari pilihan.
  int scoreFor(Pb pb) {
    var score = 0;
    if (level != null && pb.acceptsLevel(level!)) score += 2;
    if (pb.area == area) score += 1;
    if (pb.sessions.any((s) => weekdays.contains(s.weekday))) score += 2;
    return score;
  }
}
