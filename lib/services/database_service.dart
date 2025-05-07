import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/activity_record.dart';
import '../models/meal_record.dart';
import '../models/task_type.dart';
import '../models/chat_model.dart';
import '../models/exercise_model.dart';
import '../models/food_item.dart';
import '../models/workout_log.dart';
import '../models/exercise_log.dart';
import '../models/workout_set.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // groupBy için eklendi
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io'; // Dosya işlemleri için eklendi
import 'package:flutter/services.dart'
    show rootBundle; // Asset okumak için eklendi

// Basit beslenme özeti modeli (isteğe bağlı, Map de kullanılabilir)
class NutritionSummary {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  NutritionSummary(
      {this.calories = 0, this.protein = 0, this.carbs = 0, this.fat = 0});
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  static const int _dbVersion =
      19; // 18'den 19'a yükseltildi (autoCalculateNutrition eklendi)

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Public getter for the database instance
  Future<Database> get dbInstance async => await database;

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'kaplanfit.db');
    print("Veritabanı yolu: $path");
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        print("Veritabanı açıldı, sürüm: ${await db.getVersion()}");
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    print("Veritabanı oluşturuluyor (ilk kez), sürüm: $version");
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        profileImagePath TEXT,
        email TEXT,
        phoneNumber TEXT,
        gender TEXT,
        createdAt INTEGER NOT NULL,
        lastWeightUpdate INTEGER NOT NULL,
        targetCalories REAL,
        targetProtein REAL,
        targetCarbs REAL,
        targetFat REAL,
        targetWeight REAL,
        weeklyWeightGoal REAL,
        activityLevel TEXT,
        targetWaterIntake REAL,
        weeklyActivityGoal REAL,
        autoCalculateNutrition INTEGER DEFAULT 0 -- YENİ: Varsayılan 0 (false)
      )
    ''');
    print("Users tablosu oluşturuldu.");

    await db.execute('''
      CREATE TABLE IF NOT EXISTS weight_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        date INTEGER NOT NULL,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    print("Weight Records tablosu oluşturuldu.");

    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        durationMinutes INTEGER NOT NULL,
        date INTEGER NOT NULL,
        notes TEXT,
        taskId INTEGER,
        caloriesBurned REAL
      )
    ''');
    print("Activities tablosu oluşturuldu.");

    await db.execute('''
      CREATE TABLE IF NOT EXISTS meals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        foods TEXT NOT NULL,
        date INTEGER NOT NULL,
        calories INTEGER,
        taskId INTEGER,
        notes TEXT,
        proteinGrams REAL,
        carbsGrams REAL,
        fatGrams REAL,
        userId INTEGER, -- YENİ: userId eklendi
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    print("Meals tablosu oluşturuldu.");

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        type INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        date INTEGER NOT NULL,
        estimatedCalories REAL,
        estimatedProtein REAL,
        estimatedCarbs REAL,
        estimatedFat REAL
      )
    ''');
    print("Tasks tablosu oluşturuldu.");

    await _createExercisesTable(db);
    await _createFoodsTable(db);
    await _createChatTables(db);
    await _createWorkoutTables(db);

    // YENİ: Water Log tablosu
    await db.execute('''
      CREATE TABLE IF NOT EXISTS water_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL UNIQUE, -- Sadece gün bazında tek kayıt
        amount_ml INTEGER NOT NULL DEFAULT 0,
        userId INTEGER, 
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    print("Water Log tablosu oluşturuldu.");

    print("Tüm tablolar oluşturuldu.");
  }

  Future<void> _createExercisesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercises(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        targetMuscleGroup TEXT NOT NULL,
        equipment TEXT,
        videoUrl TEXT,
        isCustom INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
    print("Exercises tablosu oluşturuldu.");
  }

  Future<void> _createFoodsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS foods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        category TEXT NOT NULL, -- Eklendi
        servingSizeG REAL NOT NULL, -- servingSize -> servingSizeG ve REAL yapıldı
        caloriesKcal REAL NOT NULL, -- caloriesPerServing -> caloriesKcal
        proteinG REAL NOT NULL, -- proteinPerServing -> proteinG
        carbsG REAL NOT NULL, -- carbsPerServing -> carbsG
        fatG REAL NOT NULL, -- fatPerServing -> fatG
        name_lowercase TEXT, -- Arama için eklendi
        isCustom INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT -- NOT NULL kaldırıldı, import sırasında ayarlanmayabilir
      )
    ''');
    print("Foods tablosu oluşturuldu.");
    // _prepopulateFoods(db); // Bu fonksiyon yerine asset'ten import kullanılıyor gibi
  }

  Future<void> _prepopulateFoods(Database db) async {
    print("Başlangıç besinleri (_prepopulateFoods) ekleniyor...");
    const String foodDataTsv = """
Besin Adı	Kategori	Porsiyon (g)	Kalori (kcal)	Karbonhidrat (g)	Protein (g)	Yağ (g)
Salatalık	Sebzeler	91	13.7	3.3	0.6	0.1
Pirinç (pişmiş)	Tahıllar	160	208.0	45.0	4.6	0.4
Tavuk Göğsü	Et Ürünleri	98	161.7	0.0	30.4	3.5
Mercimek (pişmiş)	Baklagiller	156	218.4	37.4	18.7	0.8
Makarna (haşlanmış)	Tahıllar	146	214.1	38.9	6.8	1.3
Tam Buğday Ekmeği	Tahıllar	45	108.0	18.0	3.6	1.4
Tam Buğday Ekmeği	Tahıllar	55	132.0	22.0	4.4	1.6
Havuç	Sebzeler	108	44.3	10.8	1.0	0.2
Yoğurt (tam yağlı)	Süt Ürünleri	194	130.0	9.7	5.8	6.8
Havuç	Sebzeler	97	39.8	9.7	0.9	0.2
Makarna (haşlanmış)	Tahıllar	160	234.7	42.7	7.5	1.4
Tavuk Göğsü	Et Ürünleri	109	179.8	0.0	33.8	3.9
Nohut (pişmiş)	Baklagiller	154	246.4	35.9	12.3	4.1
Ceviz	Kuruyemişler	24	160.0	3.2	4.0	16.0
Beyaz Peynir	Süt Ürünleri	43	114.4	0.9	6.0	9.5
Domates	Sebzeler	156	28.1	6.0	1.4	0.3
Ceviz	Kuruyemişler	22	146.7	2.9	3.7	14.7
Tavuk Göğsü	Et Ürünleri	92	151.8	0.0	28.5	3.3
Haşlanmış Yumurta	Yumurtalar	55	85.8	0.7	6.9	5.8
Mercimek (pişmiş)	Baklagiller	143	200.2	34.3	17.2	0.8
Tavuk Göğsü	Et Ürünleri	108	178.2	0.0	33.5	3.9
Fındık	Kuruyemişler	32	192.0	5.3	4.3	18.1
Tavuk Göğsü	Et Ürünleri	103	169.9	0.0	31.9	3.7
Beyaz Peynir	Süt Ürünleri	59	156.9	1.2	8.3	13.0
Mercimek (pişmiş)	Baklagiller	140	196.0	33.6	16.8	0.7
Pirinç (pişmiş)	Tahıllar	141	183.3	39.7	4.0	0.4
Mercimek (pişmiş)	Baklagiller	143	200.2	34.3	17.2	0.8
Karpuz	Meyveler	204	61.2	15.3	1.2	0.2
Karpuz	Meyveler	196	58.8	14.7	1.2	0.2
Yoğurt (tam yağlı)	Süt Ürünleri	202	135.3	10.1	6.1	7.1
Muz	Meyveler	115	100.6	25.9	1.2	0.3
Bulgur (pişmiş)	Tahıllar	145	135.3	29.0	3.9	0.2
Elma	Meyveler	160	83.2	22.4	0.3	0.2
Makarna (haşlanmış)	Tahıllar	145	212.7	38.7	6.8	1.3
Haşlanmış Yumurta	Yumurtalar	49	76.4	0.6	6.2	5.2
Ceviz	Kuruyemişler	32	213.3	4.3	5.3	21.3
Zeytinyağı	Yağlar	11	99.0	0.0	0.0	11.0
Havuç	Sebzeler	107	43.9	10.7	1.0	0.2
Salatalık	Sebzeler	102	15.3	3.7	0.7	0.1
Muz	Meyveler	113	98.9	25.4	1.2	0.3
Mercimek (pişmiş)	Baklagiller	150	210.0	36.0	18.0	0.8
Pirinç (pişmiş)	Tahıllar	157	204.1	44.2	4.5	0.4
Pirinç (pişmiş)	Tahıllar	146	189.8	41.1	4.2	0.4
Haşlanmış Yumurta	Yumurtalar	42	65.5	0.5	5.3	4.5
Makarna (haşlanmış)	Tahıllar	154	225.9	41.1	7.2	1.3
Tam Buğday Ekmeği	Tahıllar	59	141.6	23.6	4.7	1.8
Nohut (pişmiş)	Baklagiller	144	230.4	33.6	11.5	3.8
Patates (haşlanmış)	Sebzeler	146	126.5	29.2	2.9	0.2
Patates (haşlanmış)	Sebzeler	152	131.7	30.4	3.0	0.2
Mercimek (pişmiş)	Baklagiller	147	205.8	35.3	17.6	0.8
Pirinç (pişmiş)	Tahıllar	143	185.9	40.2	4.1	0.4
Muz	Meyveler	128	112.0	28.8	1.4	0.3
Domates	Sebzeler	147	26.5	5.7	1.3	0.3
Elma	Meyveler	146	75.9	20.4	0.3	0.2
Dana Kıyma (yağlı)	Et Ürünleri	101	252.5	0.0	18.2	20.2
Kuzu Pirzola	Et Ürünleri	91	267.5	0.0	23.3	19.1
Dana Kıyma (yağlı)	Et Ürünleri	104	260.0	0.0	18.7	20.8
Portakal	Meyveler	120	57.2	14.2	1.1	0.2
Bulgur (pişmiş)	Tahıllar	155	144.7	31.0	4.1	0.2
Fındık	Kuruyemişler	24	144.0	4.0	3.2	13.6
Domates	Sebzeler	147	26.5	5.7	1.3	0.3
Süt (tam yağlı)	Süt Ürünleri	198	128.7	9.9	6.5	7.1
Nohut (pişmiş)	Baklagiller	148	236.8	34.5	11.8	3.9
Tam Buğday Ekmeği	Tahıllar	54	129.6	21.6	4.3	1.6
Mercimek (pişmiş)	Baklagiller	148	207.2	35.5	17.8	0.8
Salatalık	Sebzeler	104	15.6	3.7	0.7	0.1
Salatalık	Sebzeler	101	15.2	3.6	0.7	0.1
Mercimek (pişmiş)	Baklagiller	153	214.2	36.7	18.4	0.8
Patates (haşlanmış)	Sebzeler	143	123.9	28.6	2.9	0.2
Tavuk Göğsü	Et Ürünleri	105	173.2	0.0	32.5	3.8
Patates (haşlanmış)	Sebzeler	149	129.1	29.8	3.0	0.2
Tavuk Göğsü	Et Ürünleri	91	150.2	0.0	28.2	3.3
Kuzu Pirzola	Et Ürünleri	103	302.8	0.0	26.4	21.6
Mercimek (pişmiş)	Baklagiller	140	196.0	33.6	16.8	0.7
Nohut (pişmiş)	Baklagiller	145	232.0	33.8	11.6	3.9
Fındık	Kuruyemişler	21	126.0	3.5	2.8	11.9
Beyaz Peynir	Süt Ürünleri	57	151.6	1.1	8.0	12.5
Mercimek (pişmiş)	Baklagiller	155	217.0	37.2	18.6	0.8
Havuç	Sebzeler	104	42.6	10.4	0.9	0.2
Havuç	Sebzeler	95	39.0	9.5	0.9	0.2
Kuzu Pirzola	Et Ürünleri	92	270.5	0.0	23.6	19.3
Nohut (pişmiş)	Baklagiller	158	252.8	36.9	12.6	4.2
Patates (haşlanmış)	Sebzeler	152	131.7	30.4	3.0	0.2
Zeytinyağı	Yağlar	0	0.0	0.0	0.0	0.0
Yoğurt (tam yağlı)	Süt Ürünleri	200	134.0	10.0	6.0	7.0
Domates	Sebzeler	149	26.8	5.8	1.3	0.3
Havuç	Sebzeler	97	39.8	9.7	0.9	0.2
Domates	Sebzeler	159	28.6	6.1	1.4	0.3
Dana Kıyma (yağlı)	Et Ürünleri	108	270.0	0.0	19.4	21.6
Mercimek (pişmiş)	Baklagiller	157	219.8	37.7	18.8	0.8
Bulgur (pişmiş)	Tahıllar	151	140.9	30.2	4.0	0.2
Portakal	Meyveler	123	58.7	14.6	1.1	0.2
Havuç	Sebzeler	97	39.8	9.7	0.9	0.2
Makarna (haşlanmış)	Tahıllar	158	231.7	42.1	7.4	1.4
Dana Kıyma (yağlı)	Et Ürünleri	106	265.0	0.0	19.1	21.2
Havuç	Sebzeler	102	41.8	10.2	0.9	0.2
Fındık	Kuruyemişler	30	180.0	5.0	4.0	17.0
Badem	Kuruyemişler	27	153.0	5.4	5.4	13.5
Mercimek (pişmiş)	Baklagiller	145	203.0	34.8	17.4	0.8
Zeytinyağı	Yağlar	8	72.0	0.0	0.0	8.0
Portakal	Meyveler	123	58.7	14.6	1.1	0.2
Kuzu Pirzola	Et Ürünleri	105	308.7	0.0	26.9	22.1
Tam Buğday Ekmeği	Tahıllar	52	124.8	20.8	4.2	1.6
Bulgur (pişmiş)	Tahıllar	141	131.6	28.2	3.8	0.2
Mercimek (pişmiş)	Baklagiller	157	219.8	37.7	18.8	0.8
Haşlanmış Yumurta	Yumurtalar	53	82.7	0.6	6.7	5.6
Fındık	Kuruyemişler	38	228.0	6.3	5.1	21.5
Bulgur (pişmiş)	Tahıllar	144	134.4	28.8	3.8	0.2
Pirinç (pişmiş)	Tahıllar	155	201.5	43.6	4.4	0.4
Patates (haşlanmış)	Sebzeler	153	132.6	30.6	3.1	0.2
Havuç	Sebzeler	103	42.2	10.3	0.9	0.2
Tavuk Göğsü	Et Ürünleri	105	173.2	0.0	32.5	3.8
Ceviz	Kuruyemişler	37	246.7	4.9	6.2	24.7
Ceviz	Kuruyemişler	25	166.7	3.3	4.2	16.7
Dana Kıyma (yağlı)	Et Ürünleri	98	245.0	0.0	17.6	19.6
Havuç	Sebzeler	102	41.8	10.2	0.9	0.2
Zeytinyağı	Yağlar	9	81.0	0.0	0.0	9.0
Patates (haşlanmış)	Sebzeler	148	128.3	29.6	3.0	0.2
Kuzu Pirzola	Et Ürünleri	91	267.5	0.0	23.3	19.1
Zeytinyağı	Yağlar	11	99.0	0.0	0.0	11.0
Tam Buğday Ekmeği	Tahıllar	41	98.4	16.4	3.3	1.2
Salatalık	Sebzeler	98	14.7	3.5	0.7	0.1
Karpuz	Meyveler	204	61.2	15.3	1.2	0.2
Patates (haşlanmış)	Sebzeler	153	132.6	30.6	3.1	0.2
Domates	Sebzeler	152	27.4	5.9	1.3	0.3
Havuç	Sebzeler	104	42.6	10.4	0.9	0.2
Patates (haşlanmış)	Sebzeler	155	134.3	31.0	3.1	0.2
Portakal	Meyveler	122	58.2	14.5	1.1	0.2
Badem	Kuruyemişler	34	192.7	6.8	6.8	17.0
Domates	Sebzeler	151	27.2	5.8	1.3	0.3
Beyaz Peynir	Süt Ürünleri	48	127.7	1.0	6.7	10.6
Süt (tam yağlı)	Süt Ürünleri	198	128.7	9.9	6.5	7.1
Muz	Meyveler	113	98.9	25.4	1.2	0.3
Fındık	Kuruyemişler	21	126.0	3.5	2.8	11.9
Bulgur (pişmiş)	Tahıllar	150	140.0	30.0	4.0	0.2
Kuzu Pirzola	Et Ürünleri	107	314.6	0.0	27.4	22.5
Patates (haşlanmış)	Sebzeler	160	138.7	32.0	3.2	0.2
Domates	Sebzeler	148	26.6	5.7	1.3	0.3
Tavuk Göğsü	Et Ürünleri	98	161.7	0.0	30.4	3.5
Muz	Meyveler	113	98.9	25.4	1.2	0.3
Salatalık	Sebzeler	96	14.4	3.5	0.7	0.1
Elma	Meyveler	159	82.7	22.3	0.3	0.2
Beyaz Peynir	Süt Ürünleri	58	154.3	1.2	8.1	12.8
Karpuz	Meyveler	209	62.7	15.7	1.3	0.2
Kuzu Pirzola	Et Ürünleri	110	323.4	0.0	28.2	23.1
Fındık	Kuruyemişler	34	204.0	5.7	4.5	19.3
Ceviz	Kuruyemişler	20	133.3	2.7	3.3	13.3
Muz	Meyveler	119	104.1	26.8	1.3	0.3
Tavuk Göğsü	Et Ürünleri	98	161.7	0.0	30.4	3.5
Badem	Kuruyemişler	27	153.0	5.4	5.4	13.5
Bulgur (pişmiş)	Tahıllar	141	131.6	28.2	3.8	0.2
Patates (haşlanmış)	Sebzeler	152	131.7	30.4	3.0	0.2
Ceviz	Kuruyemişler	26	173.3	3.5	4.3	17.3
Kuzu Pirzola	Et Ürünleri	95	279.3	0.0	24.3	19.9
Havuç	Sebzeler	110	45.1	11.0	1.0	0.2
Tavuk Göğsü	Et Ürünleri	103	169.9	0.0	31.9	3.7
Yoğurt (tam yağlı)	Süt Ürünleri	199	133.3	9.9	6.0	7.0
Tam Buğday Ekmeği	Tahıllar	42	100.8	16.8	3.4	1.3
Kuzu Pirzola	Et Ürünleri	93	273.4	0.0	23.8	19.5
Kuzu Pirzola	Et Ürünleri	105	308.7	0.0	26.9	22.1
Haşlanmış Yumurta	Yumurtalar	40	62.4	0.5	5.0	4.2
Bulgur (pişmiş)	Tahıllar	142	132.5	28.4	3.8	0.2
Fındık	Kuruyemişler	21	126.0	3.5	2.8	11.9
Fındık	Kuruyemişler	36	216.0	6.0	4.8	20.4
Haşlanmış Yumurta	Yumurtalar	55	85.8	0.7	6.9	5.8
Nohut (pişmiş)	Baklagiller	145	232.0	33.8	11.6	3.9
Havuç	Sebzeler	101	41.4	10.1	0.9	0.2
Salatalık	Sebzeler	98	14.7	3.5	0.7	0.1
Haşlanmış Yumurta	Yumurtalar	51	79.6	0.6	6.4	5.4
Tavuk Göğsü	Et Ürünleri	99	163.3	0.0	30.7	3.6
Haşlanmış Yumurta	Yumurtalar	57	88.9	0.7	7.2	6.0
Salatalık	Sebzeler	99	14.8	3.6	0.7	0.1
Tam Buğday Ekmeği	Tahıllar	49	117.6	19.6	3.9	1.5
Patates (haşlanmış)	Sebzeler	151	130.9	30.2	3.0	0.2
Badem	Kuruyemişler	40	226.7	8.0	8.0	20.0
Yoğurt (tam yağlı)	Süt Ürünleri	205	137.3	10.2	6.2	7.2
Pirinç (pişmiş)	Tahıllar	151	196.3	42.5	4.3	0.4
Badem	Kuruyemişler	22	124.7	4.4	4.4	11.0
Bulgur (pişmiş)	Tahıllar	150	140.0	30.0	4.0	0.2
Elma	Meyveler	146	77.0	20.7	0.3	0.2
Dana Kıyma (yağlı)	Et Ürünleri	98	245.0	0.0	17.6	19.6
Zeytinyağı	Yağlar	8	72.0	0.0	0.0	8.0
Salatalık	Sebzeler	110	16.5	4.0	0.8	0.1
Süt (tam yağlı)	Süt Ürünleri	195	126.8	9.8	6.4	7.0
Bulgur (pişmiş)	Tahıllar	145	135.3	29.0	3.9	0.2
Domates	Sebzeler	146	26.3	5.6	1.3	0.3
Salatalık	Sebzeler	108	16.2	3.9	0.8	0.1
Yoğurt (tam yağlı)	Süt Ürünleri	192	128.6	9.6	5.8	6.7
Beyaz Peynir	Süt Ürünleri	42	111.7	0.8	5.9	9.2
Zeytinyağı	Yağlar	11	99.0	0.0	0.0	11.0
Portakal	Meyveler	137	65.3	16.2	1.3	0.2
Patates (haşlanmış)	Sebzeler	151	130.9	30.2	3.0	0.2
Muz	Meyveler	110	96.2	24.8	1.2	0.3
Kuzu Pirzola	Et Ürünleri	102	299.9	0.0	26.1	21.4
Tam Buğday Ekmeği	Tahıllar	41	98.4	16.4	3.3	1.2
Muz	Meyveler	124	108.5	27.9	1.3	0.3
Makarna (haşlanmış)	Tahıllar	140	205.3	37.3	6.5	1.2
Portakal	Meyveler	132	63.0	15.6	1.2	0.2
Ceviz	Kuruyemişler	38	253.3	5.1	6.3	25.3
Patates (haşlanmış)	Sebzeler	160	138.7	32.0	3.2	0.2
Haşlanmış Yumurta	Yumurtalar	58	90.5	0.7	7.3	6.1
Muz	Meyveler	119	104.1	26.8	1.3	0.3
Badem	Kuruyemişler	22	124.7	4.4	4.4	11.0
Mercimek (pişmiş)	Baklagiller	151	211.4	36.2	18.1	0.8
Tam Buğday Ekmeği	Tahıllar	47	112.8	18.8	3.8	1.4
Badem	Kuruyemişler	21	119.0	4.2	4.2	10.5
Salatalık	Sebzeler	106	15.9	3.8	0.7	0.1
Badem	Kuruyemişler	38	215.3	7.6	7.6	19.0
Nohut (pişmiş)	Baklagiller	152	243.2	35.5	12.2	4.1
Kuzu Pirzola	Et Ürünleri	90	264.6	0.0	23.0	18.9
Badem	Kuruyemişler	20	113.3	4.0	4.0	10.0
Dana Kıyma (yağlı)	Et Ürünleri	91	227.5	0.0	16.4	18.2
Havuç	Sebzeler	105	43.0	10.5	0.9	0.2
Bulgur (pişmiş)	Tahıllar	151	140.9	30.2	4.0	0.2
Domates	Sebzeler	142	25.6	5.5	1.2	0.3
Salatalık	Sebzeler	106	15.9	3.9	0.7	0.1
Zeytinyağı	Yağlar	2	18.0	0.0	0.0	2.0
Pirinç (pişmiş)	Tahıllar	152	197.6	42.8	4.4	0.4
Mercimek (pişmiş)	Baklagiller	150	210.0	36.0	18.0	0.8
Mercimek (pişmiş)	Baklagiller	150	210.0	36.0	18.0	0.8
Bulgur (pişmiş)	Tahıllar	156	145.6	31.2	4.2	0.2
Zeytinyağı	Yağlar	15	135.0	0.0	0.0	15.0
Bulgur (pişmiş)	Tahıllar	151	140.9	30.2	4.0	0.2
Mercimek (pişmiş)	Baklagiller	143	200.2	34.3	17.2	0.8
Yoğurt (tam yağlı)	Süt Ürünleri	205	137.3	10.2	6.2	7.2
Tam Buğday Ekmeği	Tahıllar	59	141.6	23.6	4.7	1.8
Haşlanmış Yumurta	Yumurtalar	49	76.4	0.6	6.2	5.2
Beyaz Peynir	Süt Ürünleri	45	119.7	0.9	6.3	9.9
Nohut (pişmiş)	Baklagiller	151	241.6	35.2	12.1	4.0
Fındık	Kuruyemişler	31	186.0	5.2	4.1	17.6
Havuç	Sebzeler	97	39.8	9.7	0.9	0.2
Haşlanmış Yumurta	Yumurtalar	48	74.9	0.6	6.0	5.1
Ceviz	Kuruyemişler	22	146.7	2.9	3.7	14.7
Dana Kıyma (yağlı)	Et Ürünleri	94	235.0	0.0	16.9	18.8
Elma	Meyveler	149	77.5	20.9	0.3	0.2
Tam Buğday Ekmeği	Tahıllar	56	134.4	22.4	4.5	1.7
Nohut (pişmiş)	Baklagiller	153	244.8	35.7	12.2	4.1
Tavuk Göğsü	Et Ürünleri	92	151.8	0.0	28.5	3.3
Karpuz	Meyveler	196	58.8	14.7	1.2	0.2
Domates	Sebzeler	147	26.5	5.7	1.3	0.3
Zeytinyağı	Yağlar	7	63.0	0.0	0.0	7.0
Tam Buğday Ekmeği	Tahıllar	41	98.4	16.4	3.3	1.2
Kuzu Pirzola	Et Ürünleri	91	267.5	0.0	23.3	19.1
Nohut (pişmiş)	Baklagiller	148	236.8	34.5	11.8	3.9
Kuzu Pirzola	Et Ürünleri	99	291.1	0.0	25.3	20.8
Badem	Kuruyemişler	33	187.0	6.6	6.6	16.5
Yoğurt (tam yağlı)	Süt Ürünleri	195	130.7	9.8	5.8	6.8
Dana Kıyma (yağlı)	Et Ürünleri	105	262.5	0.0	18.9	21.0
Domates	Sebzeler	141	25.4	5.5	1.2	0.3
Ceviz	Kuruyemişler	38	253.3	5.1	6.3	25.3
Ceviz	Kuruyemişler	25	166.7	3.3	4.2	16.7
Salatalık	Sebzeler	96	14.4	3.5	0.7	0.1
Bulgur (pişmiş)	Tahıllar	155	144.7	31.0	4.1	0.2
Elma	Meyveler	146	75.9	20.4	0.3	0.2
Fındık	Kuruyemişler	32	192.0	5.3	4.3	18.1
Beyaz Peynir	Süt Ürünleri	45	119.7	0.9	6.3	10.8
Makarna (haşlanmış)	Tahıllar	145	212.7	38.7	6.8	1.3
Elma	Meyveler	140	72.8	19.6	0.3	0.2
Dana Kıyma (yağlı)	Et Ürünleri	97	242.5	0.0	17.5	19.4
Badem	Kuruyemişler	25	141.7	5.0	5.0	12.5
Elma	Meyveler	155	80.6	21.7	0.3	0.2
Tavuk Göğsü	Et Ürünleri	103	169.9	0.0	31.9	3.7
Portakal	Meyveler	130	62.0	15.4	1.2	0.2
Nohut (pişmiş)	Baklagiller	147	235.2	34.3	11.8	3.9
Patates (haşlanmış)	Sebzeler	158	136.9	31.6	3.2	0.2
Portakal	Meyveler	126	60.1	14.9	1.2	0.2
Dana Kıyma (yağlı)	Et Ürünleri	94	235.0	0.0	16.9	18.8
Domates	Sebzeler	157	28.3	6.1	1.4	0.3
Yoğurt (tam yağlı)	Süt Ürünleri	190	127.3	9.5	5.7	6.7
Süt (tam yağlı)	Süt Ürünleri	204	132.6	10.2	6.7	7.3
Pirinç (pişmiş)	Tahıllar	149	193.7	41.9	4.3	0.4
Salatalık	Sebzeler	99	14.8	3.6	0.7	0.1
Pirinç (pişmiş)	Tahıllar	154	200.2	43.3	4.4	0.4
Badem	Kuruyemişler	37	209.7	7.4	7.4	18.5
Elma	Meyveler	160	83.2	22.4	0.3	0.2
Tam Buğday Ekmeği	Tahıllar	44	105.6	17.6	3.3	1.3
Süt (tam yağlı)	Süt Ürünleri	197	128.1	9.8	6.5	7.1
Mercimek (pişmiş)	Baklagiller	155	217.0	37.2	18.6	0.8
Tam Buğday Ekmeği	Tahıllar	56	134.4	22.4	4.5	1.7
Makarna (haşlanmış)	Tahıllar	148	217.1	39.5	6.9	1.3
Muz	Meyveler	112	98.0	25.2	1.2	0.3
Ceviz	Kuruyemişler	20	133.3	2.7	3.3	13.3
Salatalık	Sebzeler	93	13.9	3.3	0.7	0.1
Beyaz Peynir	Süt Ürünleri	41	109.1	0.8	5.7	9.0
Pirinç (pişmiş)	Tahıllar	158	205.4	44.5	4.5	0.4
Tam Buğday Ekmeği	Tahıllar	50	120.0	20.0	4.0	1.5
Pirinç (pişmiş)	Tahıllar	142	184.6	39.9	4.1	0.4
Karpuz	Meyveler	203	60.9	15.2	1.2	0.2
Domates	Sebzeler	151	27.2	5.8	1.3	0.3
Muz	Meyveler	125	109.4	28.1	1.4	0.3
Yoğurt (tam yağlı)	Süt Ürünleri	205	137.3	10.2	6.2	7.2
Nohut (pişmiş)	Baklagiller	150	240.0	35.0	12.0	4.0
Nohut (pişmiş)	Baklagiller	152	243.2	35.5	12.2	4.1
Tam Buğday Ekmeği	Tahıllar	48	115.2	19.2	3.8	1.4
Makarna (haşlanmış)	Tahıllar	140	205.3	37.3	6.5	1.2
Haşlanmış Yumurta	Yumurtalar	42	65.5	0.5	5.3	4.5
Bulgur (pişmiş)	Tahıllar	149	139.1	29.8	4.0	0.2
Makarna (haşlanmış)	Tahıllar	144	211.2	38.4	6.7	1.2
Makarna (haşlanmış)	Tahıllar	159	233.2	42.4	7.4	1.4
Tavuk Göğsü	Et Ürünleri	91	150.2	0.0	28.2	3.3
Zeytinyağı	Yağlar	7	63.0	0.0	0.0	7.0
Nohut (pişmiş)	Baklagiller	158	252.8	36.9	12.6	4.2
Domates	Sebzeler	140	25.2	5.4	1.2	0.3
Salatalık	Sebzeler	105	15.8	3.8	0.7	0.1
Kuzu Pirzola	Et Ürünleri	90	264.6	0.0	23.0	18.9
Beyaz Peynir	Süt Ürünleri	40	106.4	0.8	5.6	8.8
Haşlanmış Yumurta	Yumurtalar	59	92.0	0.7	7.4	6.3
Dana Kıyma (yağlı)	Et Ürünleri	107	267.5	0.0	19.3	21.4
Yoğurt (tam yağlı)	Süt Ürünleri	199	133.3	9.9	6.0	7.0
Ceviz	Kuruyemişler	30	200.0	4.0	5.0	20.0
Havuç	Sebzeler	92	37.7	9.2	0.8	0.2
Beyaz Peynir	Süt Ürünleri	47	125.0	0.9	6.6	10.3
Elma	Meyveler	153	79.6	21.4	0.3	0.2
Yoğurt (tam yağlı)	Süt Ürünleri	210	140.7	10.5	6.3	7.3
Zeytinyağı	Yağlar	10	90.0	0.0	0.0	10.0
Dana Kıyma (yağlı)	Et Ürünleri	94	235.0	0.0	16.9	18.8
Patates (haşlanmış)	Sebzeler	157	136.1	31.4	3.1	0.2
Patates (haşlanmış)	Sebzeler	159	137.8	31.8	3.2	0.2
Havuç	Sebzeler	106	43.5	10.6	1.0	0.2
Fındık	Kuruyemişler	37	222.0	6.2	4.9	21.0
Muz	Meyveler	118	103.2	26.6	1.3	0.3
Salatalık	Sebzeler	107	16.1	3.9	0.7	0.1
Yoğurt (tam yağlı)	Süt Ürünleri	196	131.3	9.8	5.9	6.9
Mercimek (pişmiş)	Baklagiller	151	211.4	36.2	18.1	0.8
Bulgur (pişmiş)	Tahıllar	152	141.9	30.4	4.1	0.2
Yoğurt (tam yağlı)	Süt Ürünleri	210	140.7	10.5	6.3	7.3
Pirinç (pişmiş)	Tahıllar	147	191.1	41.4	4.2	0.4
Muz	Meyveler	120	105.0	27.0	1.3	0.3
Portakal	Meyveler	132	63.0	15.6	1.2	0.2
Dana Kıyma (yağlı)	Et Ürünleri	92	230.0	0.0	16.6	18.4
Fındık	Kuruyemişler	38	228.0	6.3	5.1	21.5
Dana Kıyma (yağlı)	Et Ürünleri	91	227.5	0.0	16.4	18.2
Süt (tam yağlı)	Süt Ürünleri	209	135.8	10.4	6.9	7.5
Salatalık	Sebzeler	109	16.4	3.9	0.8	0.1
Tavuk Göğsü	Et Ürünleri	92	151.8	0.0	28.5	3.3
Portakal	Meyveler	133	63.4	15.8	1.2	0.2
Kuzu Pirzola	Et Ürünleri	102	299.9	0.0	26.1	21.4
Zeytinyağı	Yağlar	6	54.0	0.0	0.0	6.0
Mercimek (pişmiş)	Baklagiller	153	214.2	36.7	18.4	0.8
Yoğurt (tam yağlı)	Süt Ürünleri	208	139.4	10.4	6.2	7.3
Domates	Sebzeler	160	28.8	6.2	1.4	0.3
Elma	Meyveler	156	81.1	21.8	0.3	0.2
Karpuz	Meyveler	199	59.7	14.9	1.2	0.2
Karpuz	Meyveler	201	60.3	15.1	1.2	0.2
Domates	Sebzeler	141	25.4	5.5	1.2	0.3
Yoğurt (tam yağlı)	Süt Ürünleri	192	128.6	9.6	5.8	6.7
Tam Buğday Ekmeği	Tahıllar	58	139.2	23.2	4.6	1.7
Patates (haşlanmış)	Sebzeler	140	121.3	28.0	2.8	0.2
Karpuz	Meyveler	193	57.9	14.5	1.2	0.2
Badem	Kuruyemişler	39	221.0	7.8	7.8	19.5
Pirinç (pişmiş)	Tahıllar	145	188.5	40.8	4.2	0.4
Yoğurt (tam yağlı)	Süt Ürünleri	201	134.7	10.1	6.0	7.0
Salatalık	Sebzeler	92	13.8	3.3	0.7	0.1
Mercimek (pişmiş)	Baklagiller	160	224.0	38.4	19.2	0.9
Mercimek (pişmiş)	Baklagiller	153	214.2	36.7	18.4	0.8
Muz	Meyveler	129	112.9	29.0	1.4	0.3
Elma	Meyveler	156	81.1	21.8	0.3	0.2
Mercimek (pişmiş)	Baklagiller	153	214.2	36.7	18.4	0.8
Badem	Kuruyemişler	38	215.3	7.6	7.6	19.0
Mercimek (pişmiş)	Baklagiller	150	210.0	36.0	18.0	0.8
Yoğurt (tam yağlı)	Süt Ürünleri	206	138.0	10.3	6.0	7.0
Portakal	Meyveler	138	65.8	16.3	1.3	0.2
Yoğurt (tam yağlı)	Süt Ürünleri	204	136.7	10.2	6.1	7.1
Tam Buğday Ekmeği	Tahıllar	57	136.8	22.8	4.6	1.7
Muz	Meyveler	130	113.8	29.2	1.4	0.3
Muz	Meyveler	117	102.4	26.3	1.3	0.3
Makarna (haşlanmış)	Tahıllar	145	212.7	38.7	6.8	1.3
Portakal	Meyveler	121	57.7	14.3	1.2	0.2
Fındık	Kuruyemişler	39	234.0	6.5	5.2	22.1
Beyaz Peynir	Süt Ürünleri	48	127.7	1.0	6.7	10.6
Muz	Meyveler	128	112.0	28.8	1.4	0.3
Domates	Sebzeler	144	25.9	5.6	1.2	0.3
Mercimek (pişmiş)	Baklagiller	152	212.8	36.5	18.2	0.8
Süt (tam yağlı)	Süt Ürünleri	193	125.5	9.7	6.4	6.9
Tam Buğday Ekmeği	Tahıllar	52	124.8	20.8	4.2	1.6
Beyaz Peynir	Süt Ürünleri	49	130.3	1.0	6.9	10.8
Fındık	Kuruyemişler	28	168.0	4.7	3.7	15.9
Süt (tam yağlı)	Süt Ürünleri	207	134.6	10.3	6.8	7.5
Pirinç (pişmiş)	Tahıllar	154	200.2	43.3	4.4	0.4
Elma	Meyveler	148	77.0	20.7	0.3	0.2
Zeytinyağı	Yağlar	7	63.0	0.0	0.0	7.0
Domates	Sebzeler	151	27.2	5.8	1.3	0.3
Kuzu Pirzola	Et Ürünleri	109	320.5	0.0	27.9	22.9
Tavuk Göğsü	Et Ürünleri	109	179.8	0.0	33.8	3.9
Yoğurt (tam yağlı)	Süt Ürünleri	207	138.7	10.3	6.2	7.3
Bulgur (pişmiş)	Tahıllar	140	130.7	28.0	3.7	0.2
Elma	Meyveler	147	76.4	20.6	0.3	0.2
Yoğurt (tam yağlı)	Süt Ürünleri	193	129.3	9.7	5.8	6.8
Havuç	Sebzeler	108	44.3	10.8	1.0	0.2
Fındık	Kuruyemişler	30	180.0	5.0	4.0	17.0
Ceviz	Kuruyemişler	36	240.0	4.8	6.0	24.0
Bulgur (pişmiş)	Tahıllar	145	135.3	29.0	3.9	0.2
Elma	Meyveler	160	83.2	22.4	0.3	0.2
Haşlanmış Yumurta	Yumurtalar	54	84.2	0.6	6.8	5.7
Dana Kıyma (yağlı)	Et Ürünleri	94	235.0	0.0	16.9	18.8
Yoğurt (tam yağlı)	Süt Ürünleri	209	140.0	10.4	6.3	7.3
Makarna (haşlanmış)	Tahıllar	151	221.5	40.3	7.0	1.3
Zeytinyağı	Yağlar	18	162.0	0.0	0.0	18.0
Makarna (haşlanmış)	Tahıllar	148	217.1	39.5	6.9	1.3
Patates (haşlanmış)	Sebzeler	153	132.6	30.6	3.1	0.2
Elma	Meyveler	157	81.6	22.0	0.3	0.2
Bulgur (pişmiş)	Tahıllar	156	145.6	31.2	4.2	0.2
Ceviz	Kuruyemişler	23	153.3	3.1	3.8	15.3
Patates (haşlanmış)	Sebzeler	150	130.0	30.0	3.0	0.2
Makarna (haşlanmış)	Tahıllar	147	215.6	39.2	6.9	1.3
Ceviz	Kuruyemişler	33	220.0	4.4	5.5	22.0
Patates (haşlanmış)	Sebzeler	159	137.8	31.8	3.2	0.2
Elma	Meyveler	157	81.6	22.0	0.3	0.2
Fındık	Kuruyemişler	28	168.0	4.7	3.7	15.9
Haşlanmış Yumurta	Yumurtalar	54	84.2	0.6	6.8	5.7
Ceviz	Kuruyemişler	27	180.0	3.6	4.5	18.0
Badem	Kuruyemişler	32	181.3	6.4	6.4	16.0
Zeytinyağı	Yağlar	0	0.0	0.0	0.0	0.0
Süt (tam yağlı)	Süt Ürünleri	195	126.8	9.8	6.4	7.0
Ceviz	Kuruyemişler	20	133.3	2.7	3.3	13.3
Domates	Sebzeler	153	27.5	5.9	1.3	0.3
Ceviz	Kuruyemişler	40	266.7	5.3	6.7	26.7
Nohut (pişmiş)	Baklagiller	158	252.8	36.9	12.6	4.2
Yoğurt (tam yağlı)	Süt Ürünleri	194	130.0	9.7	5.8	6.8
Salatalık	Sebzeler	107	16.1	3.9	0.7	0.1
Pirinç (pişmiş)	Tahıllar	157	204.1	44.2	4.5	0.4
Patates (haşlanmış)	Sebzeler	154	133.5	30.8	3.1	0.2
Badem	Kuruyemişler	22	124.7	4.4	4.4	11.0
Bulgur (pişmiş)	Tahıllar	152	141.9	30.4	4.1	0.2
Elma	Meyveler	150	78.0	21.0	0.3	0.2
Elma	Meyveler	153	79.6	21.4	0.3	0.2
Fındık	Kuruyemişler	29	174.0	4.8	3.9	16.4
Kuzu Pirzola	Et Ürünleri	99	291.1	0.0	25.3	20.8
Karpuz	Meyveler	193	57.9	14.5	1.2	0.2
Pirinç (pişmiş)	Tahıllar	159	206.7	44.7	4.6	0.4
Portakal	Meyveler	128	61.0	15.2	1.2	0.2
Kaşar Peyniri	Süt Ürünleri	100	404.0	1.3	25.0	33.0
Tulum Peyniri	Süt Ürünleri	100	380.0	2.0	22.0	32.0
Lor Peyniri	Süt Ürünleri	100	75.0	1.8	12.0	1.0
Çeçil Peyniri	Süt Ürünleri	100	280.0	2.0	20.0	22.0
Beyaz Ekmek	Tahıllar	50	135.0	25.0	3.5	1.0
Çavdar Ekmeği	Tahıllar	50	120.0	22.0	3.8	0.8
Kepek Ekmeği	Tahıllar	50	115.0	20.0	3.6	0.9
Ayçiçek Yağı	Yağlar	10	90.0	0.0	0.0	10.0
Tereyağı	Yağlar	10	75.0	0.0	0.1	8.3
Margarin	Yağlar	10	81.0	0.0	0.0	9.0
Sucuk	Et Ürünleri	50	215.0	1.0	9.0	20.0
Pastırma	Et Ürünleri	50	140.0	0.0	12.0	9.0
Hindi Füme	Et Ürünleri	50	100.0	1.0	10.0	6.0
Fasulye (kuru, pişmiş)	Baklagiller	150	240.0	35.0	13.0	0.6
Barbunya (pişmiş)	Baklagiller	150	210.0	30.0	11.0	0.5
Yeşil Mercimek (haşlanmış)	Baklagiller	150	210.0	34.0	18.0	0.7
Simit	Unlu Mamuller	100	420.0	70.0	10.0	14.0
Poğaça	Unlu Mamuller	100	410.0	45.0	8.0	20.0
Açma	Unlu Mamuller	100	430.0	46.0	7.0	22.0
Baklava	Tatlılar	100	450.0	50.0	5.0	25.0
Kadayıf	Tatlılar	100	380.0	45.0	6.0	18.0
Revani	Tatlılar	100	390.0	44.0	5.0	20.0
""";

    // Veriyi işleme mantığı (TSV formatında olduğu varsayılarak)
    try {
      final lines = foodDataTsv.trim().split('\n');
      if (lines.length < 2) {
        print("_prepopulateFoods: Yeterli veri satırı bulunamadı.");
        return;
      }

      final header = lines.first.split('\t');
      final nameIndex = header.indexOf('Besin Adı');
      final servingSizeIndex = header.indexOf('Porsiyon (g)');
      final caloriesIndex = header.indexOf('Kalori (kcal)');
      final proteinIndex = header.indexOf('Protein (g)');
      final carbsIndex = header.indexOf('Karbonhidrat (g)');
      final fatIndex = header.indexOf('Yağ (g)');
      final categoryIndex =
          header.indexOf('Kategori'); // Kategori sütununu da bul

      if ([
        nameIndex,
        servingSizeIndex,
        caloriesIndex,
        proteinIndex,
        carbsIndex,
        fatIndex,
        categoryIndex // Kategori index'ini de kontrol et
      ].contains(-1)) {
        print(
            "_prepopulateFoods: Gerekli sütun başlıkları bulunamadı. Başlıklar: $header");
        return;
      }

      List<FoodItem> foodsToInsert = [];
      for (int i = 1; i < lines.length; i++) {
        final values = lines[i].split('\t');
        if (values.length == header.length) {
          final name = values[nameIndex];
          final servingSize = double.tryParse(values[servingSizeIndex]) ??
              0.0; // Yeni: double olarak al
          final calories = double.tryParse(values[caloriesIndex]) ?? 0.0;
          final protein = double.tryParse(values[proteinIndex]) ?? 0.0;
          final carbs = double.tryParse(values[carbsIndex]) ?? 0.0;
          final fat = double.tryParse(values[fatIndex]) ?? 0.0;
          final category = values[categoryIndex]
              .trim(); // Kategoriyi al ve boşlukları temizle

          // Aynı isimde besin zaten var mı kontrol et (büyük/küçük harf duyarsız)
          final existing = await db.query('foods',
              where: 'LOWER(name) = ?',
              whereArgs: [name.toLowerCase()],
              limit: 1);
          if (existing.isEmpty) {
            foodsToInsert.add(FoodItem(
              name: name,
              category: category, // Kategori eklendi
              servingSizeG: servingSize, // Doğru parametre adı ve tipi (double)
              caloriesKcal: calories, // Doğru parametre adı
              proteinG: protein, // Doğru parametre adı
              carbsG: carbs, // Doğru parametre adı
              fatG: fat, // Doğru parametre adı
              // isCustom ve createdAt modelden kaldırıldı, Firestore'da otomatik yönetilebilir
            ));
          } else {
            // print("Zaten var: $name");
          }
        }
      }

      // Toplu ekleme (Batch)
      if (foodsToInsert.isNotEmpty) {
        final batch = db.batch();
        for (var food in foodsToInsert) {
          batch.insert('foods', food.toMap(),
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);
        print(
            "${foodsToInsert.length} adet başlangıç besini başarıyla eklendi.");
      } else {
        print(
            "Eklenecek yeni başlangıç besini bulunamadı veya hepsi zaten mevcut.");
      }
    } catch (e) {
      print("_prepopulateFoods sırasında hata: $e");
    }
  }

  Future<void> _createChatTables(Database db) async {
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
    print("Chat tabloları oluşturuldu.");
  }

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    final map = user.toMap();
    map.remove('weightHistory');
    // YENİ: autoCalculateNutrition için varsayılan değer ekle (eğer modelden gelmezse diye)
    map['autoCalculateNutrition'] ??= 0;
    int id = await db.insert('users', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
    print("[DB] Kullanıcı eklendi, ID: $id, Veri: $map");
    return id;
  }

  Future<UserModel?> getUser(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      print("[DB] Kullanıcı getirildi, ID: $id, Veri: ${maps.first}");
      // Kullanıcıyı oluştururken ağırlık geçmişini de yükle
      final userMap = Map<String, dynamic>.from(maps.first);
      // YENİ: DB'den null gelebilen autoCalculateNutrition için kontrol
      userMap['autoCalculateNutrition'] ??= 0; // Eğer null ise 0 (false) yap
      final user = UserModel.fromMap(userMap);
      final weightHistory = await getWeightHistory(id);
      user.weightHistory = weightHistory;
      return user;
    } else {
      print("[DB] Kullanıcı bulunamadı, ID: $id");
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    final db = await database;
    if (user.id == null) {
      throw Exception('Güncellenecek kullanıcı bulunamadı');
    }

    // Eğer ağırlık değişmişse, kilo geçmişine yeni kayıt ekle
    UserModel? existingUser = await getUser(user.id!);
    if (existingUser != null && existingUser.weight != user.weight) {
      // Kilo değişmiş, yeni kilo kaydı ekle
      await addWeightRecord(
          WeightRecord(
            weight: user.weight,
            date: DateTime.now(),
          ),
          user.id!);

      // lastWeightUpdate alanını da güncelle
      user = user.copyWith(lastWeightUpdate: DateTime.now());
    }

    final map = user.toMap();
    map.remove('weightHistory');
    // YENİ: autoCalculateNutrition için varsayılan değer ekle
    map['autoCalculateNutrition'] ??= 0;
    print("[DB] Kullanıcı güncelleniyor, ID: ${user.id}, Veri: $map");

    await db.update(
      'users',
      map,
      where: 'id = ?',
      whereArgs: [user.id],
    );
    print("[DB] Kullanıcı güncellendi, ID: ${user.id}");
  }

  Future<int> addWeightRecord(WeightRecord record, int userId) async {
    final db = await database;
    final map = {
      'weight': record.weight,
      'date': record.date.millisecondsSinceEpoch,
      'userId': userId,
    };

    print("[DB] Yeni kilo kaydı ekleniyor: $map");
    final id = await db.insert('weight_records', map);
    print("[DB] Kilo kaydı eklendi, ID: $id");
    return id;
  }

  // Eski isimli fonksiyon, geriye dönük uyumluluk için
  Future<int> insertWeightRecord(WeightRecord record, int userId) async {
    return addWeightRecord(record, userId);
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
    final startOfDay =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day)
        .add(Duration(days: 1))
        .millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) => DailyTask.fromMap(maps[i]));
  }

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
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteActivityByTaskId(int taskId) async {
    final db = await database;
    await db.delete('activities', where: 'taskId = ?', whereArgs: [taskId]);
  }

  Future<List<ActivityRecord>> getActivitiesForDay(DateTime date) async {
    final db = await database;
    final startOfDay =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day)
        .add(Duration(days: 1))
        .millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) {
      return ActivityRecord.fromMap(maps[i]);
    });
  }

  Future<List<ActivityRecord>> getActivitiesInRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final startDate =
        DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;
    final endDate = DateTime(end.year, end.month, end.day)
        .add(Duration(days: 1))
        .millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) {
      return ActivityRecord.fromMap(maps[i]);
    });
  }

  Future<int> insertMeal(MealRecord meal, int userId) async {
    final db = await database;
    Map<String, dynamic> mealMap = meal.toMap();
    mealMap['userId'] = userId;
    return await db.insert(
      'meals',
      mealMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMeal(MealRecord meal, int userId) async {
    final db = await database;
    Map<String, dynamic> mealMap = meal.toMap();
    mealMap['userId'] = userId;
    await db.update(
      'meals',
      mealMap,
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

  Future<void> deleteMealByTaskId(int taskId) async {
    final db = await database;
    await db.delete(
      'meals',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
  }

  Future<List<MealRecord>> getMealsForDay(DateTime date, int userId) async {
    final db = await database;
    final startOfDay =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day)
        .add(Duration(days: 1))
        .millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: 'date >= ? AND date < ? AND userId = ?',
      whereArgs: [startOfDay, endOfDay, userId],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) {
      return MealRecord.fromMap(maps[i]);
    });
  }

  Future<List<MealRecord>> getMealsInRange(
      DateTime start, DateTime end, int userId) async {
    final db = await database;
    final startDate =
        DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;
    final endDate = DateTime(end.year, end.month, end.day)
        .add(Duration(days: 1))
        .millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: 'date >= ? AND date < ? AND userId = ?',
      whereArgs: [startDate, endDate, userId],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) {
      return MealRecord.fromMap(maps[i]);
    });
  }

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
    await db.delete(
      'chat_messages',
      where: 'conversationId = ?',
      whereArgs: [id],
    );
    print("Konuşma ve ilişkili mesajlar silindi: ID $id");
  }

  Future<int> createChatMessage(ChatMessage message) async {
    final db = await database;
    final messageId = await db.insert('chat_messages', message.toMap());

    final conversation = await getChatConversation(message.conversationId);
    if (conversation != null) {
      await updateChatConversation(
        conversation.copyWith(lastMessageAt: message.timestamp),
      );
    }

    return messageId;
  }

  Future<List<ChatMessage>> getMessagesForConversation(
      int conversationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }

  Future<int> insertFoodItem(FoodItem food) async {
    final db = await database;
    try {
      return await db.insert(
        'foods',
        food.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      print("FoodItem eklenirken hata: $e");
      return -1;
    }
  }

  Future<List<FoodItem>> getFoodItems({
    String? query,
    bool? isCustom,
    int? limit,
  }) async {
    // --- YORUM SATIRI: Eski SQLite kodu, Firestore'a taşınmalı ---
    /*
    final db = await database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (query != null && query.isNotEmpty) {
      whereClauses.add('name LIKE ?');
      whereArgs.add('%$query%');
    }
    if (isCustom != null) {
      whereClauses.add('isCustom = ?');
      whereArgs.add(isCustom ? 1 : 0);
    }

    String? whereString =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => FoodItem.fromMap(maps[i]));
    */
    print("[WARN] getFoodItems (SQLite) fonksiyonu Firestore'a taşınmalı.");
    return []; // Şimdilik boş liste döndür
  }

  Future<FoodItem?> getFoodItemById(int id) async {
    // --- YORUM SATIRI: Eski SQLite kodu, Firestore'a taşınmalı ---
    /*
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return FoodItem.fromMap(maps.first);
    }
    return null;
     */
    print("[WARN] getFoodItemById (SQLite) fonksiyonu Firestore'a taşınmalı.");
    return null; // Şimdilik null döndür
  }

  Future<int> updateFoodItem(FoodItem food) async {
    final db = await database;
    if (food.id == null) return -1;
    try {
      return await db.update(
        'foods',
        food.toMap(),
        where: 'id = ?',
        whereArgs: [food.id],
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      print("FoodItem güncellenirken hata: $e");
      return -1;
    }
  }

  Future<int> deleteFoodItem(int id) async {
    final db = await database;
    try {
      return await db.delete(
        'foods',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print("FoodItem silinirken hata: $e");
      return -1;
    }
  }

  // --- Workout Logging Methods ---

  Future<int> insertWorkoutLog(WorkoutLog log) async {
    final db = await database;
    // Insert the main log entry (without ExerciseLogs)
    final Map<String, dynamic> logMap = log.toMap();
    final int workoutLogId = await db.insert(
      'workout_logs',
      logMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("WorkoutLog eklendi: ID $workoutLogId");
    return workoutLogId;
  }

  Future<int> insertExerciseLog(ExerciseLog log, int workoutLogId) async {
    final db = await database;
    // Set the workoutLogId before inserting
    final Map<String, dynamic> logMap =
        log.copyWith(workoutLogId: workoutLogId).toMap();
    final int exerciseLogId = await db.insert(
      'exercise_logs',
      logMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("ExerciseLog eklendi: ID $exerciseLogId (Workout ID: $workoutLogId)");
    return exerciseLogId;
  }

  Future<int> insertWorkoutSet(WorkoutSet set, int exerciseLogId) async {
    final db = await database;
    // Set the exerciseLogId before inserting
    final Map<String, dynamic> setMap =
        set.copyWith(exerciseLogId: exerciseLogId).toMap();
    final int setId = await db.insert(
      'workout_sets',
      setMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("WorkoutSet eklendi: ID $setId (ExerciseLog ID: $exerciseLogId)");
    return setId;
  }

  // --- Methods to retrieve workout data (needs joining/combining) ---

  Future<List<WorkoutSet>> getSetsForExerciseLog(int exerciseLogId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workout_sets',
      where: 'exerciseLogId = ?',
      whereArgs: [exerciseLogId],
      orderBy: 'setNumber ASC',
    );
    return List.generate(maps.length, (i) => WorkoutSet.fromMap(maps[i]));
  }

  Future<List<ExerciseLog>> getExerciseLogsForWorkout(int workoutLogId) async {
    final db = await database;
    final List<Map<String, dynamic>> exerciseLogMaps = await db.query(
      'exercise_logs',
      where: 'workoutLogId = ?',
      whereArgs: [workoutLogId],
      orderBy:
          '"sortOrder" ASC', // '"order" ASC' -> '"sortOrder" ASC' olarak değiştirildi
    );

    List<ExerciseLog> exerciseLogs = [];
    for (var map in exerciseLogMaps) {
      ExerciseLog log = ExerciseLog.fromMap(map);
      // Fetch sets for this exercise log
      List<WorkoutSet> sets = await getSetsForExerciseLog(log.id!);
      // Fetch exercise details (optional, could be done in Provider)
      Exercise? details = null; // Detaylar artık burada çekilmiyor.
      // Add sets and details to the log object
      exerciseLogs.add(log.copyWith(sets: sets, exerciseDetails: details));
    }
    return exerciseLogs;
  }

  Future<List<WorkoutLog>> getWorkoutLogsInRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final startDate =
        DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;
    // End date should be the start of the *next* day to include the whole end day.
    final endDate = DateTime(end.year, end.month, end.day)
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch;

    final List<Map<String, dynamic>> workoutLogMaps = await db.query(
      'workout_logs',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );

    List<WorkoutLog> workoutLogs = [];
    for (var map in workoutLogMaps) {
      WorkoutLog log = WorkoutLog.fromMap(map);
      // Fetch exercise logs (which include sets and exercise details) for this workout log
      List<ExerciseLog> exerciseLogs = await getExerciseLogsForWorkout(log.id!);
      // Add exercise logs to the workout log object
      workoutLogs.add(log.copyWith(exerciseLogs: exerciseLogs));
    }
    return workoutLogs;
  }

  // Placeholder for Update/Delete methods later
  Future<void> updateWorkoutLog(WorkoutLog log) async {
    // TODO: Implement update logic for log and potentially its children
    print("updateWorkoutLog henüz implemente edilmedi.");
  }

  Future<void> deleteWorkoutLog(int id) async {
    final db = await database;
    // Deleting a workout log should cascade delete exercise logs and workout sets
    await db.delete('workout_logs', where: 'id = ?', whereArgs: [id]);
    print("WorkoutLog silindi (ve ilişkili kayıtlar): ID $id");
  }

  // --- End Workout Logging Methods ---

  // --- Water Log Methods ---

  // Belirli bir gün için su kaydını getirir
  Future<int> getWaterLogForDay(DateTime date, int userId) async {
    final db = await database;
    // Tarihi gün başlangıcına yuvarla (saat/dakika olmadan)
    final startOfDay =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'water_log',
      columns: ['amount_ml'],
      where: 'date = ? AND userId = ?',
      whereArgs: [startOfDay, userId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['amount_ml'] as int? ?? 0;
    }
    return 0; // Kayıt yoksa 0 döndür
  }

  // Belirli bir gün için su kaydını ekler veya günceller
  Future<void> insertOrUpdateWaterLog(
      DateTime date, int amountMl, int userId) async {
    final db = await database;
    final startOfDay =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;

    await db.insert(
      'water_log',
      {
        'date': startOfDay,
        'amount_ml': amountMl,
        'userId': userId,
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Eğer aynı gün varsa üzerine yaz
    );
    print("Su kaydı eklendi/güncellendi: Tarih $startOfDay, Miktar $amountMl");
  }

  // Belirli bir tarih aralığındaki su kayıtlarını getirir
  Future<Map<DateTime, int>> getWaterLogInRange(
      DateTime start, DateTime end, int userId) async {
    final db = await database;
    final startDate =
        DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;
    final endDate = DateTime(end.year, end.month, end.day)
        .add(const Duration(
            days: 1)) // Bitiş gününü de dahil etmek için sonraki günün başı
        .millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'water_log',
      columns: ['date', 'amount_ml'],
      where: 'date >= ? AND date < ? AND userId = ?',
      whereArgs: [startDate, endDate, userId],
      orderBy: 'date ASC',
    );

    // Sonucu <DateTime, int> formatında bir Map'e dönüştür
    Map<DateTime, int> results = {};
    for (var map in maps) {
      final date = DateTime.fromMillisecondsSinceEpoch(map['date'] as int);
      final amount = map['amount_ml'] as int? ?? 0;
      results[date] = amount;
    }
    return results;
  }

  // --- End Water Log Methods ---

  // YENİ: Belirli bir aralıktaki günlük beslenme özetini alır
  Future<Map<DateTime, NutritionSummary>> getDailyNutritionSummaryInRange(
      DateTime start, DateTime end, int userId) async {
    final db = await database;
    // Tarihleri gün başlangıcı ve bitişi olarak ayarla (milliseconds)
    final startDateMillis =
        DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;
    final endDateMillis = DateTime(end.year, end.month, end.day)
        .add(const Duration(
            days:
                1)) // Bitiş gününü de dahil etmek için sonraki günün başlangıcı
        .millisecondsSinceEpoch;

    // SQL sorgusu:
    // - Belirtilen tarih aralığı ve kullanıcıya göre filtrele
    // - Tarihi (milisaniye) gün başlangıcına yuvarla
    //   (date / 86400000) * 86400000 integer aritmetiği ile çalışır
    // - Yuvarlanmış gün başlangıcına göre grupla
    // - Her grup için besin değerlerini topla (NULL ise 0 kabul et)
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        (date / 86400000) * 86400000 as dayStartMillis, 
        SUM(COALESCE(calories, 0)) as totalCalories,
        SUM(COALESCE(proteinGrams, 0)) as totalProtein,
        SUM(COALESCE(carbsGrams, 0)) as totalCarbs,
        SUM(COALESCE(fatGrams, 0)) as totalFat
      FROM meals
      WHERE date >= ? AND date < ? AND userId = ?
      GROUP BY dayStartMillis
      ORDER BY dayStartMillis ASC
    ''', [startDateMillis, endDateMillis, userId]);

    Map<DateTime, NutritionSummary> results = {};
    for (var map in maps) {
      final dayMillis = map['dayStartMillis'] as int?;
      if (dayMillis != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(dayMillis);
        // SUM fonksiyonları COALESCE sayesinde null dönmemeli ama yine de kontrol edelim
        results[date] = NutritionSummary(
          calories: (map['totalCalories'] as num?)?.toDouble() ?? 0.0,
          protein: (map['totalProtein'] as num?)?.toDouble() ?? 0.0,
          carbs: (map['totalCarbs'] as num?)?.toDouble() ?? 0.0,
          fat: (map['totalFat'] as num?)?.toDouble() ?? 0.0,
        );
      }
    }
    print("Beslenme özeti getirildi: ${results.length} gün");
    return results;
  }

  Future<void> _createWorkoutTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    print("Workout Logs tablosu oluşturuldu.");

    await db.execute("""
      CREATE TABLE IF NOT EXISTS exercise_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutLogId INTEGER NOT NULL,
        exerciseId INTEGER NOT NULL,
        sortOrder INTEGER NOT NULL, -- 'order' -> 'sortOrder' olarak değiştirildi
        FOREIGN KEY (workoutLogId) REFERENCES workout_logs (id) ON DELETE CASCADE,
        FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE
      )
    """);
    print("Exercise Logs tablosu oluşturuldu.");

    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_sets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exerciseLogId INTEGER NOT NULL,
        setNumber INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL,
        FOREIGN KEY (exerciseLogId) REFERENCES exercise_logs (id) ON DELETE CASCADE
      )
    ''');
    print("Workout Sets tablosu oluşturuldu.");
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print(
        "Veritabanı yükseltiliyor: Sürüm $oldVersion -> $newVersion"); // Loglama eklendi
    var batch = db.batch();
    if (oldVersion < 15) {
      // meals tablosuna userId sütununu ekle
      try {
        await db.execute('ALTER TABLE meals ADD COLUMN userId INTEGER');
        print("Meals tablosuna userId sütunu eklendi.");
      } catch (e) {
        print(
            "Meals tablosuna userId sütunu eklenirken hata (zaten olabilir): $e");
      }
      // water_log tablosunu ekle
      try {
        await db.execute('''
            CREATE TABLE IF NOT EXISTS water_log(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date INTEGER NOT NULL UNIQUE,
              amount_ml INTEGER NOT NULL DEFAULT 0,
              userId INTEGER, 
              FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
            )
          ''');
        print("Water Log tablosu oluşturuldu.");
      } catch (e) {
        print("Water Log tablosu oluşturulurken hata (zaten olabilir): $e");
      }
    }
    if (oldVersion < 16) {
      // workout_logs, exercise_logs, workout_sets tablolarını ekle
      await _createWorkoutTables(db);
    }
    if (oldVersion < 17) {
      try {
        await db
            .execute('ALTER TABLE users ADD COLUMN weeklyActivityGoal REAL');
        print("Users tablosuna weeklyActivityGoal sütunu eklendi.");
      } catch (e) {
        print(
            "Users tablosuna weeklyActivityGoal sütunu eklenirken hata (zaten olabilir): $e");
      }
    }
    // YENİ: Sürüm 18 için yükseltme
    if (oldVersion < 18) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN gender TEXT');
        print("Users tablosuna gender sütunu eklendi.");
      } catch (e) {
        print(
            "Users tablosuna gender sütunu eklenirken hata (zaten olabilir): $e");
      }
    }
    // YENİ: Sürüm 19 için yükseltme
    if (oldVersion < 19) {
      try {
        await db.execute(
            'ALTER TABLE users ADD COLUMN autoCalculateNutrition INTEGER DEFAULT 0');
        print("Users tablosuna autoCalculateNutrition sütunu eklendi.");
      } catch (e) {
        print(
            "Users tablosuna autoCalculateNutrition sütunu eklenirken hata (zaten olabilir): $e");
      }
    }

    await batch.commit();
    print("Veritabanı yükseltme tamamlandı.");
  }

  Future<void> deleteChatMessage(int id) async {
    final db = await database;
    await db.delete(
      'chat_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Konuşma başlığını günceller
  Future<void> updateChatConversationTitle(int id, String newTitle) async {
    final db = await database;
    await db.update(
      'chat_conversations',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
    print("[DatabaseService] Conversation title updated for id: $id");
  }

  // YENİ: Veritabanındaki ilk kullanıcıyı ID'ye göre getirir
  Future<UserModel?> getFirstUser() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        orderBy: 'id ASC', // ID'ye göre artan sırada sırala
        limit: 1, // Sadece ilk kaydı al
      );

      if (maps.isNotEmpty) {
        print(
            "[DB] İlk kullanıcı getirildi, ID: ${maps.first['id']}, Veri: ${maps.first}");
        final userMap = Map<String, dynamic>.from(maps.first);
        // YENİ: DB'den null gelebilen autoCalculateNutrition için kontrol
        userMap['autoCalculateNutrition'] ??= 0; // Eğer null ise 0 (false) yap
        final user = UserModel.fromMap(userMap);
        final weightHistory =
            await getWeightHistory(user.id!); // Ağırlık geçmişini yükle
        user.weightHistory = weightHistory;
        return user;
      } else {
        print("[DB] Veritabanında kullanıcı bulunamadı.");
        return null;
      }
    } catch (e) {
      print("[DB] getFirstUser hatası (muhtemelen tablo yok): $e");
      // Genellikle uygulama ilk kez çalıştığında veya veritabanı silindiğinde bu hata alınabilir.
      return null;
    }
  }

  // YENİ: Belirli bir tarih aralığındaki günlük toplam aktivite süresini (dakika) alır.
  Future<Map<DateTime, int>> getDailyActivitySummaryInRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final startDateMillis =
        DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;
    final endDateMillis = DateTime(end.year, end.month, end.day)
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        (date / 86400000) * 86400000 as dayStartMillis, 
        SUM(COALESCE(durationMinutes, 0)) as totalDuration
      FROM activities
      WHERE date >= ? AND date < ?
      GROUP BY dayStartMillis
      ORDER BY dayStartMillis ASC
    ''', [startDateMillis, endDateMillis]);

    Map<DateTime, int> results = {};
    for (var map in maps) {
      final dayMillis = map['dayStartMillis'] as int?;
      if (dayMillis != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(dayMillis);
        // SUM null dönmez ama yine de kontrol edelim.
        results[date] = (map['totalDuration'] as num?)?.toInt() ?? 0;
      }
    }
    print("Günlük aktivite özeti getirildi: ${results.length} gün");
    return results;
  }

  // Tek bir besin öğesi ekleme (veya güncelleme)
  Future<void> addOrUpdateFoodItem(FoodItem food) async {
    // Aynı isimde besin var mı diye kontrol et (büyük/küçük harf duyarsız)
    QuerySnapshot query = await _db
        .collection('foods')
        .where('name_lowercase', isEqualTo: food.name.toLowerCase())
        .limit(1)
        .get();

    // Veriyi hazırlarken küçük harf versiyonunu ekleyelim
    Map<String, dynamic> foodData = food.toMap();
    // toMap içinde name_lowercase zaten ekleniyor, burada tekrar eklemeye gerek yok.
    // foodData['name_lowercase'] = food.name.toLowerCase();

    if (query.docs.isNotEmpty) {
      // Varsa güncelle
      await _db.collection('foods').doc(query.docs.first.id).update(foodData);
      print('Besin güncellendi: ${food.name}');
    } else {
      // Yoksa ekle
      await _db.collection('foods').add(foodData);
      print('Besin eklendi: ${food.name}');
    }
  }

  // Asset dosyasından besin veritabanını içe aktarma (Toplu Yazma ile Güncellendi)
  Future<void> importFoodDatabaseFromAsset(String assetPath) async {
    try {
      print('[Firestore Batch] Besin veritabanı içe aktarılıyor: $assetPath');
      final String fileContent = await rootBundle.loadString(assetPath);
      final List<String> lines = fileContent.split('\n');

      WriteBatch batch = _db.batch();
      int itemCount = 0;
      const int batchLimit =
          400; // Firestore batch limiti genelde 500'dür, güvende kalalım

      // Başlık satırını atla (ilk satır)
      for (int i = 1; i < lines.length; i++) {
        final String line = lines[i].trim();
        if (line.isEmpty) continue; // Boş satırları atla

        final List<String> values = line.split('\t'); // Tab ile ayrılmış

        if (values.length == 7) {
          // Beklenen sütun sayısı (İsim, Kat, Por, Kal, Karb, Pro, Yağ)
          try {
            final food = FoodItem(
              name: values[0].trim(),
              category: values[1].trim(),
              servingSizeG: double.tryParse(values[2]) ?? 0.0,
              caloriesKcal: double.tryParse(values[3]) ?? 0.0,
              carbsG: double.tryParse(values[4]) ?? 0.0,
              proteinG: double.tryParse(values[5]) ?? 0.0,
              fatG: double.tryParse(values[6]) ?? 0.0,
            );

            // Yeni bir doküman referansı oluştur ve batch'e ekle
            DocumentReference docRef =
                _db.collection('foods').doc(); // Otomatik ID
            batch.set(docRef, food.toMap());
            itemCount++;

            // Batch limiti dolduğunda commit et ve yeni batch başlat
            if (itemCount >= batchLimit) {
              await batch.commit();
              print('[Firestore Batch] $itemCount besin yazıldı.');
              batch = _db.batch(); // Yeni batch
              itemCount = 0;
            }
          } catch (e) {
            print(
                '[Firestore Batch] Satır $i işlenirken hata: $line - Hata: $e');
          }
        } else {
          print(
              '[Firestore Batch] Satır $i atlandı (geçersiz sütun sayısı: ${values.length}): $line');
        }
      }

      // Kalan son batch'i commit et
      if (itemCount > 0) {
        await batch.commit();
        print('[Firestore Batch] Kalan $itemCount besin yazıldı.');
      }

      print('[Firestore Batch] Besin veritabanı içe aktarma tamamlandı.');
    } catch (e) {
      print(
          '[Firestore Batch] Besin veritabanı dosyası okunamadı veya işlenemedi: $e');
    }
  }

  // Besin arama fonksiyonu (AddEditMealDialog için)
  Future<List<FoodItem>> searchFoodItems(String query) async {
    if (query.isEmpty) return [];
    // Aramayı en az 2 karakter girilince yapalım (performans için)
    if (query.length < 2) return [];

    try {
      // Başlangıç eşleşmesi için (daha hızlı)
      QuerySnapshot snapshot = await _db
          .collection('foods')
          .where('name_lowercase', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name_lowercase',
              isLessThanOrEqualTo:
                  query.toLowerCase() + '\uf8ff') // Bitiş sınırı
          .orderBy('name_lowercase')
          .limit(25) // Sonuçları biraz artıralım
          .get();

      // Alternatif: Tam metin arama için 3. parti servisler (Algolia vb.) veya
      // Firestore'da daha kompleks sorgular gerekebilir. Şimdilik basit başlangıç eşleşmesi.

      return snapshot.docs.map((doc) => FoodItem.fromSnapshot(doc)).toList();
    } catch (e) {
      print("Besin arama hatası: $e");
      return [];
    }
  }

  Future<void> updateChatConversationLastActivity(int id) async {
    final db = await database;
    final now = DateTime.now();
    await db.update(
      'chat_conversations',
      {'lastMessageAt': now.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
    print("Konuşmanın son aktivite zamanı güncellendi: $id, $now");
  }
} // DatabaseService sınıfının kapanış parantezi
