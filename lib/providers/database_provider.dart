import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DatabaseProvider with ChangeNotifier {
  late DatabaseService _database;
  bool _isInitialized = false;

  // Veritabanı servisi
  DatabaseService get database {
    if (!_isInitialized) {
      throw Exception('DatabaseProvider henüz başlatılmadı. Önce init() çağrılmalı.');
    }
    return _database;
  }

  // Başlatılıp başlatılmadığını kontrol et
  bool get isInitialized => _isInitialized;

  // Başlangıç fonksiyonu
  Future<void> init() async {
    if (_isInitialized) return;
    _database = DatabaseService();
    await _database.initialize();
    _isInitialized = true;
    notifyListeners();
  }
} 