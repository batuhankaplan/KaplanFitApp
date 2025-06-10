import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/food_item.dart';

class FoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'foods';

  FoodService() {
    _addDefaultFoodsIfNeeded();
  }

  /// Varsayılan yiyecekleri Firestore'a ekler (eğer koleksiyon boşsa).
  Future<void> _addDefaultFoodsIfNeeded() async {
    try {
      debugPrint("Firebase foods koleksiyonu kontrol ediliyor...");
      final snapshot =
          await _firestore.collection(_collectionPath).limit(1).get();

      if (snapshot.docs.isEmpty) {
        debugPrint(
            "'$_collectionPath' koleksiyonu boş, varsayılan yiyecekler ekleniyor...");
        final batch = _firestore.batch();
        int count = 0;

        for (final food in _defaultFoods) {
          final docRef = _firestore.collection(_collectionPath).doc();
          batch.set(docRef, food.toMap());
          count++;
        }

        await batch.commit();
        debugPrint('$count adet varsayılan yiyecek Firestore\'a eklendi.');
      } else {
        debugPrint(
            "'$_collectionPath' koleksiyonu zaten ${snapshot.docs.length} yiyecek içeriyor.");
      }
    } catch (e) {
      debugPrint("Varsayılan yiyecekler eklenirken hata: $e");
      debugPrint("Stack trace: ${StackTrace.current}");
    }
  }

  /// Filtrelenmiş yiyecek listesini Firestore'dan getirir.
  Future<List<FoodItem>> getFoods({
    String? query,
    String? category,
    int? limit,
  }) async {
    try {
      debugPrint("🍽️ FoodService.getFoods çağrıldı");
      debugPrint("   - query: $query");
      debugPrint("   - category: $category");
      debugPrint("   - limit: $limit");

      Query collectionRef = _firestore.collection(_collectionPath);
      debugPrint("🔥 Firebase koleksiyonu: $_collectionPath");

      // Arama sorgusu varsa
      if (query != null && query.isNotEmpty) {
        debugPrint("🔍 Query ile arama yapılıyor: $query");
        final lowercaseQuery = query.toLowerCase();
        final snapshot = await collectionRef.get();
        debugPrint("📊 Toplam belge sayısı: ${snapshot.docs.length}");

        final allFoods =
            snapshot.docs.map((doc) => FoodItem.fromSnapshot(doc)).toList();
        debugPrint(
            "✅ FoodItem nesnelerine dönüştürüldü: ${allFoods.length} adet");

        final filteredFoods = allFoods
            .where((food) => food.name.toLowerCase().contains(lowercaseQuery))
            .toList();
        debugPrint("🎯 Filtrelenmiş sonuç: ${filteredFoods.length} adet");
        return filteredFoods;
      }

      // Kategori filtresi
      if (category != null && category.isNotEmpty) {
        debugPrint("🏷️ Kategoriye göre filtreleme: $category");
        collectionRef = collectionRef.where('category', isEqualTo: category);
      }

      // Sıralama ve limit
      collectionRef = collectionRef.orderBy('name');
      if (limit != null) {
        collectionRef = collectionRef.limit(limit);
      }

      debugPrint("📥 Firebase'dan veri çekiliyor...");
      final snapshot = await collectionRef.get();
      debugPrint("📊 Çekilen belge sayısı: ${snapshot.docs.length}");

      final foods =
          snapshot.docs.map((doc) => FoodItem.fromSnapshot(doc)).toList();
      debugPrint("✅ ${foods.length} adet yiyecek getirildi");
      return foods;
    } catch (e) {
      debugPrint("❌ Firestore'dan yiyecekler alınırken hata: $e");
      if (e.toString().contains('permission-denied')) {
        debugPrint(
            "🔄 Firebase izin sorunu - Offline modda varsayılan yiyecekler döndürülüyor");
        return _getDefaultFoodsAsOffline(
            query: query, category: category, limit: limit);
      }
      debugPrint("Stack trace: ${StackTrace.current}");
      return [];
    }
  }

  /// Yeni özel yiyecek ekler.
  Future<String?> addCustomFood(FoodItem food) async {
    try {
      DocumentReference docRef =
          await _firestore.collection(_collectionPath).add(food.toMap());
      debugPrint("Özel yiyecek eklendi: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      debugPrint("Özel yiyecek eklenirken hata: $e");
      return null;
    }
  }

  /// Yiyeceği günceller.
  Future<bool> updateFood(FoodItem food) async {
    if (food.id == null) {
      debugPrint("Güncellenecek yiyeceğin ID'si yok.");
      return false;
    }
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(food.id)
          .update(food.toMap());
      debugPrint("Yiyecek güncellendi: ${food.id}");
      return true;
    } catch (e) {
      debugPrint("Yiyecek güncellenirken hata (${food.id}): $e");
      return false;
    }
  }

  /// ID'ye göre yiyecek getirir.
  Future<FoodItem?> getFoodById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionPath).doc(id).get();
      if (doc.exists) {
        return FoodItem.fromSnapshot(doc);
      } else {
        debugPrint("Yiyecek bulunamadı: $id");
        return null;
      }
    } catch (e) {
      debugPrint("ID ile yiyecek alınırken hata ($id): $e");
      return null;
    }
  }

  /// Yiyecek siler.
  Future<bool> deleteFood(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
      debugPrint("Yiyecek silindi: $id");
      return true;
    } catch (e) {
      debugPrint("Yiyecek silinirken hata ($id): $e");
      return false;
    }
  }

  /// Kategori listesini getirir.
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(_collectionPath).get();
      final categories = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category'] as String);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      debugPrint("Kategoriler alınırken hata: $e");
      return [];
    }
  }

  /// Varsayılan yiyecek listesi
  static final List<FoodItem> _defaultFoods = [
    // Protein Kaynakları
    FoodItem(
      name: 'Tavuk Göğsü',
      category: 'Protein',
      servingSizeG: 100.0,
      caloriesKcal: 165,
      proteinG: 31.0,
      carbsG: 0.0,
      fatG: 3.6,
    ),
    FoodItem(
      name: 'Balık (Somon)',
      category: 'Protein',
      servingSizeG: 100.0,
      caloriesKcal: 208,
      proteinG: 25.4,
      carbsG: 0.0,
      fatG: 12.4,
    ),
    FoodItem(
      name: 'Yumurta',
      category: 'Protein',
      servingSizeG: 100.0,
      caloriesKcal: 155,
      proteinG: 13.0,
      carbsG: 1.1,
      fatG: 11.0,
    ),
    FoodItem(
      name: 'Dana Eti',
      category: 'Protein',
      servingSizeG: 100.0,
      caloriesKcal: 250,
      proteinG: 26.0,
      carbsG: 0.0,
      fatG: 15.0,
    ),

    // Karbonhidrat Kaynakları
    FoodItem(
      name: 'Beyaz Pirinç',
      category: 'Karbonhidrat',
      servingSizeG: 100.0,
      caloriesKcal: 130,
      proteinG: 2.7,
      carbsG: 28.0,
      fatG: 0.3,
    ),
    FoodItem(
      name: 'Esmer Pirinç',
      category: 'Karbonhidrat',
      servingSizeG: 100.0,
      caloriesKcal: 111,
      proteinG: 2.6,
      carbsG: 23.0,
      fatG: 0.9,
    ),
    FoodItem(
      name: 'Makarna',
      category: 'Karbonhidrat',
      servingSizeG: 100.0,
      caloriesKcal: 131,
      proteinG: 5.0,
      carbsG: 25.0,
      fatG: 1.1,
    ),
    FoodItem(
      name: 'Ekmek (Tam Buğday)',
      category: 'Karbonhidrat',
      servingSizeG: 100.0,
      caloriesKcal: 247,
      proteinG: 13.2,
      carbsG: 41.0,
      fatG: 4.2,
    ),
    FoodItem(
      name: 'Patates',
      category: 'Karbonhidrat',
      servingSizeG: 100.0,
      caloriesKcal: 77,
      proteinG: 2.0,
      carbsG: 17.0,
      fatG: 0.1,
    ),

    // Sebzeler
    FoodItem(
      name: 'Brokoli',
      category: 'Sebze',
      servingSizeG: 100.0,
      caloriesKcal: 34,
      proteinG: 2.8,
      carbsG: 7.0,
      fatG: 0.4,
    ),
    FoodItem(
      name: 'Ispanak',
      category: 'Sebze',
      servingSizeG: 100.0,
      caloriesKcal: 23,
      proteinG: 2.9,
      carbsG: 3.6,
      fatG: 0.4,
    ),
    FoodItem(
      name: 'Domates',
      category: 'Sebze',
      servingSizeG: 100.0,
      caloriesKcal: 18,
      proteinG: 0.9,
      carbsG: 3.9,
      fatG: 0.2,
    ),
    FoodItem(
      name: 'Salatalık',
      category: 'Sebze',
      servingSizeG: 100.0,
      caloriesKcal: 16,
      proteinG: 0.7,
      carbsG: 4.0,
      fatG: 0.1,
    ),

    // Meyveler
    FoodItem(
      name: 'Elma',
      category: 'Meyve',
      servingSizeG: 100.0,
      caloriesKcal: 52,
      proteinG: 0.3,
      carbsG: 14.0,
      fatG: 0.2,
    ),
    FoodItem(
      name: 'Muz',
      category: 'Meyve',
      servingSizeG: 100.0,
      caloriesKcal: 89,
      proteinG: 1.1,
      carbsG: 23.0,
      fatG: 0.3,
    ),
    FoodItem(
      name: 'Portakal',
      category: 'Meyve',
      servingSizeG: 100.0,
      caloriesKcal: 47,
      proteinG: 0.9,
      carbsG: 12.0,
      fatG: 0.1,
    ),

    // Süt Ürünleri
    FoodItem(
      name: 'Yoğurt (Az Yağlı)',
      category: 'Süt Ürünü',
      servingSizeG: 100.0,
      caloriesKcal: 59,
      proteinG: 10.0,
      carbsG: 3.6,
      fatG: 0.4,
    ),
    FoodItem(
      name: 'Süt (Yarım Yağlı)',
      category: 'Süt Ürünü',
      servingSizeG: 100.0,
      caloriesKcal: 42,
      proteinG: 3.4,
      carbsG: 5.0,
      fatG: 1.0,
    ),
    FoodItem(
      name: 'Peynir (Beyaz)',
      category: 'Süt Ürünü',
      servingSizeG: 100.0,
      caloriesKcal: 264,
      proteinG: 18.0,
      carbsG: 1.0,
      fatG: 21.0,
    ),

    // Yağlar ve Yağlı Tohumlar
    FoodItem(
      name: 'Zeytinyağı',
      category: 'Yağ',
      servingSizeG: 100.0,
      caloriesKcal: 884,
      proteinG: 0.0,
      carbsG: 0.0,
      fatG: 100.0,
    ),
    FoodItem(
      name: 'Avokado',
      category: 'Yağ',
      servingSizeG: 100.0,
      caloriesKcal: 160,
      proteinG: 2.0,
      carbsG: 9.0,
      fatG: 15.0,
    ),
    FoodItem(
      name: 'Badem',
      category: 'Yağlı Tohum',
      servingSizeG: 100.0,
      caloriesKcal: 579,
      proteinG: 21.0,
      carbsG: 22.0,
      fatG: 50.0,
    ),
    FoodItem(
      name: 'Ceviz',
      category: 'Yağlı Tohum',
      servingSizeG: 100.0,
      caloriesKcal: 654,
      proteinG: 15.0,
      carbsG: 14.0,
      fatG: 65.0,
    ),
  ];

  /// Offline modda varsayılan yiyecekleri filtreli şekilde döndürür
  List<FoodItem> _getDefaultFoodsAsOffline({
    String? query,
    String? category,
    int? limit,
  }) {
    debugPrint("📱 Offline modda yiyecekler filtreleniyor...");

    List<FoodItem> filteredFoods = List.from(_defaultFoods);

    // Query filtresi
    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      filteredFoods = filteredFoods
          .where((food) => food.name.toLowerCase().contains(lowercaseQuery))
          .toList();
    }

    // Kategori filtresi
    if (category != null && category.isNotEmpty) {
      filteredFoods =
          filteredFoods.where((food) => food.category == category).toList();
    }

    // Sıralama
    filteredFoods.sort((a, b) => a.name.compareTo(b.name));

    // Limit uygula
    if (limit != null && filteredFoods.length > limit) {
      filteredFoods = filteredFoods.take(limit).toList();
    }

    debugPrint("📱 Offline modda ${filteredFoods.length} yiyecek döndürülüyor");
    return filteredFoods;
  }
}
