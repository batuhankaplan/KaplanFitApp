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
    return ProgramItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: IconData(json['icon'] ?? 0xE5E5, fontFamily: 'MaterialIcons'),
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