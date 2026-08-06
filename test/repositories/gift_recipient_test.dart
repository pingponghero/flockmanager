import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flock_manager/database/database_helper.dart';
import 'package:flock_manager/database/tables.dart';
import 'package:flock_manager/models/enums.dart';
import 'package:flock_manager/models/income.dart';
import 'package:flock_manager/models/recipient.dart';
import 'package:flock_manager/repositories/finance_repository.dart';

class _FakeDbHelper extends Mock implements DatabaseHelper {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late FinanceRepository repository;

  final start = DateTime(2026, 1, 1);
  final end = DateTime(2026, 12, 31);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          for (final table in Tables.allTables) {
            await db.execute(table);
          }
        },
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
    final helper = _FakeDbHelper();
    when(() => helper.database).thenAnswer((_) async => db);
    repository = FinanceRepository(db: helper);

    await db.insert('flocks', {
      'id': 'f1',
      'name': 'Main Flock',
      'created_at': '2026-01-01T00:00:00.000',
    });
  });

  tearDown(() async {
    await db.close();
  });

  Income sale({int? eggs, double amount = 6.0, String? recipientId}) =>
      Income.create(
        date: DateTime(2026, 6, 1),
        amount: amount,
        eggCount: eggs,
        recipientId: recipientId,
      );

  Income gift({int? eggs, String? recipientId, String? flockId}) =>
      Income.create(
        date: DateTime(2026, 6, 2),
        amount: 0,
        eggCount: eggs,
        type: IncomeType.gift,
        recipientId: recipientId,
        flockId: flockId,
      );

  group('income validation', () {
    test('gift with zero amount is accepted', () async {
      await repository.insertIncome(gift(eggs: 10));
      final all = await repository.getAllIncome();
      expect(all.single.type, IncomeType.gift);
      expect(all.single.amount, 0);
    });

    test('sale with zero amount is rejected', () async {
      expect(
        () => repository.insertIncome(sale(amount: 0)),
        throwsArgumentError,
      );
    });

    test('negative amount is rejected for any type', () async {
      expect(
        () => repository.insertIncome(sale(amount: -1)),
        throwsArgumentError,
      );
    });
  });

  group('sale statistics exclude gifts', () {
    test('getEggSalesData ignores gifted eggs', () async {
      await repository.insertIncome(sale(eggs: 12, amount: 6.0));
      await repository.insertIncome(gift(eggs: 10));

      final (eggsSold, saleIncome) = await repository.getEggSalesData(start, end);
      expect(eggsSold, 12);
      expect(saleIncome, 6.0);
    });

    test('getTotalEggsSold ignores gifted eggs', () async {
      await repository.insertIncome(sale(eggs: 12));
      await repository.insertIncome(gift(eggs: 30));

      expect(await repository.getTotalEggsSold(start, end), 12);
    });

    test('getEggsGifted counts only gifts', () async {
      await repository.insertIncome(sale(eggs: 12));
      await repository.insertIncome(gift(eggs: 10));
      await repository.insertIncome(gift(eggs: 5));

      expect(await repository.getEggsGifted(start, end), 15);
      expect(await repository.getEggsGiftedAllTime(), 15);
    });

    test('getEggsGiftedByFlock includes shared gifts', () async {
      await repository.insertIncome(gift(eggs: 4, flockId: 'f1'));
      await repository.insertIncome(gift(eggs: 3)); // shared (null flock)

      expect(await repository.getEggsGiftedByFlock('f1', start, end), 7);
    });

    test('gifts do not contribute to total income', () async {
      await repository.insertIncome(sale(eggs: 12, amount: 6.0));
      await repository.insertIncome(gift(eggs: 100));

      expect(await repository.getTotalIncomeAllTime(), 6.0);
    });
  });

  group('recipients', () {
    test('rejects empty name', () {
      expect(
        () => repository.insertRecipient(Recipient.create(name: '  ')),
        throwsArgumentError,
      );
    });

    test('CRUD round-trip, sorted by name', () async {
      await repository.insertRecipient(Recipient.create(name: 'zuzana'));
      await repository.insertRecipient(Recipient.create(name: 'Anna'));

      final all = await repository.getAllRecipients();
      expect(all.map((r) => r.name).toList(), ['Anna', 'zuzana']);

      final renamed = all.first.copyWith(name: 'Anna K.');
      await repository.updateRecipient(renamed);
      expect(
        (await repository.getRecipientById(renamed.id))!.name,
        'Anna K.',
      );
    });

    test('deleting a recipient unlinks income but keeps records', () async {
      final anna = Recipient.create(name: 'Anna');
      await repository.insertRecipient(anna);
      await repository.insertIncome(gift(eggs: 10, recipientId: anna.id));

      await repository.deleteRecipient(anna.id);

      expect(await repository.getAllRecipients(), isEmpty);
      final remaining = await repository.getAllIncome();
      expect(remaining.single.recipientId, isNull);
      expect(remaining.single.eggCount, 10);
    });

    test('per-recipient stats aggregate sales and gifts', () async {
      final anna = Recipient.create(name: 'Anna');
      await repository.insertRecipient(anna);
      await repository.insertIncome(
          sale(eggs: 12, amount: 6.0, recipientId: anna.id));
      await repository.insertIncome(gift(eggs: 10, recipientId: anna.id));
      await repository.insertIncome(gift(eggs: 5, recipientId: anna.id));

      final stats = (await repository.getRecipientStats())[anna.id]!;
      expect(stats.saleCount, 1);
      expect(stats.giftCount, 2);
      expect(stats.eggsSold, 12);
      expect(stats.eggsGifted, 15);
      expect(stats.totalIncome, 6.0);
    });

    test('getGiftRecipientCount counts distinct gift recipients', () async {
      final anna = Recipient.create(name: 'Anna');
      final bea = Recipient.create(name: 'Bea');
      await repository.insertRecipient(anna);
      await repository.insertRecipient(bea);
      await repository.insertIncome(gift(eggs: 1, recipientId: anna.id));
      await repository.insertIncome(gift(eggs: 1, recipientId: anna.id));
      await repository.insertIncome(gift(eggs: 1, recipientId: bea.id));
      await repository.insertIncome(gift(eggs: 1)); // anonymous gift

      expect(await repository.getGiftRecipientCount(), 2);
    });
  });

  group('Income model', () {
    test('fromMap defaults missing type to sale (pre-v6 rows)', () {
      final income = Income.fromMap({
        'id': 'i1',
        'date': '2026-06-01T00:00:00.000',
        'amount': 5.0,
        'created_at': '2026-06-01T00:00:00.000',
      });
      expect(income.type, IncomeType.sale);
      expect(income.recipientId, isNull);
    });

    test('gift round-trips through toMap/fromMap', () {
      final original = gift(eggs: 10, recipientId: 'r1');
      final restored = Income.fromMap(original.toMap());
      expect(restored.type, IncomeType.gift);
      expect(restored.recipientId, 'r1');
      expect(restored.isGift, isTrue);
    });
  });
}
