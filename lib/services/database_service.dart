import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/activity_record.dart';
import '../models/meal_record.dart';
import '../models/task_type.dart';
import '../models/chat_model.dart';
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
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Foreign key kısıtlamalarını etkinleştir
        await db.execute('PRAGMA foreign_keys = ON');
        
        // Tablo oluşturma işlemlerini manuel çağıralım
        final version = await db.getVersion();
        if (version < 6) {
          await _onUpgrade(db, version, 6);
        }
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS chat_conversations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            lastMessageAt INTEGER
          )
        ''');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS chat_messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conversationId INTEGER NOT NULL,
            text TEXT NOT NULL,
            isUser INTEGER NOT NULL,
            timestamp INTEGER NOT NULL,
            FOREIGN KEY (conversationId) REFERENCES chat_conversations (id) ON DELETE CASCADE
          )
        ''');
        
        // void dönen callback olduğu için burada return olmayacak
      },
    );
  }

  Future<Database> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        profileImagePath TEXT,
        createdAt INTEGER NOT NULL,
        lastWeightUpdate INTEGER NOT NULL,
        email TEXT,
        phoneNumber TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS weight_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        date INTEGER NOT NULL,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        durationMinutes INTEGER NOT NULL,
        date INTEGER NOT NULL,
        notes TEXT,
        taskId INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        foods TEXT NOT NULL,
        date INTEGER NOT NULL,
        calories INTEGER,
        taskId INTEGER,
        notes TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        type INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        date INTEGER NOT NULL
      )
    ''');
    
    return db;
  }

  Future<Database> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE users ADD COLUMN email TEXT;');
      await db.execute('ALTER TABLE users ADD COLUMN phoneNumber TEXT;');
    }
    
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE meals ADD COLUMN notes TEXT;');
    }
    
    if (oldVersion < 5) {
      // Sohbet konuşmaları için tablo
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_conversations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          lastMessageAt INTEGER
        )
      ''');
      
      // Sohbet mesajları için tablo
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_messages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          conversationId INTEGER NOT NULL,
          text TEXT NOT NULL,
          isUser INTEGER NOT NULL,
          timestamp INTEGER NOT NULL,
          FOREIGN KEY (conversationId) REFERENCES chat_conversations (id) ON DELETE CASCADE
        )
      ''');
    }
    
    if (oldVersion < 6) {
      // Sohbet tabloları zaten onOpen'da oluşturuluyor
      // Burada başka değişiklikler yapılabilir
      
      // Önceki tabloları silip yeniden oluşturmak için (veri kaybı olur)
      // await db.execute('DROP TABLE IF EXISTS chat_conversations');
      // await db.execute('DROP TABLE IF EXISTS chat_messages');
    }
    
    return db;
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
    map['userId'] = userId;
    return await db.insert('weight_records', map);
  }

  Future<List<WeightRecord>> getWeightHistory(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'weight_records',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => WeightRecord.fromMap(maps[i]));
  }

  // Günlük görev işlemleri
  Future<int> insertTask(DailyTask task) async {
    final db = await database;
    return await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(DailyTask task) async {
    final db = await database;
    await db.update(
      'tasks',
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
      'tasks',
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
    
    return List.generate(maps.length, (i) {
      return ActivityRecord.fromMap(maps[i]);
    });
  }

  Future<List<ActivityRecord>> getActivitiesInRange(DateTime start, DateTime end) async {
    final db = await database;
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day).add(Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
    );
    
    return List.generate(maps.length, (i) {
      return ActivityRecord.fromMap(maps[i]);
    });
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
    
    return List.generate(maps.length, (i) {
      return MealRecord.fromMap(maps[i]);
    });
  }

  Future<List<MealRecord>> getMealsInRange(DateTime start, DateTime end) async {
    final db = await database;
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day).add(Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
    );
    
    return List.generate(maps.length, (i) {
      return MealRecord.fromMap(maps[i]);
    });
  }

  // Chat Conversations CRUD Operations
  Future<int> createChatConversation(ChatConversation conversation) async {
    final db = await database;
    return await db.insert('chat_conversations', conversation.toMap());
  }

  Future<List<ChatConversation>> getAllChatConversations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_conversations',
      orderBy: 'lastMessageAt DESC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => ChatConversation.fromMap(maps[i]));
  }

  Future<ChatConversation?> getChatConversation(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_conversations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ChatConversation.fromMap(maps.first);
  }

  Future<void> updateChatConversation(ChatConversation conversation) async {
    final db = await database;
    await db.update(
      'chat_conversations',
      conversation.toMap(),
      where: 'id = ?',
      whereArgs: [conversation.id],
    );
  }

  Future<void> deleteChatConversation(int id) async {
    final db = await database;
    await db.delete(
      'chat_conversations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Chat Messages CRUD Operations
  Future<int> createChatMessage(ChatMessage message) async {
    final db = await database;
    final messageId = await db.insert('chat_messages', message.toMap());
    
    // Konuşmanın son mesaj zamanını güncelle
    final conversation = await getChatConversation(message.conversationId);
    if (conversation != null) {
      await updateChatConversation(
        conversation.copyWith(lastMessageAt: message.timestamp),
      );
    }
    
    return messageId;
  }

  Future<List<ChatMessage>> getMessagesForConversation(int conversationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }
} 