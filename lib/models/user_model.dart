class UserModel {
  final int? id;
  final String name;
  final int age;
  final double height; // cm cinsinden
  final double weight; // kg cinsinden
  final String? profileImagePath;
  final String? email; // E-posta adresi
  final String? phoneNumber; // Telefon numarası
  final String? gender; // YENİ: Cinsiyet ('Erkek' veya 'Kadın')
  final DateTime? createdAt;
  DateTime? lastWeightUpdate;
  List<WeightRecord> weightHistory;

  // Beslenme Hedefleri
  final double? targetCalories;
  final double? targetProtein;
  final double? targetCarbs;
  final double? targetFat;
  final double? targetWeight; // Yeni: Hedef Kilo
  final double?
      weeklyWeightGoal; // Yeni: Haftalık Kilo Hedefi (örn. -0.5, 0.5 kg)
  final String? activityLevel; // Yeni: Aktivite Seviyesi (örn. 'Az Aktif')
  final double? targetWaterIntake; // Yeni: Günlük Su Hedefi (Litre)
  final double? weeklyActivityGoal; // Yeni: Haftalık Aktivite Hedefi (Dakika)
  final bool autoCalculateNutrition; // YENİ: Otomatik hesaplama durumu

  UserModel({
    this.id,
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    this.profileImagePath,
    this.email,
    this.phoneNumber,
    this.gender, // YENİ
    this.createdAt,
    this.lastWeightUpdate,
    this.weightHistory = const [],
    this.targetCalories,
    this.targetProtein,
    this.targetCarbs,
    this.targetFat,
    this.targetWeight,
    this.weeklyWeightGoal, // Yeni
    this.activityLevel, // Yeni
    this.targetWaterIntake, // Yeni
    this.weeklyActivityGoal, // Yeni: Haftalık aktivite hedefi
    this.autoCalculateNutrition = false, // YENİ: Varsayılan değer false
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
      'profileImagePath': profileImagePath,
      'email': email,
      'phoneNumber': phoneNumber,
      'gender': gender, // YENİ
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'lastWeightUpdate': lastWeightUpdate?.millisecondsSinceEpoch,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbs': targetCarbs,
      'targetFat': targetFat,
      'targetWeight': targetWeight,
      'weeklyWeightGoal': weeklyWeightGoal, // Yeni
      'activityLevel': activityLevel, // Yeni
      'targetWaterIntake': targetWaterIntake, // Yeni
      'weeklyActivityGoal':
          weeklyActivityGoal, // Yeni: Haftalık aktivite hedefi
      'autoCalculateNutrition':
          autoCalculateNutrition ? 1 : 0, // YENİ: Integer olarak kaydet
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      height: map['height'],
      weight: map['weight'],
      profileImagePath: map['profileImagePath'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      gender: map['gender'], // YENİ
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      lastWeightUpdate: map['lastWeightUpdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastWeightUpdate'])
          : null,
      targetCalories: map['targetCalories'],
      targetProtein: map['targetProtein'],
      targetCarbs: map['targetCarbs'],
      targetFat: map['targetFat'],
      targetWeight: map['targetWeight'],
      weeklyWeightGoal: map['weeklyWeightGoal'], // Yeni
      activityLevel: map['activityLevel'], // Yeni
      targetWaterIntake: map['targetWaterIntake'], // Yeni
      weeklyActivityGoal:
          map['weeklyActivityGoal'], // Yeni: Haftalık aktivite hedefi
      autoCalculateNutrition:
          map['autoCalculateNutrition'] == 1, // YENİ: Integer'dan bool'a çevir
    );
  }

  double get bmi {
    return weight / ((height / 100) * (height / 100));
  }

  String get bmiCategory {
    double bmiValue = bmi;
    if (bmiValue < 18.5) {
      return "Zayıf";
    } else if (bmiValue < 25) {
      return "Normal";
    } else if (bmiValue < 30) {
      return "Fazla Kilolu";
    } else if (bmiValue < 35) {
      return "Obez (Sınıf I)";
    } else if (bmiValue < 40) {
      return "Obez (Sınıf II)";
    } else {
      return "Aşırı Obez (Sınıf III)";
    }
  }

  UserModel copyWith({
    int? id,
    String? name,
    int? age,
    double? height,
    double? weight,
    String? profileImagePath,
    String? email,
    String? phoneNumber,
    String? gender, // YENİ
    DateTime? createdAt,
    DateTime? lastWeightUpdate,
    List<WeightRecord>? weightHistory,
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    double? targetWeight,
    double? weeklyWeightGoal,
    String? activityLevel,
    double? targetWaterIntake,
    double? weeklyActivityGoal,
    bool? autoCalculateNutrition, // YENİ
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender, // YENİ
      createdAt: createdAt ?? this.createdAt,
      lastWeightUpdate: lastWeightUpdate ?? this.lastWeightUpdate,
      weightHistory: weightHistory ?? this.weightHistory,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      targetWeight: targetWeight ?? this.targetWeight,
      weeklyWeightGoal: weeklyWeightGoal ?? this.weeklyWeightGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      targetWaterIntake: targetWaterIntake ?? this.targetWaterIntake,
      weeklyActivityGoal: weeklyActivityGoal ?? this.weeklyActivityGoal,
      autoCalculateNutrition:
          autoCalculateNutrition ?? this.autoCalculateNutrition, // YENİ
    );
  }
}

class WeightRecord {
  final int? id;
  final double weight;
  final DateTime date;

  WeightRecord({
    this.id,
    required this.weight,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight': weight,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      id: map['id'],
      weight: map['weight'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }
}
