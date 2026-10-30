import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/course_model.dart';
import '../models/task_model.dart';
import '../models/alarm_sound_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('unisched.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onOpen: _onOpen,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel courses (Data Mata Kuliah / KRS)
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        course_name TEXT NOT NULL,
        course_code TEXT,
        sks INTEGER DEFAULT 0,
        lecturer_name TEXT,
        room TEXT,
        day_of_week INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        color_hex TEXT DEFAULT '#3B82F6',
        course_type TEXT DEFAULT 'lecture',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Tabel alarm_sounds (Manajemen Audio Alarm)
    await db.execute('''
      CREATE TABLE alarm_sounds (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        source_type TEXT NOT NULL,
        local_file_path TEXT NOT NULL,
        remote_url TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Tabel tasks (Data Tugas Kuliah)
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        course_id TEXT,
        title TEXT NOT NULL,
        description TEXT,
        deadline_datetime TEXT NOT NULL,
        reminder_datetime TEXT NOT NULL,
        is_alarm_enabled INTEGER DEFAULT 1,
        alarm_sound_id TEXT,
        is_completed INTEGER DEFAULT 0,
        shared_origin_code TEXT,
        task_type TEXT DEFAULT 'lecture',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE SET NULL,
        FOREIGN KEY (alarm_sound_id) REFERENCES alarm_sounds (id) ON DELETE SET NULL
      )
    ''');

    // Seed default alarm sounds
    await _seedDefaultAlarms(db);
  }

  Future<void> _onOpen(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS alarm_sounds (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        source_type TEXT NOT NULL,
        local_file_path TEXT NOT NULL,
        remote_url TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    // Migrations for existing databases
    try {
      await db.execute("ALTER TABLE courses ADD COLUMN course_type TEXT DEFAULT 'lecture'");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE tasks ADD COLUMN task_type TEXT DEFAULT 'lecture'");
    } catch (_) {}

    await _seedDefaultAlarms(db);
  }

  Future<void> _seedDefaultAlarms(Database db) async {
    final defaults = [
      {
        'id': 'sound_default_1',
        'title': 'Chime Lembut (Default)',
        'source_type': 'DEFAULT',
        'local_file_path': 'assets/sounds/chime.mp3',
        'remote_url': null,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'sound_default_2',
        'title': 'Digital Clock Beep',
        'source_type': 'DEFAULT',
        'local_file_path': 'assets/sounds/beep.mp3',
        'remote_url': null,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'sound_default_3',
        'title': 'Energetic Morning',
        'source_type': 'DEFAULT',
        'local_file_path': 'assets/sounds/energetic.mp3',
        'remote_url': null,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final s in defaults) {
      await db.insert(
        'alarm_sounds',
        s,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> ensureDefaultData() async {
    final db = await database;
    await _onOpen(db);
  }

  // ================= COURSES =================
  Future<int> insertCourse(Course course) async {
    final db = await database;
    return await db.insert(
      'courses',
      course.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Course>> getAllCourses() async {
    final db = await database;
    final result = await db.query('courses', orderBy: 'day_of_week ASC, start_time ASC');
    return result.map((json) => Course.fromMap(json)).toList();
  }

  Future<List<Course>> getCoursesByDay(int dayOfWeek) async {
    final db = await database;
    final result = await db.query(
      'courses',
      where: 'day_of_week = ?',
      whereArgs: [dayOfWeek],
      orderBy: 'start_time ASC',
    );
    return result.map((json) => Course.fromMap(json)).toList();
  }

  Future<Course?> getCourseById(String id) async {
    final db = await database;
    final maps = await db.query('courses', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Course.fromMap(maps.first);
    return null;
  }

  Future<Course?> findCourseByCodeOrName(String? code, String name) async {
    final db = await database;
    if (code != null && code.trim().isNotEmpty) {
      final codeMatches = await db.query(
        'courses',
        where: 'LOWER(course_code) = ?',
        whereArgs: [code.toLowerCase().trim()],
      );
      if (codeMatches.isNotEmpty) {
        return Course.fromMap(codeMatches.first);
      }
    }
    final nameMatches = await db.query(
      'courses',
      where: 'LOWER(course_name) = ?',
      whereArgs: [name.toLowerCase().trim()],
    );
    if (nameMatches.isNotEmpty) {
      return Course.fromMap(nameMatches.first);
    }
    return null;
  }

  /// Cek Bentrok Jadwal (PRD Bab 7.1)
  /// Mengembalikan Course jika ada jadwal pada hari yang sama dengan waktu beririsan
  Future<Course?> checkCourseConflict(
    int dayOfWeek,
    String startTime,
    String endTime, {
    String? excludeCourseId,
  }) async {
    final coursesOnDay = await getCoursesByDay(dayOfWeek);
    for (final c in coursesOnDay) {
      if (excludeCourseId != null && c.id == excludeCourseId) continue;

      // Irisan waktu: (StartA < EndB) AND (EndA > StartB)
      if (startTime.compareTo(c.endTime) < 0 && endTime.compareTo(c.startTime) > 0) {
        return c;
      }
    }
    return null;
  }

  Future<int> updateCourse(Course course) async {
    final db = await database;
    return await db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<int> deleteCourse(String id) async {
    final db = await database;
    return await db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  // ================= TASKS =================
  Future<int> insertTask(Task task) async {
    final db = await database;
    await _seedDefaultAlarms(db);

    final taskMap = Map<String, dynamic>.from(task.toMap());
    if (task.alarmSoundId != null) {
      final exists = await db.query(
        'alarm_sounds',
        where: 'id = ?',
        whereArgs: [task.alarmSoundId],
      );
      if (exists.isEmpty) {
        taskMap['alarm_sound_id'] = null;
      }
    }

    return await db.insert(
      'tasks',
      taskMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final result = await db.query('tasks', orderBy: 'deadline_datetime ASC');
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getActiveTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'is_completed = 0',
      orderBy: 'deadline_datetime ASC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getCompletedTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'is_completed = 1',
      orderBy: 'deadline_datetime DESC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getUrgentTasks({int limit = 5}) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'is_completed = 0',
      orderBy: 'deadline_datetime ASC',
      limit: limit,
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<Task?> findExistingTaskForImport(String? sharedOriginCode, String title, String deadline) async {
    final db = await database;
    if (sharedOriginCode != null && sharedOriginCode.isNotEmpty) {
      final codeMatches = await db.query(
        'tasks',
        where: 'shared_origin_code = ?',
        whereArgs: [sharedOriginCode],
      );
      if (codeMatches.isNotEmpty) return Task.fromMap(codeMatches.first);
    }
    final titleMatches = await db.query(
      'tasks',
      where: 'LOWER(title) = ? AND deadline_datetime = ?',
      whereArgs: [title.toLowerCase().trim(), deadline],
    );
    if (titleMatches.isNotEmpty) return Task.fromMap(titleMatches.first);
    return null;
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    await _seedDefaultAlarms(db);

    final taskMap = Map<String, dynamic>.from(task.toMap());
    if (task.alarmSoundId != null) {
      final exists = await db.query(
        'alarm_sounds',
        where: 'id = ?',
        whereArgs: [task.alarmSoundId],
      );
      if (exists.isEmpty) {
        taskMap['alarm_sound_id'] = null;
      }
    }

    return await db.update(
      'tasks',
      taskMap,
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ================= ALARM SOUNDS =================
  Future<int> insertAlarmSound(AlarmSound sound) async {
    final db = await database;
    return await db.insert(
      'alarm_sounds',
      sound.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AlarmSound>> getAllAlarmSounds() async {
    final db = await database;
    final result = await db.query('alarm_sounds', orderBy: 'created_at ASC');
    return result.map((json) => AlarmSound.fromMap(json)).toList();
  }

  Future<int> deleteAlarmSound(String id) async {
    final db = await database;
    return await db.delete('alarm_sounds', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('tasks');
    await db.delete('courses');
    await db.delete('alarm_sounds');
    // Re-seed default alarms
    await _createDB(db, 1);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
