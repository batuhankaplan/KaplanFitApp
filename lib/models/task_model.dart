import 'package:intl/intl.dart';
import 'task_type.dart';

class DailyTask {
  final int? id;
  final String title;
  final String description;
  final DateTime date;
  final bool isCompleted;
  final TaskType type;
  // Tahmini besin değerleri
  final double? estimatedCalories;
  final double? estimatedProtein;
  final double? estimatedCarbs;
  final double? estimatedFat;

  DailyTask({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.isCompleted = false,
    required this.type,
    this.estimatedCalories,
    this.estimatedProtein,
    this.estimatedCarbs,
    this.estimatedFat,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
      'type': type.index,
      'estimatedCalories': estimatedCalories,
      'estimatedProtein': estimatedProtein,
      'estimatedCarbs': estimatedCarbs,
      'estimatedFat': estimatedFat,
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      isCompleted: map['isCompleted'] == 1,
      type: TaskType.values[map['type']],
      estimatedCalories: map['estimatedCalories'],
      estimatedProtein: map['estimatedProtein'],
      estimatedCarbs: map['estimatedCarbs'],
      estimatedFat: map['estimatedFat'],
    );
  }

  DailyTask copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? date,
    bool? isCompleted,
    TaskType? type,
    double? estimatedCalories,
    double? estimatedProtein,
    double? estimatedCarbs,
    double? estimatedFat,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      estimatedProtein: estimatedProtein ?? this.estimatedProtein,
      estimatedCarbs: estimatedCarbs ?? this.estimatedCarbs,
      estimatedFat: estimatedFat ?? this.estimatedFat,
    );
  }

  String get formattedDate => DateFormat('dd/MM/yyyy').format(date);
}

// Define a type alias for easier reference
typedef Task = DailyTask;
