import 'package:flutter/foundation.dart';
import 'exercise_model.dart'; // Exercise detayları için

@immutable
class ProgramSet {
  final String? exerciseId;
  final int order; // Program içindeki sıra
  final String? setsDescription; // Örn: "4"
  final String? repsDescription; // Örn: "12-10-8-8" veya "30 sn"
  final String? restTimeDescription; // Örn: "60 sn"
  final String? notes;
  final Exercise? exerciseDetails; // Populate edilecek egzersiz bilgisi

  ProgramSet({
    required this.exerciseId,
    required this.order,
    this.setsDescription,
    this.repsDescription,
    this.restTimeDescription,
    this.notes,
    this.exerciseDetails,
  });

  ProgramSet copyWith({
    String? exerciseId,
    int? order,
    String? setsDescription,
    String? repsDescription,
    ValueGetter<String?>?
        restTimeDescription, // nullable yapmak için ValueGetter
    ValueGetter<String?>? notes, // nullable yapmak için ValueGetter
    ValueGetter<Exercise?>? exerciseDetails, // nullable yapmak için ValueGetter
  }) {
    return ProgramSet(
      exerciseId: exerciseId ?? this.exerciseId,
      order: order ?? this.order,
      setsDescription: setsDescription ?? this.setsDescription,
      repsDescription: repsDescription ?? this.repsDescription,
      restTimeDescription: restTimeDescription != null
          ? restTimeDescription()
          : this.restTimeDescription,
      notes: notes != null ? notes() : this.notes,
      exerciseDetails:
          exerciseDetails != null ? exerciseDetails() : this.exerciseDetails,
    );
  }

  // JSON'dan nesne oluştur
  factory ProgramSet.fromJson(Map<String, dynamic> json) {
    // exerciseDetails JSON'dan yüklenmez, sonradan populate edilir.
    return ProgramSet(
      exerciseId: json['exerciseId'] as String?,
      order: json['order'] as int? ?? 0,
      setsDescription: json['setsDescription'] as String?,
      repsDescription: json['repsDescription'] as String?,
      restTimeDescription: json['restTimeDescription'] as String?,
      notes: json['notes'] as String?,
    );
  }

  // Nesneyi JSON'a dönüştür
  Map<String, dynamic> toJson() {
    // exerciseDetails JSON'a kaydedilmez.
    return {
      'exerciseId': exerciseId,
      'order': order,
      'setsDescription': setsDescription,
      'repsDescription': repsDescription,
      'restTimeDescription': restTimeDescription,
      'notes': notes,
    };
  }
}
