import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_service.dart';
import '../models/user_model.dart';
import '../models/activity_record.dart';
import '../models/meal_record.dart';
import '../models/task_type.dart';
import '../providers/gamification_provider.dart';
import '../models/badge_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AICoachService {
  // API anahtarı doğrudan kod içinde tanımlanıyor
  String _apiKey =
      'AIzaSyCpyD_2D-xJyYUlJni8YMLXiMxaVvTLswQ'; // << KENDİ API KEYİNİZİ BURAYA GİRİN!
  final DatabaseService _dbService;
  final GamificationProvider _gamificationProvider;
  late GenerativeModel _model;
  String _activeModel =
      'gemini-1.5-flash-latest'; // Varsayılan olarak en son flash modeli

  // Getter ve setter tanımlamaları
  String get apiKey => _apiKey;
  set apiKey(String value) {
    _apiKey = value;
    _initModel(); // Anahtar değiştiğinde modeli yeniden başlat
  }

  AICoachService(this._dbService, this._gamificationProvider) {
    _initModel(); // SharedPreferences'dan yükleme yapmadan direkt başlat
  }

  Future<void> _loadApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('ai_coach_api_key');
      if (savedKey != null && savedKey.isNotEmpty) {
        _apiKey = savedKey;
        print("API key başarıyla yüklendi");
      } else {
        print("Kaydedilmiş API key bulunamadı");
      }
    } catch (e) {
      print("API key yüklenirken hata oluştu: $e");
    }
  }

  Future<void> saveApiKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_coach_api_key', key);
      _apiKey = key;
      _initModel();
      print("API key başarıyla kaydedildi");
    } catch (e) {
      print("API key kaydedilirken hata oluştu: $e");
    }
  }

  void _initModel() {
    // Model başlatılıyor - API anahtarı geçerli olmadığında çalışmayacaktır
    try {
      if (_apiKey.isNotEmpty) {
        print(
            "API key mevcut (${_apiKey.length} karakter). Model başlatılıyor: $_activeModel");

        _model = GenerativeModel(
          model: _activeModel,
          apiKey: _apiKey,
        );

        print("Gemini model başarıyla başlatıldı: $_activeModel");
      } else {
        print("API key boş olduğu için model başlatılamadı");
      }
    } catch (e) {
      print("Model ($_activeModel) başlatılırken hata oluştu: $e");
    }
  }

  // Alternatif bir model dene
  void tryAlternativeModel() {
    if (_activeModel == 'gemini-1.5-flash-latest') {
      _activeModel = 'gemini-1.0-pro'; // Alternatif olarak stabil bir pro model
    } else {
      _activeModel = 'gemini-1.5-flash-latest';
    }
    print("Alternatif model deneniyor: $_activeModel");
    _initModel();
  }

  // API key'in Google AI Studio'dan doğru alındığını kontrol eden metod
  bool _isValidApiKeyFormat() {
    // Google API keyleri genellikle "AIza" ile başlar
    if (_apiKey.isEmpty || _apiKey.length < 15) return false;
    return _apiKey.startsWith('AIza');
  }

  // Kullanılabilir modelleri listelemek için metot - API henüz bu özelliği direkt olarak desteklemediği için manuel olarak
  Future<String> listAvailableModels() async {
    try {
      // Şu anda kullanılabilir modeller
      return """Kullanılabilir Gemini modeller (SDK tarafından desteklenenler):
- gemini-pro
- gemini-1.0-pro 
- gemini-1.5-flash-latest (önerilen ve mevcut varsayılan)
- gemini-1.5-pro-latest
      
Şu anda kullanılan model: $_activeModel
      """;
    } catch (e) {
      return "Model bilgisi gösterilirken hata oluştu: $e";
    }
  }

  // Kullanıcı verileri, aktiviteler ve beslenme bilgileriyle oluşturulan context
  Future<String> _buildUserContext(
      UserModel? user, GamificationProvider gamificationProvider) async {
    if (user == null || user.id == null) {
      print(
          "AICoachService: Kullanıcı modeli null veya ID'si yok, bağlam oluşturulamıyor.");
      return "Kullanıcı bilgileri alınamadı.";
    }

    final userId = user.id!;
    print(
        "AICoachService: Bağlam oluşturuluyor - Kullanıcı ID: $userId, Ad: ${user.name}");

    final activities = await _dbService.getActivitiesInRange(
        DateTime.now().subtract(Duration(days: 30)), DateTime.now(), userId);

    final meals = await _dbService.getMealsInRange(
        DateTime.now().subtract(Duration(days: 30)), DateTime.now(), userId);

    final mostFrequentActivity = _getMostFrequentActivity(activities);
    final avgCalories = _getAverageCaloriesPerDay(meals);
    final weeklyActivityStatus = _getWeeklyActivityStatus(activities);

    // Oyunlaştırma Verileri
    final totalPoints = gamificationProvider.totalEarnedPoints;
    final dailyStreak = gamificationProvider.streaks['daily'] ?? 0;
    final waterStreak = gamificationProvider.streaks['water'] ?? 0;
    final workoutCount = gamificationProvider.workoutCount;
    final List<BadgeModel> sortedUnlockedBadges =
        List.from(gamificationProvider.unlockedBadges);
    sortedUnlockedBadges.sort((a, b) {
      if (a.unlockedAt == null && b.unlockedAt == null) return 0;
      if (a.unlockedAt == null) return 1;
      if (b.unlockedAt == null) return -1;
      return b.unlockedAt!.compareTo(a.unlockedAt!);
    });
    final unlockedBadgesSummary = sortedUnlockedBadges
        .take(3)
        .map((b) => "- ${b.name} (${b.points} puan)")
        .join("\n    ");

    return """
    KULLANICI BİLGİLERİ:
    Ad: ${user.name ?? 'Bilinmiyor'}
    Yaş: ${user.age ?? 'Bilinmiyor'}
    Boy: ${user.height ?? 'Bilinmiyor'} cm
    Kilo: ${user.weight ?? 'Bilinmiyor'} kg
    BMI: ${user.bmi?.toStringAsFixed(1) ?? 'Bilinmiyor'}
    BMI Kategorisi: ${user.bmiCategory ?? 'Bilinmiyor'}
    
    SON AYLIK AKTİVİTE ÖZET:
    Toplam aktivite sayısı: ${activities.length}
    Toplam süre: ${activities.fold(0, (sum, a) => sum + (a.durationMinutes ?? 0))} dakika
    En sık yapılan aktivite: $mostFrequentActivity
    Bu hafta aktivite yapılan gün sayısı: $weeklyActivityStatus
    
    SON AYLIK BESLENME ÖZET:
    Toplam öğün sayısı: ${meals.length}
    Ortalama günlük kalori: ${avgCalories.toStringAsFixed(0)} kcal

    OYUNLAŞTIRMA DURUMU:
    Toplam Kazanılan Puan: $totalPoints
    Günlük Görev Serisi: $dailyStreak gün
    Su İçme Serisi: $waterStreak gün
    Tamamlanan Antrenman Sayısı: $workoutCount
    Son Kazanılan Rozetler:
    ${unlockedBadgesSummary.isNotEmpty ? unlockedBadgesSummary : "Henüz rozet kazanılmadı."}
    
    KAPLANFIT PROGRAMI GEREKSİNİMLERİ:
    1. Her hafta en az 3 gün egzersiz yapılmalı
    2. Günde 2-3 litre su içilmeli
    3. Protein ağırlıklı beslenme tercih edilmeli
    4. Haftada en az 2 gün yüzme yapılmalı
    5. BMI kategorisine göre beslenme düzeninin ayarlanması
    
    ROL:
    Sen KaplanFit uygulamasının AI Koçusun. 
    
    YANITLAMA KURALLARI:
    1. Selamlaşma, hal hatır sorma gibi sorulara kısa cümlelerle yanıt ver.
    2. Kullanıcı detaylı bilgi istediğinde bilgiyi net, anlaşılır tut. 
    3. Kullanıcının sorusu kısaysa, yanıtın da kısa olmalı. Örneğin "selam" denildiğinde "Merhaba ${user.name ?? 'Kullanıcı'}!" gibi tek kelime/cümle ile yanıt ver.
    4. Tavsiyeleri madde madde, güzel ve samimicümlelerle listelemeyi tercih et.
    5. Kullanıcıyı sürekli motive et pozitife yönlendir cesaretlendir.
    6. Kullanıcının günlük aktivite planını kontrol et.
    7. Kullanıcının aktivite, su, kalori, kilo ve beslenme kayıtlarını kontrol et.
    8. Kullanıcının hedeflerine yönelik yanıt ver.
    9. Kullanıcının aktivite ve yemek kayıtlarını kontrol et.
    10. Kullanıcı ile olan tüm konuşmalarını kaydet, hatırla ve bunları dikkate alarak cevap ver..
    Kullanıcıya Türkçe yanıt ver.
    """;
  }

  String _getMostFrequentActivity(List<ActivityRecord> activities) {
    if (activities.isEmpty) return "Henüz veri yok";

    // Aktivite tiplerini sayma
    Map<FitActivityType, int> activityCounts = {};
    for (var activity in activities) {
      activityCounts[activity.type] = (activityCounts[activity.type] ?? 0) + 1;
    }

    // En sık yapılan aktivite tipini bulma
    FitActivityType? mostFrequent;
    int maxCount = 0;

    activityCounts.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequent = type;
      }
    });

    // Aktivite tipini metin olarak döndürme
    if (mostFrequent == null) return "Henüz veri yok";

    switch (mostFrequent) {
      case FitActivityType.walking:
        return "Yürüyüş";
      case FitActivityType.running:
        return "Koşu";
      case FitActivityType.cycling:
        return "Bisiklet";
      case FitActivityType.swimming:
        return "Yüzme";
      case FitActivityType.weightTraining:
        return "Ağırlık Antrenmanı";
      case FitActivityType.yoga:
        return "Yoga";
      case FitActivityType.other:
        return "Diğer";
      default:
        return "Belirsiz";
    }
  }

  int _getWeeklyActivityStatus(List<ActivityRecord> activities) {
    // Son 7 gün içindeki aktiviteleri filtreleme
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));

    final weeklyActivities = activities
        .where((a) =>
            a.date.isAfter(weekAgo) &&
            a.date.isBefore(now.add(Duration(days: 1))))
        .toList();

    // Aktivite günlerini sayma (bir günde birden fazla aktivite olsa bile o gün bir kez sayılır)
    Set<String> activityDays = {};
    for (var activity in weeklyActivities) {
      // Günü yyyy-MM-dd formatında bir string olarak ekleyerek tekrarları engelliyoruz
      activityDays.add(
          "${activity.date.year}-${activity.date.month.toString().padLeft(2, '0')}-${activity.date.day.toString().padLeft(2, '0')}");
    }

    return activityDays.length;
  }

  double _getAverageCaloriesPerDay(List<MealRecord> meals) {
    if (meals.isEmpty) return 0;

    // Son ayda yenilen toplam kalori
    int totalCalories =
        meals.fold(0, (sum, meal) => sum + (meal.calories ?? 0));

    // Öğün olan tekil günleri hesaplama
    Set<String> mealDays = {};
    for (var meal in meals) {
      mealDays.add(
          "${meal.date.year}-${meal.date.month.toString().padLeft(2, '0')}-${meal.date.day.toString().padLeft(2, '0')}");
    }

    // Veri olan gün sayısı
    int numberOfDays = mealDays.length;

    // Gün sayısı 0 ise NaN dönmemek için kontrol
    return numberOfDays > 0 ? totalCalories / numberOfDays : 0;
  }

  Future<String> getCoachResponse(
      String userMessage, UserModel? currentUser) async {
    try {
      // API keyin doğru formatta olup olmadığını kontrol et
      if (!_isValidApiKeyFormat()) {
        print("API Key formatı geçersiz: $_apiKey");
        return "Üzgünüm, API anahtarı geçersiz görünüyor. Lütfen Google AI Studio'dan (https://aistudio.google.com) geçerli bir API anahtarı alın ve kod içerisinde güncelleyin.";
      }

      print("API Key kontrolü başarılı, kullanılan model: $_activeModel");

      final context =
          await _buildUserContext(currentUser, _gamificationProvider);
      final prompt = "$context\n\nKullanıcı: $userMessage";

      print("Gemini API'sine istek gönderiliyor...");
      final content = [Content.text(prompt)];

      try {
        final response = await _model.generateContent(content);
        print(
            "Gemini API yanıt verdi: ${response.text != null ? "Başarılı" : "Boş yanıt"}");
        return response.text ?? "Üzgünüm, yanıt oluşturulamadı.";
      } catch (apiError) {
        print("Gemini API hatası: $apiError");

        // Eğer API key hatası varsa, kullanıcıya yardımcı olacak bir mesaj göster
        if (apiError.toString().toLowerCase().contains("api key not valid") ||
            apiError.toString().toLowerCase().contains("invalid api key") ||
            apiError.toString().toLowerCase().contains("permission denied")) {
          print(
              "API key ile ilgili bir sorun oluştu. Alternatif model denenecek.");
          tryAlternativeModel(); // Ana modelde sorun olursa alternatifi dene

          return "API anahtarınızla ilgili bir sorun oluştu veya seçilen model için yetkiniz bulunmuyor. Google AI Studio (https://aistudio.google.com) üzerinden anahtarınızı kontrol edin. Alternatif bir model ($_activeModel) denendi. Lütfen sorunuzu tekrar sorun.";
        }

        return "Gemini API hatası ($_activeModel): $apiError. Lütfen API anahtarınızı ve internet bağlantınızı kontrol edin.";
      }
    } catch (e) {
      print("getCoachResponse genel hatası: $e");
      return "Üzgünüm, bir hata oluştu: $e";
    }
  }
}
