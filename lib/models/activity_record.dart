import 'task_type.dart';

class ActivityRecord {
  final int? id;
  final FitActivityType type;
  final int durationMinutes;
  final DateTime date;
  final String? notes;
  final int? taskId;
  final double? caloriesBurned;
  final int? userId;
  final bool isFromProgram;

  ActivityRecord({
    this.id,
    required this.type,
    required this.durationMinutes,
    required this.date,
    this.notes,
    this.taskId,
    this.caloriesBurned,
    this.userId,
    this.isFromProgram = false,
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
      'userId': userId,
      'isFromProgram': isFromProgram ? 1 : 0,
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
      userId: map['userId'],
      isFromProgram: map['isFromProgram'] == 1,
    );
  }

  ActivityRecord copyWith({
    int? id,
    FitActivityType? type,
    int? durationMinutes,
    DateTime? date,
    String? notes,
    int? taskId,
    double? caloriesBurned,
    int? userId,
    bool? isFromProgram,
  }) {
    return ActivityRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      taskId: taskId ?? this.taskId,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      userId: userId ?? this.userId,
      isFromProgram: isFromProgram ?? this.isFromProgram,
    );
  }
}
