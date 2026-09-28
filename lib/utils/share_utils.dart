import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Minimum side length for the share sheet anchor rect.
///
/// iOS rejects an empty anchor, so a zero-sized widget still needs a rect with
/// some area to it.
const double _minAnchorSide = 1;

/// Fallback anchor side length, used when the widget's own rect is unusable.
const double _fallbackAnchorSide = 44;

/// Builds an anchor rect for the iOS/iPadOS share sheet popover.
///
/// The native `UIActivityViewController` refuses to present when its popover
/// anchor is empty or falls outside the presenting view, throwing
/// `sharePositionOrigin: argument must be set ... must be non-zero and within
/// coordinate space of source view`. Any rect returned here is non-empty and
/// contained in `screenSize` so that presentation always succeeds.
///
/// Pass [anchor] as the global rect of the widget the sheet should point at
/// (a list tile, a button). When it is null, off screen, or empty, the sheet is
/// anchored near the centre of the screen instead.
Rect shareOriginRect({required Size screenSize, Rect? anchor}) {
  final screen = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
  if (screen.isEmpty) return Rect.zero;

  final candidate = _clampToScreen(anchor, screen);
  if (candidate != null) return candidate;

  // No usable anchor: point at the middle of the screen.
  final side = _fallbackAnchorSide
      .clamp(_minAnchorSide, screen.shortestSide)
      .toDouble();
  return _clampToScreen(
        Rect.fromCenter(center: screen.center, width: side, height: side),
        screen,
      ) ??
      Rect.fromLTWH(0, 0, screen.width, screen.height);
}

/// Fits [anchor] inside [screen] with a non-zero area, or returns null if it
/// cannot be salvaged (null, non-finite, or entirely off screen).
Rect? _clampToScreen(Rect? anchor, Rect screen) {
  if (anchor == null || !anchor.isFinite) return null;

  final width = anchor.width.clamp(_minAnchorSide, screen.width).toDouble();
  final height = anchor.height.clamp(_minAnchorSide, screen.height).toDouble();
  final left = anchor.left.clamp(0.0, screen.width - width).toDouble();
  final top = anchor.top.clamp(0.0, screen.height - height).toDouble();
  final rect = Rect.fromLTWH(left, top, width, height);

  // A rect that started off screen gets clamped onto the edge, which is a
  // harmless anchor, but a rect with no overlap at all means the caller handed
  // us something meaningless.
  if (!anchor.isEmpty && !anchor.overlaps(screen)) return null;
  return rect;
}

/// Anchor rect for a share sheet triggered from [context]'s widget.
///
/// Falls back to the centre of the screen when the widget has no attached
/// render box (for example when it was disposed while a file was being
/// prepared).
Rect shareOriginFor(BuildContext context) {
  final screenSize = MediaQuery.sizeOf(context);
  Rect? anchor;
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize && renderObject.attached) {
    try {
      anchor = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    } catch (_) {
      // Render object is not in a state where it can be located; use the
      // fallback anchor below.
    }
  }
  return shareOriginRect(screenSize: screenSize, anchor: anchor);
}

/// Shares [files] with a share sheet anchored at [origin].
///
/// Always supplies `sharePositionOrigin`, which iOS requires whenever the sheet
/// is presented as a popover. Build [origin] with [shareOriginFor] — usually
/// before any long running work, so the anchor is read while the widget is
/// certain to still be in the tree.
Future<ShareResult> shareFiles(
  List<XFile> files, {
  required Rect origin,
  String? subject,
  String? text,
}) {
  return Share.shareXFiles(
    files,
    subject: subject,
    text: text,
    sharePositionOrigin: origin,
  );
}

/// Shares [files] with a share sheet anchored on [context]'s widget.
Future<ShareResult> shareFilesFrom(
  BuildContext context,
  List<XFile> files, {
  String? subject,
  String? text,
}) {
  return shareFiles(
    files,
    origin: shareOriginFor(context),
    subject: subject,
    text: text,
  );
}
