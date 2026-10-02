import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

/// Service wrapping the native store review sheet.
///
/// Uses `SKStoreReviewController` on iOS and the Play In-App Review API on
/// Android. Both are throttled by the OS and may silently show nothing, so
/// never gate app behaviour on a prompt actually appearing.
class ReviewPromptService {
  static final ReviewPromptService _instance = ReviewPromptService._internal();
  factory ReviewPromptService() => _instance;
  ReviewPromptService._internal();

  /// App Store ID, required to open the iOS store listing directly.
  static const String appStoreId = '6758640804';

  InAppReview _inAppReview = InAppReview.instance;

  /// Swap the underlying plugin (tests only).
  @visibleForTesting
  set inAppReview(InAppReview value) => _inAppReview = value;

  /// Whether the platform can show the native review sheet.
  Future<bool> isAvailable() async {
    try {
      return await _inAppReview.isAvailable();
    } catch (_) {
      // Plugin missing or store unreachable — treat as unavailable.
      return false;
    }
  }

  /// Ask the OS to show the review sheet.
  ///
  /// Returns whether the request was made, *not* whether a sheet appeared —
  /// the OS decides that and gives no feedback either way.
  Future<bool> requestReview() async {
    try {
      if (!await isAvailable()) return false;
      await _inAppReview.requestReview();
      return true;
    } catch (e) {
      debugPrint('Review request failed: $e');
      return false;
    }
  }

  /// Open the store listing so the user can leave a review manually.
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(appStoreId: appStoreId);
    } catch (e) {
      debugPrint('Opening store listing failed: $e');
    }
  }
}
