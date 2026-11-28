import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_store.dart';
import 'providers.dart';

/// Status ajakan gabung ke PB yang sudah dihubungi lewat WhatsApp.
///
/// Percakapan dengan pengurus terjadi di WhatsApp, jadi app tidak bisa membaca
/// balasannya. Pemain yang menandai statusnya sendiri. Nanti, saat Supabase
/// tahap 2, status "Diterima" bisa datang dari pengurus lewat permintaan
/// gabung di dalam app.
enum JoinStatus {
  menunggu('Menunggu balasan', 'Pengurus belum membalas chat-mu.'),
  dibalas(
    'Sudah dibalas',
    'Pengurus sudah membalas, kamu sedang mengatur gabung.',
  ),
  diterima('Diterima', 'Kamu sudah diterima jadi member PB ini.'),
  batal('Tidak jadi', 'Kamu tidak jadi gabung ke PB ini.');

  const JoinStatus(this.label, this.hint);
  final String label;
  final String hint;
}

/// Status satu PB beserta waktu terakhir diubah.
class JoinRecord {
  const JoinRecord(this.status, this.updatedAt);

  final JoinStatus status;
  final DateTime updatedAt;

  /// Lama menunggu sebelum app mengajak menghubungi lagi.
  static const followUpAfter = Duration(days: 2);

  /// Masih menunggu balasan lebih dari [followUpAfter].
  bool needsFollowUp(DateTime now) =>
      status == JoinStatus.menunggu &&
      now.difference(updatedAt) >= followUpAfter;
}

/// Kunci cache status gabung, per akun.
const joinStatusCacheKey = 'v1.joinStatus';

class JoinStatusNotifier extends Notifier<Map<String, JoinRecord>> {
  @override
  Map<String, JoinRecord> build() {
    final store = ref.watch(localStoreProvider);
    final key = accountCacheKey(ref, joinStatusCacheKey);
    listenSelf(
      (_, next) => writeCached(store, key, {
        for (final e in next.entries)
          e.key: {
            'status': e.value.status.name,
            'at': e.value.updatedAt.toIso8601String(),
          },
      }),
    );
    return readCached<Map<String, JoinRecord>>(
      store,
      key,
      (json) => {
        for (final e in (json! as Map).entries)
          e.key as String: JoinRecord(
            JoinStatus.values.byName((e.value as Map)['status'] as String),
            DateTime.parse((e.value as Map)['at'] as String),
          ),
      },
      const {},
    );
  }

  void set(String pbId, JoinStatus status, DateTime at) =>
      state = {...state, pbId: JoinRecord(status, at)};
}

final joinStatusProvider =
    NotifierProvider<JoinStatusNotifier, Map<String, JoinRecord>>(
      JoinStatusNotifier.new,
    );

/// Status PB yang sudah dihubungi. Belum pernah ditandai berarti masih
/// menunggu balasan sejak waktu dihubungi.
JoinRecord joinRecordFor(
  Map<String, JoinRecord> records,
  String pbId,
  DateTime contactedAt,
) {
  final r = records[pbId];
  // Menghubungi lagi setelah status terakhir berarti kembali menunggu.
  if (r == null || contactedAt.isAfter(r.updatedAt)) {
    return JoinRecord(JoinStatus.menunggu, contactedAt);
  }
  return r;
}
