import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/providers/review_prompt_provider.dart';
import 'package:flock_manager/providers/trial_provider.dart';

void main() {
  final now = DateTime(2026, 8, 10);

  /// An engaged, happy user who has never been prompted.
  bool check({
    DateTime? firstOpenDate,
    bool noFirstOpen = false,
    int openDayCount = 10,
    int loggedDayCount = 10,
    DateTime? lastPromptDate,
    String? lastPromptVersion,
    String currentVersion = '2.5.0',
    LicenseStatus licenseStatus = LicenseStatus.premium,
  }) {
    return isEligibleForReviewPrompt(
      now: now,
      firstOpenDate: noFirstOpen
          ? null
          : firstOpenDate ?? now.subtract(const Duration(days: 30)),
      openDayCount: openDayCount,
      loggedDayCount: loggedDayCount,
      lastPromptDate: lastPromptDate,
      lastPromptVersion: lastPromptVersion,
      currentVersion: currentVersion,
      licenseStatus: licenseStatus,
    );
  }

  group('isEligibleForReviewPrompt', () {
    test('allows an engaged user who has never been prompted', () {
      expect(check(), isTrue);
    });

    test('allows an active trial user', () {
      expect(check(licenseStatus: LicenseStatus.trialActive), isTrue);
    });

    test('blocks before onboarding is finished', () {
      expect(check(licenseStatus: LicenseStatus.firstLaunch), isFalse);
    });

    test('blocks an expired trial (user is facing a paywall)', () {
      expect(check(licenseStatus: LicenseStatus.trialExpired), isFalse);
    });

    test('blocks when the install is too fresh', () {
      expect(
        check(firstOpenDate: now.subtract(const Duration(days: 2))),
        isFalse,
      );
      expect(
        check(firstOpenDate: now.subtract(const Duration(days: 3))),
        isTrue,
      );
    });

    test('blocks when first-open date was never recorded', () {
      expect(check(noFirstOpen: true), isFalse);
    });

    test('blocks below the open-day threshold', () {
      expect(check(openDayCount: reviewMinOpenDays - 1), isFalse);
      expect(check(openDayCount: reviewMinOpenDays), isTrue);
    });

    test('blocks below the logged-day threshold', () {
      expect(check(loggedDayCount: reviewMinLoggedDays - 1), isFalse);
      expect(check(loggedDayCount: reviewMinLoggedDays), isTrue);
    });

    test('blocks inside the cooldown window', () {
      expect(
        check(
          lastPromptDate: now.subtract(const Duration(days: 30)),
          lastPromptVersion: '2.0.0',
        ),
        isFalse,
      );
    });

    test('blocks after cooldown when still on the prompted version', () {
      expect(
        check(
          lastPromptDate: now.subtract(const Duration(days: 200)),
          lastPromptVersion: '2.5.0',
        ),
        isFalse,
      );
    });

    test('allows after cooldown on a newer version', () {
      expect(
        check(
          lastPromptDate: now.subtract(const Duration(days: 200)),
          lastPromptVersion: '2.0.0',
        ),
        isTrue,
      );
    });

    test('allows once cooldown elapses exactly', () {
      expect(
        check(
          lastPromptDate:
              now.subtract(const Duration(days: reviewPromptCooldownDays)),
          lastPromptVersion: '2.0.0',
        ),
        isTrue,
      );
    });

    test('a brand new user fails every gate', () {
      expect(
        check(
          firstOpenDate: now,
          openDayCount: 1,
          loggedDayCount: 0,
          licenseStatus: LicenseStatus.firstLaunch,
        ),
        isFalse,
      );
    });
  });
}
