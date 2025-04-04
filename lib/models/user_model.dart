class UserModel {
  final int? id;
  final String name;
  final int age;
  final double height; // cm cinsinden
  final double weight; // kg cinsinden
  final String? profileImagePath;
  final DateTime? createdAt;
  DateTime? lastWeightUpdate;
  List<WeightRecord> weightHistory;

  UserModel({
    this.id,
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    this.profileImagePath,
    this.createdAt,
    this.lastWeightUpdate,
    this.weightHistory = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
      'profileImagePath': profileImagePath,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'lastWeightUpdate': lastWeightUpdate?.millisecondsSinceEpoch,
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
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
          : null,
      lastWeightUpdate: map['lastWeightUpdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastWeightUpdate'])
          : null,
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
    DateTime? createdAt,
    DateTime? lastWeightUpdate,
    List<WeightRecord>? weightHistory,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      createdAt: createdAt ?? this.createdAt,
      lastWeightUpdate: lastWeightUpdate ?? this.lastWeightUpdate,
      weightHistory: weightHistory ?? this.weightHistory,
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