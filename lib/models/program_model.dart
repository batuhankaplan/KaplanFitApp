import 'package:flutter/material.dart';
// import 'workout_set.dart'; // Eski modeli kaldır
import 'program_set.dart'; // Yeni modeli import et

/// Program öğesinin türünü belirtir (antrenman, yemek, dinlenme vb.)
enum ProgramItemType { workout, meal, rest, other }

class ProgramItem {
  final ProgramItemType type; // Öğenin türü
  final String title;
  final String? description; // Yemekler veya basit notlar için
  final List<ProgramSet>?
      programSets; // Antrenmanlar için egzersiz listesi (WorkoutSet -> ProgramSet)
  final IconData icon;
  final Color color;
  final String? time;

  ProgramItem({
    required this.type,
    required this.title,
    this.description,
    this.programSets, // workoutSets -> programSets
    required this.icon,
    required this.color,
    this.time,
  }) : assert(
            (type == ProgramItemType.workout &&
                    programSets != null) || // workoutSets -> programSets
                (type != ProgramItemType.workout && description != null),
            'Workout tipindeki öğelerin programSets, diğerlerinin description alanı olmalıdır.');

  // Kopyalama metodu
  ProgramItem copyWith({
    ProgramItemType? type,
    String? title,
    String? description,
    List<ProgramSet>? programSets, // workoutSets -> programSets
    IconData? icon,
    Color? color,
    String? time,
    bool clearProgramSets = false, // workoutSets -> programSets
    bool clearDescription = false, // description'ı null yapmak için flag
  }) {
    return ProgramItem(
      type: type ?? this.type,
      title: title ?? this.title,
      // Eğer yeni tip workout ise description'ı temizle (veya flag true ise)
      description: (type == ProgramItemType.workout || clearDescription)
          ? null
          : description ?? this.description,
      // Eğer yeni tip workout değilse programSets'i temizle (veya flag true ise)
      programSets: (type != ProgramItemType.workout ||
              clearProgramSets) // workoutSets -> programSets
          ? null
          : programSets ?? this.programSets, // workoutSets -> programSets
      icon: icon ?? this.icon,
      color: color ?? this.color,
      time: time ?? this.time,
    );
  }

  // JSON'dan nesne oluştur
  factory ProgramItem.fromJson(Map<String, dynamic> json) {
    final itemType = ProgramItemType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () =>
            ProgramItemType.other // Eski veri veya hatalı tip için varsayılan
        );
    final int iconCode = json['icon'] ?? 0xE5E5;
    final IconData iconData = _getIconData(iconCode);

    List<ProgramSet>? sets; // WorkoutSet -> ProgramSet
    if (json['programSets'] != null) {
      // workoutSets -> programSets
      sets = (json['programSets'] as List) // workoutSets -> programSets
          .map((item) => ProgramSet.fromJson(
              item as Map<String, dynamic>)) // WorkoutSet -> ProgramSet
          .toList();
    }

    return ProgramItem(
      type: itemType,
      title: json['title'] ?? '',
      description: json['description'] as String?,
      programSets: sets, // workoutSets -> programSets
      icon: iconData,
      color: Color(json['color'] ?? 0xFF9E9E9E),
      time: json['time'],
    );
  }

  // Nesneyi JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(), // Enum'ı string olarak kaydet
      'title': title,
      'description': description, // null olabilir
      // programSets null değilse JSON'a çevir, değilse null bırak (WorkoutSet -> ProgramSet)
      'programSets': programSets?.map((set) => set.toJson()).toList(),
      'icon': icon.codePoint,
      'color': color.value,
      'time': time,
    };
  }

  // İkon kodunu sabit IconData nesnelerine eşleyen yardımcı metot
  static IconData _getIconData(int codePoint) {
    // En yaygın kullanılan ikonlar için sabit değerler
    switch (codePoint) {
      case 0xE5E5:
        return Icons.fitness_center;
      case 0xE3AD:
        return Icons.directions_run;
      case 0xE3F9:
        return Icons.restaurant;
      case 0xE566:
        return Icons.dinner_dining;
      case 0xE532:
        return Icons.water_drop;
      case 0xE5D2:
        return Icons.menu;
      case 0xE8B6:
        return Icons.home;
      case 0xE5DD:
        return Icons.settings;
      case 0xE8B8:
        return Icons.info;
      case 0xE5CA:
        return Icons.check;
      case 0xE4C1:
        return Icons.person;
      default:
        return Icons.circle; // Varsayılan ikon
    }
  }
}

class DailyProgram {
  final String dayName;
  ProgramItem morningExercise;
  ProgramItem lunch;
  ProgramItem eveningExercise;
  ProgramItem dinner;

  DailyProgram({
    required this.dayName,
    required this.morningExercise,
    required this.lunch,
    required this.eveningExercise,
    required this.dinner,
  });

  // JSON'dan nesne oluştur
  factory DailyProgram.fromJson(Map<String, dynamic> json) {
    return DailyProgram(
      dayName: json['dayName'] ?? '',
      morningExercise: ProgramItem.fromJson(json['morningExercise']),
      lunch: ProgramItem.fromJson(json['lunch']),
      eveningExercise: ProgramItem.fromJson(json['eveningExercise']),
      dinner: ProgramItem.fromJson(json['dinner']),
    );
  }

  // Nesneyi JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'dayName': dayName,
      'morningExercise': morningExercise.toJson(),
      'lunch': lunch.toJson(),
      'eveningExercise': eveningExercise.toJson(),
      'dinner': dinner.toJson(),
    };
  }
}

class WeeklyProgram {
  final List<DailyProgram> dailyPrograms;

  WeeklyProgram({
    required this.dailyPrograms,
  });

  // JSON'dan nesne oluştur
  factory WeeklyProgram.fromJson(Map<String, dynamic> json) {
    List<dynamic> dailyProgramsJson = json['dailyPrograms'];
    List<DailyProgram> programs = dailyProgramsJson
        .map((programJson) => DailyProgram.fromJson(programJson))
        .toList();

    return WeeklyProgram(dailyPrograms: programs);
  }

  // Nesneyi JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'dailyPrograms':
          dailyPrograms.map((program) => program.toJson()).toList(),
    };
  }
}
