import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/gamification_provider.dart';
import 'package:provider/provider.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final DatabaseService _databaseService;
  List<WeightRecord> _weightHistory = [];
  bool _isLoading = false;

  UserModel? get user => _user;
  List<WeightRecord> get weightHistory => _weightHistory;
  bool get isLoading => _isLoading;

  UserProvider(this._databaseService) {
    // loadUser(); // Kaldırıldı - artık main.dart'ta kontrollü yapılıyor
  }

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final int? activeUserId = prefs.getInt('activeUserId');

    debugPrint("[UserProvider] loadUser çağrıldı, activeUserId: $activeUserId");

    if (activeUserId != null) {
      debugPrint(
          "[UserProvider] activeUserId bulundu, veritabanından kullanıcı yükleniyor...");
      _user = await _databaseService.getUser(activeUserId);
      if (_user != null) {
        debugPrint(
            "[UserProvider] Kullanıcı yüklendi: ${_user!.name} (ID: ${_user!.id})");
        // Günlük su tüketimini veritabanından yükle
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay =
            DateTime(today.year, today.month, today.day, 23, 59, 59);

        try {
          final waterData = await _databaseService.getWaterLogInRange(
              startOfDay, endOfDay, _user!.id!);
          final todayWaterIntake = waterData[startOfDay] ?? 0;

          // Su tüketimini güncel veriye göre güncelle
          _user = _user!
              .copyWith(currentDailyWaterIntake: todayWaterIntake.toDouble());
          debugPrint(
              "[UserProvider] Su tüketimi veritabanından yüklendi: $todayWaterIntake ml");
        } catch (e) {
          debugPrint("[UserProvider] Su tüketimi yüklenirken hata: $e");
        }
      } else {
        debugPrint(
            "[UserProvider] activeUserId var ama kullanıcı bulunamadı, temizleniyor...");
        // activeUserId var ama kullanıcı bulunamadıysa temizle
        await prefs.remove('activeUserId');
        _user = null;
      }
    } else {
      debugPrint("[UserProvider] activeUserId bulunamadı, kullanıcı null");
      _user = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveUser(UserModel userToSave,
      {bool isLoginOrRegister = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      UserModel userWithId = userToSave;
      if (userToSave.id == null) {
        final newId = await _databaseService.insertUser(userToSave);
        userWithId = userToSave.copyWith(id: newId);
      } else {
        await _databaseService.updateUser(userToSave);
      }
      _user = userWithId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('activeUserId', _user!.id!);

      // Su tüketimi için son log tarihini GÜNCELLEME, eğer logWater'dan geliyorsa zaten güncellendi.
      // Login/Register durumunda zaten aşağıdaki blokta sıfırlanıyor.
      // final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      // await prefs.setString('lastWaterLogDate_$_user!.id', todayDate); // KALDIRILDI - logWater ele alacak

      if (isLoginOrRegister) {
        // Yeni kayıt veya giriş ise, günlük su tüketimini sıfırla
        // Bu sıfırlama aynı zamanda lastWaterLogDate'i de güncellemeli
        final String todayDate =
            DateFormat('yyyy-MM-dd').format(DateTime.now());
        _user = _user!.copyWith(currentDailyWaterIntake: 0.0);
        await _databaseService.updateUser(_user!); // Veritabanında da sıfırla
        await prefs.setString('lastWaterLogDate_$_user!.id', todayDate);
      }
      // _resetWaterIntakeIfNeeded(); // KALDIRILDI - Bu çağrı buradan kaldırıldı.
    } catch (e) {
      debugPrint("UserProvider saveUser Hata: $e");
      // Hata yönetimi eklenebilir
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginUser(String name) async {
    // Bu metot örnek olarak bırakıldı, gerçek login mekanizması farklı olabilir.
    _isLoading = true;
    notifyListeners();
    UserModel? foundUser = await _databaseService.getUserByName(name);
    if (foundUser != null) {
      await saveUser(foundUser.copyWith(/* lastLogin: DateTime.now() */),
          isLoginOrRegister: true);
    } else {
      // Kullanıcı bulunamadı hatası
      _isLoading = false;
      notifyListeners();
      throw Exception('Kullanıcı bulunamadı');
    }
  }

  Future<void> registerUser(UserModel newUser) async {
    // Bu metot örnek olarak bırakıldı, gerçek register mekanizması farklı olabilir.
    await saveUser(
        newUser.copyWith(
            createdAt: DateTime.now() /*, lastLogin: DateTime.now() */),
        isLoginOrRegister: true);
  }

  Future<void> logoutUser() async {
    debugPrint("[UserProvider] logoutUser çağrıldı");
    final int? userIdToDeleteChats = _user?.id;

    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeUserId');
    debugPrint("[UserProvider] activeUserId SharedPreferences'dan silindi");

    if (userIdToDeleteChats != null) {
      try {
        await _databaseService
            .deleteAllChatConversationsForUser(userIdToDeleteChats);
        debugPrint(
            "[UserProvider] Kullanıcı $userIdToDeleteChats için tüm konuşmalar silindi.");
      } catch (e) {
        debugPrint("[UserProvider] Konuşmalar silinirken hata: $e");
      }
    }
    notifyListeners();
  }

  // YENİ: Günlük su tüketimini kaydetmek için metot
  Future<void> logWater(double amountInMl, BuildContext context) async {
    if (_user == null) return;

    _isLoading = true;
    // notifyListeners(); // Başlangıçta değil, sonunda

    final prefs = await SharedPreferences.getInstance();
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String lastWaterLogDateKey = 'lastWaterLogDate_${_user!.id}';
    final String lastWaterLogDate = prefs.getString(lastWaterLogDateKey) ?? '';

    double currentIntake = _user!.currentDailyWaterIntake;

    if (lastWaterLogDate != todayDate) {
      // Yeni bir gün, mevcut tüketimi sıfırla
      debugPrint(
          "[UserProvider] New day detected for water log. Resetting intake for user ${_user!.id}.");
      currentIntake = 0.0;
      // Bu yeni gün bilgisini hemen SharedPreferences'a yazalım ki sonraki logWater çağrıları doğru çalışsın.
      await prefs.setString(lastWaterLogDateKey, todayDate);
    }

    final newTotalWater = currentIntake + amountInMl;
    _user = _user!.copyWith(
        currentDailyWaterIntake: newTotalWater.clamp(0.0, 10000.0)); // Max 10L

    try {
      // Önce water_log tablosuna güncel toplamı kaydet
      await _databaseService.insertOrUpdateWaterLog(
          DateTime.now(),
          newTotalWater.round(), // amount_ml INTEGER olduğu için yuvarla
          _user!.id!);
      // Sonra user modelini ve users tablosunu güncelle
      await _databaseService.updateUser(_user!);

      debugPrint(
          "[UserProvider] Water logged: $amountInMl ml. New total: $newTotalWater ml for user ${_user!.id}");

      // Su hedefi rozetlerini kontrol et
      final targetIntakeLiters = _user!.targetWaterIntake;
      if (targetIntakeLiters != null && targetIntakeLiters > 0) {
        final targetIntakeMl = targetIntakeLiters * 1000;
        final bool goalAchieved = newTotalWater >= targetIntakeMl;

        if (context.mounted) {
          final gamificationProvider =
              Provider.of<GamificationProvider>(context, listen: false);
        // updateStreak, günün ilk loglamasında false ile çağrılsa bile, o günkü durumu doğru yansıtacaktır.
        // Eğer o gün daha önce true ile çağrıldıysa ve sonraki loglamada hedefin altına düşülürse,
        // updateStreak mantığı seriyi kırmamalı, sadece o günkü "isCompleted" durumunu false yapmalı.
        // Ancak mevcut updateStreak, isCompleted false ise seriyi direkt sıfırlıyor gibi.
        // Bu yüzden, sadece hedefe ulaşıldığında true ile çağıralım.
        // Eğer gün içinde hedefin altına düşülürse ve tekrar üstüne çıkılırsa seri devam eder.
        // Gün sonunda hedefin altında kalınırsa, ertesi günkü ilk loglamada updateStreak false ile çağrılır ve seri kırılır.
        // Bu yaklaşım daha basit.
        if (goalAchieved) {
          await gamificationProvider.updateStreak('water', true);
          debugPrint(
              "[UserProvider] Water goal achieved for today. Streak updated.");
        } else {
          // Hedefe henüz ulaşılmadıysa veya altına düşüldüyse, updateStreak'i false ile çağırmak seriyi kırabilir.
          // updateStreak'in kendisi zaten lastUpdate kontrolü yapıyor. Gün içinde birden fazla çağrılması sorun olmamalı.
          // Eğer gün içinde hedefe ulaşılıp sonra altına düşülürse, seri korunmalı.
          // Sadece gün sonunda hedefin altında kalındıysa, ertesi günkü log'da seri kırılmalı.
          // Bu nedenle, burada false ile çağırmayalım. updateStreak('water', false) sadece gün başında veya hiç su içilmediğinde mantıklı.
          // Şimdilik sadece hedefe ulaşıldığında true gönderiyoruz.
          // GamificationProvider._syncWaterConsumption daha kapsamlı bir kontrol yapabilir.
          debugPrint(
              "[UserProvider] Water goal NOT YET achieved for today ($newTotalWater ml / $targetIntakeMl ml).");
        }
      }
    }
    } catch (e) {
      debugPrint("[UserProvider] Error logging water: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // Değişikliği bildir
    }
  }

  Future<UserModel?> getUserById(int id) async {
    return await _databaseService.getUser(id);
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
      debugPrint("[UserProvider] Ağırlık kaydı eklendi: $recordId");

      // Update user's current weight and last weight update time
      _user = _user!.copyWith(
        weight: weight,
        lastWeightUpdate: DateTime.now(),
      );

      // Update database with the new user information
      await _databaseService.updateUser(_user!);
      debugPrint(
          "[UserProvider] Kullanıcının mevcut ağırlığı güncellendi: $weight");

      // Reload weight history from the database
      _weightHistory = await _databaseService.getWeightHistory(_user!.id!);

      notifyListeners();
    } catch (e) {
      debugPrint("[UserProvider] addWeightRecord HATA: $e");
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

  // YENİ: Kullanıcıyı tamamen sil ve tüm verilerini temizle
  Future<void> deleteUserCompletely() async {
    if (_user?.id == null) return;

    debugPrint("[UserProvider] Kullanıcı tamamen siliniyor: ${_user!.id}");

    final prefs = await SharedPreferences.getInstance();
    final userId = _user!.id!;

    try {
      // 1. Veritabanından kullanıcıyı ve tüm ilgili verilerini sil
      await _databaseService.deleteUserCompletely(userId);

      // 2. SharedPreferences'dan tüm kullanıcı verilerini temizle
      await prefs.clear(); // Tüm tercihleri temizle

      // 3. Memory'deki kullanıcı bilgilerini temizle
      _user = null;
      _weightHistory = [];

      debugPrint("[UserProvider] Kullanıcı tamamen silindi: $userId");
      notifyListeners();
    } catch (e) {
      debugPrint("[UserProvider] Kullanıcı silinirken hata: $e");
      throw Exception('Kullanıcı silinirken bir hata oluştu: $e');
    }
  }

  // YENİ: Uygulamayı tamamen sıfırla (fabrika ayarları)
  Future<void> resetApp() async {
    debugPrint("[UserProvider] Uygulama sıfırlanıyor...");

    try {
      // 1. Mevcut kullanıcıyı sil
      if (_user != null) {
        await deleteUserCompletely();
      }

      // 2. SharedPreferences'ı tamamen temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. Veritabanını tamamen temizle
      await _databaseService.clearAllData();

      // 4. Memory'deki tüm verileri temizle
      _user = null;
      _weightHistory = [];
      _isLoading = false;

      // 5. Onboarding'i tekrar gösterilmesi için temizle
      // (SharedPreferences.clear() zaten bunu yapıyor ama açık olması için)
      await prefs.setBool('onboarding_completed', false);

      debugPrint("[UserProvider] Uygulama başarıyla sıfırlandı");
      notifyListeners();
    } catch (e) {
      debugPrint("[UserProvider] Uygulama sıfırlanırken hata: $e");
      throw Exception('Uygulama sıfırlanırken bir hata oluştu: $e');
    }
  }
}
