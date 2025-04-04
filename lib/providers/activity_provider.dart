import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../models/activity_record.dart';
import '../models/task_type.dart';

class ActivityProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<ActivityRecord> _activities = [];
  List<DailyTask> _dailyTasks = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  String _dailyTasksDate = '';

  List<ActivityRecord> get activities => _activities;
  List<DailyTask> get dailyTasks => _dailyTasks;
  List<DailyTask> get tasks => _dailyTasks;
  bool get isLoading => _isLoading;
  String get dailyTasksDate => _dailyTasksDate;

  ActivityProvider() {
    loadActivitiesForSelectedDate();
    loadDailyTasks();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    loadActivitiesForSelectedDate();
  }

  Future<void> loadActivitiesForSelectedDate() async {
    _isLoading = true;
    notifyListeners();

    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );
    
    _activities = List.generate(maps.length, (i) {
      return ActivityRecord.fromMap(maps[i]);
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDailyTasks() async {
    _isLoading = true;
    notifyListeners();

    _dailyTasks = await _databaseService.getTasksForDay(DateTime.now());

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTasksForSelectedDate() async {
    _isLoading = true;
    notifyListeners();

    _dailyTasks = await _databaseService.getTasksForDay(_selectedDate);

    _isLoading = false;
    notifyListeners();
  }

  Future<int?> addActivity(ActivityRecord activity) async {
    _isLoading = true;
    notifyListeners();

    final db = await _databaseService.database;
    final id = await db.insert('activities', activity.toMap());
    
    final newActivity = ActivityRecord(
      id: id,
      type: activity.type,
      durationMinutes: activity.durationMinutes,
      date: activity.date,
      notes: activity.notes,
      taskId: activity.taskId,
    );
    
    _activities.add(newActivity);
    
    _isLoading = false;
    notifyListeners();
    
    return id;
  }

  Future<void> deleteActivity(int id) async {
    _isLoading = true;
    notifyListeners();

    final db = await _databaseService.database;
    await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    _activities.removeWhere((activity) => activity.id == id);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteActivityByTaskId(int? taskId) async {
    if (taskId == null) return;
    
    final db = await _databaseService.database;
    await db.delete(
      'activities',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
    
    await loadActivitiesForSelectedDate();
  }

  Future<int> addTask(DailyTask task) async {
    _isLoading = true;
    notifyListeners();

    final id = await _databaseService.insertTask(task);
    
    final newTask = task.copyWith(id: id);
    _dailyTasks.add(newTask);
    
    _isLoading = false;
    notifyListeners();
    
    return id;
  }

  Future<void> updateTask(DailyTask task) async {
    _isLoading = true;
    notifyListeners();

    await _databaseService.updateTask(task);
    
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
    _isLoading = true;
    notifyListeners();

    await _databaseService.updateActivity(activity);
    
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      _activities[index] = activity;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<List<ActivityRecord>> getActivitiesInRange(DateTime start, DateTime end) async {
    return await _databaseService.getActivitiesInRange(start, end);
  }

  Future<Map<FitActivityType, int>> getActivityTypeDurations() async {
    final Map<FitActivityType, int> durations = {};
    for (var type in FitActivityType.values) {
      durations[type] = 0;
    }

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
    );
    
    final ogleProgrami = DailyTask(
      title: 'Öğle Yemeği',
      description: 'Programınıza uygun öğle yemeğinizi yiyin',
      date: now,
      type: TaskType.lunch,
    );
    
    final aksamProgrami = DailyTask(
      title: 'Akşam Yemeği',
      description: 'Programınıza uygun akşam yemeğinizi yiyin',
      date: now,
      type: TaskType.dinner,
    );
    
    final aksamSporu = DailyTask(
      title: 'Akşam Sporu',
      description: 'Programınıza uygun akşam sporu yapın',
      date: now,
      type: TaskType.eveningExercise,
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
    );
    
    final ogleProgrami = DailyTask(
      title: 'Öğle Yemeği',
      description: 'Programınıza uygun öğle yemeğinizi yiyin',
      date: today,
      type: TaskType.lunch,
    );
    
    final aksamProgrami = DailyTask(
      title: 'Akşam Yemeği',
      description: 'Programınıza uygun akşam yemeğinizi yiyin',
      date: today,
      type: TaskType.dinner,
    );
    
    final aksamSporu = DailyTask(
      title: 'Akşam Sporu',
      description: 'Programınıza uygun akşam sporu yapın',
      date: today,
      type: TaskType.eveningExercise,
    );

    await addTask(sabahSporu);
    await addTask(ogleProgrami);
    await addTask(aksamProgrami);
    await addTask(aksamSporu);
  }
} 