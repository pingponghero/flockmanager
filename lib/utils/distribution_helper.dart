import '../models/bird.dart';

/// Determines if egg distribution should be offered.
///
/// Distribution is offered when:
/// - A specific flock is selected (not "All Flocks")
/// - Egg count is greater than 0
/// - There are 2-10 active birds in the flock
/// - Egg count exactly matches the number of active birds
bool shouldOfferDistribution({
  required int eggCount,
  required List<Bird> activeBirds,
  required String? selectedFlockId,
}) {
  if (selectedFlockId == null) return false; // "All Flocks" mode
  if (eggCount <= 0) return false;
  if (activeBirds.length < 2) return false;
  if (activeBirds.length > 10) return false;
  if (eggCount != activeBirds.length) return false;

  return true;
}

/// Creates an even distribution map (1 egg per bird).
Map<String, int> createEvenDistribution(List<Bird> birds) {
  return {for (final bird in birds) bird.id: 1};
}
