import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../models/activity_record.dart';
import '../models/task_type.dart';
import 'package:flutter/foundation.dart';

class ActivityProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<ActivityRecord> _activities = [];
  List<ActivityRecord> _allActivities = []; // Tüm aktiviteler
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate; // Tarih aralığı başlangıcı
  DateTime? _endDate; // Tarih aralığı sonu
  List<DailyTask> _dailyTasks = [];
  String _dailyTasksDate = '';

  List<ActivityRecord> get activities => _activities;
  List<DailyTask> get dailyTasks => _dailyTasks;
  List<DailyTask> get tasks => _dailyTasks;
  bool get isLoading => _isLoading;
  String get dailyTasksDate => _dailyTasksDate;

  ActivityProvider() {
    refreshActivities();
    loadDailyTasks();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    refreshActivities();
  }

  Future<void> refreshActivities() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Seçili gün için aktiviteleri veritabanından çek
      _activities = await _db.getActivitiesForDay(_selectedDate);
      notifyListeners();
      
      // Tüm aktiviteleri de çekelim istatistikler için
      await _loadAllActivities();
    } catch (e) {
      print('Aktiviteleri yenilerken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAllActivities() async {
    try {
      // Eğer başlangıç ve bitiş tarihleri belirlenmişse aralıktaki verileri al
      if (_startDate != null && _endDate != null) {
        _allActivities = await _db.getActivitiesInRange(_startDate!, _endDate!);
      } else {
        // Bir yıllık geçmiş verileri al (varsayılan)
        final endDate = DateTime.now();
        final startDate = endDate.subtract(Duration(days: 365));
        _allActivities = await _db.getActivitiesInRange(startDate, endDate);
      }
    } catch (e) {
      print('Tüm aktiviteleri yüklerken hata: $e');
    }
  }

  void setDateRange(DateTime startDate, DateTime endDate) {
    _startDate = startDate;
    _endDate = endDate;
    _loadAllActivities(); // Yeni tarih aralığına göre verileri yükle
  }

  List<ActivityRecord> getAllActivities() {
    return _allActivities;
  }

  Future<void> loadDailyTasks() async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    if (_dailyTasksDate == todayString) {
      return; // Bugünkü görevler zaten yüklü
    }
    
    _isLoading = true;
    notifyListeners();
    
    _dailyTasks = await _db.getTasksForDay(DateTime.now());
    _dailyTasksDate = todayString;
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTasksForSelectedDate() async {
    _isLoading = true;
    notifyListeners();

    _dailyTasks = await _db.getTasksForDay(_selectedDate);

    _isLoading = false;
    notifyListeners();
  }

  Future<int?> addActivity(ActivityRecord activity) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await _db.insertActivity(activity);
      final newActivity = ActivityRecord(
        id: id,
        type: activity.type,
        durationMinutes: activity.durationMinutes,
        date: activity.date,
        notes: activity.notes,
        taskId: activity.taskId,
      );
      
      // Eklenen aktivite bugüne aitse listeye ekle
      if (_isSameDay(activity.date, _selectedDate)) {
        _activities.add(newActivity);
      }
      
      // Tüm aktivitelere ekle
      _allActivities.add(newActivity);
      
      notifyListeners();
      
      return id;
    } catch (e) {
      print('Aktivite eklerken hata: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteActivity(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.deleteActivity(id);
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

  Future<void> deleteActivityByTaskId(int? taskId) async {
    if (taskId == null) return;
    
    try {
      await _db.deleteActivityByTaskId(taskId);
      refreshActivities(); // Aktiviteleri yenile
    } catch (e) {
      print('Task ID\'ye göre aktivite silerken hata: $e');
    }
  }

  Future<int> addTask(DailyTask task) async {
    _isLoading = true;
    notifyListeners();

    final id = await _db.insertTask(task);
    
    final newTask = task.copyWith(id: id);
    _dailyTasks.add(newTask);
    
    _isLoading = false;
    notifyListeners();
    
    return id;
  }

  Future<void> updateTask(DailyTask task) async {
    _isLoading = true;
    notifyListeners();

    await _db.updateTask(task);
    
    final index = _dailyTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _dailyTasks[index] = task;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTaskCompletion(DailyTask task, bool isCompleted) async {
    final updatedTask = task.copyWith(isCompleted: isCompleted);
    await updateTask(updatedTask);
  }

  Future<void> updateActivity(ActivityRecord activity) async {
    if (activity.id == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _db.updateActivity(activity);
      
      // Düzenlenen aktivite seçili günde ise güncelle
      final index = _activities.indexWhere((a) => a.id == activity.id);
      if (index != -1) {
        _activities[index] = activity;
      }
      
      // Tüm aktivitelerde güncelle
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

  Future<List<ActivityRecord>> getActivitiesInRange(DateTime start, DateTime end) async {
    return await _db.getActivitiesInRange(start, end);
  }

  Map<FitActivityType, int> getDurationsByType() {
    Map<FitActivityType, int> durations = {};
    
    for (var activity in _activities) {
      durations[activity.type] = (durations[activity.type] ?? 0) + activity.durationMinutes;
    }
    
    return durations;
  }

  Future<void> resetDailyTasks(String today) async {
    _isLoading = true;
    notifyListeners();

    _dailyTasksDate = today;
    
    final now = DateTime.now();
    
    final sabahSporu = DailyTask(
      title: 'Sabah Sporu',
      description: 'Günün sabah spor aktivitesini yapın',
      date: now,
      type: TaskType.morningExercise,
      isCompleted: false,
    );
    
    final ogleProgrami = DailyTask(
      title: 'Öğle Yemeği',
      description: 'Programınıza uygun öğle yemeğinizi yiyin',
      date: now,
      type: TaskType.lunch,
      isCompleted: false,
    );
    
    final aksamProgrami = DailyTask(
      title: 'Akşam Yemeği',
      description: 'Programınıza uygun akşam yemeğinizi yiyin',
      date: now,
      type: TaskType.dinner,
      isCompleted: false,
    );
    
    final aksamSporu = DailyTask(
      title: 'Akşam Sporu',
      description: 'Programınıza uygun akşam sporu yapın',
      date: now,
      type: TaskType.eveningExercise,
      isCompleted: false,
    );

    await addTask(sabahSporu);
    await addTask(ogleProgrami);
    await addTask(aksamProgrami);
    await addTask(aksamSporu);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createDefaultTasks() async {
    final today = DateTime.now();
    final sabahSporu = DailyTask(
      title: 'Sabah Sporu',
      description: 'Günün sabah spor aktivitesini yapın',
      date: today,
      type: TaskType.morningExercise,
      isCompleted: false,
    );
    
    final ogleProgrami = DailyTask(
      title: 'Öğle Yemeği',
      description: 'Programınıza uygun öğle yemeğinizi yiyin',
      date: today,
      type: TaskType.lunch,
      isCompleted: false,
    );
    
    final aksamProgrami = DailyTask(
      title: 'Akşam Yemeği',
      description: 'Programınıza uygun akşam yemeğinizi yiyin',
      date: today,
      type: TaskType.dinner,
      isCompleted: false,
    );
    
    final aksamSporu = DailyTask(
      title: 'Akşam Sporu',
      description: 'Programınıza uygun akşam sporu yapın',
      date: today,
      type: TaskType.eveningExercise,
      isCompleted: false,
    );

    await addTask(sabahSporu);
    await addTask(ogleProgrami);
    await addTask(aksamProgrami);
    await addTask(aksamSporu);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
} 