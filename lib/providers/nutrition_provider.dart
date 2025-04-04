import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../models/meal_record.dart';
import '../models/task_type.dart';

class NutritionProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<MealRecord> _meals = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  List<MealRecord> get meals => _meals;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;

  NutritionProvider() {
    loadMealsForSelectedDate();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    loadMealsForSelectedDate();
  }

  Future<void> loadMealsForSelectedDate() async {
    _isLoading = true;
    notifyListeners();

    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );
    
    _meals = List.generate(maps.length, (i) {
      return MealRecord.fromMap(maps[i]);
    });
    
    _isLoading = false;
    notifyListeners();
  }

  Future<int?> addMeal(MealRecord meal) async {
    _isLoading = true;
    notifyListeners();
    
    final db = await _databaseService.database;
    final id = await db.insert('meals', meal.toMap());
    
    final newMeal = MealRecord(
      id: id,
      type: meal.type,
      foods: meal.foods,
      date: meal.date,
      calories: meal.calories,
      taskId: meal.taskId,
    );
    
    _meals.add(newMeal);
    
    _isLoading = false;
    notifyListeners();
    
    return id;
  }
  
  Future<void> updateMeal(MealRecord meal) async {
    _isLoading = true;
    notifyListeners();

    await _databaseService.updateMeal(meal);
    await loadMealsForSelectedDate();
  }
  
  Future<void> deleteMeal(int id) async {
    _isLoading = true;
    notifyListeners();
    
    final db = await _databaseService.database;
    await db.delete(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    _meals.removeWhere((meal) => meal.id == id);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteMealByTaskId(int? taskId) async {
    if (taskId == null) return;
    
    final db = await _databaseService.database;
    await db.delete(
      'meals',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
    
    await loadMealsForSelectedDate();
  }
  
  Future<int> getTotalCaloriesForDay(DateTime date) async {
    final meals = await _databaseService.getMealsForDay(date);
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

  Future<List<MealRecord>> getAllMeals() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('meals');
    return List.generate(maps.length, (i) {
      return MealRecord.fromMap(maps[i]);
    });
  }

  Future<List<MealRecord>> getMealsInRange(DateTime startDate, DateTime endDate) async {
    final List<MealRecord> meals = await getAllMeals();
    return meals.where((meal) {
      return meal.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
              meal.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
} 