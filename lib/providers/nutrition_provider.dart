import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../models/meal_record.dart';
import '../models/task_type.dart';
import 'package:flutter/foundation.dart';

class NutritionProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<MealRecord> _meals = [];
  List<MealRecord> _allMeals = []; // Tüm öğünler
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate; // Tarih aralığı başlangıcı
  DateTime? _endDate; // Tarih aralığı sonu

  List<MealRecord> get meals => _meals;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;

  NutritionProvider() {
    refreshMeals();
  }

  Future<void> refreshMeals() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Seçili gün için öğünleri veritabanından çek
      _meals = await _db.getMealsForDay(_selectedDate);
      notifyListeners();
      
      // Tüm öğünleri de çekelim istatistikler için
      await _loadAllMeals();
    } catch (e) {
      print('Öğünleri yenilerken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAllMeals() async {
    try {
      // Eğer başlangıç ve bitiş tarihleri belirlenmişse aralıktaki verileri al
      if (_startDate != null && _endDate != null) {
        _allMeals = await _db.getMealsInRange(_startDate!, _endDate!);
      } else {
        // Bir yıllık geçmiş verileri al (varsayılan)
        final endDate = DateTime.now();
        final startDate = endDate.subtract(Duration(days: 365));
        _allMeals = await _db.getMealsInRange(startDate, endDate);
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
    _isLoading = true;
    notifyListeners();
    
    try {
      final id = await _db.insertMeal(meal);
      final newMeal = MealRecord(
        id: id,
        type: meal.type,
        foods: meal.foods,
        date: meal.date,
        calories: meal.calories,
        notes: meal.notes,
        taskId: meal.taskId,
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
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _db.updateMeal(meal);
      
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
      await _db.deleteMeal(id);
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
    
    final db = await _db.database;
    await db.delete(
      'meals',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
    
    await refreshMeals();
  }
  
  Future<int> getTotalCaloriesForDay(DateTime date) async {
    final meals = await _db.getMealsForDay(date);
    return meals.fold<int>(0, (sum, meal) => sum + (meal.calories ?? 0));
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

  // Haftalık beslenme programını ekle
  Future<void> createWeeklyNutritionPlan() async {
    // Günün programını belirle (hangi gün olduğuna göre)
    final now = DateTime.now();
    final weekday = now.weekday; // 1-7 (1 = Pazartesi, 7 = Pazar)
    
    List<String> breakfastFoods = [];
    List<String> lunchFoods = [];
    List<String> dinnerFoods = [];
    
    switch (weekday) {
      case 1: // Pazartesi
        breakfastFoods = ['Yulaf', 'Muz', 'Süt'];
        lunchFoods = ['Izgara tavuk', 'Pirinç pilavı', 'Yağlı salata', 'Yoğurt', 'Muz', 'Badem/ceviz'];
        dinnerFoods = ['Ton balıklı salata', 'Yoğurt', 'Tahıllı ekmek'];
        break;
      case 2: // Salı
        breakfastFoods = ['Yulaf', 'Muz', 'Süt'];
        lunchFoods = ['Izgara tavuk', 'Pirinç pilavı', 'Yağlı salata', 'Yoğurt', 'Muz', 'Badem/ceviz'];
        dinnerFoods = ['Izgara tavuk', 'Ton balıklı salata', 'Yoğurt'];
        break;
      case 3: // Çarşamba
        breakfastFoods = ['Yulaf', 'Muz', 'Süt'];
        lunchFoods = ['Yulaf', 'Süt', 'Muz'];
        dinnerFoods = ['Tavuk', 'Ton balık', 'Yağlı salata', 'Yoğurt'];
        break;
      case 4: // Perşembe
        breakfastFoods = ['Yulaf', 'Muz', 'Süt'];
        lunchFoods = ['Izgara tavuk', 'Pirinç pilavı', 'Yağlı salata', 'Yoğurt', 'Muz', 'Badem/ceviz'];
        dinnerFoods = ['Tavuk', 'Ton balık', 'Salata', 'Yoğurt'];
        break;
      case 5: // Cuma
        breakfastFoods = ['Yulaf', 'Muz', 'Süt'];
        lunchFoods = ['Tavuk', 'Haşlanmış yumurta', 'Yoğurt', 'Salata', 'Kuruyemiş'];
        dinnerFoods = ['Menemen', 'Ton balıklı salata', 'Yoğurt'];
        break;
      case 6: // Cumartesi
        breakfastFoods = ['Yulaf', 'Muz', 'Süt'];
        lunchFoods = ['Tavuk', 'Yumurta', 'Pilav', 'Salata'];
        dinnerFoods = ['Sağlıklı serbest menü'];
        break;
      case 7: // Pazar
        breakfastFoods = ['Yulaf', 'Muz', 'Süt'];
        lunchFoods = ['Izgara tavuk', 'Pirinç pilavı', 'Yağlı salata', 'Yoğurt', 'Muz', 'Badem/ceviz'];
        dinnerFoods = ['Hafif ve dengeli öğün'];
        break;
    }
    
    // Bugünün kahvaltısı
    final breakfast = MealRecord(
      type: FitMealType.breakfast,
      foods: breakfastFoods,
      date: DateTime(now.year, now.month, now.day, 8, 0), // Sabah 8:00
      calories: 350,
    );
    
    // Bugünün öğle yemeği
    final lunch = MealRecord(
      type: FitMealType.lunch,
      foods: lunchFoods,
      date: DateTime(now.year, now.month, now.day, 13, 0), // Öğle 13:00
      calories: 650,
    );
    
    // Bugünün akşam yemeği
    final dinner = MealRecord(
      type: FitMealType.dinner,
      foods: dinnerFoods,
      date: DateTime(now.year, now.month, now.day, 19, 0), // Akşam 19:00
      calories: 500,
    );
    
    // Öğünleri ekle
    await addMeal(breakfast);
    await addMeal(lunch);
    await addMeal(dinner);
  }

  Future<List<MealRecord>> getMealsInRange(DateTime startDate, DateTime endDate) async {
    final List<MealRecord> meals = await getAllMeals();
    return meals.where((meal) {
      return meal.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
              meal.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
} 