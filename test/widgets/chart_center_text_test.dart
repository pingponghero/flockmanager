import 'package:flock_manager/widgets/chart_center_text.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatCenterCount', () {
    test('exact up to six digits, compact from a million', () {
      expect(formatCenterCount(898), '898');
      expect(formatCenterCount(12345), '12,345');
      expect(formatCenterCount(999999), '999,999');
      expect(formatCenterCount(1234567), '1.23M');
    });
  });

  group('fitCenterText', () {
    // The test font draws every glyph 1em wide: wider than real digits, so
    // this is a worst case.
    test('leaves short totals at full size', () {
      final p = fitCenterText('898', const TextStyle(fontSize: 16), maxWidth: 70);
      expect(p.text!.style!.fontSize, 16);
    });

    test('shrinks long totals to fit the circle', () {
      for (final text in ['123,456', '999,999', '1.23M']) {
        final p = fitCenterText(text, const TextStyle(fontSize: 16), maxWidth: 60);
        expect(p.width, lessThanOrEqualTo(60.5), reason: text);
      }
    });

    test('never goes below the minimum size', () {
      final p = fitCenterText('9,999,999,999', const TextStyle(fontSize: 16),
          maxWidth: 20, minFontSize: 7);
      expect(p.text!.style!.fontSize, 7);
    });
  });
}
