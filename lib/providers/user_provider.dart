import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final DatabaseService _databaseService;
  List<WeightRecord> _weightHistory = [];
  bool _isLoading = false;

  UserModel? get user => _user;
  List<WeightRecord> get weightHistory => _weightHistory;
  bool get isLoading => _isLoading;

  UserProvider(this._databaseService) {
    // loadUser(); // Otomatik yüklemeyi kaldırıyoruz, main'deki FutureBuilder yapacak
  }

  Future<bool> loadUser() async {
    print("[UserProvider] loadUser çağrıldı."); // LOG: Metot başlangıcı
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLoading) {
        _isLoading = true;
        // notifyListeners(); // FutureBuilder için gerekli değil, kaldırılabilir
      }
    });
    bool userLoaded = false;

    try {
      // Aktif kullanıcı ID'sini SharedPreferences'den al
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('activeUserId');

      UserModel? user;

      if (userId != null) {
        // Belirli ID'ye sahip kullanıcıyı getir
        user = await _databaseService.getUser(userId);
        print(
            "[UserProvider] ID ile kullanıcı yükleme: $userId -> ${user?.name}");
      } else {
        // Eğer aktif kullanıcı ID'si yoksa, ilk kullanıcıyı getir
        user = await _databaseService.getFirstUser();
        print("[UserProvider] İlk kullanıcı yükleme: ${user?.name}");

        // İlk kullanıcının ID'sini aktiflenen kullanıcı ID'si olarak kaydet
        if (user != null && user.id != null) {
          await prefs.setInt('activeUserId', user.id!);
          print("[UserProvider] Aktif kullanıcı ID'si kaydedildi: ${user.id}");
        }
      }

      if (user != null) {
        _user = user;
        _weightHistory = user.weightHistory;
        userLoaded = true;
        print("[UserProvider] Kullanıcı yüklendi: ${user.name}");
      } else {
        _user = null;
        _weightHistory = [];
        print("[UserProvider] Kullanıcı bulunamadı.");
      }
    } catch (e) {
      print("[UserProvider] loadUser HATA: $e");
      _user = null;
      _weightHistory = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return userLoaded;
  }

  Future<void> saveUser(UserModel user) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (user.id != null) {
        // Mevcut kullanıcıyı güncelle
        await _databaseService.updateUser(user);
        print("[UserProvider] Kullanıcı güncellendi: ${user.id}");
      } else {
        // Yeni kullanıcı oluştur
        final id = await _databaseService.insertUser(user);
        user = user.copyWith(id: id); // ID ile kullanıcıyı güncelle
        print("[UserProvider] Yeni kullanıcı oluşturuldu: $id");

        // Yeni kullanıcının ID'sini aktif kullanıcı olarak kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('activeUserId', id);
        print("[UserProvider] Aktif kullanıcı ID'si kaydedildi: $id");
      }

      // Ağırlık kayıtlarını ekle
      if (user.id != null && user.weightHistory.isNotEmpty) {
        // En son ağırlık kaydı varsa veritabanına ekle
        final lastWeight = user.weightHistory.first; // İlk kayıt en son eklenen
        await _databaseService.insertWeightRecord(lastWeight, user.id!);
        print("[UserProvider] Ağırlık kaydı eklendi: ${lastWeight.weight} kg");
      }

      _user = user;
      _weightHistory = await _databaseService.getWeightHistory(user.id!);
    } catch (e) {
      print("[UserProvider] saveUser HATA: $e");
      throw e; // Hatanın yukarı çıkmasına izin ver (UI'da gösterilmesi için)
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Yeni: Çıkış yapma (logout) metodu
  Future<void> logout() async {
    try {
      // SharedPreferences'den aktif kullanıcı ID'sini temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('activeUserId');

      // Mevcut kullanıcı verilerini temizle
      _user = null;
      _weightHistory = [];

      print("[UserProvider] Kullanıcı çıkış yaptı.");
      notifyListeners();
    } catch (e) {
      print("[UserProvider] logout HATA: $e");
      throw e;
    }
  }

  Future<void> addWeightRecord(double weight) async {
    if (_user == null || _user!.id == null) return;

    try {
      final record = WeightRecord(
        weight: weight,
        date: DateTime.now(),
      );

      final recordId =
          await _databaseService.insertWeightRecord(record, _user!.id!);
      print("[UserProvider] Ağırlık kaydı eklendi: $recordId");

      // Update user's current weight and last weight update time
      _user = _user!.copyWith(
        weight: weight,
        lastWeightUpdate: DateTime.now(),
      );

      // Update database with the new user information
      await _databaseService.updateUser(_user!);
      print("[UserProvider] Kullanıcının mevcut ağırlığı güncellendi: $weight");

      // Reload weight history from the database
      _weightHistory = await _databaseService.getWeightHistory(_user!.id!);

      notifyListeners();
    } catch (e) {
      print("[UserProvider] addWeightRecord HATA: $e");
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

    await loadUser(); // Yeniden tüm verileri yükle
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
