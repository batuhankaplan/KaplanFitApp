import 'task_type.dart';

class MealRecord {
  final int? id;
  final FitMealType type;
  final List<String> foods;
  final DateTime date;
  final int? calories;
  final int? taskId;
  final String? notes;

  MealRecord({
    this.id,
    required this.type,
    required this.foods,
    required this.date,
    this.calories,
    this.taskId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'foods': foods.join(','),
      'date': date.millisecondsSinceEpoch,
      'calories': calories,
      'taskId': taskId,
      'notes': notes,
    };
  }

  factory MealRecord.fromMap(Map<String, dynamic> map) {
    return MealRecord(
      id: map['id'],
      type: FitMealType.values[map['type']],
      foods: map['foods'].split(','),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      calories: map['calories'],
      taskId: map['taskId'],
      notes: map['notes'],
    );
  }
} 