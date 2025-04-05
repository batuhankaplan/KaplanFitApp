import 'package:flutter/material.dart';
import '../models/program/daily_program.dart';
import '../models/program/program_item.dart';
import '../models/program/weekly_program.dart';
import '../theme.dart';

/// Program verilerini sağlayan servis sınıfı
class ProgramService {
  static final ProgramService _instance = ProgramService._internal();
  
  factory ProgramService() {
    return _instance;
  }
  
  ProgramService._internal();
  
  /// Mevcut aktif program
  WeeklyProgram? _currentProgram;
  
  /// Tüm haftalık programlar
  final List<WeeklyProgram> _allPrograms = [];
  
  /// Başlangıçta program verilerini yükle
  Future<void> initialize() async {
    // Örnek program verileri
    _allPrograms.add(_createDefaultWeeklyProgram());
    _currentProgram = _allPrograms.first;
  }
  
  /// Varsayılan haftalık programı oluşturur
  WeeklyProgram _createDefaultWeeklyProgram() {
    // Gün adları
    final List<String> weekDays = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];
    
    // Genel tavsiyeler
    final List<String> generalTips = [
      '💧 Günde en az 2-3 litre su iç.',
      '❌ Şekerli içeceklerden uzak dur.',
      '🍽️ Egzersiz yemekten önce, akşam yemeği hafif ve dengeli olsun.',
      '🍌 Her gün 1 muz tüket (potasyum kaynağı).',
      '🥄 Zeytinyağı 1-2 yemek kaşığı yeterlidir.',
      '🏋️‍♂️ Ağırlık antrenmanları: Salı, Çarşamba, Perşembe günleri.',
    ];
    
    // Günlük programlar listesi
    final List<DailyProgram> dailyPrograms = [];
    
    // Sabit tanımlar (program öğe başlıkları)
    const List<String> activityTitles = [
      'Sabah Programı',
      'Öğle Yemeği',
      'Akşam Egzersizi',
      'Akşam Yemeği',
    ];
    
    // Sabit ikonlar
    const List<IconData> activityIcons = [
      Icons.sunny,
      Icons.lunch_dining,
      Icons.fitness_center,
      Icons.dinner_dining,
    ];
    
    // Sabit renkler
    const List<Color> activityColors = [
      AppTheme.morningExerciseColor,
      AppTheme.lunchColor,
      AppTheme.eveningExerciseColor,
      AppTheme.dinnerColor,
    ];
    
    // Sabit zaman dilimleri
    const List<ProgramTimeSlot> timeSlots = [
      ProgramTimeSlot.morning,
      ProgramTimeSlot.lunch,
      ProgramTimeSlot.evening,
      ProgramTimeSlot.dinner,
    ];
    
    // Her gün için program tanımlamaları
    final List<List<String>> dayDescriptions = [
      // Pazartesi
      [
        '🏊‍♂️ Havuz kapalı. Dinlen veya evde esneme yap.',
        '🍗 Izgara tavuk, 🍚 pirinç pilavı, 🥗 yağlı salata, 🥛 yoğurt, 🍌 muz, badem/ceviz',
        '🛑 Spor salonu kapalı. Dinlen veya hafif yürüyüş.',
        '🥗 Ton balıklı salata, yoğurt, 🥖 tahıllı ekmek',
      ],
      // Salı
      [
        '🏊‍♂️ 08:45 - 09:15 yüzme',
        '🥣 Yulaf + süt + muz veya Pazartesi menüsü',
        '(18:00 - 18:45 Ağırlık): Squat, Leg Press, Bench Press, Lat Pull-Down',
        '🍗 Izgara tavuk veya 🐟 ton balıklı salata, yoğurt',
      ],
      // Çarşamba
      [
        '🏊‍♂️ 08:45 - 09:15 yüzme',
        '🥣 Yulaf + süt + muz veya Pazartesi menüsü',
        '(18:00 - 18:45 Ağırlık): Row, Goblet Squat, Core Çalışmaları',
        '🐔 Tavuk veya 🐟 ton balık, 🥗 yağlı salata, yoğurt',
      ],
      // Perşembe
      [
        '🏊‍♂️ 08:45 - 09:15 yüzme',
        '🍗 Izgara tavuk, 🍚 pirinç pilavı, 🥗 yağlı salata, 🥛 yoğurt, 🍌 muz, badem/ceviz veya yulaf alternatifi',
        '(18:00 - 18:45 Ağırlık): 🔄 Salı antrenmanı tekrarı',
        '🐔 Tavuk veya 🐟 ton balık, 🥗 salata, yoğurt',
      ],
      // Cuma
      [
        '🚶‍♂️ İsteğe bağlı yüzme veya yürüyüş',
        '🥚 Tavuk, haşlanmış yumurta, 🥗 yoğurt, salata, kuruyemiş',
        '🤸‍♂️ Dinlenme veya esneme',
        '🍳 Menemen, 🥗 ton balıklı salata, yoğurt',
      ],
      // Cumartesi
      [
        '🚶‍♂️ Hafif yürüyüş, esneme veya yüzme',
        '🐔 Tavuk, yumurta, pilav, salata',
        '⚡️ İsteğe bağlı egzersiz',
        '🍽️ Sağlıklı serbest menü',
      ],
      // Pazar
      [
        '🧘‍♂️ Tam dinlenme veya 20-30 dk yürüyüş',
        '🔄 Hafta içi prensipteki öğünler',
        '💤 Dinlenme',
        '🍴 Hafif ve dengeli öğün',
      ],
    ];
    
    // Her gün için program oluştur
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      // Bu gün için programlar listesi
      List<ProgramItem> dayItems = [];
      
      // Her program öğesi için
      for (int itemIndex = 0; itemIndex < 4; itemIndex++) {
        dayItems.add(ProgramItem(
          title: activityTitles[itemIndex],
          description: dayDescriptions[dayIndex][itemIndex],
          icon: activityIcons[itemIndex],
          color: activityColors[itemIndex],
          timeSlot: timeSlots[itemIndex],
        ));
      }
      
      // Günlük programı oluştur
      dailyPrograms.add(DailyProgram(
        dayName: weekDays[dayIndex],
        dayIndex: dayIndex,
        items: dayItems,
        tips: generalTips,
      ));
    }
    
    // Haftalık programı oluştur ve döndür
    return WeeklyProgram(
      name: 'Sağlıklı Yaşam Programı',
      weekNumber: 1,
      dailyPrograms: dailyPrograms,
      tips: generalTips,
      startDate: DateTime.now(),
    );
  }
  
  /// Mevcut aktif programı döndürür
  WeeklyProgram? getCurrentProgram() {
    return _currentProgram;
  }
  
  /// Verilen güne ait program bilgilerini döndürür
  DailyProgram? getDailyProgram(int dayIndex) {
    return _currentProgram?.getDailyProgram(dayIndex);
  }
  
  /// Bugüne ait program bilgilerini döndürür
  DailyProgram? getTodayProgram() {
    return _currentProgram?.getTodayProgram();
  }
} 