import 'package:flutter/material.dart';
// import '../models/task_model.dart'; // Kaldırıldı
import '../services/database_service.dart';
import '../models/meal_record.dart';
import '../models/task_type.dart';
import 'package:flutter/foundation.dart';
import '../models/food_item.dart';

class NutritionProvider with ChangeNotifier {
  final DatabaseService _dbService;
  List<MealRecord> _meals = [];
  List<MealRecord> _allMeals = []; // Tüm öğünler
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate; // Tarih aralığı başlangıcı
  DateTime? _endDate; // Tarih aralığı sonu
  String _dailyTasksDate = '';
  int? _currentUserId; // Mevcut kullanıcı ID'si

  // YENİ: currentUserId için public getter
  int? get currentUserId => _currentUserId;

  List<MealRecord> get meals => _meals;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  String get dailyTasksDate => _dailyTasksDate;

  // YENİ: Seçili gün için toplam kalori
  double get currentDailyCalories {
    if (_meals.isEmpty) return 0.0;
    // Sadece _selectedDate ile aynı güne ait öğünlerin kalorilerini topla
    return _meals
        .where((meal) => _isSameDay(meal.date, _selectedDate))
        .fold(0.0, (sum, meal) => sum + (meal.calories ?? 0.0));
  }

  NutritionProvider(this._dbService) {
    // refreshMeals(); // Artık ProxyProvider tetikleyecek
  }

  // YENİ: Kullanıcı ID'sini güncellemek için metot
  void updateUserId(int? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      // Kullanıcı değiştiğinde veya ilk kez ayarlandığında verileri yenile
      if (_currentUserId != null) {
        print("NutritionProvider: Kullanıcı ID güncellendi: $_currentUserId");
        refreshMeals();
      } else {
        print(
            "NutritionProvider: Kullanıcı ID null olarak ayarlandı, veriler temizleniyor.");
        _meals = [];
        _allMeals = [];
        notifyListeners();
      }
    }
  }

  Future<void> refreshMeals() async {
    if (_currentUserId == null) {
      print(
          "NutritionProvider refreshMeals: Kullanıcı ID'si henüz ayarlanmadı.");
      _meals = []; // Kullanıcı yoksa listeyi temizle
      _allMeals = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      // Seçili gün için öğünleri veritabanından çek (userId ile)
      _meals = await _dbService.getMealsForDay(_selectedDate, _currentUserId!);
      notifyListeners();

      // Tüm öğünleri de çekelim istatistikler için (userId ile)
      await _loadAllMeals();
    } catch (e) {
      print('Öğünleri yenilerken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAllMeals() async {
    if (_currentUserId == null) {
      print(
          "NutritionProvider _loadAllMeals: Kullanıcı ID'si henüz ayarlanmadı.");
      _allMeals = [];
      notifyListeners();
      return;
    }
    try {
      // Eğer başlangıç ve bitiş tarihleri belirlenmişse aralıktaki verileri al (userId ile)
      if (_startDate != null && _endDate != null) {
        _allMeals = await _dbService.getMealsInRange(
            _startDate!, _endDate!, _currentUserId!);
      } else {
        // Bir yıllık geçmiş verileri al (varsayılan) (userId ile)
        final endDate = DateTime.now();
        final startDate = endDate.subtract(Duration(days: 365));
        _allMeals = await _dbService.getMealsInRange(
            startDate, endDate, _currentUserId!);
      }
    } catch (e) {
      print('Tüm öğünleri yüklerken hata: $e');
    }
  }

  void setDateRange(DateTime startDate, DateTime endDate) {
    _startDate = startDate;
    _endDate = endDate;
    _loadAllMeals(); // Yeni tarih aralığına göre verileri yükle
  }

  List<MealRecord> getAllMeals() {
    return _allMeals;
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    refreshMeals();
  }

  Future<int?> addMeal(MealRecord meal) async {
    if (_currentUserId == null) {
      print(
          "NutritionProvider addMeal: Kullanıcı ID'si ayarlanamadığı için öğün eklenemiyor.");
      return null;
    }
    _isLoading = true;
    notifyListeners();

    try {
      // userId ile ekle
      final id = await _dbService.insertMeal(meal, _currentUserId!);
      final newMeal = MealRecord(
        id: id,
        type: meal.type,
        foods: meal.foods,
        date: meal.date,
        calories: meal.calories,
        notes: meal.notes,
        taskId: meal.taskId,
        proteinGrams: meal.proteinGrams,
        carbsGrams: meal.carbsGrams,
        fatGrams: meal.fatGrams,
      );

      // Eklenen öğün bugüne aitse listeye ekle
      if (_isSameDay(meal.date, _selectedDate)) {
        _meals.add(newMeal);
      }

      // Tüm öğünlere ekle
      _allMeals.add(newMeal);

      notifyListeners();
      return id;
    } catch (e) {
      print('Öğün eklerken hata: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMeal(MealRecord meal) async {
    if (meal.id == null) return;
    if (_currentUserId == null) {
      print(
          "NutritionProvider updateMeal: Kullanıcı ID'si ayarlanamadığı için öğün güncellenemiyor.");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // userId ile güncelle
      await _dbService.updateMeal(meal, _currentUserId!);

      // Düzenlenen öğün seçili günde ise güncelle
      final index = _meals.indexWhere((m) => m.id == meal.id);
      if (index != -1) {
        _meals[index] = meal;
      }

      // Tüm öğünlerde güncelle
      final allIndex = _allMeals.indexWhere((m) => m.id == meal.id);
      if (allIndex != -1) {
        _allMeals[allIndex] = meal;
      }

      notifyListeners();
    } catch (e) {
      print('Öğün güncellerken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMeal(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.deleteMeal(id);
      _meals.removeWhere((meal) => meal.id == id);
      _allMeals.removeWhere((meal) => meal.id == id);
      notifyListeners();
    } catch (e) {
      print('Öğün silerken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> deleteMealByTaskId(int? taskId) async {
    if (taskId == null) return;

    final db = await _dbService.database;
    await db.delete(
      'meals',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );

    await refreshMeals();
  }

  Future<int> getTotalCaloriesForDay(DateTime date) async {
    if (_currentUserId == null) {
      print(
          "NutritionProvider getTotalCaloriesForDay: Kullanıcı ID'si ayarlanamadı.");
      return 0;
    }
    // userId ile getir
    final meals = await _dbService.getMealsForDay(date, _currentUserId!);
    return meals.fold<int>(0, (sum, meal) => sum + (meal.calories ?? 0));
  }

  Future<List<FoodItem>> getAvailableFoodItems(
      {String? query, bool? isCustom, int? limit}) async {
    try {
      return await _dbService.getFoodItems(
          query: query, isCustom: isCustom, limit: limit);
    } catch (e) {
      print("getAvailableFoodItems hata: $e");
      return []; // Hata durumunda boş liste döndür
    }
  }

  Future<Map<FitMealType, int>> getMealTypeCounts() async {
    final Map<FitMealType, int> counts = {};
    for (var type in FitMealType.values) {
      counts[type] = 0;
    }

    for (var meal in _meals) {
      counts[meal.type] = (counts[meal.type] ?? 0) + 1;
    }

    return counts;
  }

  Future<Map<FitMealType, int>> getMealTypeCalories() async {
    final Map<FitMealType, int> calories = {};
    for (var type in FitMealType.values) {
      calories[type] = 0;
    }

    for (var meal in _meals) {
      calories[meal.type] = (calories[meal.type] ?? 0) + (meal.calories ?? 0);
    }

    return calories;
  }

  // Günlük toplam makro getter'ları
  double get totalProtein {
    return _meals.fold(0.0, (sum, meal) => sum + (meal.proteinGrams ?? 0.0));
  }

  double get totalCarbs {
    return _meals.fold(0.0, (sum, meal) => sum + (meal.carbsGrams ?? 0.0));
  }

  double get totalFat {
    return _meals.fold(0.0, (sum, meal) => sum + (meal.fatGrams ?? 0.0));
  }

  // Günlük toplam kalori
  int get totalCalories {
    return _meals.fold(0, (sum, meal) => sum + (meal.calories ?? 0));
  }

  // Haftalık beslenme programını ekle (Bu metodun amacı belirsiz, belki program servisine taşınmalı?)
  // Future<void> createWeeklyNutritionPlan() async { ... }

  Future<List<MealRecord>> getMealsInRange(
      DateTime startDate, DateTime endDate) async {
    final List<MealRecord> meals = await getAllMeals();
    return meals.where((meal) {
      return meal.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          meal.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Belirli bir tarih için öğünleri getir
  List<MealRecord> getMealsForDate(DateTime date) {
    return _allMeals.where((meal) => _isSameDay(meal.date, date)).toList();
  }

  // İstatistikler ekranı için mevcut tarih aralığını döndür
  ({DateTime? start, DateTime? end}) getCurrentDateRange() {
    return (start: _startDate, end: _endDate);
  }
}
