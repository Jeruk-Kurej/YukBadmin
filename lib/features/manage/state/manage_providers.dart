import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_store.dart';
import '../data/manage_codec.dart';

import '../../pb/data/pb_models.dart';
import '../data/import_parser.dart';
import '../data/manage_models.dart';

final noteParserProvider = Provider<NoteParser>(
  (ref) => const RuleBasedNoteParser(),
);

/// Apakah pengurus sudah membuka atau menutup panduan singkat. Masih di
/// memori, jadi kartu panduan muncul lagi setiap app dibuka ulang.
class ManagerGuideSeenNotifier extends Notifier<bool> {
  @override
  bool build() {
    final store = ref.watch(localStoreProvider);
    listenSelf((_, next) => writeCached(store, CacheKeys.guideSeen, next));
    return readCached(store, CacheKeys.guideSeen, (j) => j! as bool, false);
  }

  void markSeen() => state = true;
}

final managerGuideSeenProvider =
    NotifierProvider<ManagerGuideSeenNotifier, bool>(
      ManagerGuideSeenNotifier.new,
    );

/// Jam saat ini. Dijadikan provider supaya bisa diganti di tes.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Data PB yang dikelola pengguna. Masih disimpan di memori; akan dipindah
/// ke Supabase.
class ManageNotifier extends Notifier<ManageState> {
  var _seq = 0;

  @override
  ManageState build() {
    final store = ref.watch(localStoreProvider);
    listenSelf(
      (_, next) =>
          writeCached(store, CacheKeys.manage, manageStateToJson(next)),
    );
    final restored = readCached(
      store,
      CacheKeys.manage,
      manageStateFromJson,
      const ManageState(),
    );
    _seq = maxIdSeq([
      ...restored.members.map((m) => m.id),
      ...restored.events.map((e) => e.id),
      ...restored.coManagers.map((c) => c.id),
    ]);
    return restored;
  }

  String _id(String prefix) => '$prefix-${++_seq}';

  /// Mendaftarkan PB baru dan menyiapkan sesi untuk tiap jadwal rutinnya.
  void registerPb(Pb pb) {
    final now = ref.read(nowProvider)();
    state = ManageState(
      pb: pb,
      events: [
        for (final s in pb.sessions)
          _eventFor(s, _nextDate(now, s), 'Latihan rutin'),
      ],
    );
  }

  void updatePb(Pb pb) => state = state.copyWith(pb: _withCount(pb));

  /// Jumlah member di profil PB mengikuti daftar member yang sebenarnya.
  Pb _withCount(Pb pb, [int? count]) =>
      copyPb(pb, memberCount: count ?? state.members.length);

  void _setMembers(List<Member> members) {
    final pb = state.pb;
    state = state.copyWith(
      members: members,
      pb: pb == null ? null : _withCount(pb, members.length),
    );
  }

  Member addMember({
    required String name,
    required MemberType type,
    Level? level,
    String? whatsapp,
    String? photoPath,
  }) {
    final member = Member(
      id: _id('m'),
      name: name.trim(),
      type: type,
      level: level,
      whatsapp: whatsapp,
      photoPath: photoPath,
    );
    _setMembers([...state.members, member]);
    return member;
  }

  void updateMember(Member member) => _setMembers([
    for (final m in state.members) m.id == member.id ? member : m,
  ]);

  /// Menghapus member beserta kehadiran dan iurannya di semua sesi.
  void removeMember(String memberId) {
    state = state.copyWith(
      events: [
        for (final e in state.events)
          e.copyWith(
            attendees: {...e.attendees}..remove(memberId),
            dues: {...e.dues}..remove(memberId),
            rsvps: {...e.rsvps}..remove(memberId),
          ),
      ],
    );
    _setMembers(state.members.where((m) => m.id != memberId).toList());
  }

  SessionEvent addEvent({
    required String title,
    required DateTime start,
    required int durationMinutes,
    required String venue,
  }) {
    final event = SessionEvent(
      id: _id('s'),
      title: title.trim(),
      start: start,
      durationMinutes: durationMinutes,
      venue: venue.trim(),
    );
    state = state.copyWith(events: [...state.events, event]);
    return event;
  }

  void removeEvent(String eventId) => state = state.copyWith(
    events: state.events.where((e) => e.id != eventId).toList(),
  );

  void _replaceEvent(SessionEvent event) => state = state.copyWith(
    events: [for (final e in state.events) e.id == event.id ? event : e],
  );

  /// Menyimpan kehadiran. Yang hadir mendapat iuran sebesar biaya per sesi
  /// (bisa diubah per orang); yang batal hadir iurannya dihapus kecuali
  /// sudah lunas atau sudah mengirim bukti transfer.
  void saveAttendance(String eventId, Set<String> attendees) {
    final event = state.eventById(eventId);
    final pb = state.pb;
    if (event == null || pb == null) return;
    final dues = <String, Due>{};
    for (final id in attendees) {
      dues[id] = event.dues[id] ?? Due(amount: pb.feePerSession);
    }
    for (final entry in event.dues.entries) {
      if (entry.value.paid || entry.value.proof != null) {
        dues.putIfAbsent(entry.key, () => entry.value);
      }
    }
    _replaceEvent(
      event.copyWith(attendees: attendees, dues: dues, attendanceSaved: true),
    );
  }

  void setDue(String eventId, String memberId, Due due) {
    final event = state.eventById(eventId);
    if (event == null) return;
    _replaceEvent(event.copyWith(dues: {...event.dues, memberId: due}));
  }

  /// Menghapus catatan iuran satu member di satu sesi (dipakai untuk
  /// membatalkan "bayar di muka").
  void removeDue(String eventId, String memberId) {
    final event = state.eventById(eventId);
    if (event == null) return;
    _replaceEvent(event.copyWith(dues: {...event.dues}..remove(memberId)));
  }

  /// Konfirmasi member ikut atau tidak. Null menghapus jawabannya.
  void setRsvp(String eventId, String memberId, Rsvp? rsvp) {
    final event = state.eventById(eventId);
    if (event == null) return;
    final rsvps = {...event.rsvps};
    if (rsvp == null) {
      rsvps.remove(memberId);
    } else {
      rsvps[memberId] = rsvp;
    }
    _replaceEvent(event.copyWith(rsvps: rsvps));
  }

  /// Member mengirim bukti transfer. Kalau iurannya belum tercatat (bayar
  /// sebelum kehadiran dicatat), iuran dibuat sebesar biaya per sesi.
  void submitProof(String eventId, String memberId, String path) {
    final event = state.eventById(eventId);
    final pb = state.pb;
    if (event == null || pb == null) return;
    final due = event.dues[memberId] ?? Due(amount: pb.feePerSession);
    if (due.paid) return;
    setDue(
      eventId,
      memberId,
      due.copyWith(
        proof: PaymentProof(path: path, sentAt: ref.read(nowProvider)()),
      ),
    );
  }

  /// Pengurus menyetujui bukti transfer: iuran jadi lunas.
  void approveProof(String eventId, String memberId) {
    final due = state.eventById(eventId)?.dues[memberId];
    final proof = due?.proof;
    if (due == null || proof == null) return;
    setDue(
      eventId,
      memberId,
      due.copyWith(
        paid: true,
        proof: proof.copyWith(status: ProofStatus.disetujui),
      ),
    );
  }

  /// Pengurus menolak bukti transfer dengan alasan; member bisa kirim ulang.
  void rejectProof(String eventId, String memberId, String reason) {
    final due = state.eventById(eventId)?.dues[memberId];
    final proof = due?.proof;
    if (due == null || proof == null) return;
    setDue(
      eventId,
      memberId,
      due.copyWith(
        proof: proof.copyWith(
          status: ProofStatus.ditolak,
          reason: reason.trim(),
        ),
      ),
    );
  }

  /// Mencatat undangan pengurus baru. Undangannya sendiri dikirim lewat
  /// WhatsApp; status berubah jadi aktif setelah diterima (butuh server).
  CoManager inviteCoManager({required String name, required String whatsapp}) {
    final manager = CoManager(
      id: _id('p'),
      name: name.trim(),
      whatsapp: whatsapp,
    );
    state = state.copyWith(coManagers: [...state.coManagers, manager]);
    return manager;
  }

  void removeCoManager(String id) => state = state.copyWith(
    coManagers: state.coManagers.where((c) => c.id != id).toList(),
  );

  /// Menambahkan hasil impor sebagai member. Nama yang sudah ada dilewati.
  /// Mengembalikan jumlah member baru.
  int importRows(List<ImportRow> rows) {
    final existing = state.members.map((m) => m.name.toLowerCase()).toSet();
    final added = <Member>[];
    for (final row in rows) {
      final name = row.name.trim();
      if (name.isEmpty || !existing.add(name.toLowerCase())) continue;
      added.add(Member(id: _id('m'), name: name, type: row.type));
    }
    if (added.isNotEmpty) _setMembers([...state.members, ...added]);
    return added.length;
  }

  void clear() => state = const ManageState();

  SessionEvent _eventFor(PbSession s, DateTime date, String title) =>
      SessionEvent(
        id: _id('s'),
        title: title,
        start: DateTime(
          date.year,
          date.month,
          date.day,
          s.startHour,
          s.startMinute,
        ),
        durationMinutes:
            (s.endHour * 60 + s.endMinute) - (s.startHour * 60 + s.startMinute),
        venue: s.venue,
      );

  /// Tanggal terdekat (hari ini atau sesudahnya) untuk jadwal mingguan itu.
  static DateTime _nextDate(DateTime now, PbSession s) {
    var date = DateTime(now.year, now.month, now.day);
    while (date.weekday != s.weekday) {
      date = date.add(const Duration(days: 1));
    }
    final end = DateTime(
      date.year,
      date.month,
      date.day,
      s.endHour,
      s.endMinute,
    );
    return end.isAfter(now) ? date : date.add(const Duration(days: 7));
  }
}

final manageProvider = NotifierProvider<ManageNotifier, ManageState>(
  ManageNotifier.new,
);

/// Salinan [Pb] dengan sebagian nilai diganti.
Pb copyPb(
  Pb pb, {
  String? name,
  String? venue,
  String? district,
  String? area,
  int? memberCount,
  int? quota,
  Level? minLevel,
  Level? maxLevel,
  Set<MemberType>? memberTypes,
  int? feePerSession,
  int? monthlyFee,
  List<PbSession>? sessions,
  String? about,
  List<String>? rules,
  PbManager? manager,
  bool? openForNewMembers,
  int? foundedYear,
  bool clearFoundedYear = false,
  bool? levelTest,
  String? logoPath,
  bool clearLogo = false,
  List<String>? photoPaths,
  String? paymentInfo,
  bool clearPaymentInfo = false,
}) => Pb(
  id: pb.id,
  name: name ?? pb.name,
  venue: venue ?? pb.venue,
  district: district ?? pb.district,
  area: area ?? pb.area,
  memberCount: memberCount ?? pb.memberCount,
  quota: quota ?? pb.quota,
  minLevel: minLevel ?? pb.minLevel,
  maxLevel: maxLevel ?? pb.maxLevel,
  memberTypes: memberTypes ?? pb.memberTypes,
  feePerSession: feePerSession ?? pb.feePerSession,
  monthlyFee: monthlyFee ?? pb.monthlyFee,
  sessions: sessions ?? pb.sessions,
  about: about ?? pb.about,
  rules: rules ?? pb.rules,
  manager: manager ?? pb.manager,
  openForNewMembers: openForNewMembers ?? pb.openForNewMembers,
  artSeed: pb.artSeed,
  latitude: pb.latitude,
  longitude: pb.longitude,
  foundedYear: clearFoundedYear ? null : (foundedYear ?? pb.foundedYear),
  levelTest: levelTest ?? pb.levelTest,
  logoPath: clearLogo ? null : (logoPath ?? pb.logoPath),
  photoPaths: photoPaths ?? pb.photoPaths,
  paymentInfo: clearPaymentInfo ? null : (paymentInfo ?? pb.paymentInfo),
);
