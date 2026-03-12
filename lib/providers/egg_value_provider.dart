import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/egg_value_summary.dart';
import 'egg_provider.dart';
import 'expense_provider.dart';
import 'flock_provider.dart';

// ==================== RETAIL PRICE SETTING ====================

const _retailPriceKey = 'retail_price_per_dozen';
const _defaultRetailPrice = 4.50;

/// Notifier for user-configured retail egg price per dozen.
class RetailPriceNotifier extends Notifier<double> {
  @override
  double build() {
    _loadSavedPrice();
    return _defaultRetailPrice;
  }

  Future<void> _loadSavedPrice() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_retailPriceKey);
    if (saved != null) state = saved;
  }

  Future<void> setPrice(double price) async {
    state = price;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_retailPriceKey, price);
  }
}

final retailPricePerDozenProvider =
    NotifierProvider<RetailPriceNotifier, double>(RetailPriceNotifier.new);

// ==================== EGG VALUE PROVIDERS ====================

/// Compute egg production value using actual sale prices for sold eggs
/// and store price for consumed eggs.
///
/// Total Value = consumed value + sale value
///   consumed = (totalEggs − eggsSold) × storePrice/egg
///   saleValue = actual income from sales with egg counts
///
/// Income without egg_count is additive cash — those eggs stay at store price.
/// Visible for testing. Builds an [EggValueSummary] from raw query results.
EggValueSummary buildEggValueSummary({
  required int eggCount,
  required double totalExpenses,
  required double totalIncome,
  required double retailPrice,
  required int eggsSold,
  required double saleIncome,
}) {
  final retailPerEgg = retailPrice / 12;
  final eggsConsumed = (eggCount - eggsSold).clamp(0, eggCount);
  final consumedValue = eggsConsumed * retailPerEgg;
  final eggProductionValue = consumedValue + saleIncome;

  return EggValueSummary(
    eggCount: eggCount,
    eggProductionValue: eggProductionValue,
    totalExpenses: totalExpenses,
    totalIncome: totalIncome,
    retailPricePerDozen: retailPrice,
    eggsSold: eggsSold,
  );
}

/// Egg value summary for the selected finance date range.
/// Respects the selected flock filter.
final selectedRangeEggValueProvider =
    FutureProvider<EggValueSummary>((ref) async {
  final repository = ref.read(financeRepositoryProvider);
  final eggRepository = ref.read(eggRepositoryProvider);
  final range = ref.watch(financeDateRangeProvider);
  final retailPrice = ref.watch(retailPricePerDozenProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final (start, end) = range.dates;

  final double totalExpenses;
  final double totalIncome;
  final int eggCount;
  final (int, double) salesData;

  if (selectedFlockId == null) {
    totalExpenses = await repository.getTotalExpenses(start, end);
    totalIncome = await repository.getTotalIncome(start, end);
    eggCount = await eggRepository.getEggCountByDateRange(start, end);
    salesData = await repository.getEggSalesData(start, end);
  } else {
    totalExpenses =
        await repository.getTotalExpensesByFlock(selectedFlockId, start, end);
    totalIncome =
        await repository.getTotalIncomeByFlock(selectedFlockId, start, end);
    eggCount = await eggRepository.getEggCountByFlockAndDateRange(
        selectedFlockId, start, end);
    salesData =
        await repository.getEggSalesDataByFlock(selectedFlockId, start, end);
  }

  final (eggsSold, saleIncome) = salesData;

  return buildEggValueSummary(
    eggCount: eggCount,
    totalExpenses: totalExpenses,
    totalIncome: totalIncome,
    retailPrice: retailPrice,
    eggsSold: eggsSold,
    saleIncome: saleIncome,
  );
});

/// Egg value summary for the current month (used on home screen).
/// Respects the selected flock filter.
final monthEggValueProvider = FutureProvider<EggValueSummary>((ref) async {
  final repository = ref.read(financeRepositoryProvider);
  final eggRepository = ref.read(eggRepositoryProvider);
  final retailPrice = ref.watch(retailPricePerDozenProvider);
  final selectedFlockId = ref.watch(selectedFlockIdProvider);

  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final double totalExpenses;
  final double totalIncome;
  final int eggCount;
  final (int, double) salesData;

  if (selectedFlockId == null) {
    totalExpenses = await repository.getTotalExpenses(start, end);
    totalIncome = await repository.getTotalIncome(start, end);
    eggCount = await eggRepository.getEggCountByDateRange(start, end);
    salesData = await repository.getEggSalesData(start, end);
  } else {
    totalExpenses =
        await repository.getTotalExpensesByFlock(selectedFlockId, start, end);
    totalIncome =
        await repository.getTotalIncomeByFlock(selectedFlockId, start, end);
    eggCount = await eggRepository.getEggCountByFlockAndDateRange(
        selectedFlockId, start, end);
    salesData =
        await repository.getEggSalesDataByFlock(selectedFlockId, start, end);
  }

  final (eggsSold, saleIncome) = salesData;

  return buildEggValueSummary(
    eggCount: eggCount,
    totalExpenses: totalExpenses,
    totalIncome: totalIncome,
    retailPrice: retailPrice,
    eggsSold: eggsSold,
    saleIncome: saleIncome,
  );
});

/// Egg value summary for all time (used for home screen cost per dozen).
final allTimeEggValueProvider = FutureProvider<EggValueSummary>((ref) async {
  final repository = ref.read(financeRepositoryProvider);
  final eggRepository = ref.read(eggRepositoryProvider);
  final retailPrice = ref.watch(retailPricePerDozenProvider);

  final totalExpenses = await repository.getTotalExpensesAllTime();
  final totalIncome = await repository.getTotalIncomeAllTime();
  final eggCount = await eggRepository.getTotalEggCount();
  final salesData = await repository.getEggSalesDataAllTime();
  final (eggsSold, saleIncome) = salesData;

  return buildEggValueSummary(
    eggCount: eggCount,
    totalExpenses: totalExpenses,
    totalIncome: totalIncome,
    retailPrice: retailPrice,
    eggsSold: eggsSold,
    saleIncome: saleIncome,
  );
});

/// Whether the user has ever logged any income (for conditional UI display).
final hasEverLoggedIncomeProvider = FutureProvider<bool>((ref) async {
  final incomeList = await ref.watch(incomeProvider.future);
  return incomeList.isNotEmpty;
});
