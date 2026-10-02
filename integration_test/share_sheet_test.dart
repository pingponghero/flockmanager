// On-device verification for the iOS export share sheet (#41).
//
// The unit tests in test/utils/share_utils_test.dart mock the method channel
// and assert our anchor satisfies the plugin's documented precondition. These
// tests go further: they drive the real share_plus plugin against the real
// UIActivityViewController, so a change in what iOS accepts shows up here.
//
// Run against a booted simulator or an attached device:
//   flutter test integration_test/share_sheet_test.dart -d <device-id>
//
// Afterwards, regenerate the iOS build config before archiving:
//   flutter build ios --release --config-only
//
// Running this suite rewrites ios/Flutter/Generated.xcconfig so FLUTTER_TARGET
// points at a temporary test listener, and leaves it pointing there on exit.
// The temp file is deleted, so a later Xcode archive fails in the "Run Script"
// phase with "No such file or directory ... listener.dart" and "No 'main'
// method found". It also leaves TRACK_WIDGET_CREATION=true, which does not
// belong in a release build. Using `flutter build ipa` rather than archiving
// from Xcode avoids this, since it sets the config itself.
//
// On iPad this is the case that originally failed outright. On iPhone it
// depends on whether UIActivityViewController is given a popover presentation
// controller, which is why the negative control below reports rather than
// asserts.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flock_manager/utils/share_utils.dart';
import 'package:share_plus/share_plus.dart';

/// Writes a small zip-shaped file to share, standing in for an export.
Future<XFile> makeExportFile() async {
  final dir = await Directory.systemTemp.createTemp('flock_export_test');
  final file = File('${dir.path}/flock_export_integration.zip');
  // Minimal end-of-central-directory record: a valid, empty zip.
  await file.writeAsBytes(<int>[
    0x50, 0x4b, 0x05, 0x06, //
    0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]);
  return XFile(file.path);
}

/// Pumps [child] with a button that shares [file] and records any error.
Future<List<Object?>> tapAndShare(
  WidgetTester tester, {
  required XFile file,
  required Future<void> Function(BuildContext context, XFile file) onTap,
}) async {
  final errors = <Object?>[];

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => ListTile(
              title: const Text('Export Data'),
              onTap: () async {
                try {
                  await onTap(context, file);
                } catch (e) {
                  errors.add(e);
                }
              },
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Export Data'));
  // The share sheet is a native modal: its future only completes once the user
  // dismisses it. A presentation failure, by contrast, throws straight away, so
  // settling briefly is enough to tell the two apart.
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));

  return errors;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('export share sheet presents with an anchored origin',
      (tester) async {
    final file = await makeExportFile();

    final errors = await tapAndShare(
      tester,
      file: file,
      onTap: (context, f) => shareFilesFrom(
        context,
        [f],
        subject: 'Flock Manager Data Export',
      ),
    );

    expect(
      errors,
      isEmpty,
      reason: 'the share sheet should present; see #41 for the failure this '
          'guards against',
    );
  });

  testWidgets('unanchored share is what iOS rejects (negative control)',
      (tester) async {
    // Reproduces the original bug path. Whether iOS rejects it depends on the
    // device giving UIActivityViewController a popover presentation controller
    // — always true on iPad, and true on iPhone on the iOS versions the bug was
    // reported from. Where it is not rejected this test records that fact
    // instead of failing, so the suite stays meaningful on every device.
    final file = await makeExportFile();

    final errors = await tapAndShare(
      tester,
      file: file,
      // Deliberately no sharePositionOrigin.
      onTap: (context, f) => Share.shareXFiles([f]),
    );

    if (errors.isEmpty) {
      // ignore: avoid_print
      print(
        'NOTE: this device accepted an unanchored share sheet, so it does not '
        'reproduce #41. The positive test above still verifies the anchor is '
        'accepted. Run on an iPad simulator to exercise the failing case.',
      );
      return;
    }

    expect(
      errors.single,
      isA<PlatformException>().having(
        (e) => e.message,
        'message',
        contains('sharePositionOrigin'),
      ),
    );
  });
}
