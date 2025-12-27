import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flock_manager/database/database_helper.dart';

/// Mock DatabaseHelper using mocktail.
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

/// Mock Database for direct database operations.
class MockDatabase extends Mock implements Database {}
