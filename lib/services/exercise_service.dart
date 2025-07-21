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
    // Firebase bağlantısı hazır olduğunda egzersizleri kontrol et
    Future.delayed(Duration(seconds: 2), () {
      _addDefaultExercisesIfNeeded();
    });
  }

  // Varsayılan egzersiz listesi (newtraining.txt'den güncellenmiş)
  final List<Exercise> _defaultExercises = [
    // ISINMA HAREKETLERİ
    Exercise(
        name: 'Pelvic Tilt',
        description: 'Pelvik Eğme hareketi. Sırtüstü yatarak, dizlerinizi büküp ayaklarınızı yere koyun. Karın kaslarınızı sıkarak belinizdeki çukurluğu yere bastırın.',
        targetMuscleGroup: 'Isınma',
        equipment: 'Vücut Ağırlığı',
        defaultSets: '1',
        defaultReps: '15'),
    Exercise(
        name: 'Cat-Camel',
        description: 'Kedi-Deve hareketi. Dört ayak üzerinde durun, sırtınızı yukarı doğru kambur yapın (kedi), sonra aşağı doğru çukurlaştırın (deve).',
        targetMuscleGroup: 'Isınma',
        equipment: 'Vücut Ağırlığı',
        defaultSets: '1',
        defaultReps: '10'),
    Exercise(
        name: 'Bird-Dog',
        description: 'Kuş-Köpek hareketi. Dört ayak üzerinde, karşı kol ve bacağı aynı anda kaldırın. Dengeyi koruyarak pozisyonu tutun.',
        targetMuscleGroup: 'Isınma',
        equipment: 'Vücut Ağırlığı',
        defaultSets: '1',
        defaultReps: '10'),
    Exercise(
        name: 'Glute Bridge',
        description: 'Kalça Köprüsü. Sırtüstü yatarak dizlerinizi büküp, kalçanızı yukarı kaldırın. Kalça kaslarınızı sıkın.',
        targetMuscleGroup: 'Isınma',
        equipment: 'Vücut Ağırlığı',
        defaultSets: '1',
        defaultReps: '15'),

    // ÜST VÜCUT - YATAY İTME/ÇEKME
    Exercise(
        name: 'Floor Press (Dumbbell ile)',
        description: 'Yere sırtüstü uzanın. Bu hareket, zeminin omuzlarınızı desteklemesi ve belinizi aşırı bükmenizi engellemesi nedeniyle son derece güvenlidir.',
        targetMuscleGroup: 'Üst Vücut - Yatay İtme/Çekme',
        equipment: 'Dumbbell',
        defaultSets: '3',
        defaultReps: '10-12',
        defaultRestTime: '90 sn'),
    Exercise(
        name: 'Chest-Supported Row',
        description: 'Yüzüstü eğimli bir sehpaya yaslanarak yapın. Bu, belinizdeki tüm yükü kaldırır ve sırt kaslarınızı güvenle izole eder.',
        targetMuscleGroup: 'Üst Vücut - Yatay İtme/Çekme',
        equipment: 'Makine',
        defaultSets: '3',
        defaultReps: '10-12',
        defaultRestTime: '90 sn'),
    Exercise(
        name: 'Dumbbell Lateral Raise',
        description: 'Ayakta veya oturarak, hafif kilolarla ve kontrollü bir şekilde omuzlarınızı yana doğru kaldırın. Gövdenizi sallamayın.',
        targetMuscleGroup: 'Üst Vücut - Yatay İtme/Çekme',
        equipment: 'Dumbbell',
        defaultSets: '3',
        defaultReps: '12-15',
        defaultRestTime: '60 sn'),
    Exercise(
        name: 'Dumbbell Alternate Curl',
        description: 'Ayakta dik durun, core bölgeniz sıkı olsun. Dirseklerinizi vücudunuza yakın tutarak dumbbell\'ları sırayla kaldırın.',
        targetMuscleGroup: 'Üst Vücut - Yatay İtme/Çekme',
        equipment: 'Dumbbell',
        defaultSets: '3',
        defaultReps: '10-12',
        defaultRestTime: '60 sn'),
    Exercise(
        name: 'Cable Triceps Extension',
        description: 'Gövdenizi dik tutun, öne eğilmeyin. Karın ve kalça kaslarınızı sıkarak belinizin kavis yapmasını engelleyin.',
        targetMuscleGroup: 'Üst Vücut - Yatay İtme/Çekme',
        equipment: 'Kablo Makinesi',
        defaultSets: '3',
        defaultReps: '12-15',
        defaultRestTime: '60 sn'),

    // ALT VÜCUT & CORE
    Exercise(
        name: 'Goblet Squat',
        description: 'Dumbbell\'ı göğsünüze yakın tutmak, sırtınızı dik tutmanıza yardımcı olur. Belinizi yuvarlamadan, ağrısız bir derinliğe kadar inin.',
        targetMuscleGroup: 'Alt Vücut & Core',
        equipment: 'Dumbbell',
        defaultSets: '3',
        defaultReps: '10-12',
        defaultRestTime: '90 sn'),
    Exercise(
        name: 'Dumbbell RDL',
        description: 'DİKKAT: Sırtınız tamamen düz kalmalı. Kalçanızı geriye doğru itin. Belinizde değil, arka bacaklarınızda gerginlik hissedin.',
        targetMuscleGroup: 'Alt Vücut & Core',
        equipment: 'Dumbbell',
        defaultSets: '3',
        defaultReps: '10-12',
        defaultRestTime: '90 sn'),
    Exercise(
        name: 'Leg Curl Machine',
        description: 'Arka bacak kaslarını (hamstring) bele yük bindirmeden güvenli bir şekilde izole eder.',
        targetMuscleGroup: 'Alt Vücut & Core',
        equipment: 'Makine',
        defaultSets: '3',
        defaultReps: '12-15',
        defaultRestTime: '60 sn'),
    Exercise(
        name: 'Pallof Press',
        description: 'Kablo makinesine yan durun. Kablonun sizi döndürmesine karşı direnerek core stabilitenizi geliştirin.',
        targetMuscleGroup: 'Alt Vücut & Core',
        equipment: 'Kablo Makinesi',
        defaultSets: '3',
        defaultReps: '10',
        defaultRestTime: '60 sn'),
    Exercise(
        name: 'Plank',
        description: 'Kalçanızı sıkın ve belinizin çukurlaşmasına izin vermeyin. Form bozulduğu an seti bitirin.',
        targetMuscleGroup: 'Alt Vücut & Core',
        equipment: 'Vücut Ağırlığı',
        defaultSets: '3',
        defaultReps: 'Maksimum Süre',
        defaultRestTime: '60 sn'),

    // ÜST VÜCUT - DİKEY İTME/ÇEKME
    Exercise(
        name: 'Lat Pulldown',
        description: 'Gövdenizi dik ve sabit tutun. Ağırlığı çekmek için geriye doğru sallanmayın. Hareketi yavaş ve kontrollü yapın.',
        targetMuscleGroup: 'Üst Vücut - Dikey İtme/Çekme',
        equipment: 'Makine',
        defaultSets: '3',
        defaultReps: '10-12',
        defaultRestTime: '90 sn'),
    Exercise(
        name: 'Landmine Press',
        description: 'Omuzları, omurgaya direkt dikey baskı uygulamadan çalıştırmanın en güvenli yoludur.',
        targetMuscleGroup: 'Üst Vücut - Dikey İtme/Çekme',
        equipment: 'Barbell',
        defaultSets: '3',
        defaultReps: '10',
        defaultRestTime: '90 sn'),
    Exercise(
        name: 'Push-up',
        description: 'Gerekirse dizlerinizin üzerinde yaparak başlayın. Vücudunuzu baştan dize (veya ayağa) kadar düz bir çizgi halinde tutun.',
        targetMuscleGroup: 'Üst Vücut - Dikey İtme/Çekme',
        equipment: 'Vücut Ağırlığı',
        defaultSets: '3',
        defaultReps: 'Maksimum Tekrar',
        defaultRestTime: '90 sn'),
    Exercise(
        name: 'Unilateral Dumbbell Row',
        description: 'Bir eliniz ve diziniz sehpada destekli olsun. Sırtınız yere paralel ve dümdüz kalmalı. Gövdeyi döndürmeden çekiş yapın.',
        targetMuscleGroup: 'Üst Vücut - Dikey İtme/Çekme',
        equipment: 'Dumbbell',
        defaultSets: '3',
        defaultReps: '10',
        defaultRestTime: '90 sn'),
    Exercise(
        name: 'Cable Hammer Curl',
        description: 'Ön kol kaslarını farklı bir açıyla çalıştırır. Core bölgenizi sabit tutun.',
        targetMuscleGroup: 'Üst Vücut - Dikey İtme/Çekme',
        equipment: 'Kablo Makinesi',
        defaultSets: '3',
        defaultReps: '12-15',
        defaultRestTime: '60 sn'),

    // AKTİF TOPARLANMA VE OMURGA SAĞLIĞI
    Exercise(
        name: 'Dead Bug',
        description: 'Belinizi yerden kaldırmadan, core stabilitesine odaklanın.',
        targetMuscleGroup: 'Aktif Toparlanma ve Omurga Sağlığı',
        equipment: 'Vücut Ağırlığı',
        defaultSets: '2',
        defaultReps: '10',
        defaultRestTime: '30 sn'),
    Exercise(
        name: 'Side Plank',
        description: 'Kalçanızın düşmesine izin vermeyin.',
        targetMuscleGroup: 'Aktif Toparlanma ve Omurga Sağlığı',
        equipment: 'Vücut Ağırlığı',
        defaultSets: '2',
        defaultReps: '30 sn',
        defaultRestTime: '30 sn'),

    // KARDİYO
    Exercise(
        name: 'Eliptik Bisiklet',
        description: 'Orta tempo ile kardiyovasküler kondisyonu geliştirin.',
        targetMuscleGroup: 'Kardiyo',
        equipment: 'Eliptik Makine',
        defaultSets: '1',
        defaultReps: '20-30 dakika'),
    Exercise(
        name: 'Kondisyon Bisikleti',
        description: 'Sırt destekli yatar model tercih edilir. Orta tempo ile pedal çevirin.',
        targetMuscleGroup: 'Kardiyo',
        equipment: 'Kondisyon Bisikleti',
        defaultSets: '1',
        defaultReps: '20-30 dakika'),
    Exercise(
        name: 'Tempolu Yürüyüş',
        description: 'Sabit tempo ile kardiyovasküler dayanıklılığı artırın.',
        targetMuscleGroup: 'Kardiyo',
        equipment: 'Yürüyüş Bandı',
        defaultSets: '1',
        defaultReps: '30 dakika'),
    Exercise(
        name: 'Yürüyüş',
        description: 'Açık havada veya kapalı alanda yapılan doğal kardiyovasküler egzersiz.',
        targetMuscleGroup: 'Kardiyo',
        equipment: 'Vücut Ağırlığı',
        defaultSets: '1',
        defaultReps: '30-40 dakika'),
    Exercise(
        name: 'Yüzme',
        description: 'Suyun kaldırma kuvveti sayesinde omurgaya hiç yük bindirmez ve ideal bir seçenektir.',
        targetMuscleGroup: 'Kardiyo',
        equipment: 'Havuz',
        defaultSets: '1',
        defaultReps: '30-40 dakika'),

    // SOĞUMA HAREKETLERİ
    Exercise(
        name: 'Sırtüstü Hamstring Esnetme',
        description: 'Sırtüstü yatarak bir bacağınızı yukarı kaldırın ve arka bacak kaslarınızı nazikçe esnetin.',
        targetMuscleGroup: 'Soğuma',
        equipment: 'Vücut Ağırlığı',
        defaultSets: '1',
        defaultReps: '20-30 sn'),
    Exercise(
        name: 'Piriformis Esnetme',
        description: 'Kalça bölgesindeki piriformis kasını esnetmek için özel pozisyon.',
        targetMuscleGroup: 'Soğuma',
        equipment: 'Vücut Ağırlığı',
        defaultSets: '1',
        defaultReps: '20-30 sn'),
    Exercise(
        name: 'Tek Diz Göğüse Çekme',
        description: 'Sırtüstü yatarak bir dizinizi göğsünüze çekin ve bel kaslarınızı esnetin.',
        targetMuscleGroup: 'Soğuma',
        equipment: 'Vücut Ağırlığı',
        defaultSets: '1',
        defaultReps: '20-30 sn'),

    // ESKİ HAREKETLERİ KORU (Mevcut sistemle uyumluluk için)
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
    Exercise(
        name: 'Cable Overhead Triceps Extension',
        targetMuscleGroup: 'Arka Kol',
        equipment: 'Kablo Makinesi'),
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
    Exercise(
        name: 'Dumbbell Shoulder Press',
        targetMuscleGroup: 'Omuz',
        equipment: 'Dumbbell'),
    Exercise(
        name: 'Facepull',
        targetMuscleGroup: 'Omuz',
        equipment: 'Kablo Makinesi'),
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
    Exercise(
        name: 'Leg Raises',
        targetMuscleGroup: 'Karın',
        equipment: 'Vücut Ağırlığı'),
    Exercise(
        name: 'Crunch',
        targetMuscleGroup: 'Karın',
        equipment: 'Vücut Ağırlığı'),
    Exercise(
        name: 'Esneme',
        targetMuscleGroup: 'Esneklik',
        equipment: 'Vücut Ağırlığı'),
  ];

  /// Servisi başlatır ve varsayılan egzersizleri ekler (eğer yoksa).
  // initialize metodu kaldırıldı, constructor içinde kontrol ediliyor.
  // Future<void> initialize() async { ... }

  /// Manuel olarak eksik egzersizleri kontrol et ve ekle (public method)
  Future<void> checkAndAddMissingExercises() async {
    await _addDefaultExercisesIfNeeded();
  }

  /// Manuel olarak tüm varsayılan egzersizleri Firebase'e zorla ekler
  Future<void> forceAddAllExercises() async {
    try {
      debugPrint("🔥 FORCE: Tüm egzersizler Firebase'e ekleniyor...");
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (final exercise in _defaultExercises) {
        final docRef = _firestore.collection(_collectionPath).doc();
        batch.set(docRef, exercise.toMap());
        debugPrint("   + Ekleniyor: ${exercise.name}");
        count++;
      }
      
      await batch.commit();
      debugPrint('✅ FORCE: ${count} adet egzersiz zorla Firebase\'e eklendi.');
    } catch (e) {
      debugPrint("❌ FORCE: Egzersizler eklenirken hata: $e");
    }
  }

  /// Varsayılan egzersizleri Firestore'a ekler (eksik olanları).
  Future<void> _addDefaultExercisesIfNeeded() async {
    try {
      debugPrint("🔥 Firebase exercises koleksiyonu kontrol ediliyor...");

      // İlk önce Firebase bağlantısını test et
      await _testFirebaseConnection();

      // Mevcut egzersizleri kontrol et
      final snapshot = await _firestore.collection(_collectionPath).get();
      final existingNames = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String?)
          .where((name) => name != null)
          .map((name) => name!.toLowerCase().trim())
          .toSet();

      debugPrint("📋 Mevcut egzersizler: ${existingNames.length} adet");
      debugPrint("🔍 Mevcut isimler: $existingNames");

      // Eksik egzersizleri bul - daha detaylı kontrol
      final missingExercises = <Exercise>[];
      for (final exercise in _defaultExercises) {
        final exerciseName = exercise.name.toLowerCase().trim();
        if (!existingNames.contains(exerciseName)) {
          missingExercises.add(exercise);
          debugPrint("❌ Eksik: '${exercise.name}' (normalized: '$exerciseName')");
        } else {
          debugPrint("✅ Mevcut: '${exercise.name}'");
        }
      }

      if (missingExercises.isNotEmpty) {
        debugPrint("➕ ${missingExercises.length} yeni egzersiz ekleniyor...");
        final batch = _firestore.batch();
        
        for (final exercise in missingExercises) {
          final docRef = _firestore.collection(_collectionPath).doc();
          batch.set(docRef, exercise.toMap());
          debugPrint("   + ${exercise.name}");
        }
        
        await batch.commit();
        debugPrint('✅ ${missingExercises.length} adet yeni egzersiz Firestore\'a eklendi.');
      } else {
        debugPrint("✅ Tüm varsayılan egzersizler zaten mevcut.");
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
