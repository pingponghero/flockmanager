import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/enums.dart';
import 'package:flock_manager/models/flock.dart';
import 'package:flock_manager/providers/bird_provider.dart';
import 'package:flock_manager/providers/flock_provider.dart';
import 'package:flock_manager/providers/trial_provider.dart';
import 'package:flock_manager/screens/birds/bird_list_screen.dart';

class _FakeBirds extends BirdsNotifier {
  final List<Bird> birds;
  _FakeBirds(this.birds);

  @override
  Future<List<Bird>> build() async => birds;
}

class _FakeFlocks extends FlocksNotifier {
  @override
  Future<List<Flock>> build() async => [];
}

Bird _bird(String name, BirdSex sex, BirdStatus status) => Bird(
      id: name,
      flockId: 'flock-1',
      name: name,
      sex: sex,
      status: status,
      createdAt: DateTime(2025, 1, 1),
    );

/// #61: the sex/status filters are compact chips that make the default
/// "Female · Active" filter visible and clearable.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final birds = [
    _bird('Henrietta', BirdSex.female, BirdStatus.active),
    _bird('Clucky', BirdSex.female, BirdStatus.active),
    _bird('Rocky', BirdSex.male, BirdStatus.active),
    _bird('Grandma', BirdSex.female, BirdStatus.inactive),
  ];

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          birdsProvider.overrideWith(() => _FakeBirds(birds)),
          flocksProvider.overrideWith(_FakeFlocks.new),
          canEditProvider.overrideWithValue(true),
        ],
        child: const MaterialApp(home: BirdListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('default filter is shown as chips with a count', (tester) async {
    await pumpScreen(tester);

    expect(find.widgetWithText(InputChip, 'Female'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Active'), findsOneWidget);
    expect(find.text('2 of 4'), findsOneWidget);
    expect(find.text('Henrietta'), findsOneWidget);
    expect(find.text('Rocky'), findsNothing);
  });

  testWidgets('clearing both chips shows every bird', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Clear Sex filter'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Any sex'), findsOneWidget);
    expect(find.text('3 of 4'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear Status filter'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Any status'), findsOneWidget);
    expect(find.text('4 birds'), findsOneWidget);
  });

  testWidgets('choosing from the chip menu applies the filter',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(InputChip, 'Female'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Male'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InputChip, 'Male'), findsOneWidget);
    expect(find.text('1 of 4'), findsOneWidget);
    expect(find.text('Rocky'), findsOneWidget);
  });
}
