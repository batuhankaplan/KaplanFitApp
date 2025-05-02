import 'package:flutter/foundation.dart';
import './exercise_model.dart'; // To reference Exercise
import './workout_set.dart'; // To hold the list of sets

@immutable
class ExerciseLog {
  final int? id;
  final int workoutLogId;
  final String? exerciseId;
  final int sortOrder;
  final String? notes;
  final List<WorkoutSet>? sets; // This will be populated after fetching from DB
  final DateTime createdAt;
  final Exercise? exerciseDetails; // Optional: populated for UI

  const ExerciseLog({
    this.id,
    required this.workoutLogId,
    required this.exerciseId,
    required this.sortOrder,
    this.notes,
    this.sets,
    required this.createdAt,
    this.exerciseDetails,
  });

  ExerciseLog copyWith({
    int? id,
    int? workoutLogId,
    String? exerciseId,
    int? sortOrder,
    String? notes,
    List<WorkoutSet>? sets,
    DateTime? createdAt,
    Exercise? exerciseDetails,
    bool clearSets = false,
    bool clearExerciseDetails = false,
  }) {
    return ExerciseLog(
      id: id ?? this.id,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      exerciseId: exerciseId ?? this.exerciseId,
      sortOrder: sortOrder ?? this.sortOrder,
      notes: notes ?? this.notes,
      sets: clearSets ? null : (sets ?? this.sets),
      createdAt: createdAt ?? this.createdAt,
      exerciseDetails: clearExerciseDetails
          ? null
          : (exerciseDetails ?? this.exerciseDetails),
    );
  }

  // Note: `toMap` will not include `sets` or `exerciseDetails` as they are stored/
  // referenced separately in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutLogId': workoutLogId,
      'exerciseId': exerciseId,
      'sortOrder': sortOrder,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Note: `fromMap` does not populate `sets` or `exerciseDetails` directly.
  // These need to be fetched separately and added to the model object.
  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      id: map['id'] as int?,
      workoutLogId: map['workoutLogId'] as int,
      exerciseId: map['exerciseId'] as String?,
      sortOrder: map['sortOrder'] as int,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      // sets and exerciseDetails are initially null/empty
    );
  }

  @override
  String toString() {
    return 'ExerciseLog(id: $id, workoutLogId: $workoutLogId, exerciseId: $exerciseId, sortOrder: $sortOrder, notes: $notes, sets: ${sets?.length ?? 0}, createdAt: $createdAt, exerciseDetails: ${exerciseDetails?.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExerciseLog &&
        other.id == id &&
        other.workoutLogId == workoutLogId &&
        other.exerciseId == exerciseId &&
        other.sortOrder == sortOrder &&
        other.notes == notes &&
        listEquals(other.sets, sets) &&
        other.createdAt == createdAt &&
        other.exerciseDetails ==
            exerciseDetails; // Also compare details if loaded
  }

  @override
  int get hashCode {
    return id.hashCode ^
        workoutLogId.hashCode ^
        exerciseId.hashCode ^
        sortOrder.hashCode ^
        notes.hashCode ^
        sets.hashCode ^ // Use list hashcode
        createdAt.hashCode ^
        exerciseDetails.hashCode;
  }
}
