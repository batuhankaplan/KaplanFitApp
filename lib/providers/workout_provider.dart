import 'package:flutter/material.dart';
import '../models/workout_log.dart';
import '../models/exercise_log.dart';
import '../models/workout_set.dart';
import '../models/exercise_model.dart';
import '../services/database_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  List<WorkoutLog> _workoutLogs = [];
  bool _isLoading = false;
  WorkoutLog? _currentWorkoutLog; // For live tracking/building a workout
  List<WorkoutLog> _workoutHistory = [];

  List<WorkoutLog> get workoutLogs => _workoutLogs;
  bool get isLoading => _isLoading;
  WorkoutLog? get currentWorkoutLog => _currentWorkoutLog;
  List<WorkoutLog> get workoutHistory => _workoutHistory;

  WorkoutProvider(this._dbService) {
    _loadWorkoutHistory();
    _checkActiveWorkout();
  }

  Future<void> _checkActiveWorkout() async {
    // Implementation of _checkActiveWorkout method
  }

  Future<void> _loadWorkoutHistory() async {
    // Implementation of _loadWorkoutHistory method
  }

  Future<void> loadWorkoutLogs(DateTime start, DateTime end) async {
    _isLoading = true;
    notifyListeners();
    try {
      _workoutLogs = await _dbService.getWorkoutLogsInRange(start, end);
      print(
          "WorkoutProvider: ${_workoutLogs.length} workout log loaded for range.");
    } catch (e) {
      print("Error loading workout logs: $e");
      _workoutLogs = []; // Clear logs on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Live Workout Management ---

  Future<void> startNewWorkout(String name) async {
    if (_currentWorkoutLog != null) {
      print("Warning: Cannot start a new workout while one is in progress.");
      return;
    }
    _currentWorkoutLog = WorkoutLog(
      date: DateTime.now(),
      createdAt: DateTime.now(),
      exerciseLogs: [], // Start with empty exercises
    );
    print("New workout started (in memory).");
    notifyListeners();
  }

  void addExerciseToWorkout(Exercise exercise) {
    if (_currentWorkoutLog == null) return;
    // _currentWorkoutLog null olamayacağı için ! kullanımı güvenli.
    // exerciseLogs WorkoutLog içinde [] ile initialize edildiği için null olamaz.
    // final exerciseLogs = _currentWorkoutLog!.exerciseLogs ?? []; // Bu satır gereksizleşiyor

    final newExerciseLog = ExerciseLog(
      workoutLogId: -1, // Temporary ID, will be set during save
      exerciseId: exercise.id!,
      sortOrder:
          _currentWorkoutLog!.exerciseLogs!.length, // Direkt erişim güvenli
      createdAt: DateTime.now(),
      exerciseDetails: exercise, // Keep details for UI
      sets: [], // Start with empty sets - guaranteed non-null here
    );

    // exerciseLogs null olamayacağı için bu if/else bloğu basitleştirilebilir.
    _currentWorkoutLog!.exerciseLogs!.add(newExerciseLog);

    print("Exercise '${exercise.name}' added to current workout.");
    notifyListeners();
  }

  void addSetToExercise(int exerciseLogIndex, WorkoutSet set) {
    // Check currentWorkoutLog and its exerciseLogs list
    if (_currentWorkoutLog == null ||
        exerciseLogIndex >= _currentWorkoutLog!.exerciseLogs!.length) return;

    final exerciseLog = _currentWorkoutLog!.exerciseLogs![exerciseLogIndex];
    // Ensure sets list is not null before accessing length or adding
    final setNumber = exerciseLog.sets!.length + 1; // Direkt erişim güvenli

    final newSet = WorkoutSet(
      exerciseLogId: -1, // Temporary ID
      setNumber: setNumber,
      reps: set.reps,
      weight: set.weight,
      durationSeconds: set.durationSeconds,
      notes: set.notes,
      isCompleted: false, // Mark as not completed initially
      createdAt: DateTime.now(),
    );

    // Create a new list with the added set
    final updatedSets = [...exerciseLog.sets!, newSet]; // Direkt erişim güvenli
    // Update the exercise log with the new sets list
    _currentWorkoutLog!.exerciseLogs![exerciseLogIndex] =
        exerciseLog.copyWith(sets: updatedSets);

    print(
        "Set $setNumber added to exercise '${exerciseLog.exerciseDetails?.name}'.");
    notifyListeners();
  }

  void updateSetInExercise(int exerciseLogIndex, int setIndex, WorkoutSet set) {
    // Check currentWorkoutLog, its exerciseLogs list, and the specific exerciseLog's sets list
    if (_currentWorkoutLog == null ||
        exerciseLogIndex >= _currentWorkoutLog!.exerciseLogs!.length ||
        setIndex >=
            _currentWorkoutLog!.exerciseLogs![exerciseLogIndex].sets!.length)
      return;

    // Clone the sets list to make modifications safely
    final List<WorkoutSet> currentSets = List.from(_currentWorkoutLog!
        .exerciseLogs![exerciseLogIndex].sets!); // Non-null assertion ok
    final WorkoutSet setToUpdate = currentSets[setIndex];

    // Create a new set object with updated completion status
    final WorkoutSet updatedSet = setToUpdate.copyWith(
      isCompleted: set.isCompleted,
      reps: set.reps,
      weight: set.weight,
      durationSeconds: set.durationSeconds,
      notes: set.notes,
    );
    // Replace the old set in the cloned list
    currentSets[setIndex] = updatedSet;

    // Update the ExerciseLog with the modified sets list
    _currentWorkoutLog!.exerciseLogs![exerciseLogIndex] = _currentWorkoutLog!
        .exerciseLogs![exerciseLogIndex]
        .copyWith(sets: currentSets);

    print(
        "Set $setIndex updated for exercise '${_currentWorkoutLog!.exerciseLogs![exerciseLogIndex].exerciseDetails?.name}'.");
    notifyListeners();
  }

  void deleteSetFromExercise(int exerciseLogIndex, int setIndex) {
    // Check currentWorkoutLog and its exerciseLogs list
    if (_currentWorkoutLog == null ||
        exerciseLogIndex >= _currentWorkoutLog!.exerciseLogs!.length ||
        setIndex >=
            _currentWorkoutLog!.exerciseLogs![exerciseLogIndex].sets!.length)
      return;

    // Clone the sets list to make modifications safely
    final List<WorkoutSet> currentSets = List.from(_currentWorkoutLog!
        .exerciseLogs![exerciseLogIndex].sets!); // Non-null assertion ok
    currentSets.removeAt(setIndex);

    // Update the ExerciseLog with the modified sets list
    _currentWorkoutLog!.exerciseLogs![exerciseLogIndex] = _currentWorkoutLog!
        .exerciseLogs![exerciseLogIndex]
        .copyWith(sets: currentSets);

    print(
        "Set $setIndex deleted from exercise '${_currentWorkoutLog!.exerciseLogs![exerciseLogIndex].exerciseDetails?.name}'.");
    notifyListeners();
  }

  void deleteExerciseFromWorkout(int exerciseLogIndex) {
    // Check currentWorkoutLog and its exerciseLogs list
    if (_currentWorkoutLog == null ||
        exerciseLogIndex >= _currentWorkoutLog!.exerciseLogs!.length) return;

    // Clone the exerciseLogs list to make modifications safely
    final List<ExerciseLog> currentExerciseLogs =
        List.from(_currentWorkoutLog!.exerciseLogs!); // Non-null assertion ok
    currentExerciseLogs.removeAt(exerciseLogIndex);

    // Update the WorkoutLog with the modified exerciseLogs list
    _currentWorkoutLog =
        _currentWorkoutLog!.copyWith(exerciseLogs: currentExerciseLogs);

    print("Exercise $exerciseLogIndex deleted from workout.");
    notifyListeners();
  }

  void cancelWorkout() {
    if (_currentWorkoutLog == null) return;
    _currentWorkoutLog = null;
    print("Current workout cancelled.");
    notifyListeners();
  }

  Future<bool> saveWorkout(
      {String? notes,
      int? durationMinutes,
      int? rating,
      String? feeling}) async {
    if (_currentWorkoutLog == null ||
        _currentWorkoutLog!.exerciseLogs!.isEmpty) {
      print("Cannot save an empty workout.");
      _currentWorkoutLog = null; // Clear the cancelled/empty workout
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Finalize the main WorkoutLog details
      final workoutToSave = _currentWorkoutLog!.copyWith(
        durationMinutes: durationMinutes,
        notes: notes,
        rating: rating,
        feeling: feeling,
        // Ensure date/createdAt are set (should be from startNewWorkout)
      );

      // 1. Insert the main WorkoutLog entry to get its ID
      final int workoutLogId = await _dbService.insertWorkoutLog(workoutToSave);

      // 2. Insert each ExerciseLog and its Sets
      for (final exerciseLog in workoutToSave.exerciseLogs!) {
        // Null assertion ok after check
        // Insert ExerciseLog with the obtained workoutLogId
        final int exerciseLogId = await _dbService.insertExerciseLog(
            exerciseLog.copyWith(
                workoutLogId: workoutLogId), // Pass the correct workoutLogId
            workoutLogId // Redundant? Check insertExerciseLog signature
            );

        // Null check before iterating sets
        for (final set in exerciseLog.sets!) {
          // Null assertion ok after check
          // Ensure exerciseLogId is passed correctly
          await _dbService.insertWorkoutSet(
              set.copyWith(
                  exerciseLogId:
                      exerciseLogId), // Pass the correct exerciseLogId
              exerciseLogId // Redundant? Check insertWorkoutSet signature
              );
        }
      }

      print("Workout saved successfully with ID: $workoutLogId");
      _currentWorkoutLog = null; // Clear current workout after saving
      _isLoading = false;
      notifyListeners();
      // Optionally, reload logs for the current view
      // await loadWorkoutLogs(DateTime.now(), DateTime.now());
      return true;
    } catch (e) {
      print("Error saving workout: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Other Methods ---

  Future<void> deleteWorkout(int workoutLogId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dbService.deleteWorkoutLog(workoutLogId);
      _workoutLogs.removeWhere((log) => log.id == workoutLogId);
      print("WorkoutProvider: Workout log $workoutLogId deleted.");
    } catch (e) {
      print("Error deleting workout log $workoutLogId: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
