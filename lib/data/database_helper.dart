import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/pest_results.dart';
import 'models/plant_remiinder.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pest_scans.db');

    return await openDatabase(
      path,
      version: 12,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Helper to safely add a column
    Future<void> addColumn(String table, String column, String type) async {
      try {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
      } catch (e) {
        // Column might already exist, ignore error
      }
    }

    // Safety: Ensure these columns exist regardless of version
    // (In case previous migration crashed)
    await addColumn('pest_scans', 'health_status', 'TEXT');
    await addColumn('pest_scans', 'health_score', 'INTEGER');
    await addColumn('pest_scans', 'care_recommendations', 'TEXT');
    await addColumn('pest_scans', 'scan_type', 'TEXT DEFAULT "pest"');
    await addColumn('pest_scans', 'complete_data', 'TEXT');

    if (oldVersion < 2) {
      await addColumn('pest_scans', 'description', 'TEXT');
      await addColumn('pest_scans', 'life_cycle', 'TEXT');
      await addColumn('pest_scans', 'host_plants', 'TEXT');
      await addColumn('pest_scans', 'identification_tips', 'TEXT');
    }
    if (oldVersion < 3) {
      await addColumn('pest_scans', 'damage_details', 'TEXT');
      await addColumn('pest_scans', 'favorable_conditions', 'TEXT');
      await addColumn('pest_scans', 'economic_impact', 'TEXT');
      await addColumn('pest_scans', 'long_term_prevention', 'TEXT');
    }
    if (oldVersion < 4) {
      await addColumn('pest_scans', 'is_history', 'INTEGER DEFAULT 0');
    }
    if (oldVersion < 5) {
      await addColumn('pest_scans', 'plant_name', 'TEXT');
      await addColumn('pest_scans', 'origin', 'TEXT');
      await addColumn('pest_scans', 'use_case', 'TEXT');
      await addColumn('pest_scans', 'expected_price', 'TEXT');
      await addColumn('pest_scans', 'benefits', 'TEXT');
    }
    if (oldVersion < 6) {
      await addColumn('pest_scans', 'care_guide', 'TEXT');
    }
    if (oldVersion < 7) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS plant_reminders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plant_name TEXT,
            times TEXT,
            is_active INTEGER DEFAULT 1
          )
        ''');
      } catch (e) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pest_scans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pest_name TEXT,
        scientific_name TEXT,
        severity_level TEXT,
        confidence TEXT,
        affected_area TEXT,
        symptoms TEXT,
        description TEXT,
        life_cycle TEXT,
        damage_details TEXT,
        favorable_conditions TEXT,
        economic_impact TEXT,
        long_term_prevention TEXT,
        host_plants TEXT,
        identification_tips TEXT,
        organic_treatments TEXT,
        chemical_treatments TEXT,
        prevention_tips TEXT,
        image_path TEXT,
        date_scanned TEXT,
        is_favorite INTEGER,
        is_history INTEGER DEFAULT 0,
        plant_name TEXT,
        origin TEXT,
        use_case TEXT,
        expected_price TEXT,
        benefits TEXT,
        care_guide TEXT,
        health_status TEXT,
        health_score INTEGER,
        care_recommendations TEXT,
        scan_type TEXT,
        complete_data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE plant_reminders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_name TEXT,
        times TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');
  }

  Future<int> insertScan(PestResult scan) async {
    final db = await database;
    return await db.insert('pest_scans', scan.toMap());
  }

  Future<List<PestResult>> getScans({bool? isHistory, bool? isFavorite}) async {
    final db = await database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (isHistory != null) {
      whereClause = 'is_history = ?';
      whereArgs = [isHistory ? 1 : 0];
    } else if (isFavorite != null) {
      whereClause = 'is_favorite = ?';
      whereArgs = [isFavorite ? 1 : 0];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'pest_scans',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );

    return List.generate(maps.length, (i) {
      return PestResult.fromMap(maps[i]);
    });
  }

  Future<PestResult?> getScan(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pest_scans',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PestResult.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteScan(int id) async {
    final db = await database;
    return await db.delete('pest_scans', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateScan(PestResult scan) async {
    final db = await database;
    return await db.update(
      'pest_scans',
      scan.toMap(),
      where: 'id = ?',
      whereArgs: [scan.id],
    );
  }

  // Plant Reminders
  Future<int> insertReminder(PlantReminder reminder) async {
    final db = await database;
    return await db.insert('plant_reminders', reminder.toMap());
  }

  Future<List<PlantReminder>> getReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('plant_reminders');
    return List.generate(maps.length, (i) => PlantReminder.fromMap(maps[i]));
  }

  Future<int> updateReminder(PlantReminder reminder) async {
    final db = await database;
    return await db.update(
      'plant_reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete('plant_reminders', where: 'id = ?', whereArgs: [id]);
  }
}
