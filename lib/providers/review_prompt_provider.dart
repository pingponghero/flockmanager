import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/review_prompt_service.dart';
import 'egg_provider.dart';
import 'trial_provider.dart';

const _keyFirstOpenDate = 'review_first_open_date';
const _keyOpenDayCount = 'review_open_day_count';
const _keyLastOpenDay = 'review_last_open_day';
const _keyLastPromptDate = 'review_last_prompt_date';
const _keyLastPromptVersion = 'review_last_prompt_version';

/// Days the app must have been installed before we ask for a review.
const reviewMinDaysSinceFirstOpen = 3;

/// Distinct days the app must have been opened on.
const reviewMinOpenDays = 5;

/// Distinct days the user must have logged eggs on.
const reviewMinLoggedDays = 5;

/// Minimum gap between prompts. The OS throttles harder than this, but we
/// avoid burning an OS-level slot on a user who already saw the sheet.
const reviewPromptCooldownDays = 90;

/// Whether the user has earned a review prompt.
///
/// Pure so the gate can be tested without prefs or a database.
bool isEligibleForReviewPrompt({
  required DateTime now,
  required DateTime? firstOpenDate,
  required int openDayCount,
  required int loggedDayCount,
  required DateTime? lastPromptDate,
  required String? lastPromptVersion,
  required String currentVersion,
  required LicenseStatus licenseStatus,
}) {
  // Onboarding not finished, or the user is staring at a paywall — both are
  // bad moments to ask, and Apple rejects review prompts tied to purchases.
  if (licenseStatus == LicenseStatus.firstLaunch ||
      licenseStatus == LicenseStatus.trialExpired) {
    return false;
  }

  if (firstOpenDate == null) return false;
  if (now.difference(firstOpenDate).inDays < reviewMinDaysSinceFirstOpen) {
    return false;
  }

  if (openDayCount < reviewMinOpenDays) return false;
  if (loggedDayCount < reviewMinLoggedDays) return false;

  if (lastPromptDate != null) {
    if (now.difference(lastPromptDate).inDays < reviewPromptCooldownDays) {
      return false;
    }
    // Re-asking is only reasonable once there is something new to rate.
    if (lastPromptVersion == currentVersion) return false;
  }

  return true;
}

/// Tracks engagement and asks for a store review at a good moment.
///
/// State is whether we already prompted this session — one ask per launch,
/// no matter how many positive moments happen.
class ReviewPromptNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Record that the app was opened, counting distinct calendar days.
  /// Call once per session.
  Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dayKey(DateTime.now());

    if (prefs.getString(_keyFirstOpenDate) == null) {
      await prefs.setString(
          _keyFirstOpenDate, DateTime.now().toIso8601String());
    }

    if (prefs.getString(_keyLastOpenDay) == today) return;

    await prefs.setString(_keyLastOpenDay, today);
    await prefs.setInt(
        _keyOpenDayCount, (prefs.getInt(_keyOpenDayCount) ?? 0) + 1);
  }

  /// Ask for a review if the user has earned it. Safe to call from any
  /// positive moment — the gate and the session flag handle the rest.
  ///
  /// Returns whether a request was sent to the OS.
  Future<bool> maybePromptForReview() async {
    if (state) return false;

    final prefs = await SharedPreferences.getInstance();
    final firstOpen = prefs.getString(_keyFirstOpenDate);
    final lastPrompt = prefs.getString(_keyLastPromptDate);

    final eligible = isEligibleForReviewPrompt(
      now: DateTime.now(),
      firstOpenDate: firstOpen != null ? DateTime.tryParse(firstOpen) : null,
      openDayCount: prefs.getInt(_keyOpenDayCount) ?? 0,
      loggedDayCount:
          await ref.read(eggRepositoryProvider).getDistinctLogDays(),
      lastPromptDate: lastPrompt != null ? DateTime.tryParse(lastPrompt) : null,
      lastPromptVersion: prefs.getString(_keyLastPromptVersion),
      currentVersion: await _currentVersion(),
      licenseStatus: ref.read(licenseStatusProvider),
    );

    if (!eligible) return false;

    return _requestAndRecord();
  }

  Future<bool> _requestAndRecord() async {
    final requested = await ReviewPromptService().requestReview();
    if (!requested) return false;

    // Record even though we can't tell whether the sheet rendered — the OS
    // may have consumed a slot, so treat it as asked either way.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastPromptDate, DateTime.now().toIso8601String());
    await prefs.setString(_keyLastPromptVersion, await _currentVersion());
    state = true;
    return true;
  }

  /// Open the store listing directly (Settings → "Rate Flock Manager").
  Future<void> openStoreListing() => ReviewPromptService().openStoreListing();

  Future<String> _currentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return 'unknown';
    }
  }

  String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Debug only: request the sheet regardless of eligibility.
  ///
  /// The OS still throttles it, and iOS shows nothing at all in TestFlight or
  /// debug builds — verify on a real App Store / Play build.
  Future<bool> debugForcePrompt() => _requestAndRecord();

  /// Debug only: wipe all review-prompt tracking.
  Future<void> debugResetReviewPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstOpenDate);
    await prefs.remove(_keyOpenDayCount);
    await prefs.remove(_keyLastOpenDay);
    await prefs.remove(_keyLastPromptDate);
    await prefs.remove(_keyLastPromptVersion);
    state = false;
  }
}

/// Provider for review-prompt tracking. State is "already prompted this
/// session".
final reviewPromptProvider =
    NotifierProvider<ReviewPromptNotifier, bool>(ReviewPromptNotifier.new);
