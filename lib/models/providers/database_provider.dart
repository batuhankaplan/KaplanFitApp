import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/program_service.dart';
import '../activity_record.dart';
import '../meal_record.dart';

class DatabaseProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final ProgramService _programService = ProgramService();
  
  List<ActivityRecord> _activities = [];
  List<MealRecord> _meals = [];
  String? _userGoalMessage;
  
  ProgramService get programService => _programService;
  
  List<ActivityRecord> get activities => _activities;
  List<MealRecord> get meals => _meals;
  String? get userGoalMessage => _userGoalMessage;

  // Getter for accessing the database service
  DatabaseService get database => _databaseService;
  
  DatabaseProvider() {
    // Future<void> init() async {}
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    print('DatabaseProvider: Listeners notified');
  }
} 