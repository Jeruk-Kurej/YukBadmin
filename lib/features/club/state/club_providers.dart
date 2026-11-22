import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_store.dart';
import '../../manage/data/manage_models.dart';
import '../../manage/state/manage_providers.dart';
import '../../pb/state/providers.dart';
import '../data/club_models.dart';
import '../data/club_repository.dart';

final membershipRepositoryProvider = Provider<MembershipRepository>(
  (ref) => const SeedMembershipRepository(),
);

/// PB tempat pengguna tercatat sebagai member. Perubahan (konfirmasi ikut,
/// bukti transfer) disimpan di cache per akun.
class MembershipNotifier extends Notifier<List<Membership>> {
  @override
  List<Membership> build() {
    final store = ref.watch(localStoreProvider);
    final user = ref.watch(sessionProvider);
    if (user == null) return const [];
    listenSelf(
      (_, next) => writeCached(store, CacheKeys.membership, {
        'email': user.email,
        'items': [for (final m in next) membershipToJson(m)],
      }),
    );
    final cached = readCached<List<Membership>?>(store, CacheKeys.membership, (
      json,
    ) {
      final m = json! as Map<String, Object?>;
      // Cache milik akun lain tidak dipakai.
      if (m['email'] != user.email) return null;
      return [for (final x in m['items']! as List) membershipFromJson(x)];
    }, null);
    return cached ??
        ref
            .read(membershipRepositoryProvider)
            .forUser(user.email, ref.read(nowProvider)());
  }

  void _updateEvent(
    String pbId,
    String eventId,
    SessionEvent Function(SessionEvent e, String memberId) change,
  ) {
    state = [
      for (final m in state)
        m.pbId != pbId
            ? m
            : m.copyWith(
                events: [
                  for (final e in m.events)
                    e.id == eventId ? change(e, m.memberId) : e,
                ],
              ),
    ];
  }

  /// Menjawab ikut atau tidak. Null menghapus jawaban.
  void setRsvp(String pbId, String eventId, Rsvp? rsvp) =>
      _updateEvent(pbId, eventId, (e, me) {
        final rsvps = {...e.rsvps};
        if (rsvp == null) {
          rsvps.remove(me);
        } else {
          rsvps[me] = rsvp;
        }
        return e.copyWith(rsvps: rsvps);
      });

  /// Mengirim bukti transfer untuk iuran yang belum lunas.
  void submitProof(String pbId, String eventId, String path) {
    final now = ref.read(nowProvider)();
    _updateEvent(pbId, eventId, (e, me) {
      final due = e.dues[me];
      if (due == null || due.paid) return e;
      return e.copyWith(
        dues: {
          ...e.dues,
          me: due.copyWith(
            proof: PaymentProof(path: path, sentAt: now),
          ),
        },
      );
    });
  }
}

final membershipProvider =
    NotifierProvider<MembershipNotifier, List<Membership>>(
      MembershipNotifier.new,
    );
