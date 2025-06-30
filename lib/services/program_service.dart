import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/program_model.dart';
import '../models/program_set.dart';
import '../services/exercise_service.dart';

import '../models/exercise_model.dart';
import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';
import 'package:collection/collection.dart';

/// Program verilerini sağlayan servis sınıfı
class ProgramService extends ChangeNotifier {
  static const String _programKey = 'weekly_program';
  List<DailyProgram> _workoutPrograms = [];
  List<ProgramItem> _unassignedCategories = [];
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
      debugPrint("[ProgramService][_loadProgram] Program yükleniyor...");
      final prefs = await SharedPreferences.getInstance();
      final programJson = prefs.getString(_programKey);

      // Eğer kayıtlı program yoksa varsayılan programı oluştur
      if (programJson == null) {
        debugPrint(
            "[ProgramService][_loadProgram] Kayıtlı program bulunamadı, varsayılan oluşturuluyor...");
        await _createDefaultProgram(exerciseService);
        await _saveProgram();
      } else {
        debugPrint(
            "[ProgramService][_loadProgram] Kayıtlı program bulundu, yükleniyor...");
        // Kayıtlı programı yükle ve ID'leri kontrol et/ata
        final programMap = json.decode(programJson);
        final List<dynamic> dailyProgramsJson = programMap['dailyPrograms'];

        _workoutPrograms = dailyProgramsJson.map((dailyJson) {
          final dayName = dailyJson['dayName'] as String? ?? 'UnknownDay';
          DailyProgram dailyProgram = DailyProgram.fromJson(dailyJson);

          // ID'leri kontrol et ve gerekirse ata (eski verilerle uyumluluk için)
          dailyProgram.morningExercise.id ??= '${dailyProgram.dayName}_morning';
          dailyProgram.lunch.id ??= '${dailyProgram.dayName}_lunch';
          dailyProgram.eveningExercise.id ??= '${dailyProgram.dayName}_evening';
          dailyProgram.dinner.id ??= '${dailyProgram.dayName}_dinner';
          return dailyProgram;
        }).toList();
        debugPrint(
            "[ProgramService][_loadProgram] Kayıtlı program başarıyla yüklendi. ${_workoutPrograms.length} gün.");
        // Yüklenen ilk günün detayını logla (kontrol için)
        if (_workoutPrograms.isNotEmpty) {
          debugPrint(
              "[ProgramService][_loadProgram] Yüklenen ilk gün (${_workoutPrograms.first.dayName}): ${_workoutPrograms.first.toJson()}");
        }

        // Atanmamış kategorileri yükle
        if (programMap.containsKey('unassignedCategories')) {
          final List<dynamic> categoriesJson =
              programMap['unassignedCategories'];
          _unassignedCategories = categoriesJson
              .map((json) => ProgramItem.fromJson(json as Map<String, dynamic>))
              .toList();
          debugPrint(
              "[ProgramService][_loadProgram] Atanmamış ${_unassignedCategories.length} kategori yüklendi.");
        } else {
          _unassignedCategories = []; // Veri yoksa boş liste
        }
      }
    } catch (e, stackTrace) {
      debugPrint(
          '[ProgramService][_loadProgram] Program yüklenirken HATA: $e\n$stackTrace');
      debugPrint(
          "[ProgramService][_loadProgram] Hata nedeniyle varsayılan program oluşturuluyor...");
      await _createDefaultProgram(exerciseService);
      await _saveProgram(); // Hata durumunda da varsayılanı kaydet
    }
    notifyListeners();
  }

  // Programı SharedPreferences'a kaydet
  Future<void> _saveProgram() async {
    try {
      debugPrint(
          "[ProgramService][_saveProgram] Program SharedPreferences'a kaydediliyor...");
      final prefs = await SharedPreferences.getInstance();
      final programMap = {
        'dailyPrograms':
            _workoutPrograms.map((program) => program.toJson()).toList(),
        'unassignedCategories':
            _unassignedCategories.map((item) => item.toJson()).toList(),
      };

      // Log details of the first workout item being saved (example)
      final firstWorkoutItem = _workoutPrograms
          .expand((dp) => [dp.morningExercise, dp.eveningExercise])
          .firstWhereOrNull((pi) => pi.type == ProgramItemType.workout);
      if (firstWorkoutItem != null) {
        debugPrint(
            "[ProgramService][_saveProgram] Saving first workout item: ID=${firstWorkoutItem.id}, Title='${firstWorkoutItem.title}', SetsCount=${firstWorkoutItem.programSets?.length}");
      } else {
        debugPrint(
            "[ProgramService][_saveProgram] No workout items found to log details.");
      }
      await prefs.setString(_programKey, json.encode(programMap));
      debugPrint(
          "[ProgramService][_saveProgram] Program başarıyla kaydedildi.");
    } catch (e, stackTrace) {
      debugPrint(
          '[ProgramService][_saveProgram] Program kaydedilirken HATA: $e\n$stackTrace');
    }
    notifyListeners();
  }

  /// Varsayılan haftalık programı oluştur
  Future<void> _createDefaultProgram(ExerciseService exerciseService) async {
    debugPrint(
        "[ProgramService] Varsayılan program oluşturma işlemi başladı...");
    final List<String> weekDays = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];

    debugPrint("[ProgramService] Egzersizler ExerciseService'ten alınıyor...");
    final allExercises = await exerciseService.getExercises();
    final Map<String, String?> exerciseIdMap = {
      for (var ex in allExercises)
        if (ex.id != null) ex.name.toLowerCase(): ex.id
    };
    debugPrint(
        "[ProgramService] ${allExercises.length} egzersiz bulundu ve ${exerciseIdMap.length} elemanlı ID map oluşturuldu.");

    String? findExerciseId(String name) {
      final id = exerciseIdMap[name.toLowerCase()];
      if (id == null) {
        debugPrint('UYARI: "$name" isimli egzersiz veritabanında bulunamadı.');
      }
      return id;
    }

    debugPrint("[ProgramService] Haftalık program döngüsü başlıyor...");
    _workoutPrograms = List.generate(7, (index) {
      final String dayName = weekDays[index];

      // Sabit ID'leri oluştur
      final String morningId = '${dayName}_morning';
      final String lunchId = '${dayName}_lunch';
      final String eveningId = '${dayName}_evening';
      final String dinnerId = '${dayName}_dinner';

      ProgramItem morningActivity;
      ProgramItem lunch;
      ProgramItem eveningActivity;
      ProgramItem dinner;

      switch (index) {
        case 0: // Pazartesi (Dinlenme)
          morningActivity = ProgramItem(
            id: morningId, // ID Ata
            type: ProgramItemType.rest,
            title: 'Sabah: Dinlenme',
            description: '🧘‍♂️ Tam dinlenme veya 20-30 dk yürüyüş',
            icon: Icons.hotel,
            color: Colors.green,
            time: '09:00',
          );
          lunch = ProgramItem(
            id: lunchId, // ID Ata
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description: '🔄 Hafta içi prensipteki öğünler',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '13:00',
          );
          eveningActivity = ProgramItem(
            id: eveningId, // ID Ata
            type: ProgramItemType.rest,
            title: 'Akşam: Dinlenme',
            description: '💤 Tam dinlenme günü.',
            icon: Icons.hotel,
            color: Colors.green,
            time: '18:00',
          );
          dinner = ProgramItem(
            id: dinnerId, // ID Ata
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
            id: morningId, // ID Ata
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
            id: lunchId, // ID Ata
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description: '🥣 Yulaf + süt + muz veya Pazartesi menüsü',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '12:30',
          );
          eveningActivity = ProgramItem(
            id: eveningId, // ID Ata
            type: ProgramItemType.workout,
            title: 'Göğüs & Arka Kol',
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
            id: dinnerId, // ID Ata
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
            id: morningId, // ID Ata
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
            id: lunchId, // ID Ata
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description: '🥣 Yulaf + süt + muz veya Pazartesi menüsü',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '12:30',
          );
          eveningActivity = ProgramItem(
            id: eveningId, // ID Ata
            type: ProgramItemType.workout,
            title: 'Sırt & Ön Kol',
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
            id: dinnerId, // ID Ata
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
            id: morningId, // ID Ata
            type: ProgramItemType.rest,
            title: 'Sabah: Dinlenme',
            description: 'Hafif aktivite veya dinlenme',
            icon: Icons.hotel,
            color: Colors.orange,
            time: '08:45',
          );
          lunch = ProgramItem(
            id: lunchId, // ID Ata
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description:
                '🍗 Izgara tavuk, 🍚 pirinç pilavı, 🥗 yağlı salata, 🥛 yoğurt, 🍌 muz',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '12:30',
          );
          eveningActivity = ProgramItem(
            id: eveningId, // ID Ata
            type: ProgramItemType.workout,
            title: 'Omuz & Bacak & Karın',
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
            id: dinnerId, // ID Ata
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
            id: morningId, // ID Ata
            type: ProgramItemType.rest,
            title: 'Sabah: Dinlenme/Hafif Aktivite',
            description: '🚶‍♂️ İsteğe bağlı yüzme veya yürüyüş',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            time: '08:45',
          );
          lunch = ProgramItem(
            id: lunchId, // ID Ata
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description:
                '🥚 Tavuk, haşlanmış yumurta, 🥗 yoğurt, salata, kuruyemiş',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '12:30',
          );
          eveningActivity = ProgramItem(
            id: eveningId, // ID Ata
            type: ProgramItemType.rest,
            title: 'Akşam: Dinlenme',
            description: '🤸‍♂️ Tam dinlenme veya hafif esneme.',
            icon: Icons.hotel,
            color: Colors.green,
            time: '18:00',
          );
          dinner = ProgramItem(
            id: dinnerId, // ID Ata
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
            id: morningId, // ID Ata
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
            id: lunchId, // ID Ata
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description: '🐔 Tavuk, yumurta, pilav, salata',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '13:00',
          );
          eveningActivity = ProgramItem(
            id: eveningId, // ID Ata
            type: ProgramItemType.rest,
            title: 'Akşam: Aktif Dinlenme',
            description: '🚶‍♀️ Hafif aktivite veya dinlenme.',
            icon: Icons.mood,
            color: Colors.teal,
            time: '18:00',
          );
          dinner = ProgramItem(
            id: dinnerId, // ID Ata
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
            id: morningId, // ID Ata
            type: ProgramItemType.rest,
            title: 'Sabah: Dinlenme/Hafif Aktivite',
            description: '🧘‍♂️ Tam dinlenme veya 20-30 dk yürüyüş',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            time: '09:00',
          );
          lunch = ProgramItem(
            id: lunchId, // ID Ata
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description: '🔄 Hafta içi prensipteki öğünler',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '13:00',
          );
          eveningActivity = ProgramItem(
            id: eveningId, // ID Ata
            type: ProgramItemType.workout,
            title: 'Bel Sağlığı Egzersizleri',
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
            id: dinnerId, // ID Ata
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
            id: morningId, // ID Ata
            type: ProgramItemType.rest,
            title: 'Sabah: Dinlenme',
            description: '🧘‍♂️ Dinlenme',
            icon: Icons.hotel,
            color: Colors.green,
            time: '09:00',
          );
          lunch = ProgramItem(
            id: lunchId, // ID Ata
            type: ProgramItemType.meal,
            title: 'Öğle Yemeği',
            description: '🔄 Hafta içi prensipteki öğünler',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '13:00',
          );
          eveningActivity = ProgramItem(
            id: eveningId, // ID Ata
            type: ProgramItemType.rest,
            title: 'Akşam: Dinlenme',
            description: '💤 Dinlenme.',
            icon: Icons.hotel,
            color: Colors.green,
            time: '18:00',
          );
          dinner = ProgramItem(
            id: dinnerId, // ID Ata
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
    notifyListeners();
  }

  /// Mevcut aktif programı döndürür
  WeeklyProgram? getCurrentProgram() {
    return _currentProgram;
  }

  /// Verilen güne ait program bilgilerini döndürür
  DailyProgram? getDailyProgram(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= _workoutPrograms.length) {
      return null;
    }
    return _workoutPrograms[dayIndex];
  }

  /// Bugüne ait program bilgilerini döndürür
  DailyProgram? getTodayProgram() {
    final today = DateTime.now().weekday - 1; // 0: Pazartesi, 6: Pazar
    return getDailyProgram(today);
  }

  /// Tüm haftalık programı al (Egzersiz detayları ile birlikte)
  Future<List<DailyProgram>> getWeeklyProgram() async {
    if (_workoutPrograms.isEmpty) {
      debugPrint(
          'UYARI: getWeeklyProgram çağrıldığında _workoutPrograms boştu. Initialize doğru çağrıldı mı?');
      // await initialize(_exerciseService); // Gerekirse tekrar başlat (dikkatli ol)
    }

    // Egzersiz detaylarını yükle
    await _populateExerciseDetails();

    return _workoutPrograms;
  }

  /// Haftalık programdaki ProgramSet'ler için Exercise detaylarını doldurur.
  Future<void> _populateExerciseDetails() async {
    Set<String?> exerciseIds = {};

    // Haftalık programdaki tüm egzersiz ID'lerini topla
    for (var dailyProgram in _workoutPrograms) {
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
      debugPrint(
          "HATA: _populateExerciseDetails çağrıldığında _exerciseService null.");
      return;
    }

    final exercises =
        await _exerciseService!.getExercisesByIds(validExerciseIds);
    debugPrint(
        '[ProgramService] Fetched ${exercises?.length ?? 0} exercises from ExerciseService.');
    final Map<String?, Exercise> exerciseMap = {};

    if (exercises != null) {
      for (var ex in exercises) {
        exerciseMap[ex.id] = ex;
      }
    }

    debugPrint('[ProgramService] Exercise Map: ${exerciseMap.keys}');

    // ProgramSet'lerdeki exerciseDetails alanını doldur
    for (var dailyProgram in _workoutPrograms) {
      _populateDetailsForItem(dailyProgram.morningExercise, exerciseMap);
      _populateDetailsForItem(dailyProgram.eveningExercise, exerciseMap);
    }
  }

  /// Yardımcı metod: Bir ProgramItem içindeki ProgramSet'lere detayları ekler
  void _populateDetailsForItem(
      ProgramItem item, Map<String?, Exercise> exerciseMap) {
    if (item.type == ProgramItemType.workout && item.programSets != null) {
      List<ProgramSet> updatedProgramSets = [];
      for (var ps in item.programSets!) {
        if (exerciseMap.containsKey(ps.exerciseId)) {
          updatedProgramSets.add(
              ps.copyWith(exerciseDetails: () => exerciseMap[ps.exerciseId]));
        } else {
          updatedProgramSets.add(ps);
        }
      }
      item.programSets = updatedProgramSets;
    }
  }

  // Günlük programı güncelle
  Future<void> updateDailyProgram(int dayIndex, DailyProgram program) async {
    if (dayIndex < 0 || dayIndex >= _workoutPrograms.length) {
      return;
    }

    _workoutPrograms[dayIndex] = program;
    await _saveProgram();
  }

  // Programı sıfırla
  Future<void> resetProgram() async {
    if (_exerciseService == null) {
      debugPrint("Hata: ExerciseService başlatılmadan program sıfırlanamaz.");
      return;
    }
    await _createDefaultProgram(_exerciseService!);
    await _saveProgram();
  }

  /// Tüm ProgramItem'ları getirir (WorkoutProgramScreen için)
  /// Dikkat: Bu metot SharedPreferences'taki yapıya göre çalışır.
  /// EditProgramCategoryScreen'in beklediği ID'li item listesi için uyarlama gerekebilir.
  List<ProgramItem> getAllProgramItems() {
    List<ProgramItem> allItems = [];
    for (var dailyProgram in _workoutPrograms) {
      // ProgramItem'ları kopyalayarak ve KENDİ ID'leri ile listeye al
      allItems.add(dailyProgram.morningExercise);
      allItems.add(dailyProgram.lunch);
      allItems.add(dailyProgram.eveningExercise);
      allItems.add(dailyProgram.dinner);
    }
    debugPrint(
        "[ProgramService][getAllProgramItems] Returning ${allItems.length} items. First item title (if exists): ${allItems.isNotEmpty ? allItems.first.title : 'N/A'}");
    return allItems;
  }

  /// Belirli bir ProgramItem'ı ID'sine göre günceller.
  /// ID'nin formatı '{dayName}_{type}' şeklinde olmalıdır (örn: 'Pazartesi_morning').
  Future<void> updateProgramItem(ProgramItem updatedItem) async {
    if (updatedItem.id == null) {
      debugPrint("[ProgramService] Hata: Güncellenecek item ID'si null.");
      return;
    }

    // ID'den gün adını ve tipi çıkar (örn: "Pazartesi_morning")
    final idParts = updatedItem.id!.split('_');
    if (idParts.length != 2) {
      debugPrint(
          "[ProgramService] Hata: Güncelleme için geçersiz item ID formatı: ${updatedItem.id}. Beklenen format: 'GünAdı_tip'");
      return;
    }
    final dayName = idParts[0];
    final itemTypeStr = idParts[1]; // 'morning', 'lunch', 'evening', 'dinner'

    // İlgili günü bul
    final dayIndex = _workoutPrograms.indexWhere((dp) => dp.dayName == dayName);
    if (dayIndex == -1) {
      debugPrint(
          "[ProgramService] Hata: Güncellenecek gün bulunamadı (ID: ${updatedItem.id})");
      return;
    }

    // İlgili DailyProgram'ı al ve doğru slotu güncelle
    DailyProgram daily = _workoutPrograms[dayIndex];
    bool itemFoundAndUpdated = false;

    switch (itemTypeStr) {
      case 'morning':
        daily.morningExercise = updatedItem; // Direkt ata, ID korunmuş olur
        itemFoundAndUpdated = true;
        break;
      case 'lunch':
        daily.lunch = updatedItem;
        itemFoundAndUpdated = true;
        break;
      case 'evening':
        daily.eveningExercise = updatedItem;
        itemFoundAndUpdated = true;
        break;
      case 'dinner':
        daily.dinner = updatedItem;
        itemFoundAndUpdated = true;
        break;
      default:
        debugPrint(
            "[ProgramService] Hata: Geçersiz item tipi (ID: ${updatedItem.id})");
    }

    if (itemFoundAndUpdated) {
      _workoutPrograms[dayIndex] =
          daily; // Güncellenmiş DailyProgram'ı listeye geri koy
      debugPrint("[ProgramService] ProgramItem güncellendi: ${updatedItem.id}");
      await _saveProgram(); // Değişiklikleri kaydet
    } else {
      // Bu noktaya gelinmemesi lazım ama hata logu kalsın
      debugPrint(
          "[ProgramService] Güncellenecek item bulunamadı veya tip eşleşmedi: ${updatedItem.id}");
    }
  }

  /// Belirli bir ProgramItem'ı ID'sine göre siler (yerine varsayılan bir 'Rest' item koyar).
  /// ID'nin formatı '{dayName}_{type}' şeklinde olmalıdır (örn: 'Pazartesi_morning').
  Future<void> deleteProgramItem(String itemId) async {
    final idParts = itemId.split('_');
    if (idParts.length != 2) {
      debugPrint(
          "[ProgramService] Hata: Silme için geçersiz item ID formatı: $itemId. Beklenen format: 'GünAdı_tip'");
      return;
    }
    final dayName = idParts[0];
    final itemTypeStr = idParts[1];

    final dayIndex = _workoutPrograms.indexWhere((dp) => dp.dayName == dayName);
    if (dayIndex == -1) {
      debugPrint(
          "[ProgramService] Hata: Silinecek gün bulunamadı (ID: $itemId)");
      return;
    }

    DailyProgram daily = _workoutPrograms[dayIndex];
    bool itemFoundAndReplaced = false;
    ProgramItem? originalItem; // Zamanı almak için

    // Silme yerine konulacak varsayılan 'Rest' item
    ProgramItem replacementItem = ProgramItem(
      id: itemId, // Orijinal ID'yi koru
      type: ProgramItemType.rest,
      title: "Dinlenme",
      description: "-",
      icon: Icons.circle_outlined,
      color: Colors.grey,
      // time: null // Orijinalden alacağız
    );

    // İlgili slotu bul ve değiştir
    switch (itemTypeStr) {
      case 'morning':
        originalItem = daily.morningExercise;
        replacementItem = replacementItem.copyWith(time: originalItem.time);
        daily.morningExercise = replacementItem;
        itemFoundAndReplaced = true;
        break;
      case 'lunch':
        originalItem = daily.lunch;
        replacementItem = replacementItem.copyWith(
            type: ProgramItemType.meal,
            title: "Öğle Yemeği",
            icon: Icons.restaurant,
            time: originalItem.time); // Yemekse meal kalsın
        daily.lunch = replacementItem;
        itemFoundAndReplaced = true;
        break;
      case 'evening':
        originalItem = daily.eveningExercise;
        replacementItem = replacementItem.copyWith(time: originalItem.time);
        daily.eveningExercise = replacementItem;
        itemFoundAndReplaced = true;
        break;
      case 'dinner':
        originalItem = daily.dinner;
        replacementItem = replacementItem.copyWith(
            type: ProgramItemType.meal,
            title: "Akşam Yemeği",
            icon: Icons.dinner_dining,
            time: originalItem.time);
        daily.dinner = replacementItem;
        break;
      default:
        debugPrint(
            "[ProgramService] Hata: Silme için geçersiz item tipi (ID: $itemId)");
    }

    if (itemFoundAndReplaced) {
      _workoutPrograms[dayIndex] = daily;
      debugPrint(
          "[ProgramService] ProgramItem silindi (yerine varsayılan kondu): $itemId");
      await _saveProgram();
    } else {
      // Bu noktaya gelinmemesi lazım
      debugPrint(
          "[ProgramService] Silinecek item bulunamadı veya tip eşleşmedi: $itemId");
    }
  }

  /// Yeni bir ProgramItem ekler (genellikle bir 'rest' item yerine).
  /// targetDayName ve targetSlotType **belirtilmelidir**.
  /// ID'si bu bilgilere göre atanır.
  Future<void> addProgramItem(ProgramItem newItem,
      {required String targetDayName, required String targetSlotType}) async {
    final dayIndex =
        _workoutPrograms.indexWhere((dp) => dp.dayName == targetDayName);
    if (dayIndex == -1) {
      debugPrint(
          "[ProgramService] Hata: Yeni item eklenecek gün bulunamadı: $targetDayName");
      return;
    }

    DailyProgram daily = _workoutPrograms[dayIndex];
    String newId = "${targetDayName}_$targetSlotType";
    ProgramItem itemToAdd = newItem.copyWith(id: newId); // ID'yi ata
    bool added = false;

    switch (targetSlotType) {
      case 'morning':
        // İsteğe bağlı: Eğer mevcut item rest değilse uyarı verilebilir veya üzerine yazma engellenebilir.
        // if (daily.morningExercise.type != ProgramItemType.rest) { ... }
        itemToAdd = itemToAdd.copyWith(
            time: daily.morningExercise.time); // Eski zamanı koru
        daily.morningExercise = itemToAdd;
        added = true;
        break;
      case 'lunch':
        itemToAdd = itemToAdd.copyWith(time: daily.lunch.time);
        daily.lunch = itemToAdd;
        added = true;
        break;
      case 'evening':
        itemToAdd = itemToAdd.copyWith(time: daily.eveningExercise.time);
        daily.eveningExercise = itemToAdd;
        added = true;
        break;
      case 'dinner':
        itemToAdd = itemToAdd.copyWith(time: daily.dinner.time);
        daily.dinner = itemToAdd;
        added = true;
        break;
      default:
        debugPrint(
            "[ProgramService] Hata: Yeni item eklemek için geçersiz slot tipi: $targetSlotType");
    }

    if (added) {
      _workoutPrograms[dayIndex] = daily;
      debugPrint("[ProgramService] Yeni ProgramItem eklendi: $newId");
      await _saveProgram(); // Değişiklikleri kaydet
    }
  }

  // ================================================
  // Aşağıdaki metotların isimleri _internal ile değiştirildi veya kaldırıldı
  // Mükerrer tanımları önlemek için.
  // ================================================

  // Belirli bir günün programını güncelleme (Adı değiştirildi)
  Future<void> updateDailyProgramByName(
      String dayName, DailyProgram program) async {
    final index = _workoutPrograms.indexWhere((dp) => dp.dayName == dayName);
    if (index != -1) {
      _workoutPrograms[index] = program;
      await _saveProgram();
      debugPrint("[ProgramService] Günlük program güncellendi: $dayName");
    } else {
      debugPrint(
          '[ProgramService] Hata: Güncellenecek gün bulunamadı: $dayName');
    }
  }

  // Günlük programı getirme (internal)
  DailyProgram _getDailyProgramInternal(String dayName) {
    return _workoutPrograms.firstWhere((dp) => dp.dayName == dayName,
        orElse: () {
      debugPrint(
          "[ProgramService] Uyarı: '$dayName' için program bulunamadı, varsayılan oluşturuluyor.");
      return _createDefaultDailyProgram(dayName);
    });
  }

  // Varsayılan günlük program (Yardımcı metot - ID'ler eklendi)
  DailyProgram _createDefaultDailyProgram(String dayName) {
    final String morningId = '${dayName}_morning';
    final String lunchId = '${dayName}_lunch';
    final String eveningId = '${dayName}_evening';
    final String dinnerId = '${dayName}_dinner';

    return DailyProgram(
      dayName: dayName,
      morningExercise: ProgramItem(
          id: morningId,
          type: ProgramItemType.rest,
          title: 'Dinlenme',
          description: '-',
          icon: Icons.hotel,
          color: Colors.grey),
      lunch: ProgramItem(
          id: lunchId,
          type: ProgramItemType.meal,
          title: 'Öğle Yemeği',
          description: '-',
          icon: Icons.restaurant,
          color: Colors.grey),
      eveningExercise: ProgramItem(
          id: eveningId,
          type: ProgramItemType.rest,
          title: 'Dinlenme',
          description: '-',
          icon: Icons.hotel,
          color: Colors.grey),
      dinner: ProgramItem(
          id: dinnerId,
          type: ProgramItemType.meal,
          title: 'Akşam Yemeği',
          description: '-',
          icon: Icons.dinner_dining,
          color: Colors.grey),
    );
  }

  // Get today's program based on device timezone (non-async)
  DailyProgram getTodaysProgram() {
    final String today = DateFormat('EEEE', 'tr_TR').format(DateTime.now());
    debugPrint("[ProgramService] Bugünün programı getiriliyor: $today");
    return _getDailyProgramInternal(today); // internal metodu çağır
  }

  // Get tomorrow's program (non-async)
  DailyProgram getTomorrowsProgram() {
    final String tomorrow = DateFormat('EEEE', 'tr_TR')
        .format(DateTime.now().add(Duration(days: 1)));
    debugPrint("[ProgramService] Yarının programı getiriliyor: $tomorrow");
    return _getDailyProgramInternal(tomorrow); // internal metodu çağır
  }

  /// Verilen ProgramItem listesini ve silinecek ID listesini işleyerek
  /// _workoutPrograms listesini günceller.
  Future<void> updateProgramItems(
      List<ProgramItem> itemsToUpdate,
      List<String> idsToDelete,
      Map<String, String> categoryTitleChanges // Yeni parametre
      ) async {
    debugPrint(
        "[ProgramService][updateProgramItems] Başladı. Güncellenecek: ${itemsToUpdate.length}, Silinecek: ${idsToDelete.length}, Başlık Değişiklikleri: $categoryTitleChanges");
    bool changed = false;
    bool unassignedChanged = false; // Atanmamış liste değişti mi?

    Map<String, List<ProgramSet>?> categorySetUpdates = {};
    List<ProgramItem> newCategoryItems = []; // Yeni eklenecek kategoriler
    Set<String> titlesToUpdateSetsFor = {}; // Setleri güncellenecek başlıklar
    Set<String> categoriesToDelete = {}; // Silinecek kategori başlıkları

    // Silinecek kategori başlıklarını belirle
    for (var id in idsToDelete) {
      // ID'den kategori başlığını bulmamız lazım.
      // Eğer 'category_' ile başlıyorsa, _unassignedCategories içinde bulalım.
      if (id.startsWith('category_')) {
        final itemIndex =
            _unassignedCategories.indexWhere((item) => item.id == id);
        if (itemIndex != -1) {
          categoriesToDelete.add(_unassignedCategories[itemIndex].title!);
        }
      } else {
        // Eğer atanmış bir ID ise (örn: Salı_evening), _weeklyProgram içinde bulalım.
        final idParts = id.split('_');
        if (idParts.length == 2) {
          final dayName = idParts[0];
          final itemTypeStr = idParts[1];
          final dayIndex =
              _workoutPrograms.indexWhere((dp) => dp.dayName == dayName);
          if (dayIndex != -1) {
            DailyProgram daily = _workoutPrograms[dayIndex];
            ProgramItem? item;
            if (itemTypeStr == 'morning')
              item = daily.morningExercise;
            else if (itemTypeStr == 'evening') item = daily.eveningExercise;
            if (item != null &&
                item.type == ProgramItemType.workout &&
                item.title != null) {
              categoriesToDelete.add(item.title!);
            }
          }
        }
      }
    }
    debugPrint(
        "[ProgramService] Silinecek kategori başlıkları: $categoriesToDelete");

    // itemsToUpdate listesini işle
    for (var item in itemsToUpdate) {
      if (item.id == null || item.title == null) continue;

      // Eğer bu bir kategori güncelleme item'ı ise (ID'si 'category_' ile başlıyor veya başlığı değişti)
      bool isCategoryUpdate = item.id!.startsWith('category_') ||
          categoryTitleChanges.containsValue(item.title);

      if (isCategoryUpdate) {
        debugPrint(
            "[ProgramService] Kategori güncelleme item'ı algılandı: ID=${item.id}, Başlık=${item.title}");

        // Bu kategori başlığı _weeklyProgram'da veya _unassignedCategories'de var mı kontrolü (isTrulyNew için)
        String originalTitle = categoryTitleChanges.entries
            .firstWhere((entry) => entry.value == item.title,
                orElse: () => MapEntry(item.title!, item.title!))
            .key;

        bool existsInWeekly = _workoutPrograms.any((day) =>
            (day.morningExercise.type == ProgramItemType.workout &&
                day.morningExercise.title == originalTitle) ||
            (day.eveningExercise.type == ProgramItemType.workout &&
                day.eveningExercise.title == originalTitle));
        bool existsInUnassigned = _unassignedCategories
            .any((cat) => cat.title == originalTitle && cat.id != item.id);

        bool isTrulyNew = !existsInWeekly &&
            !existsInUnassigned &&
            !categoryTitleChanges.containsKey(originalTitle);

        if (isTrulyNew) {
          debugPrint(
              "[ProgramService] Yeni kategori tespit edildi: ${item.title}");
          newCategoryItems.add(item);
          unassignedChanged = true;
        } else {
          debugPrint(
              "[ProgramService] Mevcut kategori (${item.title}) için set güncellemesi.");
          // Mevcut kategori setlerini güncellemek için başlığı işaretle
          titlesToUpdateSetsFor.add(item.title!); // Yeni başlığı kullan
          categorySetUpdates[item.title!] = item.programSets;
        }
        changed = true; // Kategori değişikliği olduğunu işaretle
      } else {
        // --- NEW LOGIC for updating existing assigned categories without name change ---
        // Check if this item ID corresponds to an existing item in the weekly program
        final idParts = item.id!.split('_');
        if (idParts.length == 2) {
          final dayName = idParts[0];
          final itemTypeStr = idParts[1];
          final dayIndex =
              _workoutPrograms.indexWhere((dp) => dp.dayName == dayName);
          if (dayIndex != -1) {
            DailyProgram daily = _workoutPrograms[dayIndex];
            ProgramItem? existingItem;
            if (itemTypeStr == 'morning')
              existingItem = daily.morningExercise;
            else if (itemTypeStr == 'evening')
              existingItem = daily.eveningExercise;

            // Check if the title matches (it should if the name wasn't changed)
            // and the ID also matches the item being processed
            if (existingItem != null &&
                existingItem.id == item.id &&
                existingItem.title == item.title) {
              debugPrint(
                  "[ProgramService] Mevcut atanmış kategori (${item.title}, ID: ${item.id}) için set güncellemesi.");
              titlesToUpdateSetsFor.add(item.title!); // Use existing title
              categorySetUpdates[item.title!] = item.programSets;
              changed = true; // Mark change
            }
          }
        }
        // --- END NEW LOGIC ---
      }
    } // itemsToUpdate döngüsü sonu

    // Yeni kategorileri ekle
    _unassignedCategories.addAll(newCategoryItems);
    // Eklenenler zaten varsa çıkaralım (ID'ye göre)
    _unassignedCategories =
        _unassignedCategories.fold<List<ProgramItem>>([], (prev, element) {
      if (!prev.any((e) => e.id == element.id)) {
        prev.add(element);
      }
      return prev;
    });

    // Silinecek kategorileri _unassignedCategories'den çıkar
    int initialUnassignedCount = _unassignedCategories.length;
    _unassignedCategories
        .removeWhere((item) => categoriesToDelete.contains(item.title));
    if (_unassignedCategories.length != initialUnassignedCount) {
      unassignedChanged = true;
    }

    // --- _weeklyProgram ÜZERİNDE GÜNCELLEME ve SİLME ---
    for (int i = 0; i < _workoutPrograms.length; i++) {
      DailyProgram currentDay = _workoutPrograms[i];
      bool dayChanged = false;

      // Sabah Egzersizi Güncelleme / Silme
      ProgramItem morningEx = currentDay.morningExercise;
      if (morningEx.type == ProgramItemType.workout &&
          morningEx.title != null) {
        String currentTitle = morningEx.title!;
        ProgramItem updatedMorningEx = morningEx;

        // Kategori silinecek mi?
        if (categoriesToDelete.contains(currentTitle)) {
          debugPrint(
              "[ProgramService] Sabah egzersizi (${currentDay.dayName}, Kategori: '$currentTitle') siliniyor (yerine Rest konuluyor).");
          updatedMorningEx = ProgramItem(
              id: morningEx.id,
              type: ProgramItemType.rest,
              title: "Dinlenme",
              description: "-",
              icon: Icons.circle_outlined,
              color: Colors.grey,
              time: morningEx.time);
          dayChanged = true;
        } else {
          // Silinmiyorsa güncelleme kontrolleri
          // 1. Başlık Güncelleme
          if (categoryTitleChanges.containsKey(currentTitle)) {
            String newTitle = categoryTitleChanges[currentTitle]!;
            updatedMorningEx = updatedMorningEx.copyWith(title: newTitle);
            debugPrint(
                "[ProgramService] Sabah egzersizi (${currentDay.dayName}) başlığı güncellendi: '$currentTitle' -> '$newTitle'");
            currentTitle = newTitle;
            dayChanged = true;
          }

          // 2. İçerik (ProgramSet) Güncelleme
          if (titlesToUpdateSetsFor.contains(currentTitle)) {
            if (!DeepCollectionEquality().equals(updatedMorningEx.programSets,
                categorySetUpdates[currentTitle])) {
              updatedMorningEx = updatedMorningEx.copyWith(
                  programSets: categorySetUpdates[currentTitle]);
              debugPrint(
                  "[ProgramService] Sabah egzersizi (${currentDay.dayName}, Başlık: '$currentTitle') içeriği güncellendi.");
              dayChanged = true;
            }
          }
        }
        currentDay.morningExercise = updatedMorningEx;
      }

      // Akşam Egzersizi Güncelleme / Silme (Sabah ile aynı mantık)
      ProgramItem eveningEx = currentDay.eveningExercise;
      if (eveningEx.type == ProgramItemType.workout &&
          eveningEx.title != null) {
        String currentTitle = eveningEx.title!;
        ProgramItem updatedEveningEx = eveningEx;

        // Kategori silinecek mi?
        if (categoriesToDelete.contains(currentTitle)) {
          debugPrint(
              "[ProgramService] Akşam egzersizi (${currentDay.dayName}, Kategori: '$currentTitle') siliniyor (yerine Rest konuluyor).");
          updatedEveningEx = ProgramItem(
              id: eveningEx.id,
              type: ProgramItemType.rest,
              title: "Dinlenme",
              description: "-",
              icon: Icons.circle_outlined,
              color: Colors.grey,
              time: eveningEx.time);
          dayChanged = true;
        } else {
          // Silinmiyorsa güncelleme kontrolleri
          // 1. Başlık Güncelleme
          if (categoryTitleChanges.containsKey(currentTitle)) {
            String newTitle = categoryTitleChanges[currentTitle]!;
            updatedEveningEx = updatedEveningEx.copyWith(title: newTitle);
            debugPrint(
                "[ProgramService] Akşam egzersizi (${currentDay.dayName}) başlığı güncellendi: '$currentTitle' -> '$newTitle'");
            currentTitle = newTitle;
            dayChanged = true;
          }

          // 2. İçerik (ProgramSet) Güncelleme
          if (titlesToUpdateSetsFor.contains(currentTitle)) {
            if (!DeepCollectionEquality().equals(updatedEveningEx.programSets,
                categorySetUpdates[currentTitle])) {
              updatedEveningEx = updatedEveningEx.copyWith(
                  programSets: categorySetUpdates[currentTitle]);
              debugPrint(
                  "[ProgramService] Akşam egzersizi (${currentDay.dayName}, Başlık: '$currentTitle') içeriği güncellendi.");
              dayChanged = true;
            }
          }
        }
        currentDay.eveningExercise = updatedEveningEx;
      }

      if (dayChanged) {
        _workoutPrograms[i] =
            currentDay; // Güncellenen DailyProgram'ı listeye geri koy
        changed = true; // Genel değişiklik flag'ini ayarla
      }
    } // _weeklyProgram döngüsü sonu

    // Değişiklik varsa kaydet ve bildir
    if (changed || unassignedChanged) {
      debugPrint("[ProgramService] Değişiklikler kaydediliyor...");
      await _saveProgram();
      debugPrint("[ProgramService] Değişiklikler kaydedildi.");
    } else {
      debugPrint("[ProgramService] Kaydedilecek bir değişiklik bulunamadı.");
    }
  }

  // İki program seti listesinin aynı egzersizlere sahip olup olmadığını kontrol eder
  bool _hasMatchingExercises(List<ProgramSet>? list1, List<ProgramSet>? list2) {
    if (list1 == null || list2 == null) return false;
    if (list1.isEmpty && list2.isEmpty) return true;
    if (list1.length != list2.length) return false;

    // Egzersiz ID'lerini karşılaştır
    Set<String?> ids1 = list1.map((s) => s.exerciseId).toSet();
    Set<String?> ids2 = list2.map((s) => s.exerciseId).toSet();

    return SetEquality().equals(ids1, ids2);
  }

  /// Tüm ProgramItem'ları (hem haftalık programdaki hem de atanmamış kategoriler)
  /// düz bir liste olarak döndürür.
  List<ProgramItem> getAllProgramItemsIncludingUnassigned() {
    List<ProgramItem> allItems = [];
    // Haftalık programdaki item'lar
    for (var dailyProgram in _workoutPrograms) {
      allItems.add(dailyProgram.morningExercise);
      allItems.add(dailyProgram.lunch);
      allItems.add(dailyProgram.eveningExercise);
      allItems.add(dailyProgram.dinner);
    }
    // Atanmamış kategoriler
    allItems.addAll(_unassignedCategories);
    return allItems;
  }
}
