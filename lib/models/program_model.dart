import 'package:flutter/material.dart';

class ProgramItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? time;

  ProgramItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.time,
  });

  // Kopyalama metodu
  ProgramItem copyWith({
    String? title,
    String? description,
    IconData? icon,
    Color? color,
    String? time,
  }) {
    return ProgramItem(
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      time: time ?? this.time,
    );
  }
  
  // JSON'dan nesne oluştur
  factory ProgramItem.fromJson(Map<String, dynamic> json) {
    // Varsayılan icon ve renkler - sabit değerler kullan
    final int iconCode = json['icon'] ?? 0xE5E5;
    final IconData iconData = _getIconData(iconCode);
    
    return ProgramItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: iconData,
      color: Color(json['color'] ?? 0xFF9E9E9E),
      time: json['time'],
    );
  }
  
  // Nesneyi JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'icon': icon.codePoint,
      'color': color.value,
      'time': time,
    };
  }
  
  // İkon kodunu sabit IconData nesnelerine eşleyen yardımcı metot
  static IconData _getIconData(int codePoint) {
    // En yaygın kullanılan ikonlar için sabit değerler
    switch (codePoint) {
      case 0xE5E5: return Icons.fitness_center;
      case 0xE3AD: return Icons.directions_run;
      case 0xE3F9: return Icons.restaurant;
      case 0xE566: return Icons.dinner_dining;
      case 0xE532: return Icons.water_drop;
      case 0xE5D2: return Icons.menu;
      case 0xE8B6: return Icons.home;
      case 0xE5DD: return Icons.settings;
      case 0xE8B8: return Icons.info;
      case 0xE5CA: return Icons.check;
      case 0xE4C1: return Icons.person;
      default: return Icons.circle; // Varsayılan ikon
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
      'dailyPrograms': dailyPrograms.map((program) => program.toJson()).toList(),
    };
  }
} 