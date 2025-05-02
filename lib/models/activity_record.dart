import 'task_type.dart';

class ActivityRecord {
  final int? id;
  final FitActivityType type;
  final int durationMinutes;
  final DateTime date;
  final String? notes;
  final int? taskId;
  final double? caloriesBurned;

  ActivityRecord({
    this.id,
    required this.type,
    required this.durationMinutes,
    required this.date,
    this.notes,
    this.taskId,
    this.caloriesBurned,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'durationMinutes': durationMinutes,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'taskId': taskId,
      'caloriesBurned': caloriesBurned,
    };
  }

  factory ActivityRecord.fromMap(Map<String, dynamic> map) {
    return ActivityRecord(
      id: map['id'],
      type: FitActivityType.values[map['type']],
      durationMinutes: map['durationMinutes'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      notes: map['notes'],
      taskId: map['taskId'],
      caloriesBurned: map['caloriesBurned'],
    );
  }
}
