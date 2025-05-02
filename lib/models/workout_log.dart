import 'package:flutter/foundation.dart';
import './exercise_log.dart'; // To hold the list of exercise logs

@immutable
class WorkoutLog {
  final int? id;
  final DateTime date;
  final int? durationMinutes;
  final String? notes;
  final int? rating;
  final String? feeling;
  final List<ExerciseLog> exerciseLogs; // Populated after fetching from DB
  final int? taskId;
  final DateTime createdAt;

  const WorkoutLog({
    this.id,
    required this.date,
    this.durationMinutes,
    this.notes,
    this.rating,
    this.feeling,
    this.exerciseLogs = const [], // Default to empty list
    this.taskId,
    required this.createdAt,
  });

  WorkoutLog copyWith({
    int? id,
    DateTime? date,
    int? durationMinutes,
    String? notes,
    int? rating,
    String? feeling,
    List<ExerciseLog>? exerciseLogs,
    int? taskId,
    DateTime? createdAt,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      feeling: feeling ?? this.feeling,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      taskId: taskId ?? this.taskId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Note: `toMap` does not include `exerciseLogs`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'notes': notes,
      'rating': rating,
      'feeling': feeling,
      'taskId': taskId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Note: `fromMap` does not populate `exerciseLogs`.
  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    return WorkoutLog(
      id: map['id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      durationMinutes: map['durationMinutes'] as int?,
      notes: map['notes'] as String?,
      rating: map['rating'] as int?,
      feeling: map['feeling'] as String?,
      taskId: map['taskId'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      // exerciseLogs is initially empty
    );
  }

  @override
  String toString() {
    return 'WorkoutLog(id: $id, date: $date, durationMinutes: $durationMinutes, notes: $notes, rating: $rating, feeling: $feeling, exerciseLogs: ${exerciseLogs.length} exercises, taskId: $taskId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkoutLog &&
        other.id == id &&
        other.date == date &&
        other.durationMinutes == durationMinutes &&
        other.notes == notes &&
        other.rating == rating &&
        other.feeling == feeling &&
        listEquals(other.exerciseLogs, exerciseLogs) &&
        other.taskId == taskId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        durationMinutes.hashCode ^
        notes.hashCode ^
        rating.hashCode ^
        feeling.hashCode ^
        exerciseLogs.hashCode ^
        taskId.hashCode ^
        createdAt.hashCode;
  }
}
