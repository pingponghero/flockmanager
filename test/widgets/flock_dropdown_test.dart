import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/models/flock.dart';
import 'package:flock_manager/providers/flock_provider.dart';
import 'package:flock_manager/widgets/flock_dropdown.dart';

/// Serves a fixed flock list without touching the database.
class _FakeFlocksNotifier extends FlocksNotifier {
  _FakeFlocksNotifier(this._flocks);

  final List<Flock> _flocks;

  @override
  Future<List<Flock>> build() async => _flocks;
}

Flock _flock(String id, String name) => Flock(
      id: id,
      name: name,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  Future<void> pumpDropdown(WidgetTester tester, List<Flock> flocks) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flocksProvider.overrideWith(() => _FakeFlocksNotifier(flocks)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: FlockDropdown(
              selectedFlockId: flocks.isEmpty ? null : flocks.first.id,
              onChanged: (_) {},
              showAllOption: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('FlockDropdown', () {
    testWidgets('renders for a single flock (#15)', (tester) async {
      await pumpDropdown(tester, [_flock('f1', 'Backyard Girls')]);

      expect(find.byType(DropdownMenu<String?>), findsOneWidget);
    });

    testWidgets('offers "Add flock…" alongside a single flock (#15)',
        (tester) async {
      await pumpDropdown(tester, [_flock('f1', 'Backyard Girls')]);

      await tester.tap(find.byType(DropdownMenu<String?>));
      await tester.pumpAndSettle();

      expect(find.text('Add flock…'), findsOneWidget);
      expect(find.text('Backyard Girls'), findsWidgets);
    });

    testWidgets('offers "Add flock…" with several flocks', (tester) async {
      await pumpDropdown(tester, [
        _flock('f1', 'Backyard Girls'),
        _flock('f2', 'The Bantams'),
      ]);

      await tester.tap(find.byType(DropdownMenu<String?>));
      await tester.pumpAndSettle();

      expect(find.text('Add flock…'), findsOneWidget);
      expect(find.text('The Bantams'), findsWidgets);
    });

    testWidgets('renders nothing when there are no flocks', (tester) async {
      await pumpDropdown(tester, []);

      expect(find.byType(DropdownMenu<String?>), findsNothing);
    });
  });
}
