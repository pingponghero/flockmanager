import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _lastExportDateKey = 'last_export_date';

/// Nudge for a fresh backup once the last export is this old.
const _nudgeIntervalDays = 30;

/// Record that the user completed a data export just now.
Future<void> recordExportDate() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_lastExportDateKey, DateTime.now().toIso8601String());
}

/// The date of the most recent data export, or null if never exported.
final lastExportDateProvider = FutureProvider<DateTime?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_lastExportDateKey);
  return raw != null ? DateTime.tryParse(raw) : null;
});

/// Whether to nudge the user to make a backup — true when they have never
/// exported or their last export is older than [_nudgeIntervalDays].
final showExportNudgeProvider = FutureProvider<bool>((ref) async {
  final last = await ref.watch(lastExportDateProvider.future);
  if (last == null) return true;
  return DateTime.now().difference(last).inDays >= _nudgeIntervalDays;
});
