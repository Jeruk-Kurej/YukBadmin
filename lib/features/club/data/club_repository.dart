import '../../manage/data/manage_models.dart';
import '../../pb/data/pb_models.dart';
import 'club_models.dart';

/// Sumber data keanggotaan pengguna. Layar hanya mengenal antarmuka ini.
/// Nanti diganti Supabase: member dihubungkan ke akun lewat nomor WhatsApp
/// atau undangan dari pengurus.
abstract interface class MembershipRepository {
  List<Membership> forUser(String email, DateTime now);
}

/// Data contoh: akun demo tercatat sebagai member tetap PB Smash Surabaya,
/// dengan dua sesi yang sudah lewat dan tiga sesi mendatang.
class SeedMembershipRepository implements MembershipRepository {
  const SeedMembershipRepository();

  static const pbId = 'pb-smash-surabaya';
  static const memberId = 'm-saya';
  static const _fee = 150000;

  @override
  List<Membership> forUser(String email, DateTime now) {
    // Jadwal PB Smash Surabaya: Rabu 19.00–22.00 dan Sabtu 08.00–11.00.
    final slots = [(3, 19, 180), (6, 8, 180)];
    final past = _occurrences(now, slots, forward: false).take(2).toList();
    final next = _occurrences(now, slots, forward: true).take(3).toList();

    // Id member lain hanya untuk jumlah; namanya tidak pernah dikirim.
    Set<String> others(int n) => {for (var i = 1; i <= n; i++) 'lain-$i'};

    return [
      Membership(
        pbId: pbId,
        memberId: memberId,
        type: MemberType.tetap,
        events: [
          for (final (i, start) in past.indexed)
            SessionEvent(
              id: 'smash-lalu-$i',
              title: 'Latihan rutin',
              start: start,
              durationMinutes: 180,
              venue: 'GOR Kertajaya',
              attendanceSaved: true,
              attendees: {memberId, ...others(11)},
              // Sesi terakhir belum dibayar, sesi sebelumnya sudah lunas.
              dues: {memberId: Due(amount: _fee, paid: i == 1)},
            ),
          for (final (i, start) in next.indexed)
            SessionEvent(
              id: 'smash-$i',
              title: i == 1 ? 'Sparing' : 'Latihan rutin',
              start: start,
              durationMinutes: 180,
              venue: 'GOR Kertajaya',
              rsvps: {
                for (final id in others(switch (i) {
                  0 => 9,
                  1 => 4,
                  _ => 0,
                }))
                  id: id == 'lain-1' && i == 0 ? Rsvp.tidak : Rsvp.ikut,
              },
            ),
        ],
      ),
    ];
  }

  /// Waktu mulai sesi mingguan, maju dari sekarang atau mundur ke belakang.
  static Iterable<DateTime> _occurrences(
    DateTime now,
    List<(int weekday, int hour, int minutes)> slots, {
    required bool forward,
  }) sync* {
    final today = DateTime(now.year, now.month, now.day);
    for (var d = 0; d < 60; d++) {
      final day = today.add(Duration(days: forward ? d : -d));
      final daySlots = slots.where((s) => s.$1 == day.weekday).toList()
        ..sort((a, b) => forward ? a.$2 - b.$2 : b.$2 - a.$2);
      for (final s in daySlots) {
        final start = DateTime(day.year, day.month, day.day, s.$2);
        final end = start.add(Duration(minutes: s.$3));
        if (forward ? end.isAfter(now) : !end.isAfter(now)) yield start;
      }
    }
  }
}
