// import '../models/exercise_model.dart'; // Kaldırıldı
import 'package:flutter/foundation.dart';

/// Bir antrenman programındaki tek bir egzersiz setini temsil eder.
@immutable
class WorkoutSet {
  final int? id;
  final int exerciseLogId;
  final int setNumber;
  final int? reps;
  final double? weight;
  final int? durationSeconds;
  final int? distanceMeters;
  final String? notes;
  final bool isCompleted;
  final DateTime createdAt;

  const WorkoutSet({
    this.id,
    required this.exerciseLogId,
    required this.setNumber,
    this.reps,
    this.weight,
    this.durationSeconds,
    this.distanceMeters,
    this.notes,
    required this.isCompleted,
    required this.createdAt,
  });

  WorkoutSet copyWith({
    int? id,
    int? exerciseLogId,
    int? setNumber,
    int? reps,
    double? weight,
    int? durationSeconds,
    int? distanceMeters,
    String? notes,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      exerciseLogId: exerciseLogId ?? this.exerciseLogId,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseLogId': exerciseLogId,
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'durationSeconds': durationSeconds,
      'distanceMeters': distanceMeters,
      'notes': notes,
      'isCompleted': isCompleted ? 1 : 0, // Convert bool to int for DB
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] as int?,
      exerciseLogId: map['exerciseLogId'] as int,
      setNumber: map['setNumber'] as int,
      reps: map['reps'] as int?,
      weight: map['weight'] as double?,
      durationSeconds: map['durationSeconds'] as int?,
      distanceMeters: map['distanceMeters'] as int?,
      notes: map['notes'] as String?,
      isCompleted:
          (map['isCompleted'] as int? ?? 0) == 1, // Convert int from DB to bool
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  @override
  String toString() {
    return 'WorkoutSet(id: $id, exerciseLogId: $exerciseLogId, setNumber: $setNumber, reps: $reps, weight: $weight, durationSeconds: $durationSeconds, distanceMeters: $distanceMeters, notes: $notes, isCompleted: $isCompleted, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkoutSet &&
        other.id == id &&
        other.exerciseLogId == exerciseLogId &&
        other.setNumber == setNumber &&
        other.reps == reps &&
        other.weight == weight &&
        other.durationSeconds == durationSeconds &&
        other.distanceMeters == distanceMeters &&
        other.notes == notes &&
        other.isCompleted == isCompleted &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        exerciseLogId.hashCode ^
        setNumber.hashCode ^
        reps.hashCode ^
        weight.hashCode ^
        durationSeconds.hashCode ^
        distanceMeters.hashCode ^
        notes.hashCode ^
        isCompleted.hashCode ^
        createdAt.hashCode;
  }
}
