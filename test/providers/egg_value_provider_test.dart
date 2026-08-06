import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/providers/egg_value_provider.dart';

void main() {
  group('buildEggValueSummary', () {
    test('all eggs consumed at retail price', () {
      final summary = buildEggValueSummary(
        eggCount: 100,
        totalExpenses: 50.0,
        totalIncome: 0.0,
        retailPrice: 6.00,
        eggsSold: 0,
        saleIncome: 0.0,
      );

      // 100 eggs × $0.50/egg = $50.00
      expect(summary.eggProductionValue, closeTo(50.0, 0.01));
      expect(summary.eggCount, 100);
      expect(summary.eggsSold, 0);
      expect(summary.totalExpenses, 50.0);
      expect(summary.totalIncome, 0.0);
      expect(summary.retailPricePerDozen, 6.00);
    });

    test('all eggs sold at actual income', () {
      final summary = buildEggValueSummary(
        eggCount: 60,
        totalExpenses: 30.0,
        totalIncome: 45.0,
        retailPrice: 6.00,
        eggsSold: 60,
        saleIncome: 45.0,
      );

      // 0 consumed, 60 sold for $45 → production value = $45
      expect(summary.eggProductionValue, closeTo(45.0, 0.01));
      expect(summary.eggsConsumed, 0);
    });

    test('mixed consumed and sold', () {
      final summary = buildEggValueSummary(
        eggCount: 100,
        totalExpenses: 80.0,
        totalIncome: 25.0,
        retailPrice: 6.00,
        eggsSold: 30,
        saleIncome: 25.0,
      );

      // 70 consumed × $0.50 = $35, + $25 sold = $60
      expect(summary.eggProductionValue, closeTo(60.0, 0.01));
      expect(summary.eggsConsumed, 70);
      expect(summary.eggsSold, 30);
    });

    test('clamps eggsConsumed when eggsSold exceeds eggCount', () {
      final summary = buildEggValueSummary(
        eggCount: 50,
        totalExpenses: 20.0,
        totalIncome: 100.0,
        retailPrice: 6.00,
        eggsSold: 80,
        saleIncome: 100.0,
      );

      // eggsSold > eggCount → eggsConsumed clamped to 0
      expect(summary.eggsConsumed, 0);
      // Production value = 0 consumed + $100 sold = $100
      expect(summary.eggProductionValue, closeTo(100.0, 0.01));
    });

    test('zero eggs produces zero value', () {
      final summary = buildEggValueSummary(
        eggCount: 0,
        totalExpenses: 15.0,
        totalIncome: 0.0,
        retailPrice: 6.00,
        eggsSold: 0,
        saleIncome: 0.0,
      );

      expect(summary.eggProductionValue, 0.0);
      expect(summary.eggsConsumed, 0);
    });

    test('passes through totalIncome separately from saleIncome', () {
      // totalIncome includes ALL income; saleIncome only income with egg counts
      final summary = buildEggValueSummary(
        eggCount: 100,
        totalExpenses: 50.0,
        totalIncome: 75.0, // includes $25 without egg counts
        retailPrice: 6.00,
        eggsSold: 20,
        saleIncome: 50.0, // only income with egg counts
      );

      // 80 consumed × $0.50 = $40, + $50 saleIncome = $90
      expect(summary.eggProductionValue, closeTo(90.0, 0.01));
      // totalIncome is passed through for netCostPerDozen calculation
      expect(summary.totalIncome, 75.0);
    });

    test('high retail price scales consumed value correctly', () {
      final summary = buildEggValueSummary(
        eggCount: 12,
        totalExpenses: 10.0,
        totalIncome: 0.0,
        retailPrice: 9.00,
        eggsSold: 0,
        saleIncome: 0.0,
      );

      // 12 eggs × $0.75/egg = $9.00
      expect(summary.eggProductionValue, closeTo(9.0, 0.01));
    });

    test('netCostPerDozen derived correctly from summary', () {
      final summary = buildEggValueSummary(
        eggCount: 387,
        totalExpenses: 198.0,
        totalIncome: 54.0,
        retailPrice: 9.00,
        eggsSold: 108,
        saleIncome: 54.0,
      );

      // eggsConsumed = 387 - 108 = 279
      expect(summary.eggsConsumed, 279);
      // netCostPerDozen (produced) = (198 - 54) / 387 * 12 = 4.47
      expect(summary.netCostPerDozen, closeTo(4.47, 0.01));
    });

    test('netSavings derived correctly from summary', () {
      final summary = buildEggValueSummary(
        eggCount: 100,
        totalExpenses: 40.0,
        totalIncome: 0.0,
        retailPrice: 6.00,
        eggsSold: 0,
        saleIncome: 0.0,
      );

      // eggProductionValue = 100 × 0.50 = $50
      // netSavings = 50 - 40 = 10
      expect(summary.netSavings, closeTo(10.0, 0.01));
      expect(summary.isBeatingTheStore, true);
    });
  });
}
