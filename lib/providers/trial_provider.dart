import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/iap_service.dart';

/// Trial/license state for the app.
enum LicenseStatus {
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
  final DateTime? installDate;
  final int daysRemaining;
  final bool isLoading;

  const TrialState({
    this.status = LicenseStatus.trialActive,
    this.installDate,
    this.daysRemaining = 14,
    this.isLoading = true,
  });

  TrialState copyWith({
    LicenseStatus? status,
    DateTime? installDate,
    int? daysRemaining,
    bool? isLoading,
  }) {
    return TrialState(
      status: status ?? this.status,
      installDate: installDate ?? this.installDate,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Whether the user can add/edit data.
  bool get canEdit => status != LicenseStatus.trialExpired;

  /// Whether to show the trial banner.
  bool get showTrialBanner =>
      status == LicenseStatus.trialActive || status == LicenseStatus.trialExpired;

  /// Whether to show purchase prompts.
  bool get showPurchasePrompt => status == LicenseStatus.trialExpired;
}

/// Notifier for managing trial/license state.
class TrialNotifier extends Notifier<TrialState> {
  static const int trialDays = 14;
  static const String _keyInstallDate = 'trial_install_date';
  static const String _keyIsPremium = 'trial_is_premium';

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

    // Get or set install date
    final installDateStr = prefs.getString(_keyInstallDate);
    DateTime installDate;

    if (installDateStr != null) {
      installDate = DateTime.parse(installDateStr);
    } else {
      // First launch - set install date
      installDate = DateTime.now();
      await prefs.setString(_keyInstallDate, installDate.toIso8601String());
    }

    // Calculate days remaining
    final daysSinceInstall = DateTime.now().difference(installDate).inDays;
    final daysRemaining = trialDays - daysSinceInstall;

    if (daysRemaining <= 0) {
      state = state.copyWith(
        status: LicenseStatus.trialExpired,
        installDate: installDate,
        daysRemaining: 0,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        status: LicenseStatus.trialActive,
        installDate: installDate,
        daysRemaining: daysRemaining,
        isLoading: false,
      );
    }

    // Set up IAP callbacks
    _setupIAPCallbacks();
  }

  void _setupIAPCallbacks() {
    final iapService = IAPService();
    iapService.onPurchaseStatusChanged = (isPremium) {
      if (isPremium) {
        _setPremium();
      }
    };
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
    final iapService = IAPService();
    await iapService.restorePurchases();
  }

  /// For testing: Reset trial (debug only).
  Future<void> debugResetTrial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyInstallDate);
    await prefs.remove(_keyIsPremium);
    await _initialize();
  }

  /// For testing: Expire trial immediately (debug only).
  Future<void> debugExpireTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final expiredDate = DateTime.now().subtract(const Duration(days: 15));
    await prefs.setString(_keyInstallDate, expiredDate.toIso8601String());
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
