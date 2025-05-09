import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_service.dart';
import '../models/user_model.dart';
import '../models/activity_record.dart';
import '../models/meal_record.dart';
import '../models/task_type.dart';

class AICoachService {
  // API anahtarı geçici olarak boş bırakılmıştır, kullanıcı kendi anahtarını girecektir
  String _apiKey = 'AIzaSyCpyD_2D-xJyYUlJni8YMLXiMxaVvTLswQ';
  final DatabaseService _dbService;
  late GenerativeModel _model;

  // Getter ve setter tanımlamaları
  String get apiKey => _apiKey;
  set apiKey(String value) {
    _apiKey = value;
    _initModel(); // Anahtar değiştiğinde modeli yeniden başlat
  }

  AICoachService(this._dbService) {
    _initModel();
  }

  void _initModel() {
    // Model başlatılıyor - API anahtarı geçerli olmadığında çalışmayacaktır
    _model = GenerativeModel(
      model: 'gemini-2.0-flash', // Kullanıcının belirttiği model
      apiKey: _apiKey,
    );
  }

  // Kullanılabilir modelleri listelemek için metot - API henüz bu özelliği direkt olarak desteklemediği için manuel olarak
  Future<String> listAvailableModels() async {
    try {
      // Şu anda kullanılabilir modeller
      return """Kullanılabilir Gemini modeller:
- gemini-pro (standart model)
- gemini-pro-vision (görüntü desteği)
- gemini-ultra (yüksek performans)
- gemini-1.0-pro
- gemini-1.0-pro-vision
- gemini-1.0-ultra
- gemini-2.0-flash (beta)
      
Şu anda kullanılan model: gemini-2.0-flash (beta)
      """;
    } catch (e) {
      return "Model bilgisi gösterilirken hata oluştu: $e";
    }
  }

  // Kullanıcı verileri, aktiviteler ve beslenme bilgileriyle oluşturulan context
  Future<String> _buildUserContext() async {
    // GEÇİCİ ÇÖZÜM: Varsayılan ID 1
    // TODO: Gerçek kullanıcı ID yönetimini ekle
    const int currentUserId = 1;
    final user =
        await _dbService.getUser(currentUserId); // ID parametresi eklendi

    // Kullanıcı yoksa veya ID'si yoksa, bağlam oluşturmadan çık
    if (user == null || user.id == null) {
      print("AICoachService: Kullanıcı bulunamadı, bağlam oluşturulamıyor.");
      return "Kullanıcı bilgileri alınamadı."; // veya başka bir uygun mesaj
    }

    final userId = user.id!; // Null check zaten yapıldı
    print("AICoachService: Bağlam oluşturuluyor - Kullanıcı ID: $userId");

    // Aktiviteleri al (şimdilik userId gerektirmiyor varsayıyoruz)
    final activities = await _dbService.getActivitiesInRange(
        DateTime.now().subtract(Duration(days: 30)), DateTime.now());

    // Öğünleri userId ile al
    final meals = await _dbService.getMealsInRange(
        DateTime.now().subtract(Duration(days: 30)), DateTime.now(), userId);

    // En sık yapılan aktivite ve ortalama kalori hesaplamaları
    final mostFrequentActivity = _getMostFrequentActivity(activities);
    final avgCalories = _getAverageCaloriesPerDay(meals);

    // Haftalık aktivite durumu
    final weeklyActivityStatus = _getWeeklyActivityStatus(activities);

    return """
    KULLANICI BİLGİLERİ:
    Ad: ${user?.name ?? 'Bilinmiyor'}
    Yaş: ${user?.age ?? 'Bilinmiyor'}
    Boy: ${user?.height ?? 'Bilinmiyor'} cm
    Kilo: ${user?.weight ?? 'Bilinmiyor'} kg
    BMI: ${user?.bmi.toStringAsFixed(1) ?? 'Bilinmiyor'}
    BMI Kategorisi: ${user?.bmiCategory ?? 'Bilinmiyor'}
    
    SON AYLIK AKTİVİTE ÖZET:
    Toplam aktivite sayısı: ${activities.length}
    Toplam süre: ${activities.fold(0, (sum, a) => sum + a.durationMinutes)} dakika
    En sık yapılan aktivite: $mostFrequentActivity
    Bu hafta aktivite yapılan gün sayısı: $weeklyActivityStatus
    
    SON AYLIK BESLENME ÖZET:
    Toplam öğün sayısı: ${meals.length}
    Ortalama günlük kalori: ${avgCalories.toStringAsFixed(0)} kcal
    
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
    3. Kullanıcının sorusu kısaysa, yanıtın da kısa olmalı. Örneğin "selam" denildiğinde "Merhaba (kullanıcı adı)!" gibi tek kelime/cümle ile yanıt ver.
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

  Future<String> getCoachResponse(String userMessage) async {
    try {
      // API anahtarı kontrolünü kaldırıyoruz

      final context = await _buildUserContext();
      final prompt = "$context\n\nKullanıcı: $userMessage";

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? "Üzgünüm, yanıt oluşturulamadı.";
    } catch (e) {
      return "Üzgünüm, bir hata oluştu: $e";
    }
  }
}
