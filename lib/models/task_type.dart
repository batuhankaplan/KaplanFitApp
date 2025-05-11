// import 'package:flutter/foundation.dart' kaldırıldı

// Görev türleri
enum TaskType {
  morningExercise,
  lunch,
  eveningExercise,
  dinner,
  other,
}

// Aktivite türleri
enum FitActivityType {
  walking,
  running,
  swimming,
  weightTraining,
  cycling,
  yoga,
  other;

  String get displayName {
    switch (this) {
      case FitActivityType.walking:
        return 'Yürüyüş';
      case FitActivityType.running:
        return 'Koşu';
      case FitActivityType.swimming:
        return 'Yüzme';
      case FitActivityType.weightTraining:
        return 'Ağırlık Antrenmanı';
      case FitActivityType.cycling:
        return 'Bisiklet';
      case FitActivityType.yoga:
        return 'Yoga';
      case FitActivityType.other:
        return 'Diğer Aktivite';
      default:
        return 'Bilinmeyen Aktivite';
    }
  }
}

// Öğün türleri
enum FitMealType {
  breakfast,
  lunch,
  dinner,
  snack,
  other;

  String get displayName {
    switch (this) {
      case FitMealType.breakfast:
        return 'Kahvaltı';
      case FitMealType.lunch:
        return 'Öğle Yemeği';
      case FitMealType.dinner:
        return 'Akşam Yemeği';
      case FitMealType.snack:
        return 'Ara Öğün';
      case FitMealType.other:
        return 'Diğer Öğün';
      default:
        return 'Bilinmeyen Öğün';
    }
  }
}
