import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/bird_status_event.dart';
import 'package:flock_manager/providers/bird_provider.dart';
import 'package:flock_manager/providers/bird_status_event_provider.dart';
import 'package:flock_manager/repositories/bird_repository.dart';
import 'package:flock_manager/repositories/bird_status_event_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBirds extends Mock implements BirdRepository {}

class _MockEvents extends Mock implements BirdStatusEventRepository {}

/// #88: a bird's first 'active' event marks when she joined the flock.
void main() {
  late _MockBirds birds;
  late _MockEvents events;
  late ProviderContainer container;

  final henrietta = Bird(
    id: 'h',
    flockId: 'f',
    name: 'Henrietta',
    acquiredDate: DateTime(2024, 3, 1),
    createdAt: DateTime(2025, 6, 10),
  );

  BirdStatusEvent event(String id, String status, DateTime date) => BirdStatusEvent(
        id: id,
        birdId: 'h',
        flockId: 'f',
        status: status,
        eventDate: date,
        createdAt: date,
      );

  setUpAll(() {
    registerFallbackValue(henrietta);
    registerFallbackValue(event('x', 'active', DateTime(2024)));
    registerFallbackValue(DateTime(2024));
  });

  setUp(() {
    birds = _MockBirds();
    events = _MockEvents();
    when(() => birds.getAllBirds()).thenAnswer((_) async => [henrietta]);
    when(() => birds.insertBird(any())).thenAnswer((_) async {});
    when(() => birds.updateBird(any())).thenAnswer((_) async {});
    when(() => events.insertEvent(any())).thenAnswer((_) async {});
    when(() => events.updateEventDate(any(), any())).thenAnswer((_) async {});
    container = ProviderContainer(overrides: [
      birdRepositoryProvider.overrideWithValue(birds),
      birdStatusEventRepositoryProvider.overrideWithValue(events),
    ]);
    addTearDown(container.dispose);
  });

  test('a new bird joins on her acquired date, not when she was entered', () async {
    await container.read(birdsProvider.notifier).addBird(henrietta);
    final inserted = verify(() => events.insertEvent(captureAny())).captured.single
        as BirdStatusEvent;
    expect(inserted.status, 'active');
    expect(inserted.eventDate, DateTime(2024, 3, 1));
  });

  test('editing the acquired date moves her joined event', () async {
    when(() => birds.getBirdById('h')).thenAnswer((_) async => henrietta);
    when(() => events.getEventsByBird('h'))
        .thenAnswer((_) async => [event('e1', 'active', DateTime(2024, 3, 1))]);

    await container
        .read(birdsProvider.notifier)
        .updateBird(henrietta.copyWith(acquiredDate: DateTime(2023, 9, 1)));

    verify(() => events.updateEventDate('e1', DateTime(2023, 9, 1))).called(1);
  });

  test('never moves it past a later status change', () async {
    when(() => birds.getBirdById('h')).thenAnswer((_) async => henrietta);
    when(() => events.getEventsByBird('h')).thenAnswer((_) async => [
          event('e2', 'sold', DateTime(2025, 1, 1)),
          event('e1', 'active', DateTime(2024, 3, 1)),
        ]);

    await container
        .read(birdsProvider.notifier)
        .updateBird(henrietta.copyWith(acquiredDate: DateTime(2025, 2, 1)));

    verifyNever(() => events.updateEventDate(any(), any()));
  });
}
