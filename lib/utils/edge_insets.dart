import 'package:flutter/material.dart';

/// Extension to easily add system navigation padding to EdgeInsets.
extension EdgeInsetsX on EdgeInsets {
  /// Returns new EdgeInsets with bottom padding increased by system navigation bar height.
  /// Use this for scrollable content to ensure last items aren't behind gesture navigation.
  EdgeInsets withSystemNavigation(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    return copyWith(bottom: bottom + bottomPadding);
  }
}

/// Standard page padding with system navigation bar accounted for.
EdgeInsets pagePadding(BuildContext context) {
  return const EdgeInsets.all(16).withSystemNavigation(context);
}
