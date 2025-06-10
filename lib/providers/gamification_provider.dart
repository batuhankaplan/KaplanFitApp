import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/badge_model.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import 'user_provider.dart'; // UserProvider importu

class GamificationProvider with ChangeNotifier {
  final List<BadgeModel> _badges = [];
  Map<String, int> _streaks = {}; // Aktivite türüne göre seriler
  int _totalPoints = 0;
  bool _isLoading = true;
  int _workoutCount = 0;
  double _weightLossKg = 0.0;
  int _chatInteractionCount = 0;
  bool _weeklyGoalCompleted = false;
  bool _monthlyGoalCompleted = false;
  bool _yearlyGoalCompleted = false;

  final DatabaseService _dbService; // Değiştirildi
  final UserProvider _userProvider; // Eklendi

  // Constructor eklendi
  GamificationProvider(this._dbService, this._userProvider) {
    // initialize(); // initialize çağrısı main.dart içinde yapılabilir veya burada kalabilir.
    // Şimdilik burada bırakalım, main.dart'taki çağrıyı kaldırırız.
    initialize();
  }

  // Getter'lar
  List<BadgeModel> get badges => _badges;
  Map<String, int> get streaks => _streaks;
  int get totalPoints => _totalPoints;
  bool get isLoading => _isLoading;
  int get workoutCount => _workoutCount;
  double get weightLossKg => _weightLossKg;
  int get chatInteractionCount => _chatInteractionCount;
  bool get weeklyGoalCompleted => _weeklyGoalCompleted;
  bool get monthlyGoalCompleted => _monthlyGoalCompleted;
  bool get yearlyGoalCompleted => _yearlyGoalCompleted;

  // Kilidi açılmış rozetler
  List<BadgeModel> get unlockedBadges =>
      _badges.where((badge) => badge.isUnlocked).toList();

  // Kilidi açılmamış rozetler
  List<BadgeModel> get lockedBadges =>
      _badges.where((badge) => !badge.isUnlocked).toList();

  // Rozetleri türe göre filtreleme
  List<BadgeModel> getBadgesByType(BadgeType type) =>
      _badges.where((badge) => badge.type == type).toList();

  // Provider'ı başlat
  Future<void> initialize() async {
    _isLoading = true;

    try {
      await _loadDefaultBadges();
      await _loadData();
    } catch (e) {
      debugPrint('GamificationProvider initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verileri yükle
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Puanları yükle
    _totalPoints = prefs.getInt('totalPoints') ?? 0;

    // Serileri yükle
    final dailyStreak = prefs.getInt('dailyStreak') ?? 0;
    final waterStreak = prefs.getInt('waterStreak') ?? 0;
    final workoutStreak = prefs.getInt('workoutStreak') ?? 0;

    _streaks = {
      'daily': dailyStreak,
      'water': waterStreak,
      'workout': workoutStreak,
    };

    // İlerleme verilerini yükle
    _workoutCount = prefs.getInt('workoutCount') ?? 0;
    _weightLossKg = prefs.getDouble('weightLossKg') ?? 0.0;
    _chatInteractionCount = prefs.getInt('chatInteractionCount') ?? 0;
    _weeklyGoalCompleted = prefs.getBool('weeklyGoalCompleted') ?? false;
    _monthlyGoalCompleted = prefs.getBool('monthlyGoalCompleted') ?? false;
    _yearlyGoalCompleted = prefs.getBool('yearlyGoalCompleted') ?? false;

    // Rozetlerin kilit durumunu yükle
    final badgeIdsString = prefs.getStringList('unlockedBadgeIds') ?? [];
    final unlockedDatesString = prefs.getStringList('unlockedBadgeDates') ?? [];

    // Rozet ID'lerini ve açılma tarihlerini eşleştir
    final Map<int, DateTime> unlockedBadges = {};
    for (int i = 0;
        i < badgeIdsString.length && i < unlockedDatesString.length;
        i++) {
      final id = int.tryParse(badgeIdsString[i]);
      final date = DateTime.tryParse(unlockedDatesString[i]);

      if (id != null && date != null) {
        unlockedBadges[id] = date;
      }
    }

    // Rozet kilit durumlarını güncelle
    for (var i = 0; i < _badges.length; i++) {
      final badge = _badges[i];
      if (unlockedBadges.containsKey(badge.id)) {
        _badges[i] = BadgeModel(
          id: badge.id,
          name: badge.name,
          description: badge.description,
          type: badge.type,
          rarity: badge.rarity,
          threshold: badge.threshold,
          color: badge.color,
          points: badge.points,
          unlockedAt: unlockedBadges[badge.id],
        );
      }
    }
  }

  // Veri kaydetme
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Puanları kaydet
    prefs.setInt('totalPoints', _totalPoints);

    // Serileri kaydet
    prefs.setInt('dailyStreak', _streaks['daily'] ?? 0);
    prefs.setInt('waterStreak', _streaks['water'] ?? 0);
    prefs.setInt('workoutStreak', _streaks['workout'] ?? 0);

    // İlerleme verilerini kaydet
    prefs.setInt('workoutCount', _workoutCount);
    prefs.setDouble('weightLossKg', _weightLossKg);
    prefs.setInt('chatInteractionCount', _chatInteractionCount);
    prefs.setBool('weeklyGoalCompleted', _weeklyGoalCompleted);
    prefs.setBool('monthlyGoalCompleted', _monthlyGoalCompleted);
    prefs.setBool('yearlyGoalCompleted', _yearlyGoalCompleted);

    // Açılmış rozet ID'lerini ve tarihlerini kaydet
    final List<String> unlockedBadgeIds = [];
    final List<String> unlockedBadgeDates = [];

    for (final badge in _badges.where((b) => b.isUnlocked)) {
      unlockedBadgeIds.add(badge.id.toString());
      unlockedBadgeDates.add(badge.unlockedAt!.toIso8601String());
    }

    prefs.setStringList('unlockedBadgeIds', unlockedBadgeIds);
    prefs.setStringList('unlockedBadgeDates', unlockedBadgeDates);
  }

  // Seriyi (streak) güncelle
  Future<void> updateStreak(String streakType, bool isCompleted) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastUpdate = prefs.getString('${streakType}_last_update') ?? '';

    if (lastUpdate != today) {
      // Yeni gün
      prefs.setString('${streakType}_last_update', today);

      if (isCompleted) {
        // Seri devam ediyor
        _streaks[streakType] = (_streaks[streakType] ?? 0) + 1;
      } else {
        // Seri kesildi
        _streaks[streakType] = 0;
      }

      // Seri rozetlerini kontrol et
      await _checkStreakBadges(streakType);

      // Verileri kaydet
      await _saveData();
      notifyListeners();
    }
  }

  // Puan ekle
  Future<void> addPoints(int points) async {
    _totalPoints += points;
    await _saveData();
    notifyListeners();
  }

  // Rozet kilidini aç
  Future<void> unlockBadge(int badgeId) async {
    final index = _badges.indexWhere((badge) => badge.id == badgeId);

    if (index != -1 && !_badges[index].isUnlocked) {
      final badge = _badges[index];

      // Rozeti güncelle ve puanları ekle
      _badges[index] = badge.unlock();
      _totalPoints += badge.points;

      await _saveData();
      notifyListeners();
    }
  }

  // Serilere göre rozet durumunu kontrol et
  Future<void> _checkStreakBadges(String streakType) async {
    final currentStreak = _streaks[streakType] ?? 0;

    // Streak tipine göre rozet tipini belirle
    BadgeType badgeType;
    switch (streakType) {
      case 'daily':
        badgeType = BadgeType.dailyStreak;
        break;
      case 'water':
        badgeType = BadgeType.waterStreak;
        break;
      case 'workout':
        badgeType = BadgeType.workoutCount;
        break;
      default:
        badgeType = BadgeType.dailyStreak;
    }

    // İlgili rozet tipindeki tüm rozetleri kontrol et
    for (final badge
        in _badges.where((b) => b.type == badgeType && !b.isUnlocked)) {
      if (currentStreak >= badge.threshold) {
        await unlockBadge(badge.id);
      }
    }
  }

  // AI Sohbet etkileşimini kaydet
  Future<void> recordChatInteraction(int userId) async {
    _chatInteractionCount++;
    debugPrint(
        'GamificationProvider: Chat interaction count: $_chatInteractionCount for user $userId');
    await _saveData(); // Kaydet

    // Sohbet etkileşim rozetlerini kontrol et
    for (final badge in _badges
        .where((b) => b.type == BadgeType.chatInteraction && !b.isUnlocked)) {
      if (_chatInteractionCount >= badge.threshold) {
        await unlockBadge(badge.id);
        debugPrint('GamificationProvider: Unlocked chat badge: ${badge.name}');
      }
    }
    notifyListeners();
  }

  // Varsayılan rozetleri yükle
  Future<void> _loadDefaultBadges() async {
    _badges.clear();

    // Günlük seri rozetleri
    _badges.addAll([
      BadgeModel(
        id: 1,
        name: 'Başlangıç',
        description: '3 gün üst üste günlük görevleri tamamla',
        type: BadgeType.dailyStreak,
        rarity: BadgeRarity.common,
        threshold: 3,
        color: AppTheme.primaryColor,
        points: 30,
      ),
      BadgeModel(
        id: 2,
        name: 'Tutarlı',
        description: '7 gün üst üste günlük görevleri tamamla',
        type: BadgeType.dailyStreak,
        rarity: BadgeRarity.uncommon,
        threshold: 7,
        color: AppTheme.primaryColor,
        points: 70,
      ),
      BadgeModel(
        id: 3,
        name: 'Kararlı',
        description: '30 gün üst üste günlük görevleri tamamla',
        type: BadgeType.dailyStreak,
        rarity: BadgeRarity.rare,
        threshold: 30,
        color: AppTheme.primaryColor,
        points: 300,
      ),
      BadgeModel(
        id: 4,
        name: 'Uzman',
        description: '90 gün üst üste günlük görevleri tamamla',
        type: BadgeType.dailyStreak,
        rarity: BadgeRarity.epic,
        threshold: 90,
        color: AppTheme.primaryColor,
        points: 900,
      ),
      BadgeModel(
        id: 5,
        name: 'Usta',
        description: '365 gün üst üste günlük görevleri tamamla',
        type: BadgeType.dailyStreak,
        rarity: BadgeRarity.legendary,
        threshold: 365,
        color: AppTheme.primaryColor,
        points: 3650,
      ),
    ]);

    // Su içme seri rozetleri
    _badges.addAll([
      BadgeModel(
        id: 6,
        name: 'Su Arkadaşı',
        description: '5 gün üst üste su hedefini tamamla',
        type: BadgeType.waterStreak,
        rarity: BadgeRarity.common,
        threshold: 5,
        color: AppTheme.waterColor,
        points: 50,
      ),
      BadgeModel(
        id: 7,
        name: 'Hidrasyon Uzmanı',
        description: '20 gün üst üste su hedefini tamamla',
        type: BadgeType.waterStreak,
        rarity: BadgeRarity.rare,
        threshold: 20,
        color: AppTheme.waterColor,
        points: 200,
      ),
    ]);

    // Antrenman rozetleri
    _badges.addAll([
      BadgeModel(
        id: 8,
        name: 'İlk Adım',
        description: '1 antrenman tamamla',
        type: BadgeType.workoutCount,
        rarity: BadgeRarity.common,
        threshold: 1,
        color: AppTheme.workoutColor,
        points: 10,
      ),
      BadgeModel(
        id: 9,
        name: 'Sporcu',
        description: '10 antrenman tamamla',
        type: BadgeType.workoutCount,
        rarity: BadgeRarity.uncommon,
        threshold: 10,
        color: AppTheme.workoutColor,
        points: 100,
      ),
      BadgeModel(
        id: 10,
        name: 'Fitness Tutkunu',
        description: '50 antrenman tamamla',
        type: BadgeType.workoutCount,
        rarity: BadgeRarity.rare,
        threshold: 50,
        color: AppTheme.workoutColor,
        points: 500,
      ),
      BadgeModel(
        id: 11,
        name: 'Fitness Gurusu',
        description: '100 antrenman tamamla',
        type: BadgeType.workoutCount,
        rarity: BadgeRarity.epic,
        threshold: 100,
        color: AppTheme.workoutColor,
        points: 1000,
      ),
      BadgeModel(
        id: 12,
        name: 'Efsane Atlet',
        description: '500 antrenman tamamla',
        type: BadgeType.workoutCount,
        rarity: BadgeRarity.legendary,
        threshold: 500,
        color: AppTheme.workoutColor,
        points: 5000,
      ),
    ]);

    // Haftalık, aylık, yıllık hedef rozetleri
    _badges.addAll([
      BadgeModel(
        id: 13,
        name: 'Haftalık Başarı',
        description: 'Bir haftalık tüm hedeflerini tamamla',
        type: BadgeType.weeklyGoal,
        rarity: BadgeRarity.uncommon,
        threshold: 1,
        color: AppTheme.goalColor,
        points: 70,
      ),
      BadgeModel(
        id: 14,
        name: 'Aylık Başarı',
        description: 'Bir aylık tüm hedeflerini tamamla',
        type: BadgeType.monthlyGoal,
        rarity: BadgeRarity.rare,
        threshold: 1,
        color: AppTheme.goalColor,
        points: 300,
      ),
      BadgeModel(
        id: 15,
        name: 'Yıllık Başarı',
        description: 'Bir yıllık tüm hedeflerini tamamla',
        type: BadgeType.yearlyGoal,
        rarity: BadgeRarity.legendary,
        threshold: 1,
        color: AppTheme.goalColor,
        points: 3650,
      ),
    ]);

    // Kilo verme rozetleri
    _badges.addAll([
      BadgeModel(
        id: 16,
        name: 'İlk Kilometre Taşı',
        description: 'İlk 1 kg verme hedefine ulaş',
        type: BadgeType.weightLoss,
        rarity: BadgeRarity.common,
        threshold: 1,
        color: AppTheme.weightColor,
        points: 100,
      ),
      BadgeModel(
        id: 17,
        name: 'İyi Gidiyorsun',
        description: '5 kg verme hedefine ulaş',
        type: BadgeType.weightLoss,
        rarity: BadgeRarity.uncommon,
        threshold: 5,
        color: AppTheme.weightColor,
        points: 500,
      ),
      BadgeModel(
        id: 18,
        name: 'Büyük Başarı',
        description: '10 kg verme hedefine ulaş',
        type: BadgeType.weightLoss,
        rarity: BadgeRarity.rare,
        threshold: 10,
        color: AppTheme.weightColor,
        points: 1000,
      ),
    ]);

    // Sohbet etkileşim rozetleri
    _badges.addAll([
      BadgeModel(
        id: 19,
        name: 'İlk Sohbet',
        description: 'AI asistan ile ilk sohbetini tamamla',
        type: BadgeType.chatInteraction,
        rarity: BadgeRarity.common,
        threshold: 1,
        color: AppTheme.infoColor,
        points: 10,
      ),
      BadgeModel(
        id: 20,
        name: 'Diyalog Ustası',
        description: 'AI asistan ile 50 sohbet tamamla',
        type: BadgeType.chatInteraction,
        rarity: BadgeRarity.rare,
        threshold: 50,
        color: AppTheme.infoColor,
        points: 500,
      ),
      BadgeModel(
        id: 21,
        name: 'AI Dostu',
        description: 'AI asistan ile 100 sohbet tamamla',
        type: BadgeType.chatInteraction,
        rarity: BadgeRarity.epic,
        threshold: 100,
        color: AppTheme.infoColor,
        points: 1000,
      ),
    ]);
  }

  // Veri takibi için diğer kaynaklardan veri alma metodları
  Future<void> syncAllUserData(String? userId) async {
    if (userId == null) return;

    try {
      await Future.wait([
        _syncAICoachInteractions(userId),
        _syncWorkoutActivities(userId),
        _syncWeightRecords(userId),
        _syncWaterConsumption(userId),
      ]);

      debugPrint(
          "GamificationProvider: Tüm kullanıcı verileri senkronize edildi");
      notifyListeners();
    } catch (e) {
      debugPrint("GamificationProvider: Veri senkronizasyon hatası: $e");
    }
  }

  // AI Koç etkileşimlerini veritabanından al ve senkronize et
  Future<void> _syncAICoachInteractions(String userId) async {
    try {
      final conversations =
          await _dbService.getAllChatConversations(int.parse(userId));
      final List<ChatMessage> allMessages = [];

      // Tüm konuşmalardan tüm mesajları al
      for (final conversation in conversations) {
        final messages =
            await _dbService.getMessagesForConversation(conversation.id!);
        allMessages.addAll(messages
            .where((m) => m.isUser)); // Sadece kullanıcı mesajlarını say
      }

      // Toplam etkileşim sayısını güncelle
      _chatInteractionCount = allMessages.length;
      debugPrint(
          "GamificationProvider: AI Koç etkileşimleri senkronize edildi. Toplam: $_chatInteractionCount");

      // Etkileşim sayısına göre rozet kontrolü yap
      await updateChatInteractionCount(
          0); // 0 ekleyerek sadece mevcut değer ile kontrol et
    } catch (e) {
      debugPrint(
          "GamificationProvider: AI Koç etkileşimleri senkronizasyon hatası: $e");
    }
  }

  // Antrenman aktivitelerini veritabanından al ve senkronize et
  Future<void> _syncWorkoutActivities(String userId) async {
    try {
      // Tüm workout logları al
      final workoutLogs = await _dbService.getWorkoutLogsInRange(
          DateTime.now().subtract(Duration(days: 365)), DateTime.now());

      // Tamamlanmış workout sayısını güncelle
      _workoutCount = workoutLogs.length;
      debugPrint(
          "GamificationProvider: Antrenman aktiviteleri senkronize edildi. Toplam: $_workoutCount");

      // Antrenman sayısına göre rozet kontrolü yap
      await updateWorkoutCount(
          0); // 0 ekleyerek sadece mevcut değer ile kontrol et
    } catch (e) {
      debugPrint(
          "GamificationProvider: Antrenman aktiviteleri senkronizasyon hatası: $e");
    }
  }

  // Kilo kayıtlarını veritabanından al ve senkronize et
  Future<void> _syncWeightRecords(String userId) async {
    try {
      // Kullanıcının kilo geçmişini al
      final weightRecords =
          await _dbService.getWeightHistory(int.parse(userId));

      if (weightRecords.isNotEmpty && weightRecords.length > 1) {
        // En son ve ilk kayıt arasındaki farkı hesapla - kilo kaybını bul
        weightRecords.sort((a, b) => a.date.compareTo(b.date));
        final firstWeight = weightRecords.first.weight;
        final lastWeight = weightRecords.last.weight;

        // Kilo kaybı (pozitif değer)
        final weightLoss =
            firstWeight > lastWeight ? firstWeight - lastWeight : 0.0;
        _weightLossKg = weightLoss;

        debugPrint(
            "GamificationProvider: Kilo kaybı senkronize edildi. Toplam: $_weightLossKg kg");

        // Kilo kaybına göre rozet kontrolü yap
        await updateWeightLoss(_weightLossKg);
      }
    } catch (e) {
      debugPrint(
          "GamificationProvider: Kilo kayıtları senkronizasyon hatası: $e");
    }
  }

  // Su tüketimini veritabanından al ve senkronize et
  Future<void> _syncWaterConsumption(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Son 30 günü kontrol et
      final startDate = today.subtract(Duration(days: 30));
      final endDate = today.add(Duration(hours: 23, minutes: 59, seconds: 59));

      // Su tüketim verilerini al
      final waterData = await _dbService.getWaterLogInRange(
          startDate, endDate, int.parse(userId));

      // Su hedefini al
      final prefs = await SharedPreferences.getInstance();
      final waterGoal =
          prefs.getInt('water_goal') ?? 2000; // ml cinsinden, varsayılan 2000ml

      // Son 30 günü kontrol et ve hedefi karşılayan günleri say
      int consecutiveDays = 0;
      int maxConsecutiveDays = 0;

      for (int i = 0; i < 30; i++) {
        final checkDate = today.subtract(Duration(days: i));
        final dailyWater = waterData[
                DateTime(checkDate.year, checkDate.month, checkDate.day)] ??
            0;

        if (dailyWater >= waterGoal) {
          // Hedefi karşılıyor
          consecutiveDays++;
          if (consecutiveDays > maxConsecutiveDays) {
            maxConsecutiveDays = consecutiveDays;
          }
        } else {
          // Seriyi kır
          consecutiveDays = 0;
        }
      }

      // Su serisini güncelle
      _streaks['water'] = maxConsecutiveDays;
      debugPrint(
          "GamificationProvider: Su tüketimi senkronize edildi. En uzun seri: ${_streaks['water']} gün");

      // Su serisine göre rozet kontrolü yap
      await _checkStreakBadges('water');
    } catch (e) {
      debugPrint("GamificationProvider: Su tüketimi senkronizasyon hatası: $e");
    }
  }

  // Antreman sayısını güncelle ve rozet durumunu kontrol et
  Future<void> updateWorkoutCount(int count) async {
    _workoutCount += count;
    for (final badge in _badges
        .where((b) => b.type == BadgeType.workoutCount && !b.isUnlocked)) {
      if (_workoutCount >= badge.threshold) {
        await unlockBadge(badge.id);
      }
    }
    await _saveData();
    notifyListeners();
  }

  // Kilo kaybını güncelle ve rozet durumunu kontrol et
  Future<void> updateWeightLoss(double weightLossKg) async {
    _weightLossKg = weightLossKg;
    for (final badge in _badges
        .where((b) => b.type == BadgeType.weightLoss && !b.isUnlocked)) {
      if (_weightLossKg >= badge.threshold) {
        await unlockBadge(badge.id);
      }
    }
    await _saveData();
    notifyListeners();
  }

  // Sohbet etkileşim sayısını güncelle ve rozet durumunu kontrol et
  Future<void> updateChatInteractionCount(int count) async {
    _chatInteractionCount += count;
    for (final badge in _badges
        .where((b) => b.type == BadgeType.chatInteraction && !b.isUnlocked)) {
      if (_chatInteractionCount >= badge.threshold) {
        await unlockBadge(badge.id);
      }
    }
    await _saveData();
    notifyListeners();
  }

  // Haftalık hedef tamamlamayı kontrol et ve rozet durumunu güncelle
  Future<void> checkWeeklyGoal(bool isCompleted) async {
    _weeklyGoalCompleted = isCompleted;
    if (isCompleted) {
      for (final badge in _badges
          .where((b) => b.type == BadgeType.weeklyGoal && !b.isUnlocked)) {
        await unlockBadge(badge.id);
      }
    }
    await _saveData();
    notifyListeners();
  }

  // Aylık hedef tamamlamayı kontrol et ve rozet durumunu güncelle
  Future<void> checkMonthlyGoal(bool isCompleted) async {
    _monthlyGoalCompleted = isCompleted;
    if (isCompleted) {
      for (final badge in _badges
          .where((b) => b.type == BadgeType.monthlyGoal && !b.isUnlocked)) {
        await unlockBadge(badge.id);
      }
    }
    await _saveData();
    notifyListeners();
  }

  // Yıllık hedef tamamlamayı kontrol et ve rozet durumunu güncelle
  Future<void> checkYearlyGoal(bool isCompleted) async {
    _yearlyGoalCompleted = isCompleted;
    if (isCompleted) {
      for (final badge in _badges
          .where((b) => b.type == BadgeType.yearlyGoal && !b.isUnlocked)) {
        await unlockBadge(badge.id);
      }
    }
    await _saveData();
    notifyListeners();
  }

  // Herhangi bir rozet için mevcut ilerlemeyi hesapla
  double getBadgeProgress(BadgeModel badge) {
    if (badge.isUnlocked) return 1.0; // %100 tamamlandı

    switch (badge.type) {
      case BadgeType.dailyStreak:
        final currentStreak = _streaks['daily'] ?? 0;
        return currentStreak / badge.threshold;
      case BadgeType.waterStreak:
        final currentStreak = _streaks['water'] ?? 0;
        return currentStreak / badge.threshold;
      case BadgeType.workoutCount:
        return _workoutCount / badge.threshold;
      case BadgeType.weightLoss:
        return _weightLossKg / badge.threshold;
      case BadgeType.chatInteraction:
        return _chatInteractionCount / badge.threshold;
      case BadgeType.weeklyGoal:
        return _weeklyGoalCompleted ? 1.0 : 0.0;
      case BadgeType.monthlyGoal:
        return _monthlyGoalCompleted ? 1.0 : 0.0;
      case BadgeType.yearlyGoal:
        return _yearlyGoalCompleted ? 1.0 : 0.0;
      default:
        return 0.0;
    }
  }

  // Rozete ait ilerleme bilgisini string olarak döndür
  String getProgressText(BadgeModel badge) {
    if (badge.isUnlocked) return 'Tamamlandı';

    switch (badge.type) {
      case BadgeType.dailyStreak:
        final currentStreak = _streaks['daily'] ?? 0;
        return '$currentStreak/${badge.threshold} gün';
      case BadgeType.waterStreak:
        final currentStreak = _streaks['water'] ?? 0;
        return '$currentStreak/${badge.threshold} gün';
      case BadgeType.workoutCount:
        return '$_workoutCount/${badge.threshold} antrenman';
      case BadgeType.weightLoss:
        return '${_weightLossKg.toStringAsFixed(1)}/${badge.threshold} kg';
      case BadgeType.chatInteraction:
        return '$_chatInteractionCount/${badge.threshold} sohbet';
      case BadgeType.weeklyGoal:
        return _weeklyGoalCompleted ? 'Tamamlandı' : 'Henüz başarılmadı';
      case BadgeType.monthlyGoal:
        return _monthlyGoalCompleted ? 'Tamamlandı' : 'Henüz başarılmadı';
      case BadgeType.yearlyGoal:
        return _yearlyGoalCompleted ? 'Tamamlandı' : 'Henüz başarılmadı';
      default:
        return 'Bilgi yok';
    }
  }

  // Kilitli ve açık tüm rozetlerden kazanılan toplam puan
  int get totalEarnedPoints {
    return unlockedBadges.fold(0, (sum, badge) => sum + badge.points);
  }

  // Tüm rozetlerden kazanılabilecek maksimum puan
  int get maxPossiblePoints {
    return _badges.fold(0, (sum, badge) => sum + badge.points);
  }

  // Kilo verme rozetlerini kontrol et
  Future<void> checkWeightLossBadges(int userId) async {
    final user = await _dbService.getUser(userId);
    if (user == null) {
      debugPrint(
          'GamificationProvider: User not found for weight loss badges check.');
      return;
    }

    final weightHistory = await _dbService.getWeightHistory(userId);
    if (weightHistory.length < 2) {
      // Karşılaştırma yapmak için en az 2 kayıt gerekli (başlangıç ve mevcut)
      debugPrint(
          'GamificationProvider: Not enough weight history to calculate loss.');
      _weightLossKg = 0.0; // Kilo kaybını sıfırla
      await _saveData();
      notifyListeners();
      return;
    }

    // Kilo geçmişini tarihe göre sırala (en eski en başta)
    weightHistory.sort((a, b) => a.date.compareTo(b.date));

    final initialWeightRecord = weightHistory.first;
    // En son kilo kaydını bulmak için user.weight kullanılabilir veya weightHistory.last
    // User modelindeki weight güncel olmayabilir, bu yüzden history.last daha güvenli.
    final currentWeightRecord = weightHistory.last;

    double totalLoss = initialWeightRecord.weight - currentWeightRecord.weight;

    if (totalLoss < 0) totalLoss = 0; // Kilo almışsa kayıp 0 kabul edilir.

    _weightLossKg = totalLoss;
    debugPrint(
        'GamificationProvider: Total weight loss calculated: $_weightLossKg kg for user $userId');
    await _saveData();

    for (final badge in _badges
        .where((b) => b.type == BadgeType.weightLoss && !b.isUnlocked)) {
      if (_weightLossKg >= badge.threshold) {
        await unlockBadge(badge.id);
        debugPrint(
            'GamificationProvider: Unlocked weight loss badge: ${badge.name}');
      }
    }
    notifyListeners();
  }

  // Programdan bir antrenman tamamlandığında çağrılır
  Future<void> recordProgramWorkoutCompleted(int userId, int activityId) async {
    // Aktiviteyi DB'den çekip isFromProgram kontrolü yapılabilir,
    // ancak ActivityProvider.addActivity zaten bu bilgiyi ActivityRecord'a yazıyor.
    // Bu metodun, aktivite eklendikten sonra ve isFromProgram true ise çağrılması beklenir.
    // Şimdilik, bu metodun yalnızca programdan gelen aktiviteler için çağrıldığını varsayalım.

    _workoutCount++;
    debugPrint(
        'GamificationProvider: Program workout count: $_workoutCount for user $userId, activityId: $activityId');
    await _saveData(); // workoutCount'u kaydet

    // Antrenman sayısı rozetlerini kontrol et (BadgeType.workoutCount)
    for (final badge in _badges
        .where((b) => b.type == BadgeType.workoutCount && !b.isUnlocked)) {
      if (_workoutCount >= badge.threshold) {
        await unlockBadge(badge.id);
        debugPrint(
            'GamificationProvider: Unlocked workout count badge: ${badge.name}');
      }
    }

    // Antrenman serisini de güncelle (eğer program antrenmanları seriye dahilse)
    // Kullanıcı her program antrenmanı tamamladığında burası tetikleneceği için,
    // günlük seri mantığı için günün ilk program antrenmanında 'true' ile çağrılmalı.
    // Bu biraz karmaşıklaşabilir. Şimdilik sadece sayacı artıralım.
    // Streak mantığı için _checkStreakBadges('workout') ayrıca ele alınabilir.

    notifyListeners();
  }
}
