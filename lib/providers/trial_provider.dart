import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/iap_service.dart';

/// Trial/license state for the app.
enum LicenseStatus {
  /// First launch, user hasn't started trial yet.
  firstLaunch,

  /// Trial is active, user has full access.
  trialActive,

  /// Trial has expired, read-only mode.
  trialExpired,

  /// User has purchased premium, full access.
  premium,
}

/// State class for trial/license information.
class TrialState {
  final LicenseStatus status;
  final DateTime? trialStartDate;
  final int daysRemaining;
  final bool isLoading;

  const TrialState({
    this.status = LicenseStatus.firstLaunch,
    this.trialStartDate,
    this.daysRemaining = 14,
    this.isLoading = true,
  });

  TrialState copyWith({
    LicenseStatus? status,
    DateTime? trialStartDate,
    int? daysRemaining,
    bool? isLoading,
  }) {
    return TrialState(
      status: status ?? this.status,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Whether the user can add/edit data.
  bool get canEdit =>
      status != LicenseStatus.trialExpired &&
      status != LicenseStatus.firstLaunch;

  /// Whether to show the trial banner.
  bool get showTrialBanner =>
      status == LicenseStatus.trialActive ||
      status == LicenseStatus.trialExpired;

  /// Whether to show purchase prompts.
  bool get showPurchasePrompt => status == LicenseStatus.trialExpired;
}

/// Notifier for managing trial/license state.
class TrialNotifier extends Notifier<TrialState> {
  static const int trialDays = 14;
  static const String _keyTrialStartDate = 'trial_start_date';
  static const String _keyIsPremium = 'trial_is_premium';
  static const String _keyTrialStarted = 'trial_started';
  // Legacy key from pre-2.1 versions
  static const String _keyLegacyInstallDate = 'trial_install_date';

  @override
  TrialState build() {
    _initialize();
    return const TrialState();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if premium
    final isPremium = prefs.getBool(_keyIsPremium) ?? false;
    if (isPremium) {
      state = state.copyWith(
        status: LicenseStatus.premium,
        isLoading: false,
      );
      return;
    }

    // Check if trial has been started
    var trialStarted = prefs.getBool(_keyTrialStarted) ?? false;

    // Migrate from legacy key (pre-2.1 users already have a trial running)
    if (!trialStarted) {
      final legacyDate = prefs.getString(_keyLegacyInstallDate);
      if (legacyDate != null) {
        trialStarted = true;
        await prefs.setBool(_keyTrialStarted, true);
        await prefs.setString(_keyTrialStartDate, legacyDate);
        await prefs.remove(_keyLegacyInstallDate);
      }
    }

    if (!trialStarted) {
      // First launch — show onboarding
      state = state.copyWith(
        status: LicenseStatus.firstLaunch,
        isLoading: false,
      );
      return;
    }

    // Trial has been started — check dates
    final trialStartStr = prefs.getString(_keyTrialStartDate);
    if (trialStartStr == null) {
      // Trial marked as started but no date — treat as first launch
      state = state.copyWith(
        status: LicenseStatus.firstLaunch,
        isLoading: false,
      );
      return;
    }

    final trialStartDate = DateTime.parse(trialStartStr);
    _updateTrialStatus(trialStartDate);

    // On iOS, also try to restore purchases to pick up trial/premium receipts
    if (Platform.isIOS) {
      _setupIAPCallbacks();
      try {
        await IAPService().restorePurchases();
      } catch (_) {
        // Restore failed — rely on local date
      }
    } else {
      _setupIAPCallbacks();
    }
  }

  void _updateTrialStatus(DateTime trialStartDate) {
    final daysSinceStart = DateTime.now().difference(trialStartDate).inDays;
    final daysRemaining = trialDays - daysSinceStart;

    if (daysRemaining <= 0) {
      state = state.copyWith(
        status: LicenseStatus.trialExpired,
        trialStartDate: trialStartDate,
        daysRemaining: 0,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        status: LicenseStatus.trialActive,
        trialStartDate: trialStartDate,
        daysRemaining: daysRemaining,
        isLoading: false,
      );
    }
  }

  void _setupIAPCallbacks() {
    final iapService = IAPService();
    iapService.onPurchaseStatusChanged = (isPremium) {
      if (isPremium) {
        _setPremium();
      }
    };
    iapService.onTrialActivated = (purchaseDate) {
      _onTrialPurchased(purchaseDate);
    };
  }

  /// Called when user starts the trial (from onboarding dialog).
  /// On iOS, this triggers the Tier 0 IAP purchase.
  /// On Android, it just records the start date locally.
  Future<bool> startTrial() async {
    if (Platform.isIOS) {
      _setupIAPCallbacks();
      final iapService = IAPService();
      final success = await iapService.purchaseTrial();
      if (!success) {
        // If IAP fails (e.g., sandbox issues), fall back to local trial
        await _startLocalTrial();
      }
      return true;
    } else {
      await _startLocalTrial();
      return true;
    }
  }

  /// Start trial using local date (Android, or iOS fallback).
  Future<void> _startLocalTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setBool(_keyTrialStarted, true);
    await prefs.setString(_keyTrialStartDate, now.toIso8601String());
    _updateTrialStatus(now);
  }

  /// Called when the free trial IAP purchase completes (iOS).
  Future<void> _onTrialPurchased(DateTime purchaseDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTrialStarted, true);
    await prefs.setString(
        _keyTrialStartDate, purchaseDate.toIso8601String());
    _updateTrialStatus(purchaseDate);
  }

  /// Called when user purchases premium.
  Future<void> _setPremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, true);

    state = state.copyWith(
      status: LicenseStatus.premium,
    );
  }

  /// Purchase premium.
  Future<bool> purchasePremium() async {
    final iapService = IAPService();
    return iapService.purchasePremium();
  }

  /// Restore purchases.
  Future<void> restorePurchases() async {
    _setupIAPCallbacks();
    final iapService = IAPService();
    await iapService.restorePurchases();
  }

  /// For testing: Reset trial (debug only).
  Future<void> debugResetTrial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTrialStartDate);
    await prefs.remove(_keyIsPremium);
    await prefs.remove(_keyTrialStarted);
    await _initialize();
  }

  /// For testing: Expire trial immediately (debug only).
  Future<void> debugExpireTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final expiredDate = DateTime.now().subtract(const Duration(days: 15));
    await prefs.setBool(_keyTrialStarted, true);
    await prefs.setString(_keyTrialStartDate, expiredDate.toIso8601String());
    await prefs.remove(_keyIsPremium);
    await _initialize();
  }

  /// For testing: Grant premium (debug only).
  Future<void> debugGrantPremium() async {
    await _setPremium();
  }
}

/// Provider for trial state.
final trialProvider = NotifierProvider<TrialNotifier, TrialState>(() {
  return TrialNotifier();
});

/// Convenience provider for checking if user can edit.
final canEditProvider = Provider<bool>((ref) {
  final trial = ref.watch(trialProvider);
  return trial.canEdit;
});

/// Convenience provider for license status.
final licenseStatusProvider = Provider<LicenseStatus>((ref) {
  final trial = ref.watch(trialProvider);
  return trial.status;
});
