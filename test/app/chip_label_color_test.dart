import 'package:flock_manager/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// #62: unselected chip labels drew near-white on light chips because the
/// chip theme's labelStyle had no colour.
void main() {
  for (final brightness in Brightness.values) {
    for (final palette in AppPalette.values) {
      testWidgets('chip labels use the text colour ($palette, $brightness)', (tester) async {
        final theme = AppTheme.buildTheme(palette, brightness: brightness);
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Row(children: [
              ChoiceChip(label: const Text('On'), selected: true, onSelected: (_) {}),
              ChoiceChip(label: const Text('Off'), selected: false, onSelected: (_) {}),
            ]),
          ),
        ));
        final text = brightness == Brightness.dark
            ? palette.darkColors.text
            : palette.colors.text;
        for (final label in ['On', 'Off']) {
          final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
          expect(paragraph.text.style?.color, text, reason: label);
        }
      });
    }
  }
}
