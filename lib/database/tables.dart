/// SQL table creation statements for Flock Manager database.
/// Keep all SQL centralized here for maintainability.
class Tables {
  Tables._();

  static const String flocks = '''
    CREATE TABLE flocks (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      icon TEXT,
      color TEXT,
      is_archived INTEGER DEFAULT 0,
      created_at TEXT NOT NULL
    )
  ''';

  static const String birds = '''
    CREATE TABLE birds (
      id TEXT PRIMARY KEY,
      flock_id TEXT NOT NULL,
      name TEXT NOT NULL,
      breed TEXT,
      breed_id TEXT,
      photo_primary TEXT,
      hatch_date TEXT,
      acquired_date TEXT,
      source TEXT,
      egg_color TEXT,
      status TEXT DEFAULT 'active',
      status_date TEXT,
      status_notes TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (flock_id) REFERENCES flocks(id)
    )
  ''';

  static const String birdPhotos = '''
    CREATE TABLE bird_photos (
      id TEXT PRIMARY KEY,
      bird_id TEXT NOT NULL,
      photo_path TEXT NOT NULL,
      sort_order INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (bird_id) REFERENCES birds(id)
    )
  ''';

  static const String eggLogs = '''
    CREATE TABLE egg_logs (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      flock_id TEXT NOT NULL,
      bird_id TEXT,
      count INTEGER NOT NULL,
      size TEXT,
      quality TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (flock_id) REFERENCES flocks(id),
      FOREIGN KEY (bird_id) REFERENCES birds(id)
    )
  ''';

  static const String expenses = '''
    CREATE TABLE expenses (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      description TEXT,
      flock_id TEXT,
      is_recurring INTEGER DEFAULT 0,
      recurring_interval TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (flock_id) REFERENCES flocks(id)
    )
  ''';

  static const String income = '''
    CREATE TABLE income (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      amount REAL NOT NULL,
      description TEXT,
      egg_count INTEGER,
      created_at TEXT NOT NULL
    )
  ''';

  static const String medicationLogs = '''
    CREATE TABLE medication_logs (
      id TEXT PRIMARY KEY,
      bird_id TEXT,
      flock_id TEXT NOT NULL,
      medication_name TEXT NOT NULL,
      dosage TEXT,
      start_date TEXT NOT NULL,
      end_date TEXT,
      withdrawal_days INTEGER,
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (bird_id) REFERENCES birds(id),
      FOREIGN KEY (flock_id) REFERENCES flocks(id)
    )
  ''';

  static const String healthNotes = '''
    CREATE TABLE health_notes (
      id TEXT PRIMARY KEY,
      bird_id TEXT NOT NULL,
      date TEXT NOT NULL,
      type TEXT NOT NULL,
      description TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (bird_id) REFERENCES birds(id)
    )
  ''';

  /// All tables in creation order (respecting foreign key dependencies)
  static const List<String> allTables = [
    flocks,
    birds,
    birdPhotos,
    eggLogs,
    expenses,
    income,
    medicationLogs,
    healthNotes,
  ];
}
