import 'package:flutter/material.dart';

/// Shows a snackbar that can be dismissed by tapping anywhere on it
/// (except the action button). Clears any existing snackbar first.
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
  Color? backgroundColor,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => messenger.hideCurrentSnackBar(),
        child: Text(message),
      ),
      action: actionLabel != null
          ? SnackBarAction(label: actionLabel, onPressed: onAction ?? () {})
          : null,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      backgroundColor: backgroundColor,
    ),
  );
}

/// Shows a friendly failure message in an error-coloured snackbar and logs
/// the underlying [error] instead of displaying it (#57).
void showErrorSnackBar(BuildContext context, String message, Object error) {
  debugPrint('$message: $error');
  showAppSnackBar(
    context,
    message,
    backgroundColor: Theme.of(context).colorScheme.error,
  );
}
