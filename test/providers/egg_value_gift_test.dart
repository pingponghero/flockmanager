import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/providers/egg_value_provider.dart';

void main() {
  group('buildEggValueSummary with gifted eggs', () {
    test('gifted eggs are excluded from consumed value and sale stats', () {
      // 100 eggs: 24 sold for $12, 20 gifted, 56 consumed
      final summary = buildEggValueSummary(
        eggCount: 100,
        totalExpenses: 30,
        totalIncome: 12,
        retailPrice: 6.0, // $0.50/egg
        eggsSold: 24,
        saleIncome: 12,
        eggsGifted: 20,
      );

      expect(summary.eggsSold, 24);
      expect(summary.eggsGifted, 20);
      expect(summary.eggsConsumed, 56);
      // value = 56 consumed × $0.50 + $12 sales = $40
      expect(summary.eggProductionValue, closeTo(40.0, 0.001));
    });

    test('gifts do not change average sale price', () {
      final withoutGifts = buildEggValueSummary(
        eggCount: 50,
        totalExpenses: 0,
        totalIncome: 12,
        retailPrice: 6.0,
        eggsSold: 24,
        saleIncome: 12,
      );
      final withGifts = buildEggValueSummary(
        eggCount: 50,
        totalExpenses: 0,
        totalIncome: 12,
        retailPrice: 6.0,
        eggsSold: 24,
        saleIncome: 12,
        eggsGifted: 20,
      );

      // Avg sale price per egg (income / eggsSold) is identical
      expect(
        withGifts.totalIncome / withGifts.eggsSold,
        withoutGifts.totalIncome / withoutGifts.eggsSold,
      );
    });

    test('consumed count clamps when sold + gifted exceed logged eggs', () {
      final summary = buildEggValueSummary(
        eggCount: 10,
        totalExpenses: 0,
        totalIncome: 5,
        retailPrice: 6.0,
        eggsSold: 8,
        saleIncome: 5,
        eggsGifted: 8,
      );
      expect(summary.eggsConsumed, 0);
    });

    test('defaults to no gifted eggs for backward compatibility', () {
      final summary = buildEggValueSummary(
        eggCount: 10,
        totalExpenses: 0,
        totalIncome: 0,
        retailPrice: 6.0,
        eggsSold: 0,
        saleIncome: 0,
      );
      expect(summary.eggsGifted, 0);
      expect(summary.eggsConsumed, 10);
    });
  });
}
