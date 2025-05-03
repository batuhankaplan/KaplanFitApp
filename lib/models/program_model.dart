import 'package:flutter/material.dart';
// import 'workout_set.dart'; // Eski modeli kaldır
import 'program_set.dart'; // Yeni modeli import et

/// Program öğesinin türünü belirtir (antrenman, yemek, dinlenme vb.)
enum ProgramItemType { workout, meal, rest, other }

class ProgramItem {
  String? id; // Veritabanı ID'si (opsiyonel, sonradan atanabilir)
  final ProgramItemType type; // Öğenin türü
  String title; // final olmaktan çıkardık, düzenlenebilir
  String? description; // Yemekler veya basit notlar için
  List<ProgramSet>? programSets; // final olmaktan çıkardık
  final IconData icon;
  final Color color;
  final String? time;

  ProgramItem({
    this.id, // ID'yi constructor'a ekleyelim (opsiyonel)
    required this.type,
    required this.title,
    this.description,
    this.programSets,
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
    String? id,
    ProgramItemType? type,
    String? title,
    String? description,
    List<ProgramSet>? programSets,
    IconData? icon,
    Color? color,
    String? time,
    bool clearProgramSets = false,
    bool clearDescription = false,
  }) {
    // programSets için null kontrolü ve deep copy
    List<ProgramSet>? copiedSets;
    if (clearProgramSets) {
      copiedSets = null;
    } else if (programSets != null) {
      copiedSets =
          programSets.map((set) => set.copyWith()).toList(); // Her seti kopyala
    } else {
      copiedSets = this.programSets?.map((set) => set.copyWith()).toList();
    }

    return ProgramItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: (type == ProgramItemType.workout || clearDescription)
          ? null
          : description ?? this.description,
      programSets: copiedSets,
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

    List<ProgramSet>? sets;
    if (json['programSets'] != null && json['programSets'] is List) {
      sets = (json['programSets'] as List)
          .map((item) => ProgramSet.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ProgramItem(
      id: json['id'] as String?,
      type: itemType,
      title: json['title'] ?? '',
      description: json['description'] as String?,
      programSets: sets,
      icon: iconData,
      color: Color(json['color'] ?? 0xFF9E9E9E),
      time: json['time'],
    );
  }

  // Nesneyi JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id, // ID'yi JSON'a ekle
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
