import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/widgets/hen_icon.dart';

/// #64: HenIcon drops in where an Icon would go.
void main() {
  testWidgets('takes size and colour from the ambient IconTheme',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: IconTheme(
        data: IconThemeData(size: 40, color: Colors.green),
        child: HenIcon(),
      ),
    ));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 40);
    expect(image.height, 40);
    expect(image.color, Colors.green);
  });

  testWidgets('explicit size and colour win', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: HenIcon(size: 16, color: Colors.red),
    ));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 16);
    expect(image.color, Colors.red);
  });
}
