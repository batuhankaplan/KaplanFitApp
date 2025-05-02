import 'task_type.dart';

class MealRecord {
  final int? id;
  final FitMealType type;
  final List<String> foods;
  final DateTime date;
  final int? calories;
  final int? taskId;
  final String? notes;
  final double? proteinGrams;
  final double? carbsGrams;
  final double? fatGrams;

  MealRecord({
    this.id,
    required this.type,
    required this.foods,
    required this.date,
    this.calories,
    this.taskId,
    this.notes,
    this.proteinGrams,
    this.carbsGrams,
    this.fatGrams,
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
      'proteinGrams': proteinGrams,
      'carbsGrams': carbsGrams,
      'fatGrams': fatGrams,
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
      proteinGrams: map['proteinGrams'],
      carbsGrams: map['carbsGrams'],
      fatGrams: map['fatGrams'],
    );
  }

  MealRecord copyWith({
    int? id,
    FitMealType? type,
    List<String>? foods,
    DateTime? date,
    int? calories,
    int? taskId,
    String? notes,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
  }) {
    return MealRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      foods: foods ?? this.foods,
      date: date ?? this.date,
      calories: calories ?? this.calories,
      taskId: taskId ?? this.taskId,
      notes: notes ?? this.notes,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
    );
  }
}
