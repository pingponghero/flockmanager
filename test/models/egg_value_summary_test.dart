import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/egg_value_summary.dart';

void main() {
  group('EggValueSummary', () {
    test('netSavings is eggProductionValue minus totalExpenses', () {
      final summary = EggValueSummary(
        eggCount: 30,
        eggProductionValue: 11.25, // 30 * (4.50 / 12)
        totalExpenses: 8.00,
        totalIncome: 0,
        retailPricePerDozen: 4.50,
      );

      expect(summary.netSavings, closeTo(3.25, 0.001));
    });

    test('isBeatingTheStore is true when netSavings >= 0', () {
      final summary = EggValueSummary(
        eggCount: 30,
        eggProductionValue: 11.25,
        totalExpenses: 8.00,
        totalIncome: 0,
        retailPricePerDozen: 4.50,
      );

      expect(summary.isBeatingTheStore, isTrue);
    });

    test('isBeatingTheStore is true when netSavings is exactly 0', () {
      final summary = EggValueSummary(
        eggCount: 30,
        eggProductionValue: 8.00,
        totalExpenses: 8.00,
        totalIncome: 0,
        retailPricePerDozen: 4.50,
      );

      expect(summary.isBeatingTheStore, isTrue);
    });

    test('isBeatingTheStore is false when netSavings < 0', () {
      final summary = EggValueSummary(
        eggCount: 30,
        eggProductionValue: 11.25,
        totalExpenses: 15.00,
        totalIncome: 0,
        retailPricePerDozen: 4.50,
      );

      expect(summary.isBeatingTheStore, isFalse);
      expect(summary.netSavings, closeTo(-3.75, 0.001));
    });

    test('costPerEgg returns null when eggCount is 0', () {
      final summary = EggValueSummary(
        eggCount: 0,
        eggProductionValue: 0,
        totalExpenses: 10.00,
        totalIncome: 0,
        retailPricePerDozen: 4.50,
      );

      expect(summary.costPerEgg, isNull);
    });

    test('costPerEgg calculates correctly', () {
      final summary = EggValueSummary(
        eggCount: 30,
        eggProductionValue: 11.25,
        totalExpenses: 8.00,
        totalIncome: 0,
        retailPricePerDozen: 4.50,
      );

      // 8.00 / 30 = 0.2667
      expect(summary.costPerEgg, closeTo(0.2667, 0.001));
    });

    test('retailPricePerEgg is retailPricePerDozen / 12', () {
      final summary = EggValueSummary(
        eggCount: 30,
        eggProductionValue: 11.25,
        totalExpenses: 8.00,
        totalIncome: 0,
        retailPricePerDozen: 4.50,
      );

      expect(summary.retailPricePerEgg, closeTo(0.375, 0.001));
    });

    test('cashFlow is totalIncome minus totalExpenses', () {
      final summary = EggValueSummary(
        eggCount: 30,
        eggProductionValue: 11.25,
        totalExpenses: 8.00,
        totalIncome: 5.00,
        retailPricePerDozen: 4.50,
      );

      expect(summary.cashFlow, closeTo(-3.00, 0.001));
    });

    test('cashFlow is positive when income exceeds expenses', () {
      final summary = EggValueSummary(
        eggCount: 100,
        eggProductionValue: 37.50,
        totalExpenses: 20.00,
        totalIncome: 30.00,
        retailPricePerDozen: 4.50,
      );

      expect(summary.cashFlow, closeTo(10.00, 0.001));
    });

    test('eggsConsumed is eggCount minus eggsSold', () {
      final summary = EggValueSummary(
        eggCount: 150,
        eggProductionValue: 58.75,
        totalExpenses: 38.00,
        totalIncome: 7.00,
        retailPricePerDozen: 4.50,
        eggsSold: 12,
      );

      expect(summary.eggsConsumed, 138);
    });

    test('netCostPerDozen returns null when no eggs produced', () {
      const summary = EggValueSummary(
        eggCount: 0,
        eggProductionValue: 0,
        totalExpenses: 30.00,
        totalIncome: 0,
        retailPricePerDozen: 4.50,
      );

      expect(summary.netCostPerDozen, isNull);
    });

    test('netCostPerDozen is (expenses - income) / eggCount * 12 (produced)', () {
      // 150 eggs produced, 12 sold for $7, $38 expenses, $4.50/dz
      // netCostPerDozen = (38 - 7) / 150 * 12 = 31 / 150 * 12 = $2.48
      final summary = EggValueSummary(
        eggCount: 150,
        eggProductionValue: 58.75,
        totalExpenses: 38.00,
        totalIncome: 7.00,
        retailPricePerDozen: 4.50,
        eggsSold: 12,
      );

      expect(summary.netCostPerDozen, closeTo(2.48, 0.001));
    });

    test('netCostPerDozen is independent of how eggs are distributed', () {
      // Same production/expenses/income; gifting more must not change it.
      const base = EggValueSummary(
        eggCount: 150,
        eggProductionValue: 0,
        totalExpenses: 38.00,
        totalIncome: 7.00,
        retailPricePerDozen: 4.50,
        eggsSold: 12,
      );
      final gifted = EggValueSummary(
        eggCount: base.eggCount,
        eggProductionValue: 0,
        totalExpenses: base.totalExpenses,
        totalIncome: base.totalIncome,
        retailPricePerDozen: base.retailPricePerDozen,
        eggsSold: base.eggsSold,
        eggsGifted: 100,
      );

      expect(gifted.netCostPerDozen, closeTo(base.netCostPerDozen!, 0.001));
    });

    test('netCostPerDozen can be negative when income exceeds expenses', () {
      // 100 eggs produced, 50 sold for $30, $20 expenses
      // netCostPerDozen = (20 - 30) / 100 * 12 = -10 / 100 * 12 = -$1.20
      final summary = EggValueSummary(
        eggCount: 100,
        eggProductionValue: 48.75,
        totalExpenses: 20.00,
        totalIncome: 30.00,
        retailPricePerDozen: 4.50,
        eggsSold: 50,
      );

      expect(summary.netCostPerDozen, closeTo(-1.20, 0.001));
    });

    test('netCostPerDozen with no income equals gross cost per dozen', () {
      // 120 eggs, 0 sold, $30 expenses
      // netCostPerDozen = (30 - 0) / 120 * 12 = $3.00
      final summary = EggValueSummary(
        eggCount: 120,
        eggProductionValue: 45.00,
        totalExpenses: 30.00,
        totalIncome: 0,
        retailPricePerDozen: 4.50,
        eggsSold: 0,
      );

      expect(summary.netCostPerDozen, closeTo(3.00, 0.001));
      // Should equal costPerEgg * 12 when no income
      expect(summary.netCostPerDozen, closeTo(summary.costPerEgg! * 12, 0.001));
    });
  });

  // =======================================================
  // Valuation formula tests
  //
  // These replicate _buildSummary logic:
  //   consumedValue = (eggCount - eggsSold) × (retailPrice / 12)
  //   eggProductionValue = consumedValue + saleIncome
  //   netSavings = eggProductionValue - totalExpenses
  // =======================================================

  group('Valuation: all consumed (no sales)', () {
    // User eats every egg — pure consumer.
    // 150 eggs, 0 sold, $38 expenses, $4.50/dz
    // Value: 150 × $0.375 = $56.25
    // Net: $56.25 − $38 = +$18.25
    test('all eggs valued at store price', () {
      const retailPrice = 4.50;
      const eggCount = 150;
      const eggsSold = 0;
      const saleIncome = 0.0;
      const totalExpenses = 38.0;

      final consumedValue = (eggCount - eggsSold) * (retailPrice / 12);
      final eggProductionValue = consumedValue + saleIncome;

      final summary = EggValueSummary(
        eggCount: eggCount,
        eggProductionValue: eggProductionValue,
        totalExpenses: totalExpenses,
        totalIncome: 0,
        retailPricePerDozen: retailPrice,
        eggsSold: eggsSold,
      );

      expect(summary.eggProductionValue, closeTo(56.25, 0.001));
      expect(summary.netSavings, closeTo(18.25, 0.001));
      expect(summary.isBeatingTheStore, isTrue);
      expect(summary.eggsConsumed, 150);
      expect(summary.eggsSold, 0);
    });

    test('consumer operating at a loss', () {
      // 24 eggs, 0 sold, $50 expenses (coop build), $4.50/dz
      // Value: 24 × $0.375 = $9.00
      // Net: $9.00 − $50 = −$41.00
      const retailPrice = 4.50;
      const eggCount = 24;
      const totalExpenses = 50.0;

      final eggProductionValue = eggCount * (retailPrice / 12);

      final summary = EggValueSummary(
        eggCount: eggCount,
        eggProductionValue: eggProductionValue,
        totalExpenses: totalExpenses,
        totalIncome: 0,
        retailPricePerDozen: retailPrice,
        eggsSold: 0,
      );

      expect(summary.eggProductionValue, closeTo(9.00, 0.001));
      expect(summary.netSavings, closeTo(-41.00, 0.001));
      expect(summary.isBeatingTheStore, isFalse);
      expect(summary.eggsConsumed, 24);
    });
  });

  group('Valuation: all sold', () {
    // User sells every egg — pure seller.
    // 120 eggs, all 120 sold for $48, $30 expenses, $4.50/dz
    // Consumed: 0 × $0.375 = $0
    // Sale value: $48
    // Total value: $48
    // Net: $48 − $30 = +$18
    test('all eggs valued at actual sale price', () {
      const retailPrice = 4.50;
      const eggCount = 120;
      const eggsSold = 120;
      const saleIncome = 48.0;
      const totalExpenses = 30.0;

      final consumedValue = (eggCount - eggsSold) * (retailPrice / 12);
      final eggProductionValue = consumedValue + saleIncome;

      final summary = EggValueSummary(
        eggCount: eggCount,
        eggProductionValue: eggProductionValue,
        totalExpenses: totalExpenses,
        totalIncome: saleIncome,
        retailPricePerDozen: retailPrice,
        eggsSold: eggsSold,
      );

      expect(summary.eggProductionValue, closeTo(48.00, 0.001));
      expect(summary.netSavings, closeTo(18.00, 0.001));
      expect(summary.isBeatingTheStore, isTrue);
      expect(summary.eggsConsumed, 0);
      expect(summary.eggsSold, 120);
    });

    test('seller pricing below retail sees lower value than naive approach', () {
      // 120 eggs, all sold at $3/dz = $30, $25 expenses, $4.50/dz
      // Naive (all at store): 120 × $0.375 = $45
      // Actual: $30 (sale value)
      // Net: $30 − $25 = +$5 (not $20 the naive approach would show)
      const retailPrice = 4.50;
      const eggCount = 120;
      const eggsSold = 120;
      const saleIncome = 30.0; // $3/dz = below retail
      const totalExpenses = 25.0;

      final naiveValue = eggCount * (retailPrice / 12);
      final consumedValue = (eggCount - eggsSold) * (retailPrice / 12);
      final eggProductionValue = consumedValue + saleIncome;

      final summary = EggValueSummary(
        eggCount: eggCount,
        eggProductionValue: eggProductionValue,
        totalExpenses: totalExpenses,
        totalIncome: saleIncome,
        retailPricePerDozen: retailPrice,
        eggsSold: eggsSold,
      );

      // Naive would have been $45
      expect(naiveValue, closeTo(45.00, 0.001));
      // Actual is $30 — correctly lower
      expect(summary.eggProductionValue, closeTo(30.00, 0.001));
      expect(summary.netSavings, closeTo(5.00, 0.001));
    });

    test('seller pricing above retail sees higher value than naive approach', () {
      // 120 eggs, all sold at $7/dz = $70, $25 expenses, $4.50/dz
      // Naive: 120 × $0.375 = $45
      // Actual: $70
      // Net: $70 − $25 = +$45
      const retailPrice = 4.50;
      const eggCount = 120;
      const eggsSold = 120;
      const saleIncome = 70.0; // $7/dz = above retail
      const totalExpenses = 25.0;

      final naiveValue = eggCount * (retailPrice / 12);
      final consumedValue = (eggCount - eggsSold) * (retailPrice / 12);
      final eggProductionValue = consumedValue + saleIncome;

      final summary = EggValueSummary(
        eggCount: eggCount,
        eggProductionValue: eggProductionValue,
        totalExpenses: totalExpenses,
        totalIncome: saleIncome,
        retailPricePerDozen: retailPrice,
        eggsSold: eggsSold,
      );

      // Naive would have been $45
      expect(naiveValue, closeTo(45.00, 0.001));
      // Actual is $70 — correctly higher
      expect(summary.eggProductionValue, closeTo(70.00, 0.001));
      expect(summary.netSavings, closeTo(45.00, 0.001));
    });
  });

  group('Valuation: mixed (some sold, some consumed)', () {
    test('user spec example: 150 eggs, 12 sold for \$7', () {
      // 150 eggs, 12 sold for $7, $38 expenses, $4.50/dz
      // Consumed: 138 × $0.375 = $51.75
      // Sold: $7.00
      // Total value: $58.75
      // Net: $58.75 − $38 = +$20.75
      const retailPrice = 4.50;
      const eggCount = 150;
      const eggsSold = 12;
      const saleIncome = 7.0;
      const totalExpenses = 38.0;

      final consumedValue = (eggCount - eggsSold) * (retailPrice / 12);
      final eggProductionValue = consumedValue + saleIncome;

      final summary = EggValueSummary(
        eggCount: eggCount,
        eggProductionValue: eggProductionValue,
        totalExpenses: totalExpenses,
        totalIncome: saleIncome,
        retailPricePerDozen: retailPrice,
        eggsSold: eggsSold,
      );

      expect(summary.eggProductionValue, closeTo(58.75, 0.001));
      expect(summary.netSavings, closeTo(20.75, 0.001));
      expect(summary.isBeatingTheStore, isTrue);
      expect(summary.eggsConsumed, 138);
      expect(summary.eggsSold, 12);
    });

    test('mixed with above-retail sale price boosts value vs naive', () {
      // 100 eggs, 24 sold for $14 ($7/dz), $20 expenses, $4.50/dz
      // Consumed: 76 × $0.375 = $28.50
      // Sold: $14.00
      // Total value: $42.50
      // Naive: 100 × $0.375 = $37.50 — undervalues by $5
      const retailPrice = 4.50;
      const eggCount = 100;
      const eggsSold = 24;
      const saleIncome = 14.0;
      const totalExpenses = 20.0;

      final naiveValue = eggCount * (retailPrice / 12);
      final consumedValue = (eggCount - eggsSold) * (retailPrice / 12);
      final eggProductionValue = consumedValue + saleIncome;

      final summary = EggValueSummary(
        eggCount: eggCount,
        eggProductionValue: eggProductionValue,
        totalExpenses: totalExpenses,
        totalIncome: saleIncome,
        retailPricePerDozen: retailPrice,
        eggsSold: eggsSold,
      );

      expect(naiveValue, closeTo(37.50, 0.001));
      expect(summary.eggProductionValue, closeTo(42.50, 0.001));
      expect(summary.netSavings, closeTo(22.50, 0.001));
    });

    test('mixed with below-retail sale price lowers value vs naive', () {
      // 100 eggs, 24 sold for $6 ($3/dz), $20 expenses, $4.50/dz
      // Consumed: 76 × $0.375 = $28.50
      // Sold: $6.00
      // Total value: $34.50
      // Naive: 100 × $0.375 = $37.50 — overvalues by $3
      const retailPrice = 4.50;
      const eggCount = 100;
      const eggsSold = 24;
      const saleIncome = 6.0;
      const totalExpenses = 20.0;

      final naiveValue = eggCount * (retailPrice / 12);
      final consumedValue = (eggCount - eggsSold) * (retailPrice / 12);
      final eggProductionValue = consumedValue + saleIncome;

      final summary = EggValueSummary(
        eggCount: eggCount,
        eggProductionValue: eggProductionValue,
        totalExpenses: totalExpenses,
        totalIncome: saleIncome,
        retailPricePerDozen: retailPrice,
        eggsSold: eggsSold,
      );

      expect(naiveValue, closeTo(37.50, 0.001));
      expect(summary.eggProductionValue, closeTo(34.50, 0.001));
      expect(summary.netSavings, closeTo(14.50, 0.001));
    });
  });

  group('Valuation: edge cases', () {
    test('income without egg count — eggs stay at store price, income is additive', () {
      // 100 eggs, 0 eggs sold (income has no egg_count), $15 income, $30 expenses
      // All eggs at store price: 100 × $0.375 = $37.50
      // saleIncome = $0 (no egg_count means eggsSold = 0, saleIncome = 0)
      // The $15 income shows up in totalIncome/cashFlow but NOT in eggProductionValue
      const retailPrice = 4.50;
      const eggCount = 100;
      const eggsSold = 0; // no egg_count on the income record
      const saleIncome = 0.0; // excluded since no egg_count
      const totalIncome = 15.0; // still tracked for cashFlow
      const totalExpenses = 30.0;

      final eggProductionValue = eggCount * (retailPrice / 12) + saleIncome;

      final summary = EggValueSummary(
        eggCount: eggCount,
        eggProductionValue: eggProductionValue,
        totalExpenses: totalExpenses,
        totalIncome: totalIncome,
        retailPricePerDozen: retailPrice,
        eggsSold: eggsSold,
      );

      // Egg value is purely store-priced
      expect(summary.eggProductionValue, closeTo(37.50, 0.001));
      expect(summary.netSavings, closeTo(7.50, 0.001));
      // Cash flow reflects the actual income
      expect(summary.cashFlow, closeTo(-15.00, 0.001));
      expect(summary.eggsConsumed, 100);
    });

    test('zero eggs with expenses — net savings is negative', () {
      const summary = EggValueSummary(
        eggCount: 0,
        eggProductionValue: 0,
        totalExpenses: 50.0,
        totalIncome: 0,
        retailPricePerDozen: 4.50,
        eggsSold: 0,
      );

      expect(summary.eggProductionValue, 0);
      expect(summary.netSavings, closeTo(-50.00, 0.001));
      expect(summary.isBeatingTheStore, isFalse);
      expect(summary.eggsConsumed, 0);
      expect(summary.costPerEgg, isNull);
    });

    test('zero eggs zero expenses — completely empty period', () {
      const summary = EggValueSummary(
        eggCount: 0,
        eggProductionValue: 0,
        totalExpenses: 0,
        totalIncome: 0,
        retailPricePerDozen: 4.50,
        eggsSold: 0,
      );

      expect(summary.netSavings, 0);
      expect(summary.isBeatingTheStore, isTrue);
      expect(summary.eggsConsumed, 0);
    });

    test('eggsSold defaults to 0 when not provided', () {
      const summary = EggValueSummary(
        eggCount: 50,
        eggProductionValue: 18.75,
        totalExpenses: 10.0,
        totalIncome: 0,
        retailPricePerDozen: 4.50,
      );

      expect(summary.eggsSold, 0);
      expect(summary.eggsConsumed, 50);
    });

    test('different retail prices change valuation', () {
      // Same eggs, different store price: $6/dz organic
      const retailPrice = 6.00;
      const eggCount = 100;
      const eggsSold = 0;
      const totalExpenses = 30.0;

      final eggProductionValue = eggCount * (retailPrice / 12);

      final summary = EggValueSummary(
        eggCount: eggCount,
        eggProductionValue: eggProductionValue,
        totalExpenses: totalExpenses,
        totalIncome: 0,
        retailPricePerDozen: retailPrice,
        eggsSold: eggsSold,
      );

      // 100 × $0.50 = $50
      expect(summary.eggProductionValue, closeTo(50.00, 0.001));
      expect(summary.netSavings, closeTo(20.00, 0.001));
      expect(summary.retailPricePerEgg, closeTo(0.50, 0.001));
    });
  });
}
