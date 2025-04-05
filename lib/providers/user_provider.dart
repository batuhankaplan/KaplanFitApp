import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final DatabaseService _databaseService = DatabaseService();
  List<WeightRecord> _weightHistory = [];
  bool _isLoading = false;

  UserModel? get user => _user;
  List<WeightRecord> get weightHistory => _weightHistory;
  bool get isLoading => _isLoading;

  UserProvider() {
    // Otomatik çağrıyı kaldırdık
  }

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _databaseService.getUser();
      
      if (_user != null && _user!.id != null) {
        _weightHistory = await _databaseService.getWeightHistory(_user!.id!);
        _user = _user!.copyWith(weightHistory: _weightHistory);
      }
    } catch (e) {
      print('Kullanıcı yükleme hatası: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (user.id == null) {
        final id = await _databaseService.insertUser(user);
        _user = user.copyWith(id: id);
      } else {
        await _databaseService.updateUser(user);
        _user = user;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateWeight(double newWeight) async {
    if (_user == null || _user!.id == null) return;

    _isLoading = true;
    notifyListeners();

    WeightRecord record = WeightRecord(
      weight: newWeight,
      date: DateTime.now(),
    );

    await _databaseService.insertWeightRecord(record, _user!.id!);
    
    _user = _user!.copyWith(
      weight: newWeight,
      lastWeightUpdate: DateTime.now(),
    );
    
    await _databaseService.updateUser(_user!);
    
    await loadUser();  // Yeniden tüm verileri yükle
  }

  // Kullanıcı bilgilerini temizle
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Kullanıcı bilgilerini temizle
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_height');
    await prefs.remove('user_weight');
    await prefs.remove('user_age');
    await prefs.remove('user_gender');
    await prefs.remove('user_goal');
    await prefs.remove('user_activity_level');
    await prefs.remove('user_profile_image');
    
    // Kullanıcı modelini sıfırla
    _user = null;
    notifyListeners();
  }
} 