import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/widgets/tappable_tile.dart';

/// #66: tappable banners give ink feedback and read as buttons.
void main() {
  testWidgets('ripples, announces as a button and calls onTap',
      (tester) async {
    var taps = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TappableTile(
          onTap: () => taps++,
          color: Colors.amber.shade50,
          borderColor: Colors.amber.shade200,
          padding: const EdgeInsets.all(12),
          child: const Text('Egg Withdrawal Active'),
        ),
      ),
    ));

    expect(find.byType(InkWell), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(TappableTile)),
      matchesSemantics(
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        label: 'Egg Withdrawal Active',
      ),
    );

    await tester.tap(find.text('Egg Withdrawal Active'));
    await tester.pump(const Duration(milliseconds: 50));
    // An ink splash is painted on the Material while the tap is active.
    final inkFeatures = tester.allRenderObjects
        .where((r) => r.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, isNotEmpty);
    expect(taps, 1);
    semantics.dispose();
  });
}
