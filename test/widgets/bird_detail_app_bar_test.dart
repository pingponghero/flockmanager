import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/app/theme.dart';
import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/enums.dart';
import 'package:flock_manager/providers/bird_provider.dart';
import 'package:flock_manager/providers/egg_provider.dart';
import 'package:flock_manager/providers/flock_provider.dart';
import 'package:flock_manager/providers/medication_provider.dart';
import 'package:flock_manager/screens/birds/bird_detail_screen.dart';

/// #56: once the photo header collapses, the app bar falls back to the theme's
/// (white, in light mode) background, so its icons must stop being forced
/// white and the bird's name should appear as the title.
void main() {
  final bird = Bird(
    id: 'bird-1',
    flockId: 'flock-1',
    name: 'Henrietta',
    breed: 'Rhode Island Red',
    status: BirdStatus.active,
    createdAt: DateTime(2025, 1, 1),
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          birdByIdProvider.overrideWith((ref, id) async => bird),
          totalEggCountByBirdProvider.overrideWith((ref, id) async => 0),
          eggLogsByBirdProvider.overrideWith((ref, id) async => []),
          flockByIdProvider.overrideWith((ref, id) async => null),
          healthNotesByBirdProvider.overrideWith((ref, id) async => []),
          medicationsByBirdProvider.overrideWith((ref, id) async => []),
        ],
        child: MaterialApp(
          theme: AppTheme.buildTheme(AppPalette.barnRed),
          home: BirdDetailScreen(birdId: bird.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  SliverAppBar appBar(WidgetTester tester) =>
      tester.widget<SliverAppBar>(find.byType(SliverAppBar));

  double titleOpacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(find.ancestor(
        of: find.text('Henrietta'),
        matching: find.byType(AnimatedOpacity),
      ))
      .opacity;

  testWidgets('expanded header uses white icons and hides the title',
      (tester) async {
    await pumpScreen(tester);

    expect(appBar(tester).foregroundColor, Colors.white);
    expect(titleOpacity(tester), 0);
  });

  testWidgets('collapsed header uses theme colours and shows the name',
      (tester) async {
    await pumpScreen(tester);

    await tester.drag(find.byType(NestedScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(appBar(tester).foregroundColor, isNull);
    expect(appBar(tester).systemOverlayStyle, isNull);
    expect(titleOpacity(tester), 1);
  });
}
