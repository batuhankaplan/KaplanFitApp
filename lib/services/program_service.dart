import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/program_model.dart';

/// Program verilerini sağlayan servis sınıfı
class ProgramService {
  static const String _programKey = 'weekly_program';
  List<DailyProgram> _weeklyProgram = [];
  
  // Singleton yapı
  static final ProgramService _instance = ProgramService._internal();
  
  factory ProgramService() {
    return _instance;
  }
  
  ProgramService._internal();
  
  /// Mevcut aktif program
  WeeklyProgram? _currentProgram;
  
  /// Tüm haftalık programlar
  final List<WeeklyProgram> _allPrograms = [];
  
  // Servis başlatma
  Future<void> initialize() async {
    await _loadProgram();
  }
  
  // Programı SharedPreferences'tan yükle
  Future<void> _loadProgram() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final programJson = prefs.getString(_programKey);
      
      // Eğer kayıtlı program yoksa varsayılan programı oluştur
      if (programJson == null) {
        _createDefaultProgram();
        await _saveProgram();
      } else {
        // Kayıtlı programı yükle
        final programMap = json.decode(programJson);
        final List<dynamic> dailyProgramsJson = programMap['dailyPrograms'];
        
        _weeklyProgram = dailyProgramsJson
            .map((json) => DailyProgram.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Program yüklenirken hata: $e');
      _createDefaultProgram();
    }
  }
  
  // Programı SharedPreferences'a kaydet
  Future<void> _saveProgram() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final programMap = {
        'dailyPrograms': _weeklyProgram.map((program) => program.toJson()).toList(),
      };
      
      await prefs.setString(_programKey, json.encode(programMap));
    } catch (e) {
      print('Program kaydedilirken hata: $e');
    }
  }
  
  /// Varsayılan haftalık programı oluştur
  void _createDefaultProgram() {
    final List<String> weekDays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    
    _weeklyProgram = List.generate(7, (index) {
      final String dayName = weekDays[index];
      
      ProgramItem morningExercise;
      ProgramItem lunch;
      ProgramItem eveningExercise;
      ProgramItem dinner;
      
      switch (index) {
        case 0: // Pazartesi
          morningExercise = ProgramItem(
            title: 'Sabah Egzersizi',
            description: '🏊‍♂️ Havuz kapalı. Dinlen veya evde esneme yap.',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            time: '08:00',
          );
          lunch = ProgramItem(
            title: 'Öğle Yemeği',
            description: '🍗 Izgara tavuk, 🍚 pirinç pilavı, 🥗 yağlı salata, 🥛 yoğurt',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '12:30',
          );
          eveningExercise = ProgramItem(
            title: 'Akşam Egzersizi',
            description: '🛑 Spor salonu kapalı. Dinlen veya hafif yürüyüş.',
            icon: Icons.fitness_center,
            color: Colors.purple,
            time: '18:00',
          );
          dinner = ProgramItem(
            title: 'Akşam Yemeği',
            description: '🥗 Ton balıklı salata, yoğurt, 🥖 tahıllı ekmek',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;
          
        case 1: // Salı
          morningExercise = ProgramItem(
            title: 'Sabah Egzersizi',
            description: '🏊‍♂️ 08:45 - 09:15 yüzme',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            time: '08:45',
          );
          lunch = ProgramItem(
            title: 'Öğle Yemeği',
            description: '🥣 Yulaf + süt + muz veya Pazartesi menüsü',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '12:30',
          );
          eveningExercise = ProgramItem(
            title: 'Akşam Egzersizi',
            description: '(18:00 - 18:45 Ağırlık): Squat, Leg Press, Bench Press, Lat Pull-Down',
            icon: Icons.fitness_center,
            color: Colors.purple,
            time: '18:00',
          );
          dinner = ProgramItem(
            title: 'Akşam Yemeği',
            description: '🍗 Izgara tavuk veya 🐟 ton balıklı salata, yoğurt',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;
          
        case 2: // Çarşamba
          morningExercise = ProgramItem(
            title: 'Sabah Egzersizi',
            description: '🏊‍♂️ 08:45 - 09:15 yüzme',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            time: '08:45',
          );
          lunch = ProgramItem(
            title: 'Öğle Yemeği',
            description: '🥣 Yulaf + süt + muz veya Pazartesi menüsü',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '12:30',
          );
          eveningExercise = ProgramItem(
            title: 'Akşam Egzersizi',
            description: '(18:00 - 18:45 Ağırlık): Row, Goblet Squat, Core Çalışmaları',
            icon: Icons.fitness_center,
            color: Colors.purple,
            time: '18:00',
          );
          dinner = ProgramItem(
            title: 'Akşam Yemeği',
            description: '🐔 Tavuk veya 🐟 ton balık, 🥗 yağlı salata, yoğurt',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;
          
        case 3: // Perşembe
          morningExercise = ProgramItem(
            title: 'Sabah Egzersizi',
            description: '🏊‍♂️ 08:45 - 09:15 yüzme',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            time: '08:45',
          );
          lunch = ProgramItem(
            title: 'Öğle Yemeği',
            description: '🍗 Izgara tavuk, 🍚 pirinç pilavı, 🥗 yağlı salata, 🥛 yoğurt, 🍌 muz',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '12:30',
          );
          eveningExercise = ProgramItem(
            title: 'Akşam Egzersizi',
            description: '(18:00 - 18:45 Ağırlık): 🔄 Salı antrenmanı tekrarı',
            icon: Icons.fitness_center,
            color: Colors.purple,
            time: '18:00',
          );
          dinner = ProgramItem(
            title: 'Akşam Yemeği',
            description: '🐔 Tavuk veya 🐟 ton balık, 🥗 salata, yoğurt',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;
          
        case 4: // Cuma
          morningExercise = ProgramItem(
            title: 'Sabah Egzersizi',
            description: '🚶‍♂️ İsteğe bağlı yüzme veya yürüyüş',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            time: '08:45',
          );
          lunch = ProgramItem(
            title: 'Öğle Yemeği',
            description: '🥚 Tavuk, haşlanmış yumurta, 🥗 yoğurt, salata, kuruyemiş',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '12:30',
          );
          eveningExercise = ProgramItem(
            title: 'Akşam Egzersizi',
            description: '🤸‍♂️ Dinlenme veya esneme',
            icon: Icons.fitness_center,
            color: Colors.purple,
            time: '18:00',
          );
          dinner = ProgramItem(
            title: 'Akşam Yemeği',
            description: '🍳 Menemen, 🥗 ton balıklı salata, yoğurt',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;
          
        case 5: // Cumartesi
          morningExercise = ProgramItem(
            title: 'Sabah Egzersizi',
            description: '🚶‍♂️ Hafif yürüyüş, esneme veya yüzme',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            time: '09:00',
          );
          lunch = ProgramItem(
            title: 'Öğle Yemeği',
            description: '🐔 Tavuk, yumurta, pilav, salata',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '13:00',
          );
          eveningExercise = ProgramItem(
            title: 'Akşam Egzersizi',
            description: '⚡️ İsteğe bağlı egzersiz',
            icon: Icons.fitness_center,
            color: Colors.purple,
            time: '18:00',
          );
          dinner = ProgramItem(
            title: 'Akşam Yemeği',
            description: '🍽️ Sağlıklı serbest menü',
            icon: Icons.dinner_dining,
            color: Colors.blue,
            time: '19:30',
          );
          break;
          
        case 6: // Pazar
        default:
          morningExercise = ProgramItem(
            title: 'Sabah Egzersizi',
            description: '🧘‍♂️ Tam dinlenme veya 20-30 dk yürüyüş',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            time: '09:00',
          );
          lunch = ProgramItem(
            title: 'Öğle Yemeği',
            description: '🔄 Hafta içi prensipteki öğünler',
            icon: Icons.restaurant,
            color: const Color(0xFFA0C334),
            time: '13:00',
          );
          eveningExercise = ProgramItem(
            title: 'Akşam Egzersizi',
            description: '💤 Dinlenme',
            icon: Icons.fitness_center,
            color: Colors.purple,
            time: '18:00',
          );
          dinner = ProgramItem(
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
        morningExercise: morningExercise,
        lunch: lunch,
        eveningExercise: eveningExercise,
        dinner: dinner,
      );
    });
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
  
  /// Tüm haftalık programı al
  Future<List<DailyProgram>> getWeeklyProgram() async {
    if (_weeklyProgram.isEmpty) {
      await _loadProgram();
    }
    return _weeklyProgram;
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
    _createDefaultProgram();
    await _saveProgram();
  }
} 