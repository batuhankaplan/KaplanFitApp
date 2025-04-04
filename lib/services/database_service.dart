import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/activity_record.dart';
import '../models/meal_record.dart';
import '../models/task_type.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'kaplanfit.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Kullanıcı tablosu
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        profileImagePath TEXT,
        createdAt INTEGER,
        lastWeightUpdate INTEGER
      )
    ''');

    // Kilo geçmişi tablosu
    await db.execute('''
      CREATE TABLE weight_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        date INTEGER NOT NULL,
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Günlük görevler tablosu
    await db.execute('''
      CREATE TABLE daily_tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        date INTEGER NOT NULL,
        isCompleted INTEGER DEFAULT 0,
        type INTEGER DEFAULT 0
      )
    ''');

    // Aktivite tablosu
    await db.execute('''
      CREATE TABLE activities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        durationMinutes INTEGER NOT NULL,
        date INTEGER NOT NULL,
        notes TEXT,
        taskId INTEGER
      )
    ''');

    // Yemek kaydı tablosu
    await db.execute('''
      CREATE TABLE meals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        foods TEXT NOT NULL,
        date INTEGER NOT NULL,
        calories INTEGER,
        taskId INTEGER
      )
    ''');
  }

  // Veritabanı sürümünü güncelleme işlemi
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // users tablosuna yeni sütunlar ekle
      await db.execute('ALTER TABLE users ADD COLUMN profileImagePath TEXT;');
      await db.execute('ALTER TABLE users ADD COLUMN createdAt INTEGER;');
      
      // daily_tasks tablosuna type sütunu ekle
      await db.execute('ALTER TABLE daily_tasks ADD COLUMN type INTEGER DEFAULT 0;');
    }
  }

  // Kullanıcı işlemleri
  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    
    if (maps.isEmpty) {
      return null;
    }
    
    return UserModel.fromMap(maps.first);
  }

  Future<void> updateUser(UserModel user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Kilo geçmişi işlemleri
  Future<int> insertWeightRecord(WeightRecord record, int userId) async {
    final db = await database;
    Map<String, dynamic> map = record.toMap();
    map['user_id'] = userId;
    return await db.insert('weight_records', map);
  }

  Future<List<WeightRecord>> getWeightHistory(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'weight_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => WeightRecord.fromMap(maps[i]));
  }

  // Günlük görev işlemleri
  Future<int> insertTask(DailyTask task) async {
    final db = await database;
    return await db.insert(
      'daily_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(DailyTask task) async {
    final db = await database;
    await db.update(
      'daily_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<List<DailyTask>> getTasksForDay(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_tasks',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );
    
    return List.generate(maps.length, (i) => DailyTask.fromMap(maps[i]));
  }

  // Aktivite işlemleri
  Future<int> insertActivity(ActivityRecord activity) async {
    final db = await database;
    return await db.insert(
      'activities',
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateActivity(ActivityRecord activity) async {
    final db = await database;
    await db.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  Future<void> deleteActivity(int id) async {
    final db = await database;
    await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ActivityRecord>> getActivitiesForDay(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );
    
    return List.generate(maps.length, (i) => ActivityRecord.fromMap(maps[i]));
  }

  Future<List<ActivityRecord>> getActivitiesInRange(DateTime start, DateTime end) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    
    return List.generate(maps.length, (i) => ActivityRecord.fromMap(maps[i]));
  }

  // TaskId ile ilgili aktiviteyi bul ve sil
  Future<void> deleteActivityByTaskId(int taskId) async {
    final db = await database;
    await db.delete(
      'activities',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
  }

  // Yemek kaydı işlemleri
  Future<int> insertMeal(MealRecord meal) async {
    final db = await database;
    return await db.insert(
      'meals',
      meal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMeal(MealRecord meal) async {
    final db = await database;
    await db.update(
      'meals',
      meal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
  }

  Future<void> deleteMeal(int id) async {
    final db = await database;
    await db.delete(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // TaskId ile ilgili yemeği bul ve sil
  Future<void> deleteMealByTaskId(int taskId) async {
    final db = await database;
    await db.delete(
      'meals',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
  }

  Future<List<MealRecord>> getMealsForDay(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );
    
    return List.generate(maps.length, (i) => MealRecord.fromMap(maps[i]));
  }

  Future<List<MealRecord>> getMealsInRange(DateTime start, DateTime end) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    
    return List.generate(maps.length, (i) => MealRecord.fromMap(maps[i]));
  }
} 