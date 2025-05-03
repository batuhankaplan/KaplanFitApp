import 'package:cloud_firestore/cloud_firestore.dart';

/// Egzersiz verilerini temsil eden model sınıfı.
class Exercise {
  final String? id; // Firestore Document ID
  final String name; // Egzersiz adı (örn: Bench Press)
  final String description; // Egzersiz açıklaması veya nasıl yapıldığı
  final String
      targetMuscleGroup; // Hedeflenen kas grubu (örn: Göğüs, Sırt, Bacak)
  final String?
      equipment; // Gerekli ekipman (örn: Dumbbell, Barbell, Makine, Vücut Ağırlığı)
  final String? videoUrl; // Opsiyonel: Egzersizin videosunu gösteren URL
  final String? imageUrl; // Opsiyonel: Egzersizin görselini gösteren URL
  final Timestamp? createdAt; // Oluşturulma tarihi (Firestore Timestamp)

  // Yeni varsayılan değerler
  final String? defaultSets; // Varsayılan set sayısı
  final String? defaultReps; // Varsayılan tekrar sayısı
  final String? defaultRestTime; // Varsayılan dinlenme süresi

  Exercise({
    this.id,
    required this.name,
    this.description = '',
    required this.targetMuscleGroup,
    this.equipment,
    this.videoUrl,
    this.imageUrl,
    this.createdAt,
    this.defaultSets,
    this.defaultReps,
    this.defaultRestTime,
  });

  // Firestore'a yazmak için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'targetMuscleGroup': targetMuscleGroup,
      'equipment': equipment,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      'defaultRestTime': defaultRestTime,
    };
  }

  // Firestore'dan okurken DocumentSnapshot'tan Exercise nesnesine dönüştürme
  factory Exercise.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("Egzersiz verisi bulunamadı veya formatı bozuk!");
    }

    return Exercise(
      id: snapshot.id,
      name: data['name'] as String? ?? 'İsimsiz Egzersiz',
      description: data['description'] as String? ?? '',
      targetMuscleGroup: data['targetMuscleGroup'] as String? ?? 'Bilinmiyor',
      equipment: data['equipment'] as String?,
      videoUrl: data['videoUrl'] as String?,
      imageUrl: data['imageUrl'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      defaultSets: data['defaultSets'] as String?,
      defaultReps: data['defaultReps'] as String?,
      defaultRestTime: data['defaultRestTime'] as String?,
    );
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    String? targetMuscleGroup,
    String? equipment,
    String? videoUrl,
    String? imageUrl,
    Timestamp? createdAt,
    String? defaultSets,
    String? defaultReps,
    String? defaultRestTime,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetMuscleGroup: targetMuscleGroup ?? this.targetMuscleGroup,
      equipment: equipment ?? this.equipment,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultRestTime: defaultRestTime ?? this.defaultRestTime,
    );
  }
}
