import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/program_model.dart';
import '../models/program_set.dart';
import '../services/exercise_service.dart';
import 'package:flutter/foundation.dart';
import '../models/exercise_model.dart';
import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';
import 'package:collection/collection.dart';

/// Program verilerini sağlayan servis sınıfı
class ProgramService {
  static const String _programKey = 'weekly_program';
  List<DailyProgram> _weeklyProgram = [];
  final DatabaseService _databaseService;
  ExerciseService? _exerciseService;

  ProgramService(this._databaseService);

  /// Mevcut aktif program
  WeeklyProgram? _currentProgram;

  /// Tüm haftalık programlar
  final List<WeeklyProgram> _allPrograms = [];

  /// Servis başlatma (ExerciseService bağımlılığı eklendi)
  Future<void> initialize(ExerciseService exerciseService) async {
    this._exerciseService = exerciseService;
    await _loadProgram(exerciseService);
  }

  // Programı SharedPreferences'tan yükle
  Future<void> _loadProgram(ExerciseService exerciseService) async {
    try {
      print("[ProgramService] Program yükleniyor...");
      final prefs = await SharedPreferences.getInstance();
      final programJson = prefs.getString(_programKey);

      // Eğer kayıtlı program yoksa varsayılan programı oluştur
      if (programJson == null) {
        print(
            "[ProgramService] Kayıtlı program bulunamadı, varsayılan oluşturuluyor...");
        await _createDefaultProgram(exerciseService);
        await _saveProgram();
      } else {
        print("[ProgramService] Kayıtlı program bulundu, yükleniyor...");
        // Kayıtlı programı yükle
        final programMap = json.decode(programJson);
        final List<dynamic> dailyProgramsJson = programMap['dailyPrograms'];

        _weeklyProgram = dailyProgramsJson
            .map((json) => DailyProgram.fromJson(json))
            .toList();
        print(
            "[ProgramService] Kayıtlı program başarıyla yüklendi. ${_weeklyProgram.length} gün.");
      }
    } catch (e) {
      print('[ProgramService] Program yüklenirken HATA: $e');
      print(
          "[ProgramService] Hata nedeniyle varsayılan program oluşturuluyor...");
      await _createDefaultProgram(exerciseService);
      await _saveProgram(); // Hata durumunda da varsayılanı kaydet
    }
  }

  // Programı SharedPreferences'a kaydet
  Future<void> _saveProgram() async {
    try {
      print("[ProgramService] Program SharedPreferences'a kaydediliyor...");
      final prefs = await SharedPreferences.getInstance();
      final programMap = {
        'dailyPrograms':
            _weeklyProgram.map((program) => program.toJson()).toList(),
      };

      await prefs.setString(_programKey, json.encode(programMap));
      print("[ProgramService] Program başarıyla kaydedildi.");
    } catch (e) {
      print('[ProgramService] Program kaydedilirken HATA: $e');
    }
  }

  /// Varsayılan haftalık programı oluştur
  Future<void> _createDefaultProgram(ExerciseService exerciseService) async {
    print("[ProgramService] Varsayılan program oluşturma işlemi başladı...");
    final List<String> weekDays = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];

    print("[ProgramService] Egzersizler ExerciseService'ten alınıyor...");
    final allExercises = await exerciseService.getExercises();
    final Map<String, String?> exerciseIdMap = {
      for (var ex in allExercises)
        if (ex.id != null) ex.name.toLowerCase(): ex.id
    };
    print(
        "[ProgramService] ${allExercises.length} egzersiz bulundu ve ${exerciseIdMap.length} elemanlı ID map oluşturuldu.");

    String? findExerciseId(String name) {
      final id = exerciseIdMap[name.toLowerCase()];
      if (id == null) {
        debugPrint('UYARI: "$name" isimli egzersiz veritabanında bulunamadı.');
      }
      return id;
    }

    print("[ProgramService] Haftalık program döngüsü başlıyor...");
    _weeklyProgram = List.generate(7, (index) {
      final String dayName = weekDays[index];
      // print("[ProgramService] Gün $index ($dayName) için program oluşturuluyor..."); // Çok fazla log olabilir

      ProgramItem morningActivity;
      ProgramItem lunch;
      ProgramItem eveningActivity;
      ProgramItem dinner;

      switch (index) {
        case 0: // Pazartesi (Dinlenme)
          morningActivity = ProgramItem(
            type: ProgramItemType.rest,
            title: 'Sabah: Dinlenme',
            description: '🧘‍♂️ Tam dinlenme veya 20-30 dk yürüyüş',
            icon: Icons.hotel,
            color: Colors.green,
            time: '09:00',
          );
          lunch = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description: '🔄 Hafta içi prensipteki öğünler',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '13:00',
          );
          eveningActivity = ProgramItem(
            type: ProgramItemType.rest,
            title: 'Akşam: Dinlenme',
            description: '💤 Tam dinlenme günü.',
            icon: Icons.hotel,
            color: Colors.green,
            time: '18:00',
          );
          dinner = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Akşam Yemeği',
            description: '🍴 Hafif ve dengeli öğün',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;

        case 1: // Salı (1. Gün: Göğüs & Arka Kol)
          morningActivity = ProgramItem(
            type: ProgramItemType.workout,
            title: 'Sabah Kardiyo (İsteğe Bağlı)',
            description: null,
            programSets: [
              ProgramSet(
                exerciseId: findExerciseId('Yüzme') ?? null,
                order: 0,
                repsDescription: '30 dk',
                setsDescription: '1',
              )
            ],
            icon: Icons.pool,
            color: Colors.orange,
            time: '08:45',
          );
          lunch = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description: '🥣 Yulaf + süt + muz veya Pazartesi menüsü',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '12:30',
          );
          eveningActivity = ProgramItem(
            type: ProgramItemType.workout,
            title: 'Akşam Antrenmanı: Göğüs & Arka Kol',
            description: null,
            icon: Icons.fitness_center,
            color: Colors.purple,
            time: '18:00',
            programSets: [
              if (findExerciseId('Incline Bench Press') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Incline Bench Press')!,
                    order: 1,
                    setsDescription: '4',
                    repsDescription: '12-10-8-8'),
              if (findExerciseId('Dumbbell Bench Press') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Dumbbell Bench Press')!,
                    order: 2,
                    setsDescription: '4',
                    repsDescription: '12-10-8-8'),
              if (findExerciseId('Cable Crossover') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Cable Crossover')!,
                    order: 3,
                    setsDescription: '4',
                    repsDescription: '12'),
              if (findExerciseId('Dumbbell Hex Press') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Dumbbell Hex Press')!,
                    order: 4,
                    setsDescription: '3',
                    repsDescription: '10'),
              if (findExerciseId('Cable Triceps Extension') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Cable Triceps Extension')!,
                    order: 5,
                    setsDescription: '3',
                    repsDescription: '12'),
              if (findExerciseId('Cable Overhead Triceps Extension') != null)
                ProgramSet(
                    exerciseId:
                        findExerciseId('Cable Overhead Triceps Extension')!,
                    order: 6,
                    setsDescription: '3',
                    repsDescription: '12'),
            ],
          );
          dinner = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Akşam Yemeği',
            description: '🍗 Izgara tavuk veya 🐟 ton balıklı salata, yoğurt',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;

        case 2: // Çarşamba (2. Gün: Sırt & Ön Kol)
          morningActivity = ProgramItem(
            type: ProgramItemType.workout,
            title: 'Sabah Kardiyo (İsteğe Bağlı)',
            description: null,
            programSets: [
              ProgramSet(
                  exerciseId: findExerciseId('Yürüyüş') ?? null,
                  order: 0,
                  repsDescription: '30 dk',
                  setsDescription: '1')
            ],
            icon: Icons.directions_walk,
            color: Colors.orange,
            time: '08:45',
          );
          lunch = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description: '🥣 Yulaf + süt + muz veya Pazartesi menüsü',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '12:30',
          );
          eveningActivity = ProgramItem(
            type: ProgramItemType.workout,
            title: 'Akşam Antrenmanı: Sırt & Ön Kol',
            description: null,
            icon: Icons.fitness_center,
            color: Colors.purple,
            time: '18:00',
            programSets: [
              if (findExerciseId('Lat Pulldown') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Lat Pulldown')!,
                    order: 1,
                    setsDescription: '4',
                    repsDescription: '12-10-8-8'),
              if (findExerciseId('Cable Seated Row') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Cable Seated Row')!,
                    order: 2,
                    setsDescription: '4',
                    repsDescription: '12'),
              if (findExerciseId('Tek Kol Dumbbell Row') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Tek Kol Dumbbell Row')!,
                    order: 3,
                    setsDescription: '3',
                    repsDescription: '10'),
              if (findExerciseId('Cable Straight-Arm Pulldown') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Cable Straight-Arm Pulldown')!,
                    order: 4,
                    setsDescription: '3',
                    repsDescription: '12'),
              if (findExerciseId('Dumbbell Alternate Curl') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Dumbbell Alternate Curl')!,
                    order: 5,
                    setsDescription: '3',
                    repsDescription: '12-10-8'),
              if (findExerciseId('Cable Hammer Curl') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Cable Hammer Curl')!,
                    order: 6,
                    setsDescription: '3',
                    repsDescription: '12'),
            ],
          );
          dinner = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Akşam Yemeği',
            description: '🐔 Tavuk veya 🐟 ton balık, 🥗 yağlı salata, yoğurt',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;

        case 3: // Perşembe (3. Gün: Omuz & Bacak & Karın)
          morningActivity = ProgramItem(
            type: ProgramItemType.rest,
            title: 'Sabah: Dinlenme',
            description: 'Hafif aktivite veya dinlenme',
            icon: Icons.hotel,
            color: Colors.orange,
            time: '08:45',
          );
          lunch = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description:
                '🍗 Izgara tavuk, 🍚 pirinç pilavı, 🥗 yağlı salata, 🥛 yoğurt, 🍌 muz',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '12:30',
          );
          eveningActivity = ProgramItem(
            type: ProgramItemType.workout,
            title: 'Akşam Antrenmanı: Omuz & Bacak & Karın',
            description: null,
            icon: Icons.fitness_center,
            color: Colors.purple,
            time: '18:00',
            programSets: [
              if (findExerciseId('Dumbbell Shoulder Press') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Dumbbell Shoulder Press')!,
                    order: 1,
                    setsDescription: '4',
                    repsDescription: '12-10-8-8'),
              if (findExerciseId('Dumbbell Lateral Raise') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Dumbbell Lateral Raise')!,
                    order: 2,
                    setsDescription: '4',
                    repsDescription: '12'),
              if (findExerciseId('Facepull') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Facepull')!,
                    order: 3,
                    setsDescription: '3',
                    repsDescription: '12'),
              if (findExerciseId('Leg Extension') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Leg Extension')!,
                    order: 4,
                    setsDescription: '3',
                    repsDescription: '12'),
              if (findExerciseId('Leg Curl') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Leg Curl')!,
                    order: 5,
                    setsDescription: '3',
                    repsDescription: '12'),
              if (findExerciseId('Thigh Abduction/Adduction') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Thigh Abduction/Adduction')!,
                    order: 6,
                    setsDescription: '3',
                    repsDescription: '10'),
              if (findExerciseId('Seated Calf Raise') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Seated Calf Raise')!,
                    order: 7,
                    setsDescription: '3',
                    repsDescription: '12'),
              if (findExerciseId('Plank') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Plank')!,
                    order: 8,
                    setsDescription: '3',
                    repsDescription: '30 sn'),
              if (findExerciseId('Leg Raises') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Leg Raises')!,
                    order: 9,
                    setsDescription: '3',
                    repsDescription: '12'),
              if (findExerciseId('Crunch') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Crunch')!,
                    order: 10,
                    setsDescription: '3',
                    repsDescription: '15'),
            ],
          );
          dinner = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Akşam Yemeği',
            description: '🐔 Tavuk veya 🐟 ton balık, 🥗 salata, yoğurt',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;

        case 4: // Cuma (Dinlenme)
          morningActivity = ProgramItem(
            type: ProgramItemType.rest,
            title: 'Sabah: Dinlenme/Hafif Aktivite',
            description: '🚶‍♂️ İsteğe bağlı yüzme veya yürüyüş',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            time: '08:45',
          );
          lunch = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description:
                '🥚 Tavuk, haşlanmış yumurta, 🥗 yoğurt, salata, kuruyemiş',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '12:30',
          );
          eveningActivity = ProgramItem(
            type: ProgramItemType.rest,
            title: 'Akşam: Dinlenme',
            description: '🤸‍♂️ Tam dinlenme veya hafif esneme.',
            icon: Icons.hotel,
            color: Colors.green,
            time: '18:00',
          );
          dinner = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Akşam Yemeği',
            description: '🍳 Menemen, 🍴 ton balıklı salata, yoğurt',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;

        case 5: // Cumartesi (Aktif Dinlenme)
          morningActivity = ProgramItem(
            type: ProgramItemType.workout,
            title: 'Sabah Aktivitesi',
            description: null,
            programSets: [
              ProgramSet(
                  exerciseId: findExerciseId('Yürüyüş') ?? null,
                  order: 0,
                  repsDescription: '30-45 dk',
                  setsDescription: '1'),
              ProgramSet(
                  exerciseId: findExerciseId('Esneme') ?? null,
                  order: 1,
                  repsDescription: '10-15 dk',
                  setsDescription: '1'),
            ],
            icon: Icons.directions_walk,
            color: Colors.orange,
            time: '09:00',
          );
          lunch = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description: '🐔 Tavuk, yumurta, pilav, salata',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '13:00',
          );
          eveningActivity = ProgramItem(
            type: ProgramItemType.rest,
            title: 'Akşam: Aktif Dinlenme',
            description: '🚶‍♀️ Hafif aktivite veya dinlenme.',
            icon: Icons.mood,
            color: Colors.teal,
            time: '18:00',
          );
          dinner = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Akşam Yemeği',
            description: '🍽️ Sağlıklı serbest menü',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;

        case 6: // Pazar (Bel Sağlığı)
          morningActivity = ProgramItem(
            type: ProgramItemType.rest,
            title: 'Sabah: Dinlenme/Hafif Aktivite',
            description: '🧘‍♂️ Tam dinlenme veya 20-30 dk yürüyüş',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            time: '09:00',
          );
          lunch = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description: '🔄 Hafta içi prensipteki öğünler',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '13:00',
          );
          eveningActivity = ProgramItem(
            type: ProgramItemType.workout,
            title: 'Akşam Antrenmanı: Bel Sağlığı',
            description: null,
            icon: Icons.fitness_center,
            color: Colors.purple,
            time: '18:00',
            programSets: [
              if (findExerciseId('Pelvic Tilt') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Pelvic Tilt')!,
                    order: 1,
                    setsDescription: '3',
                    repsDescription: '12'),
              if (findExerciseId('Cat-Camel') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Cat-Camel')!,
                    order: 2,
                    setsDescription: '3',
                    repsDescription: '10'),
              if (findExerciseId('Bird-Dog') != null)
                ProgramSet(
                    exerciseId: findExerciseId('Bird-Dog')!,
                    order: 3,
                    setsDescription: '3',
                    repsDescription: '10 (her taraf)'),
            ].where((ps) => ps.exerciseId != null).toList(),
          );
          dinner = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Akşam Yemeği',
            description: '🍴 Hafif ve dengeli öğün',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;

        default:
          morningActivity = ProgramItem(
            type: ProgramItemType.rest,
            title: 'Sabah: Dinlenme',
            description: '🧘‍♂️ Dinlenme',
            icon: Icons.hotel,
            color: Colors.green,
            time: '09:00',
          );
          lunch = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description: '🔄 Hafta içi prensipteki öğünler',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '13:00',
          );
          eveningActivity = ProgramItem(
            type: ProgramItemType.rest,
            title: 'Akşam: Dinlenme',
            description: '💤 Dinlenme.',
            icon: Icons.hotel,
            color: Colors.green,
            time: '18:00',
          );
          dinner = ProgramItem(
            type: ProgramItemType.meal,
            title: 'Akşam Yemeği',
            description: '🍴 Hafif ve dengeli öğün',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;
      }

      return DailyProgram(
        dayName: dayName,
        morningExercise: morningActivity,
        lunch: lunch,
        eveningExercise: eveningActivity,
        dinner: dinner,
      );
    });
    await _saveProgram();
  }

  /// Mevcut aktif programı döndürür
  WeeklyProgram? getCurrentProgram() {
    return _currentProgram;
  }

  /// Verilen güne ait program bilgilerini döndürür
  DailyProgram? getDailyProgram(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= _weeklyProgram.length) {
      return null;
    }
    return _weeklyProgram[dayIndex];
  }

  /// Bugüne ait program bilgilerini döndürür
  DailyProgram? getTodayProgram() {
    final today = DateTime.now().weekday - 1; // 0: Pazartesi, 6: Pazar
    return getDailyProgram(today);
  }

  /// Tüm haftalık programı al (Egzersiz detayları ile birlikte)
  Future<List<DailyProgram>> getWeeklyProgram() async {
    if (_weeklyProgram.isEmpty) {
      print(
          'UYARI: getWeeklyProgram çağrıldığında _weeklyProgram boştu. Initialize doğru çağrıldı mı?');
      // await initialize(_exerciseService); // Gerekirse tekrar başlat (dikkatli ol)
    }

    // Egzersiz detaylarını yükle
    await _populateExerciseDetails();

    return _weeklyProgram;
  }

  /// Haftalık programdaki ProgramSet'ler için Exercise detaylarını doldurur.
  Future<void> _populateExerciseDetails() async {
    Set<String?> exerciseIds = {};

    // Haftalık programdaki tüm egzersiz ID'lerini topla
    for (var dailyProgram in _weeklyProgram) {
      if (dailyProgram.morningExercise.type == ProgramItemType.workout &&
          dailyProgram.morningExercise.programSets != null) {
        exerciseIds.addAll(dailyProgram.morningExercise.programSets!
            .map((ps) => ps.exerciseId));
      }
      if (dailyProgram.eveningExercise.type == ProgramItemType.workout &&
          dailyProgram.eveningExercise.programSets != null) {
        exerciseIds.addAll(dailyProgram.eveningExercise.programSets!
            .map((ps) => ps.exerciseId));
      }
    }

    exerciseIds.removeWhere((id) => id == null);
    final List<String> validExerciseIds =
        exerciseIds.whereType<String>().toList();

    debugPrint('[ProgramService] Exercise IDs to fetch: ${validExerciseIds}');
    if (validExerciseIds.isEmpty) return;

    if (_exerciseService == null) {
      print(
          "HATA: _populateExerciseDetails çağrıldığında _exerciseService null.");
      return;
    }

    final exercises =
        await _exerciseService!.getExercisesByIds(validExerciseIds);
    debugPrint(
        '[ProgramService] Fetched ${exercises.length} exercises from ExerciseService.');
    final Map<String?, Exercise> exerciseMap = {
      for (var ex in exercises) ex.id: ex
    };

    debugPrint('[ProgramService] Exercise Map: ${exerciseMap.keys}');

    // ProgramSet'lerdeki exerciseDetails alanını doldur
    for (var dailyProgram in _weeklyProgram) {
      _populateDetailsForItem(dailyProgram.morningExercise, exerciseMap);
      _populateDetailsForItem(dailyProgram.eveningExercise, exerciseMap);
    }
  }

  /// Yardımcı metod: Bir ProgramItem içindeki ProgramSet'lere detayları ekler
  void _populateDetailsForItem(
      ProgramItem item, Map<String?, Exercise> exerciseMap) {
    if (item.type == ProgramItemType.workout && item.programSets != null) {
      for (var ps in item.programSets!) {
        if (exerciseMap.containsKey(ps.exerciseId)) {
          ps.exerciseDetails = exerciseMap[ps.exerciseId];
          // debugPrint('[ProgramService] Assigned details for ${ps.exerciseId}: ${ps.exerciseDetails?.name}');
        } else {
          // debugPrint('[ProgramService] Exercise ID ${ps.exerciseId} not found in fetched map for item: ${item.title}');
        }
      }
    }
  }

  // Günlük programı güncelle
  Future<void> updateDailyProgram(int dayIndex, DailyProgram program) async {
    if (dayIndex < 0 || dayIndex >= _weeklyProgram.length) {
      return;
    }

    _weeklyProgram[dayIndex] = program;
    await _saveProgram();
  }

  // Programı sıfırla
  Future<void> resetProgram() async {
    if (_exerciseService == null) {
      print("Hata: ExerciseService başlatılmadan program sıfırlanamaz.");
      return;
    }
    await _createDefaultProgram(_exerciseService!);
    await _saveProgram();
  }

  /// YENİ: Haftalık programdaki tüm ProgramItem'ları döndürür.
  List<ProgramItem> getAllProgramItems() {
    List<ProgramItem> allItems = [];
    for (var dailyProgram in _weeklyProgram) {
      // Hata 1: items yerine ayrı ayrı ekle
      allItems.add(dailyProgram.morningExercise);
      allItems.add(dailyProgram.lunch);
      allItems.add(dailyProgram.eveningExercise);
      allItems.add(dailyProgram.dinner);
    }
    return allItems;
  }

  /// Belirli bir gün için programı getirir.
  DailyProgram getProgramForDay(DateTime date) {
    final dayIndex = date.weekday - 1; // Pazartesi 1, Pazar 7 -> index 0-6
    if (dayIndex >= 0 && dayIndex < _weeklyProgram.length) {
      return _weeklyProgram[dayIndex];
    } else {
      // Hata 2: Geçersiz gün index'i durumunda varsayılan veya hata döndür
      print("UYARI: getProgramForDay için geçersiz gün index'i: $dayIndex");
      // Boş bir DailyProgram döndürelim (veya null döndürmek için tipi DailyProgram? yap)
      // Veya ilk günün programını döndür?
      return _weeklyProgram.isNotEmpty
          ? _weeklyProgram[0]
          : _createEmptyDailyProgram(); // İlk günü veya boş programı döndür
    }
  }

  // YENİ: Boş bir DailyProgram oluşturmak için yardımcı metot
  DailyProgram _createEmptyDailyProgram() {
    return DailyProgram(
      dayName: "Hata",
      morningExercise: ProgramItem(
          type: ProgramItemType.other,
          title: "-",
          icon: Icons.error,
          color: Colors.grey),
      lunch: ProgramItem(
          type: ProgramItemType.other,
          title: "-",
          icon: Icons.error,
          color: Colors.grey),
      eveningExercise: ProgramItem(
          type: ProgramItemType.other,
          title: "-",
          icon: Icons.error,
          color: Colors.grey),
      dinner: ProgramItem(
          type: ProgramItemType.other,
          title: "-",
          icon: Icons.error,
          color: Colors.grey),
    );
  }
}
