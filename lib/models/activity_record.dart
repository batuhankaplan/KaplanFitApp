import 'task_type.dart';

class ActivityRecord {
  final int? id;
  final FitActivityType type;
  final int durationMinutes;
  final DateTime date;
  final String? notes;
  final int? taskId;

  ActivityRecord({
    this.id,
    required this.type,
    required this.durationMinutes,
    required this.date,
    this.notes,
    this.taskId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'durationMinutes': durationMinutes,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'taskId': taskId,
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
    );
  }
} 