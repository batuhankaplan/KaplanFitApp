import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore importu
import '../models/exercise_model.dart';
// import '../services/database_service.dart'; // Artık DatabaseService'e doğrudan bağımlılık yok
import 'package:flutter/foundation.dart'; // debugPrint için
// import 'package:sqflite/sqflite.dart'; // SQLite kaldırıldı

class ExerciseService {
  // SQLite _db kaldırıldı
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance
  final String _collectionPath = 'exercises'; // Firestore koleksiyon adı

  // Constructor güncellendi - artık parametre almıyor
  ExerciseService() {
    // initialize metodu belki dışarıdan çağrılmalı veya otomatik tetiklenmeli
    _addDefaultExercisesIfNeeded(); // Uygulama başlarken kontrol et
  }

  // Varsayılan egzersiz listesi (aynı kalabilir)
  final List<Exercise> _defaultExercises = [
    // Örnek egzersizler... (createdAt: DateTime.now() yerine null bırakılabilir, toMap halleder)
    // GÖĞÜS
    Exercise(
        name: 'Incline Bench Press',
        targetMuscleGroup: 'Göğüs',
        equipment: 'Barbell/Dumbbell'),
    Exercise(
        name: 'Dumbbell Bench Press',
        targetMuscleGroup: 'Göğüs',
        equipment: 'Dumbbell'),
    Exercise(
        name: 'Cable Crossover',
        targetMuscleGroup: 'Göğüs',
        equipment: 'Kablo Makinesi'),
    Exercise(
        name: 'Dumbbell Hex Press',
        targetMuscleGroup: 'Göğüs',
        equipment: 'Dumbbell'),
    // ARKA KOL
    Exercise(
        name: 'Cable Triceps Extension',
        targetMuscleGroup: 'Arka Kol',
        equipment: 'Kablo Makinesi'),
    Exercise(
        name: 'Cable Overhead Triceps Extension',
        targetMuscleGroup: 'Arka Kol',
        equipment: 'Kablo Makinesi'),
    // SIRT
    Exercise(
        name: 'Lat Pulldown', targetMuscleGroup: 'Sırt', equipment: 'Makine'),
    Exercise(
        name: 'Cable Seated Row',
        targetMuscleGroup: 'Sırt',
        equipment: 'Kablo Makinesi'),
    Exercise(
        name: 'Tek Kol Dumbbell Row',
        targetMuscleGroup: 'Sırt',
        equipment: 'Dumbbell'),
    Exercise(
        name: 'Cable Straight-Arm Pulldown',
        targetMuscleGroup: 'Sırt',
        equipment: 'Kablo Makinesi'),
    // ÖN KOL
    Exercise(
        name: 'Dumbbell Alternate Curl',
        targetMuscleGroup: 'Ön Kol',
        equipment: 'Dumbbell'),
    Exercise(
        name: 'Cable Hammer Curl',
        targetMuscleGroup: 'Ön Kol',
        equipment: 'Kablo Makinesi'),
    // OMUZ
    Exercise(
        name: 'Dumbbell Shoulder Press',
        targetMuscleGroup: 'Omuz',
        equipment: 'Dumbbell'),
    Exercise(
        name: 'Dumbbell Lateral Raise',
        targetMuscleGroup: 'Omuz',
        equipment: 'Dumbbell'),
    Exercise(
        name: 'Facepull',
        targetMuscleGroup: 'Omuz',
        equipment: 'Kablo Makinesi'),
    // BACAK
    Exercise(
        name: 'Leg Extension', targetMuscleGroup: 'Bacak', equipment: 'Makine'),
    Exercise(name: 'Leg Curl', targetMuscleGroup: 'Bacak', equipment: 'Makine'),
    Exercise(
        name: 'Thigh Abduction/Adduction',
        targetMuscleGroup: 'Bacak',
        equipment: 'Makine'),
    Exercise(
        name: 'Seated Calf Raise',
        targetMuscleGroup: 'Bacak',
        equipment: 'Makine/Dumbbell'),
    // KARIN
    Exercise(
        name: 'Plank', targetMuscleGroup: 'Karın', equipment: 'Vücut Ağırlığı'),
    Exercise(
        name: 'Leg Raises',
        targetMuscleGroup: 'Karın',
        equipment: 'Vücut Ağırlığı'),
    Exercise(
        name: 'Crunch',
        targetMuscleGroup: 'Karın',
        equipment: 'Vücut Ağırlığı'),
    // BEL SAĞLIĞI
    Exercise(
        name: 'Pelvic Tilt',
        targetMuscleGroup: 'Bel Sağlığı',
        equipment: 'Vücut Ağırlığı'),
    Exercise(
        name: 'Cat-Camel',
        targetMuscleGroup: 'Bel Sağlığı',
        equipment: 'Vücut Ağırlığı'),
    Exercise(
        name: 'Bird-Dog',
        targetMuscleGroup: 'Bel Sağlığı',
        equipment: 'Vücut Ağırlığı'),
    // DİĞER / KARDİYO
    Exercise(
        name: 'Yürüyüş',
        targetMuscleGroup: 'Kardiyo',
        equipment: 'Vücut Ağırlığı'),
    Exercise(name: 'Yüzme', targetMuscleGroup: 'Tüm Vücut', equipment: 'Havuz'),
    Exercise(
        name: 'Esneme',
        targetMuscleGroup: 'Esneklik',
        equipment: 'Vücut Ağırlığı'),
  ];

  /// Servisi başlatır ve varsayılan egzersizleri ekler (eğer yoksa).
  // initialize metodu kaldırıldı, constructor içinde kontrol ediliyor.
  // Future<void> initialize() async { ... }

  /// Varsayılan egzersizleri Firestore'a ekler (eğer koleksiyon boşsa).
  Future<void> _addDefaultExercisesIfNeeded() async {
    try {
      debugPrint("🔥 Firebase exercises koleksiyonu kontrol ediliyor...");

      // İlk önce Firebase bağlantısını test et
      await _testFirebaseConnection();

      // Koleksiyon boş mu diye kontrol et
      final snapshot =
          await _firestore.collection(_collectionPath).limit(1).get();
      if (snapshot.docs.isEmpty) {
        debugPrint(
            "'$_collectionPath' koleksiyonu boş, varsayılan egzersizler ekleniyor...");
        final batch = _firestore.batch();
        int count = 0;
        for (final exercise in _defaultExercises) {
          // Otomatik ID ile ekle
          final docRef = _firestore.collection(_collectionPath).doc();
          // Exercise modelinin toMap metodu kullanılacak
          batch.set(docRef, exercise.toMap()); // toMapForFirestore -> toMap
          count++;
        }
        await batch.commit();
        debugPrint('$count adet varsayılan egzersiz Firestore\'a eklendi.');
      } else {
        debugPrint(
            "'$_collectionPath' koleksiyonu zaten ${snapshot.docs.length} egzersiz içeriyor.");
      }
    } catch (e) {
      debugPrint("❌ Varsayılan egzersizler eklenirken hata: $e");
      debugPrint("   - Hata türü: ${e.runtimeType}");
      if (e.toString().contains('permission-denied')) {
        debugPrint(
            "🚫 Firebase izin hatası! Firestore kuralları kontrol edilmeli.");
        debugPrint(
            "   Geçici çözüm: Offline modda varsayılan egzersizler kullanılacak.");
      }
      debugPrint("Stack trace: ${StackTrace.current}");
    }
  }

  /// Firebase bağlantısını test eder
  Future<void> _testFirebaseConnection() async {
    try {
      debugPrint("🧪 Firebase bağlantısı test ediliyor...");
      await _firestore.enableNetwork();
      debugPrint("✅ Firebase network bağlantısı aktif");
    } catch (e) {
      debugPrint("❌ Firebase bağlantı testi başarısız: $e");
      throw e;
    }
  }

  /// Offline modda varsayılan egzersizleri filtreli şekilde döndürür
  List<Exercise> _getDefaultExercisesAsOffline({
    String? query,
    String? targetMuscleGroup,
    String? equipment,
    int? limit,
  }) {
    debugPrint("📱 Offline modda egzersizler filtreleniyor...");

    List<Exercise> filteredExercises = List.from(_defaultExercises);

    // Query filtresi
    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      filteredExercises = filteredExercises
          .where((exercise) =>
              exercise.name.toLowerCase().contains(lowercaseQuery))
          .toList();
    }

    // Kas grubu filtresi
    if (targetMuscleGroup != null && targetMuscleGroup.isNotEmpty) {
      filteredExercises = filteredExercises
          .where((exercise) => exercise.targetMuscleGroup == targetMuscleGroup)
          .toList();
    }

    // Ekipman filtresi
    if (equipment != null && equipment.isNotEmpty) {
      filteredExercises = filteredExercises
          .where((exercise) => exercise.equipment == equipment)
          .toList();
    }

    // Sıralama
    filteredExercises.sort((a, b) => a.name.compareTo(b.name));

    // Limit uygula
    if (limit != null && filteredExercises.length > limit) {
      filteredExercises = filteredExercises.take(limit).toList();
    }

    debugPrint(
        "📱 Offline modda ${filteredExercises.length} egzersiz döndürülüyor");
    return filteredExercises;
  }

  /// Offline modda varsayılan egzersizlerden ID'lere göre eşleştirme yapar
  List<Exercise> _getDefaultExercisesByIdsOffline(List<String> exerciseIds) {
    debugPrint("📱 Offline modda ID eşleştirmesi: ${exerciseIds.length} ID");

    // Demo amaçlı: ID'lere göre varsayılan egzersizlerden döndür
    // Gerçek uygulamada, ID mapping'i farklı olabilir
    List<Exercise> foundExercises = [];

    for (String id in exerciseIds) {
      // ID'nin hash'ine göre default exercise'lardan birini seç
      final index = id.hashCode.abs() % _defaultExercises.length;
      final exercise = _defaultExercises[index];

      // ID'yi setle (demo amaçlı)
      final exerciseWithId = Exercise(
        id: id,
        name: exercise.name,
        targetMuscleGroup: exercise.targetMuscleGroup,
        description: exercise.description,
        equipment: exercise.equipment,
        videoUrl: exercise.videoUrl,
        metValue: exercise.metValue,
        fixedCaloriesPerActivity: exercise.fixedCaloriesPerActivity,
        createdAt: exercise.createdAt,
      );

      foundExercises.add(exerciseWithId);
    }

    debugPrint(
        "📱 Offline modda ${foundExercises.length} egzersiz ID ile eşleştirildi");
    return foundExercises;
  }

  /// Filtrelenmiş egzersiz listesini Firestore'dan getirir.
  Future<List<Exercise>> getExercises({
    String? query,
    String? targetMuscleGroup,
    String? equipment,
    int? limit,
  }) async {
    try {
      debugPrint("📋 ExerciseService.getExercises çağrıldı");
      debugPrint("   - query: $query");
      debugPrint("   - targetMuscleGroup: $targetMuscleGroup");
      debugPrint("   - equipment: $equipment");
      debugPrint("   - limit: $limit");

      Query collectionRef = _firestore.collection(_collectionPath);
      debugPrint("🔥 Firebase koleksiyonu: $_collectionPath");

      // Filtreleme koşulları
      if (query != null && query.isNotEmpty) {
        debugPrint("🔍 Query ile arama yapılıyor: $query");
        // Name alanına göre basit arama yapalım
        // Firebase'de tam metin araması yerine basit bir filtreleme kullanıyoruz
        final lowercaseQuery = query.toLowerCase();

        // Doğrudan tüm belgeleri çekelim ve client tarafında filtreleme yapalım
        final snapshot = await collectionRef.get();
        debugPrint("📊 Toplam belge sayısı: ${snapshot.docs.length}");

        final allExercises =
            snapshot.docs.map((doc) => Exercise.fromSnapshot(doc)).toList();
        debugPrint(
            "✅ Exercise nesnelerine dönüştürüldü: ${allExercises.length} adet");

        // İsme göre client-side filtreleme
        final filteredExercises = allExercises
            .where((exercise) =>
                exercise.name.toLowerCase().contains(lowercaseQuery))
            .toList();
        debugPrint("🎯 Filtrelenmiş sonuç: ${filteredExercises.length} adet");
        return filteredExercises;
      }

      // Diğer filtrelemelere devam
      if (targetMuscleGroup != null && targetMuscleGroup.isNotEmpty) {
        debugPrint("💪 Kas grubuna göre filtreleme: $targetMuscleGroup");
        collectionRef = collectionRef.where('targetMuscleGroup',
            isEqualTo: targetMuscleGroup);
      }
      if (equipment != null && equipment.isNotEmpty) {
        collectionRef = collectionRef.where('equipment', isEqualTo: equipment);
      }

      // Sıralama ve Limit
      collectionRef = collectionRef.orderBy('name');
      if (limit != null) {
        collectionRef = collectionRef.limit(limit);
      }

      final snapshot = await collectionRef.get();
      final exercises =
          snapshot.docs.map((doc) => Exercise.fromSnapshot(doc)).toList();
      debugPrint("✅ ${exercises.length} adet egzersiz getirildi");
      return exercises;
    } catch (e) {
      debugPrint("❌ Firestore'dan egzersizler alınırken hata: $e");
      if (e.toString().contains('permission-denied')) {
        debugPrint(
            "🔄 Firebase izin sorunu - Offline modda varsayılan egzersizler döndürülüyor");
        return _getDefaultExercisesAsOffline(
            query: query,
            targetMuscleGroup: targetMuscleGroup,
            equipment: equipment,
            limit: limit);
      }
      debugPrint("Stack trace: ${StackTrace.current}");
      return [];
    }
  }

  /// Yeni özel bir egzersiz Firestore'a ekler.
  Future<String?> addCustomExercise(Exercise exercise) async {
    try {
      // copyWith'den isCustom ve createdAt kaldırıldı
      // final customExercise = exercise.copyWith(); // Gerekli değil, doğrudan exercise kullanılabilir

      // toMapForFirestore -> toMap
      DocumentReference docRef =
          await _firestore.collection(_collectionPath).add(exercise.toMap());
      debugPrint("Özel egzersiz eklendi: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      debugPrint("Özel egzersiz eklenirken hata: $e");
      return null;
    }
  }

  /// Bir egzersizi Firestore'da günceller.
  Future<bool> updateExercise(Exercise exercise) async {
    if (exercise.id == null) {
      debugPrint("Güncellenecek egzersizin ID'si yok.");
      return false;
    }
    try {
      // toMapForFirestore -> toMap
      await _firestore
          .collection(_collectionPath)
          .doc(exercise.id)
          .update(exercise.toMap());
      debugPrint("Egzersiz güncellendi: ${exercise.id}");
      return true;
    } catch (e) {
      debugPrint("Egzersiz güncellenirken hata (${exercise.id}): $e");
      return false;
    }
  }

  /// Bir egzersizi ID ile Firestore'dan getirir.
  Future<Exercise?> getExerciseById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionPath).doc(id).get();
      if (doc.exists) {
        return Exercise.fromSnapshot(doc);
      } else {
        debugPrint("Egzersiz bulunamadı: $id");
        return null;
      }
    } catch (e) {
      debugPrint("ID ile egzersiz alınırken hata ($id): $e");
      return null;
    }
  }

  // Egzersiz silme (Gerekirse eklenebilir)
  Future<bool> deleteExercise(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
      debugPrint("Egzersiz silindi: $id");
      return true;
    } catch (e) {
      debugPrint("Egzersiz silinirken hata ($id): $e");
      return false;
    }
  }

  /// Belirli ID'lere sahip egzersizleri Firestore'dan getirir.
  Future<List<Exercise>?> getExercisesByIds(List<String> exerciseIds) async {
    try {
      debugPrint("🔍 ExerciseService.getExercisesByIds çağrıldı");
      debugPrint("   - İstenen ID'ler: $exerciseIds");

      if (exerciseIds.isEmpty) {
        debugPrint("❌ Boş ID listesi, boş liste döndürülüyor");
        return [];
      }

      // Firestore'da 'in' operatörüyle 10'dan fazla öğe sorgulanamayacağı için
      // ID'leri 10'lu gruplara bölelim
      final List<Exercise> results = [];
      for (int i = 0; i < exerciseIds.length; i += 10) {
        final chunk = exerciseIds.sublist(
            i, i + 10 > exerciseIds.length ? exerciseIds.length : i + 10);

        debugPrint("📦 Grup ${(i ~/ 10) + 1}: ${chunk.length} ID işleniyor");
        debugPrint("   - Chunk: $chunk");

        final snapshot = await _firestore
            .collection(_collectionPath)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        debugPrint("📊 Bu grupta ${snapshot.docs.length} belge bulundu");

        final chunkResults = snapshot.docs.map((doc) {
          debugPrint("   - Belge ID: ${doc.id}");
          return Exercise.fromSnapshot(doc);
        }).toList();

        results.addAll(chunkResults);
        debugPrint(
            "✅ ${chunkResults.length} egzersiz eklendi, toplam: ${results.length}");
      }

      debugPrint("🎯 Toplam ${results.length} adet egzersiz ID'ye göre alındı");

      // Hangi ID'lerin bulunamadığını logla
      final foundIds = results.map((e) => e.id).toSet();
      final missingIds =
          exerciseIds.where((id) => !foundIds.contains(id)).toList();
      if (missingIds.isNotEmpty) {
        debugPrint("⚠️ Bulunamayan ID'ler: $missingIds");
      }

      return results;
    } catch (e) {
      debugPrint("❌ ID'lere göre egzersizler alınırken hata: $e");
      if (e.toString().contains('permission-denied')) {
        debugPrint(
            "🔄 Firebase izin sorunu - Offline modda ID eşleştirmesi yapılıyor");
        return _getDefaultExercisesByIdsOffline(exerciseIds);
      }
      debugPrint("Stack trace: ${StackTrace.current}");
      return null;
    }
  }
}

// Exercise modelinin Firestore uyumlu olması gerekir:
/*
import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String? id; // Firestore document ID
  final String name;
  final String targetMuscleGroup;
  final String? description;
  final String? equipment;
  final String? videoUrl;
  final bool isCustom;
  final DateTime createdAt;
  final String name_lowercase; // Arama için

  Exercise({
    this.id,
    required this.name,
    required this.targetMuscleGroup,
    this.description,
    this.equipment,
    this.videoUrl,
    this.isCustom = false,
    required this.createdAt,
  }) : name_lowercase = name.toLowerCase(); // Constructor'da oluştur

  // Firestore'dan okuma
  factory Exercise.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      name: data['name'] ?? '',
      targetMuscleGroup: data['targetMuscleGroup'] ?? '',
      description: data['description'],
      equipment: data['equipment'],
      videoUrl: data['videoUrl'],
      isCustom: data['isCustom'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // name_lowercase zaten constructor'da set ediliyor, okumaya gerek yok
    );
  }

  // Firestore'a yazma
  Map<String, dynamic> toMapForFirestore() {
    return {
      'name': name,
      'targetMuscleGroup': targetMuscleGroup,
      'description': description,
      'equipment': equipment,
      'videoUrl': videoUrl,
      'isCustom': isCustom,
      'createdAt': Timestamp.fromDate(createdAt),
      'name_lowercase': name_lowercase, // Küçük harf versiyonunu kaydet
    };
  }

  // copyWith (Gerekirse)
  Exercise copyWith({ ... }) { ... }
}
*/
