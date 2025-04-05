import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class DatabaseProvider with ChangeNotifier {
  final DatabaseService _database = DatabaseService();
  
  // Getter for accessing the database service
  DatabaseService get database => _database;
  
  DatabaseProvider() {
    // Future<void> init() async {}
  }
} 