import 'package:flutter/material.dart';
// import '../models/task_model.dart'; // Kaldırıldı
import '../services/database_service.dart';
import '../models/meal_record.dart';
import '../models/task_type.dart';
import 'package:flutter/foundation.dart';
import '../models/food_item.dart';
import 'user_provider.dart'; // UserProvider importu

class NutritionProvider with ChangeNotifier {
  final DatabaseService _dbService;
  final UserProvider _userProvider; // Eklendi

  List<MealRecord> _meals = [];
  List<MealRecord> _allMeals = []; // Tüm öğünler
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate; // Tarih aralığı başlangıcı
  DateTime? _endDate; // Tarih aralığı sonu
  final String _dailyTasksDate = '';
  // int? _currentUserId; // Kaldırıldı, _userProvider.user.id kullanılacak

  // int? get currentUserId => _userProvider.user?.id; // _currentUserId getter'ı kaldırıldı

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

  NutritionProvider(this._dbService, this._userProvider) {
    // _userProvider eklendi
    // UserProvider artık constructor'da alındığı için, başlangıç yüklemeleri yapılabilir.
    if (_userProvider.user?.id != null) {
      refreshMeals();
    }
  }

  Future<void> refreshMeals() async {
    final userId = _userProvider.user?.id;
    if (userId == null) {
      debugPrint(
          "NutritionProvider refreshMeals: Kullanıcı ID'si henüz ayarlanmadı.");
      _meals = [];
      _allMeals = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      _meals = await _dbService.getMealsForDay(_selectedDate, userId);
      notifyListeners();
      await _loadAllMeals();
    } catch (e) {
      debugPrint('Öğünleri yenilerken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAllMeals() async {
    final userId = _userProvider.user?.id;
    if (userId == null) {
      debugPrint(
          "NutritionProvider _loadAllMeals: Kullanıcı ID'si henüz ayarlanmadı.");
      _allMeals = [];
      notifyListeners();
      return;
    }
    try {
      // Eğer başlangıç ve bitiş tarihleri belirlenmişse aralıktaki verileri al (userId ile)
      if (_startDate != null && _endDate != null) {
        _allMeals =
            await _dbService.getMealsInRange(_startDate!, _endDate!, userId);
      } else {
        // Bir yıllık geçmiş verileri al (varsayılan) (userId ile)
        final endDate = DateTime.now();
        final startDate = endDate.subtract(Duration(days: 365));
        _allMeals =
            await _dbService.getMealsInRange(startDate, endDate, userId);
      }
    } catch (e) {
      debugPrint('Tüm öğünleri yüklerken hata: $e');
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
    final userId = _userProvider.user?.id;
    if (userId == null) {
      debugPrint(
          "NutritionProvider addMeal: Kullanıcı ID'si ayarlanamadığı için öğün eklenemiyor.");
      return null;
    }
    _isLoading = true;
    notifyListeners();

    try {
      // userId ile ekle
      final id = await _dbService.insertMeal(meal, userId);
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
      debugPrint('Öğün eklerken hata: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMeal(MealRecord meal) async {
    final userId = _userProvider.user?.id;
    if (meal.id == null) return;
    if (userId == null) {
      debugPrint(
          "NutritionProvider updateMeal: Kullanıcı ID'si ayarlanamadığı için öğün güncellenemiyor.");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // userId ile güncelle
      await _dbService.updateMeal(meal, userId);

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
      debugPrint('Öğün güncellerken hata: $e');
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
      debugPrint('Öğün silerken hata: $e');
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
    final userId = _userProvider.user?.id;
    if (userId == null) {
      debugPrint(
          "NutritionProvider getTotalCaloriesForDay: Kullanıcı ID'si ayarlanamadı.");
      return 0;
    }
    // userId ile getir
    final meals = await _dbService.getMealsForDay(date, userId);
    return meals.fold<int>(0, (sum, meal) => sum + (meal.calories ?? 0));
  }

  Future<List<FoodItem>> getAvailableFoodItems(
      {String? query, bool? isCustom, int? limit}) async {
    try {
      return await _dbService.getFoodItems(
          query: query, isCustom: isCustom, limit: limit);
    } catch (e) {
      debugPrint("getAvailableFoodItems hata: $e");
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
    final List<MealRecord> meals = getAllMeals();
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
