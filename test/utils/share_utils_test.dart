import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/utils/share_utils.dart';
import 'package:share_plus/share_plus.dart';

/// Screen size reported in the bug report (iPhone 14/15/16 Pro, logical px).
const _reportedScreen = Size(393, 852);

const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

/// Mirrors the check `FPPSharePlusPlugin` runs before presenting the share
/// sheet: the popover anchor must be non-empty and contained in the presenting
/// view's frame, otherwise the plugin fails the call.
///
/// See `ios/share_plus/Sources/share_plus/FPPSharePlusPlugin.m`:
/// `hasPopoverPresentationController && (!isCoordinateSpaceOfSourceView || CGRectIsEmpty(origin))`
bool iosWouldRejectAnchor(Rect origin, Size sourceView) {
  final isEmpty = origin.width <= 0 || origin.height <= 0;
  final isContained = origin.left >= 0 &&
      origin.top >= 0 &&
      origin.right <= sourceView.width &&
      origin.bottom <= sourceView.height;
  return isEmpty || !isContained;
}

/// Stands in for the iOS plugin: reads the origin args off the method call and
/// throws the same [PlatformException] the real plugin throws for a bad anchor.
List<Rect?> installFakeIosSharePlugin(Size sourceView) {
  final received = <Rect?>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_shareChannel, (call) async {
    final args = (call.arguments as Map).cast<String, dynamic>();
    final originX = args['originX'] as double?;
    final originY = args['originY'] as double?;
    final originWidth = args['originWidth'] as double?;
    final originHeight = args['originHeight'] as double?;

    final origin = (originX != null &&
            originY != null &&
            originWidth != null &&
            originHeight != null)
        ? Rect.fromLTWH(originX, originY, originWidth, originHeight)
        : null;
    received.add(origin);

    // The plugin defaults a missing anchor to CGRectZero.
    if (iosWouldRejectAnchor(origin ?? Rect.zero, sourceView)) {
      throw PlatformException(
        code: 'error',
        message: 'sharePositionOrigin: argument must be set, '
            '${origin ?? Rect.zero} must be non-zero and within coordinate '
            'space of source view: $sourceView',
      );
    }
    return 'dev.fluttercommunity.plus/share/success';
  });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, null);
  });
  return received;
}

void main() {
  group('shareOriginRect', () {
    test('supplies a presentable anchor when the widget rect is unknown', () {
      // Regression: export shared with no sharePositionOrigin, so the plugin
      // fell back to CGRectZero and refused to present the share sheet.
      final origin = shareOriginRect(screenSize: _reportedScreen);

      expect(iosWouldRejectAnchor(origin, _reportedScreen), isFalse);
    });

    test('repairs a zero-sized widget rect', () {
      final origin = shareOriginRect(
        screenSize: _reportedScreen,
        anchor: const Rect.fromLTWH(0, 110, 0, 0),
      );

      expect(origin.width, greaterThan(0));
      expect(origin.height, greaterThan(0));
      expect(iosWouldRejectAnchor(origin, _reportedScreen), isFalse);
    });

    test('keeps an on-screen widget rect as the anchor', () {
      const anchor = Rect.fromLTWH(16, 320, 361, 72);

      final origin =
          shareOriginRect(screenSize: _reportedScreen, anchor: anchor);

      expect(origin, anchor);
    });

    test('clamps an anchor that hangs off the edge of the screen', () {
      final origin = shareOriginRect(
        screenSize: _reportedScreen,
        anchor: const Rect.fromLTWH(300, 800, 400, 200),
      );

      expect(iosWouldRejectAnchor(origin, _reportedScreen), isFalse);
    });

    test('ignores an anchor that is nowhere near the screen', () {
      final origin = shareOriginRect(
        screenSize: _reportedScreen,
        anchor: const Rect.fromLTWH(-5000, -5000, 40, 40),
      );

      expect(iosWouldRejectAnchor(origin, _reportedScreen), isFalse);
    });

    test('ignores a non-finite anchor', () {
      final origin = shareOriginRect(
        screenSize: _reportedScreen,
        anchor: const Rect.fromLTWH(0, 0, double.infinity, double.infinity),
      );

      expect(iosWouldRejectAnchor(origin, _reportedScreen), isFalse);
    });
  });

  group('shareFilesFrom', () {
    late File file;

    setUp(() async {
      file = File(
        '${Directory.systemTemp.createTempSync('share_utils_test').path}'
        '/flock_manager_export.zip',
      );
      await file.writeAsBytes(<int>[0x50, 0x4b, 0x05, 0x06]);
    });

    testWidgets('anchors the share sheet on the tapped widget', (tester) async {
      await tester.binding.setSurfaceSize(_reportedScreen);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final received = installFakeIosSharePlugin(_reportedScreen);

      Object? error;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ListTile(
                  title: const Text('Export Data'),
                  onTap: () async {
                    try {
                      await shareFilesFrom(context, [XFile(file.path)]);
                    } catch (e) {
                      error = e;
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Export Data'));
      await tester.pumpAndSettle();

      expect(error, isNull, reason: 'share sheet should present, not throw');
      expect(received, hasLength(1));
      expect(iosWouldRejectAnchor(received.single!, _reportedScreen), isFalse);
    });

    testWidgets('reproduces the failure when no anchor is supplied',
        (tester) async {
      // Documents the original bug: Share.shareXFiles without
      // sharePositionOrigin is what the plugin rejects.
      installFakeIosSharePlugin(_reportedScreen);

      await expectLater(
        Share.shareXFiles([XFile(file.path)]),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.message,
            'message',
            contains('sharePositionOrigin: argument must be set'),
          ),
        ),
      );
    });
  });
}
