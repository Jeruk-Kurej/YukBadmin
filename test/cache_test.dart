import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/core/data/local_store.dart';
import 'package:yukbadmin/features/gear/data/gear_models.dart';
import 'package:yukbadmin/features/gear/state/gear_providers.dart';
import 'package:yukbadmin/features/manage/data/manage_models.dart';
import 'package:yukbadmin/features/manage/state/manage_providers.dart';
import 'package:yukbadmin/features/pb/data/pb_models.dart';
import 'package:yukbadmin/features/pb/state/providers.dart';

const _pb = Pb(
  id: 'pb-milikku',
  name: 'PB Uji',
  venue: 'GOR Uji',
  district: 'Gubeng',
  area: 'Surabaya Timur',
  memberCount: 0,
  quota: 30,
  minLevel: Level.d,
  maxLevel: Level.b,
  memberTypes: {MemberType.tetap, MemberType.insidental},
  feePerSession: 150000,
  monthlyFee: 300000,
  sessions: [
    PbSession(
      weekday: 3,
      startHour: 19,
      startMinute: 0,
      endHour: 22,
      endMinute: 0,
      venue: 'GOR Uji',
    ),
  ],
  about: 'Santai',
  rules: ['Bawa raket sendiri'],
  manager: PbManager(name: 'Bryan Carlie', whatsapp: '6281234567890'),
  openForNewMembers: true,
  artSeed: 3,
  foundedYear: 2019,
  levelTest: true,
);

void main() {
  /// Container baru dengan cache yang sama, seperti app yang dibuka ulang.
  ProviderContainer reopen(LocalStore store) {
    final c = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'data pemain, pengurus, dan toko tetap ada setelah app dibuka ulang',
    () async {
      final store = MemoryLocalStore();
      final first = reopen(store);

      first.read(sessionProvider.notifier).signInDemo();
      first
          .read(preferencesProvider.notifier)
          .save(const PlayerPreferences(level: Level.d, weekdays: {6}));
      first.read(savedProvider.notifier).toggle('pb-kok-kuning');
      first.read(managerGuideSeenProvider.notifier).markSeen();

      final manage = first.read(manageProvider.notifier)..registerPb(_pb);
      final andi = manage.addMember(name: 'Andi', type: MemberType.tetap);
      final event = first.read(manageProvider).events.first;
      manage
        ..saveAttendance(event.id, {andi.id})
        ..setDue(event.id, andi.id, const Due(amount: 150000, paid: true));

      first
          .read(ownShopProvider.notifier)
          .register(
            const Shop(
              id: 'shop-milikku',
              name: 'Toko Uji',
              address: 'Jl. Uji 1',
              district: 'Gubeng',
              whatsapp: '6281234567890',
              hours: '09.00–20.00',
              description: '',
            ),
          );
      first
          .read(ownShopProvider.notifier)
          .saveProduct(
            const Product(
              id: '',
              shopId: 'shop-milikku',
              name: 'Raket Uji',
              category: GearCategory.raket,
              price: 500000,
              inStock: true,
              description: '',
              racket: RacketSpec(
                weight: RacketWeight.u4,
                balance: RacketBalance.even,
                flex: RacketFlex.medium,
              ),
            ),
          );
      // Penulisan cache asinkron; beri kesempatan selesai.
      await Future<void>.delayed(Duration.zero);

      final second = reopen(store);
      expect(second.read(sessionProvider)?.name, 'Bryan Carlie');
      expect(second.read(preferencesProvider).level, Level.d);
      expect(second.read(preferencesProvider).weekdays, {6});
      expect(second.read(savedProvider), {'pb-kok-kuning'});
      expect(second.read(managerGuideSeenProvider), isTrue);

      final restored = second.read(manageProvider);
      expect(restored.pb?.name, 'PB Uji');
      expect(restored.pb?.foundedYear, 2019);
      expect(restored.pb?.levelTest, isTrue);
      expect(restored.members.single.name, 'Andi');
      final restoredEvent = restored.eventById(event.id)!;
      expect(restoredEvent.attendees, {andi.id});
      expect(restoredEvent.dues[andi.id]?.paid, isTrue);

      final shop = second.read(ownShopProvider);
      expect(shop.shop?.name, 'Toko Uji');
      expect(shop.products.single.racket?.weight, RacketWeight.u4);

      // Id baru tidak bentrok dengan id yang dipulihkan.
      final budi = second
          .read(manageProvider.notifier)
          .addMember(name: 'Budi', type: MemberType.insidental);
      expect(budi.id, isNot(andi.id));
    },
  );

  test('keluar akun mengosongkan data PB dan toko di cache', () async {
    final store = MemoryLocalStore();
    final first = reopen(store);
    first.read(sessionProvider.notifier).signInDemo();
    first.read(manageProvider.notifier).registerPb(_pb);
    await Future<void>.delayed(Duration.zero);

    first.read(manageProvider.notifier).clear();
    first.read(sessionProvider.notifier).signOut();
    await Future<void>.delayed(Duration.zero);

    final second = reopen(store);
    expect(second.read(sessionProvider), isNull);
    expect(second.read(manageProvider).hasPb, isFalse);
  });

  test('cache rusak diabaikan dan app tetap bisa dibuka', () {
    final store = MemoryLocalStore({
      CacheKeys.manage: '{bukan json',
      CacheKeys.preferences: '{"level": "z"}',
      CacheKeys.session: '[]',
    });
    final c = reopen(store);
    expect(c.read(manageProvider).hasPb, isFalse);
    expect(c.read(preferencesProvider).area, 'Surabaya Timur');
    expect(c.read(sessionProvider), isNull);
  });

  test('maxIdSeq membaca angka di akhir id', () {
    expect(maxIdSeq(['m-3', 's-12', 'pm-7', 'aneh']), 12);
    expect(maxIdSeq(const []), 0);
  });
}
