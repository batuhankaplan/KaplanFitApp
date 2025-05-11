import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../models/activity_record.dart';
import '../models/task_type.dart';
import 'package:flutter/foundation.dart';
import '../providers/gamification_provider.dart';
import 'package:provider/provider.dart';

class ActivityProvider with ChangeNotifier {
  final DatabaseService _dbService;
  List<ActivityRecord> _activities = [];
  List<ActivityRecord> _allActivities = []; // Tüm aktiviteler
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate; // Tarih aralığı başlangıcı
  DateTime? _endDate; // Tarih aralığı sonu
  List<Task> _dailyTasks = []; // Task modelini kullanıyoruz
  String _dailyTasksDate = '';

  List<ActivityRecord> get activities => _activities;
  List<Task> get dailyTasks => _dailyTasks; // Task döndür
  List<Task> get tasks => _dailyTasks; // Task döndür
  bool get isLoading => _isLoading;
  String get dailyTasksDate => _dailyTasksDate;
  DateTime get selectedDate => _selectedDate;

  // YENİ: Seçili gün için toplam aktivite süresi (dakika)
  int get currentDailyActivityMinutes {
    if (_isLoading) return 0; // Yükleniyorsa 0 dön
    return _activities.fold<int>(
        0, (sum, activity) => sum + (activity.durationMinutes ?? 0));
  }

  ActivityProvider(this._dbService) {
    // refreshActivities ve loadDailyTasks için userId gerekecek.
    // Bu, UserProvider'dan alınmalı veya UI'dan sağlanmalı.
    // Şimdilik başlangıçta yükleme yapılmayacak şekilde bırakıyorum,
    // UI'da UserProvider yüklendikten sonra çağrılmalı.
    // refreshActivities();
    loadDailyTasks();
  }

  void setSelectedDate(DateTime date, int userId) {
    // userId eklendi
    _selectedDate = date;
    refreshActivities(userId); // userId ile çağır
    // Seçili tarih değiştiğinde o günün görevlerini de yükle
    // loadTasksForSelectedDate(); // Bu belki home_screen'de tetiklenmeli?
  }

  Future<void> refreshActivities(int userId) async {
    // userId eklendi
    _isLoading = true;
    notifyListeners();

    try {
      // Seçili gün için aktiviteleri veritabanından çek (caloriesBurned dahil)
      _activities = await _dbService.getActivitiesForDay(
          _selectedDate, userId); // userId eklendi
      _activities.sort((a, b) => b.date.compareTo(a.date)); // Sırala
      notifyListeners();

      // Tüm aktiviteleri de çekelim istatistikler için (caloriesBurned dahil)
      await _loadAllActivities(userId); // userId eklendi
    } catch (e) {
      print('Aktiviteleri yenilerken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAllActivities(int userId) async {
    // userId eklendi
    try {
      DateTime effectiveStartDate;
      DateTime effectiveEndDate;

      if (_startDate != null && _endDate != null) {
        effectiveStartDate = _startDate!;
        effectiveEndDate = _endDate!;
      } else {
        effectiveEndDate = DateTime.now();
        effectiveStartDate =
            effectiveEndDate.subtract(const Duration(days: 365));
      }
      _allActivities = await _dbService.getActivitiesInRange(
          effectiveStartDate, effectiveEndDate, userId); // userId eklendi
      _allActivities.sort((a, b) => b.date.compareTo(a.date)); // Sırala
    } catch (e) {
      print('Tüm aktiviteleri yüklerken hata: $e');
      _allActivities = [];
    }
  }

  void setDateRange(DateTime startDate, DateTime endDate, int userId) {
    // userId eklendi
    _startDate = startDate;
    _endDate = endDate;
    refreshActivities(userId); // userId ile çağır
  }

  List<ActivityRecord> getAllActivities() {
    return _allActivities;
  }

  Future<void> loadDailyTasks() async {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Eğer görevler zaten bugüne aitse tekrar yükleme
    if (_dailyTasks.isNotEmpty && _dailyTasksDate == todayString) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _dailyTasks = await _dbService.getTasksForDay(DateTime.now());
      _dailyTasksDate = todayString;
    } catch (e) {
      print("Günlük görevler yüklenirken hata: $e");
      _dailyTasks = []; // Hata durumunda boşalt
    }

    _isLoading = false;
    notifyListeners();
  }

  // Bu metodun amacı net değil, belki kaldırılabilir?
  // Future<void> loadTasksForSelectedDate() async {
  //   _isLoading = true;
  //   notifyListeners();
  //   try {
  //     _dailyTasks = await _dbService.getTasksForDay(_selectedDate);
  //   } catch (e) {
  //     print("Seçili gün görevleri yüklenirken hata: $e");
  //     _dailyTasks = [];
  //   }
  //   _isLoading = false;
  //   notifyListeners();
  // }

  Future<int?> addActivity(
      ActivityRecord activity, int userId, BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    int? id;
    try {
      // caloriesBurned dahil veritabanına ekle
      id = await _dbService.insertActivity(activity, userId); // userId eklendi

      final newActivityWithId = ActivityRecord(
        id: id,
        type: activity.type,
        durationMinutes: activity.durationMinutes,
        date: activity.date,
        notes: activity.notes,
        caloriesBurned: activity.caloriesBurned, // caloriesBurned'ı aktar
        taskId: activity.taskId,
        userId: userId, // userId eklendi
        isFromProgram: activity.isFromProgram, // isFromProgram bilgisini aktar
      );

      if (_isSameDay(activity.date, _selectedDate)) {
        _activities.add(newActivityWithId);
        _activities.sort((a, b) => b.date.compareTo(a.date));
      }
      _allActivities.add(newActivityWithId);
      _allActivities.sort((a, b) => b.date.compareTo(a.date));

      // Eğer aktivite bir programdan ise rozetleri kontrol et
      if (activity.isFromProgram) {
        // YALNIZCA programdan ise çağır
        final gamificationProvider =
            Provider.of<GamificationProvider>(context, listen: false);
        await gamificationProvider.recordProgramWorkoutCompleted(userId, id!);
        print(
            "ActivityProvider: Called recordProgramWorkoutCompleted for activity ID $id");
      }

      notifyListeners();
    } catch (e) {
      print('Aktivite eklerken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return id;
  }

  Future<void> deleteActivity(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dbService.deleteActivity(id);
      _activities.removeWhere((activity) => activity.id == id);
      _allActivities.removeWhere((activity) => activity.id == id);
      notifyListeners();
    } catch (e) {
      print('Aktivite silerken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteActivityByTaskId(int? taskId, int userId) async {
    if (taskId == null) return;
    try {
      await _dbService.deleteActivityByTaskId(taskId);
      refreshActivities(userId);
    } catch (e) {
      print('Error deleting activity by taskId ' +
          taskId.toString() +
          ': ' +
          e.toString());
    }
  }

  Future<int> addTask(Task task) async {
    _isLoading = true;
    notifyListeners();
    int? id;
    try {
      id = await _dbService.insertTask(task);
      final newTask = task.copyWith(id: id);
      _dailyTasks.add(newTask);
    } catch (e) {
      print("Görev eklerken hata: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return id ?? -1; // Hata durumunda -1 dönebilir
  }

  Future<void> updateTask(Task task) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dbService.updateTask(task);
      final index = _dailyTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _dailyTasks[index] = task;
      }
    } catch (e) {
      print("Görev güncellerken hata: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // updateTaskCompletion home_screen içinde hallediliyor gibi
  // Future<void> updateTaskCompletion(Task task, bool isCompleted) async {
  //   final updatedTask = task.copyWith(isCompleted: isCompleted);
  //   await updateTask(updatedTask);
  // }

  Future<void> updateActivity(ActivityRecord activity) async {
    if (activity.id == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      // caloriesBurned dahil güncelle
      await _dbService.updateActivity(activity);

      final index = _activities.indexWhere((a) => a.id == activity.id);
      if (index != -1) {
        _activities[index] = activity;
      }
      final allIndex = _allActivities.indexWhere((a) => a.id == activity.id);
      if (allIndex != -1) {
        _allActivities[allIndex] = activity;
      }
      notifyListeners();
    } catch (e) {
      print('Aktivite güncellerken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Bu metodlar istatistikler için faydalı
  Map<FitActivityType, int> getDurationsByType(
      {bool useAllActivities = false}) {
    final sourceList = useAllActivities ? _allActivities : _activities;
    Map<FitActivityType, int> durations = {};
    for (var activity in sourceList) {
      durations[activity.type] =
          (durations[activity.type] ?? 0) + activity.durationMinutes;
    }
    return durations;
  }

  Map<FitActivityType, double> getTotalCaloriesByType(
      {bool useAllActivities = false}) {
    final sourceList = useAllActivities ? _allActivities : _activities;
    Map<FitActivityType, double> calories = {};
    for (var activity in sourceList) {
      calories[activity.type] =
          (calories[activity.type] ?? 0.0) + (activity.caloriesBurned ?? 0.0);
    }
    return calories;
  }

  // Yardımcı metod
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // İstatistikler ekranı için mevcut tarih aralığını döndür
  ({DateTime? start, DateTime? end}) getCurrentDateRange() {
    return (start: _startDate, end: _endDate);
  }
}
