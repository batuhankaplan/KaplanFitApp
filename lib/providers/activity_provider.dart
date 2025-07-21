import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../services/database_service.dart';
import '../models/activity_record.dart';
import '../models/task_type.dart';

import '../providers/gamification_provider.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart'; // UserProvider importu

class ActivityProvider with ChangeNotifier {
  final DatabaseService _dbService;
  final UserProvider _userProvider; // Eklendi
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
        0, (sum, activity) => sum + activity.durationMinutes);
  }

  ActivityProvider(this._dbService, this._userProvider) {
    // _userProvider eklendi
    // UserProvider artık constructor'da alındığı için, başlangıç yüklemeleri yapılabilir.
    // Ancak, _userProvider.user null olabilir, bu yüzden null check önemli.
    if (_userProvider.user?.id != null) {
      refreshActivities();
    }
    loadDailyTasks();
  }

  void setSelectedDate(DateTime date) {
    // userId parametresi kaldırıldı
    _selectedDate = date;
    if (_userProvider.user?.id != null) {
      refreshActivities();
    }
  }

  Future<void> refreshActivities() async {
    // userId parametresi kaldırıldı
    final userId = _userProvider.user?.id;
    if (userId == null) {
      _activities = [];
      _allActivities = [];
      _isLoading = false;
      notifyListeners();
      debugPrint(
          'ActivityProvider: Kullanıcı ID bulunamadığı için aktiviteler yüklenemedi.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _activities = await _dbService.getActivitiesForDay(_selectedDate, userId);
      _activities.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      await _loadAllActivities(); // userId parametresi kaldırıldı
    } catch (e) {
      debugPrint('Aktiviteleri yenilerken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAllActivities() async {
    // userId parametresi kaldırıldı
    final userId = _userProvider.user?.id;
    if (userId == null) {
      _allActivities = [];
      debugPrint(
          'ActivityProvider: Kullanıcı ID bulunamadığı için tüm aktiviteler yüklenemedi.');
      return;
    }
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
          effectiveStartDate, effectiveEndDate, userId);
      _allActivities.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Tüm aktiviteleri yüklerken hata: $e');
      _allActivities = [];
    }
  }

  void setDateRange(DateTime startDate, DateTime endDate) {
    // userId parametresi kaldırıldı
    _startDate = startDate;
    _endDate = endDate;
    if (_userProvider.user?.id != null) {
      refreshActivities();
    }
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
      debugPrint("Günlük görevler yüklenirken hata: $e");
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
  //     debugPrint("Seçili gün görevleri yüklenirken hata: $e");
  //     _dailyTasks = [];
  //   }
  //   _isLoading = false;
  //   notifyListeners();
  // }

  Future<int?> addActivity(
      ActivityRecord activity, BuildContext context) async {
    // userId parametresi kaldırıldı
    final userId = _userProvider.user?.id;
    if (userId == null) {
      debugPrint(
          'ActivityProvider: Aktivite eklenemedi, kullanıcı ID bulunamadı.');
      return null;
    }
    _isLoading = true;
    notifyListeners();
    int? id;
    try {
      // caloriesBurned dahil veritabanına ekle
      final activityWithUserId =
          activity.copyWith(userId: userId); // Ensure userId is in the record
      id = await _dbService.insertActivity(activityWithUserId, userId);

      final newActivityWithId = ActivityRecord(
        id: id,
        type: activity.type,
        durationMinutes: activity.durationMinutes,
        date: activity.date,
        notes: activity.notes,
        caloriesBurned: activity.caloriesBurned,
        taskId: activity.taskId,
        userId: userId, // Burası _userProvider.user.id olacak
        isFromProgram: activity.isFromProgram,
      );

      if (_isSameDay(activity.date, _selectedDate)) {
        _activities.add(newActivityWithId);
        _activities.sort((a, b) => b.date.compareTo(a.date));
      }
      _allActivities.add(newActivityWithId);
      _allActivities.sort((a, b) => b.date.compareTo(a.date));

      // Eğer aktivite bir programdan ise rozetleri kontrol et
      if (activity.isFromProgram && context.mounted) {
        final gamificationProvider =
            Provider.of<GamificationProvider>(context, listen: false);
        await gamificationProvider.recordProgramWorkoutCompleted(userId, id);
        debugPrint(
            "ActivityProvider: Called recordProgramWorkoutCompleted for activity ID $id");
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Aktivite eklerken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return id;
  }

  /// Samsung Health'ten senkronize edilen aktiviteleri ekler veya günceller
  Future<void> addOrUpdateSyncedActivity(ActivityRecord activity) async {
    final userId = _userProvider.user?.id;
    if (userId == null) {
      debugPrint('ActivityProvider: Senkronize aktivite eklenemedi, kullanıcı ID bulunamadı.');
      return;
    }

    try {
      // ID'nin benzersiz olduğunu kontrol et - eğer zaten varsa güncelle
      final existingActivityIndex = _allActivities.indexWhere(
        (existing) => existing.id == activity.id,
      );

      final activityWithUserId = activity.copyWith(userId: userId);

      if (existingActivityIndex != -1) {
        // Mevcut aktiviteyi güncelle
        _allActivities[existingActivityIndex] = activityWithUserId;
        
        // Eğer seçili gündeyse görünür listeyi de güncelle
        if (_isSameDay(activity.date, _selectedDate)) {
          final visibleActivityIndex = _activities.indexWhere(
            (existing) => existing.id == activity.id,
          );
          if (visibleActivityIndex != -1) {
            _activities[visibleActivityIndex] = activityWithUserId;
          }
        }
      } else {
        // Yeni aktivite ekle
        _allActivities.add(activityWithUserId);
        _allActivities.sort((a, b) => b.date.compareTo(a.date));

        // Eğer seçili gündeyse görünür listeye de ekle
        if (_isSameDay(activity.date, _selectedDate)) {
          _activities.add(activityWithUserId);
          _activities.sort((a, b) => b.date.compareTo(a.date));
        }
      }

      // Veritabanına kaydet/güncelle (Samsung Health'ten gelen veriler için ayrı tablo kullanılabilir)
      // Bu kısım database service'te uygun metodlar eklendikten sonra aktif edilebilir
      
      notifyListeners();
      debugPrint('Samsung Health aktivitesi senkronize edildi: ${activity.type}');
      
    } catch (e) {
      debugPrint('Samsung Health aktivitesi senkronize edilirken hata: $e');
    }
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
      debugPrint('Aktivite silerken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteActivityByTaskId(int? taskId) async {
    // userId parametresi kaldırıldı
    final userId = _userProvider.user?.id;
    if (userId == null) {
      debugPrint(
          'ActivityProvider: Task ID ile aktivite silinemedi, kullanıcı ID bulunamadı.');
      return;
    }
    if (taskId == null) return;
    try {
      await _dbService.deleteActivityByTaskId(taskId);
      // Silme işleminden sonra aktiviteleri yenilemek için userId gerekir.
      refreshActivities();
    } catch (e) {
      debugPrint('Error deleting activity by taskId $taskId: $e');
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
      debugPrint("Görev eklerken hata: $e");
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
      debugPrint("Görev güncellerken hata: $e");
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
      debugPrint('Aktivite güncellerken hata: $e');
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
