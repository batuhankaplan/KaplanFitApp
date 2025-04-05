import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/nutrition_provider.dart';
import '../theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/program_card.dart';
import '../models/task_model.dart';
import '../models/activity_record.dart';
import '../models/meal_record.dart';
import '../models/task_type.dart';
import 'package:intl/intl.dart';
import '../utils/animations.dart';
import '../models/providers/database_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Günlük görevlerin durumunu tutan değişkenler
  bool isMorningExerciseDone = false;
  bool isLunchDone = false;
  bool isEveningExerciseDone = false;
  bool isDinnerDone = false;
  bool isLoaded = false;
  
  // Aktivite ve öğün ID'lerini saklamak için değişkenler
  int? morningExerciseId;
  int? lunchMealId;
  int? eveningExerciseId;
  int? dinnerMealId;
  
  // Program içerikleri
  String morningProgram = '';
  String lunchMenu = '';
  String eveningProgram = '';
  String dinnerMenu = '';
  
  // Motivasyon mesajları
  final List<String> _motivationalMessages = [
    'Bugün için sağlıklı bir şeyler yapın',
    'Her gün biraz daha iyiye',
    'Daha güçlü, daha sağlıklı bir hayat için',
    'Kendinize yatırım yapın',
    'Sağlık en büyük zenginliktir',
    'Küçük adımlar, büyük değişimler',
    'Yarının sağlığı bugünün seçimlerinde',
    'Kendine iyi bak, daha iyi hisset',
    'Sağlıklı vücut, sağlıklı zihin',
    'Bugün kendini aş',
    'Limit yok, sadece potansiyel var',
    'Harekette bereket var',
    'Başarı her gün biraz daha iyisini yapmaktır',
    'Kendi sınırlarını zorla',
    'Sağlıklı yaşam bir maraton, sprint değil',
  ];
  
  // Seçilen motivasyon mesajı
  late String _selectedMotivationalMessage;
  
  // Sayfa kontrolcüsü
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initTasks();
    _loadSavedTaskStates();
    
    // Rastgele bir motivasyon mesajı seç
    _selectedMotivationalMessage = _getRandomMotivationalMessage();
  }
  
  // Rastgele motivasyon mesajı getiren fonksiyon
  String _getRandomMotivationalMessage() {
    _motivationalMessages.shuffle();
    return _motivationalMessages.first;
  }
  
  @override
  void dispose() {
    // Listener'ı temizle
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    databaseProvider.removeListener(_refreshProgram);
    
    _pageController.dispose();
    super.dispose();
  }

  // Kaydedilmiş görev durumlarını yükle
  Future<void> _loadSavedTaskStates() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Bugünün tarihi için kaydedilmiş durumları kontrol et
    final String lastSavedDate = prefs.getString('lastSavedDate') ?? '';
    
    // Eğer yeni bir gün başladıysa tüm durumları sıfırla
    if (lastSavedDate != today) {
      prefs.setString('lastSavedDate', today);
      prefs.setBool('isMorningExerciseDone', false);
      prefs.setBool('isLunchDone', false);
      prefs.setBool('isEveningExerciseDone', false);
      prefs.setBool('isDinnerDone', false);
      
      // ID'leri de sıfırla
      prefs.remove('morningExerciseId');
      prefs.remove('lunchMealId');
      prefs.remove('eveningExerciseId'); 
      prefs.remove('dinnerMealId');
    }
    
    // Kaydedilmiş durumları yükle
    if (mounted) {
      setState(() {
        isMorningExerciseDone = prefs.getBool('isMorningExerciseDone') ?? false;
        isLunchDone = prefs.getBool('isLunchDone') ?? false;
        isEveningExerciseDone = prefs.getBool('isEveningExerciseDone') ?? false;
        isDinnerDone = prefs.getBool('isDinnerDone') ?? false;
        
        // ID'leri de yükle
        morningExerciseId = prefs.getInt('morningExerciseId');
        lunchMealId = prefs.getInt('lunchMealId');
        eveningExerciseId = prefs.getInt('eveningExerciseId');
        dinnerMealId = prefs.getInt('dinnerMealId');
        
        isLoaded = true;
      });
    }
  }
  
  // Görev durumlarını kaydet
  Future<void> _savingTaskStates() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    prefs.setString('lastSavedDate', today);
    prefs.setBool('isMorningExerciseDone', isMorningExerciseDone);
    prefs.setBool('isLunchDone', isLunchDone);
    prefs.setBool('isEveningExerciseDone', isEveningExerciseDone);
    prefs.setBool('isDinnerDone', isDinnerDone);
    
    // ID'leri de kaydet
    if (morningExerciseId != null) prefs.setInt('morningExerciseId', morningExerciseId!);
    if (lunchMealId != null) prefs.setInt('lunchMealId', lunchMealId!);
    if (eveningExerciseId != null) prefs.setInt('eveningExerciseId', eveningExerciseId!);
    if (dinnerMealId != null) prefs.setInt('dinnerMealId', dinnerMealId!);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final activityProvider = Provider.of<ActivityProvider>(context);
    final nutritionProvider = Provider.of<NutritionProvider>(context);
    
    final activities = activityProvider.activities;
    final meals = nutritionProvider.meals;
    
    final totalCalories = meals.fold<int>(0, (sum, meal) => sum + (meal.calories ?? 0));
    
    final totalActivityMinutes = activities.fold<int>(
      0, (sum, activity) => sum + activity.durationMinutes);
    
    final swimmingMinutes = activities
      .where((activity) => activity.type == FitActivityType.swimming)
      .fold<int>(0, (sum, activity) => sum + activity.durationMinutes);
    
    final today = DateTime.now();
    final dayName = DateFormat('EEEE', 'tr_TR').format(today);
    
    // Genel tavsiyeler
    final String additionalNote = '💧 Günde en az 2-3 litre su içmeyi unutmayın!\n'
        '❌ Şekerli içeceklerden uzak durun.\n'
        '🍌 Her gün 1 muz tüketin (potasyum kaynağı).';
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık kısmı - tema uyumlu
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingCard(),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Bugünkü Program başlığı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Bugünkü Program',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sabah Egzersizi kartı
              KFAnimatedItem(
                index: 0,
                delay: const Duration(milliseconds: 150),
                child: GestureDetector(
                  onTap: _toggleMorningExercise,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: isMorningExerciseDone 
                          ? AppTheme.completedTaskColor 
                          : AppTheme.morningExerciseColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wb_sunny, 
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sabah Egzersizi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    decoration: isMorningExerciseDone 
                                        ? TextDecoration.lineThrough 
                                        : TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  morningProgram,
                                  style: TextStyle(
                                    color: isMorningExerciseDone 
                                        ? Colors.white.withOpacity(0.7) 
                                        : Colors.white,
                                    fontSize: 16,
                                    decoration: isMorningExerciseDone 
                                        ? TextDecoration.lineThrough 
                                        : TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Öğle Yemeği kartı
              KFAnimatedItem(
                index: 1,
                delay: const Duration(milliseconds: 150),
                child: GestureDetector(
                  onTap: _toggleLunch,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: isLunchDone 
                          ? AppTheme.completedTaskColor 
                          : AppTheme.lunchColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.restaurant,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Öğle Yemeği',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    decoration: isLunchDone 
                                        ? TextDecoration.lineThrough 
                                        : TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lunchMenu,
                                  style: TextStyle(
                                    color: isLunchDone 
                                        ? Colors.white.withOpacity(0.7) 
                                        : Colors.white,
                                    fontSize: 16,
                                    decoration: isLunchDone 
                                        ? TextDecoration.lineThrough 
                                        : TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Akşam Egzersizi kartı
              KFAnimatedItem(
                index: 2,
                delay: const Duration(milliseconds: 150),
                child: GestureDetector(
                  onTap: _toggleEveningExercise,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: isEveningExerciseDone 
                          ? AppTheme.completedTaskColor 
                          : AppTheme.eveningExerciseColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Akşam Egzersizi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    decoration: isEveningExerciseDone 
                                        ? TextDecoration.lineThrough 
                                        : TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  eveningProgram,
                                  style: TextStyle(
                                    color: isEveningExerciseDone 
                                        ? Colors.white.withOpacity(0.7) 
                                        : Colors.white,
                                    fontSize: 16,
                                    decoration: isEveningExerciseDone 
                                        ? TextDecoration.lineThrough 
                                        : TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Akşam Yemeği kartı
              GestureDetector(
                onTap: _toggleDinner,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isDinnerDone 
                        ? AppTheme.completedTaskColor 
                        : AppTheme.dinnerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.dinner_dining,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Akşam Yemeği',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  decoration: isDinnerDone 
                                      ? TextDecoration.lineThrough 
                                      : TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dinnerMenu,
                                style: TextStyle(
                                  color: isDinnerDone 
                                      ? Colors.white.withOpacity(0.7) 
                                      : Colors.white,
                                  fontSize: 16,
                                  decoration: isDinnerDone 
                                      ? TextDecoration.lineThrough 
                                      : TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // İstatistikler başlığı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Günlük İstatistiklerim',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // İstatistik kartları row içinde
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.restaurant,
                        color: AppTheme.lunchColor,
                        title: 'Beslenme',
                        value: '$totalCalories kalori',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        icon: Icons.directions_run,
                        color: AppTheme.eveningExerciseColor,
                        title: 'Spor',
                        value: '$totalActivityMinutes dk',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        icon: Icons.pool,
                        color: AppTheme.morningExerciseColor,
                        title: 'Yüzme',
                        value: '$swimmingMinutes dk',
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Su hatırlatması kartı
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.morningExerciseColor, 
                      AppTheme.morningExerciseColor.withOpacity(0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💧 Günlük Su Hatırlatması',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Günde en az 2-3 litre su içmeyi unutmayın! Şekerli içeceklerden uzak durun.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _toggleMorningExercise() async {
    setState(() {
      isMorningExerciseDone = !isMorningExerciseDone;
    });
    
    if (isMorningExerciseDone) {
      await _recordMorningExercise(context);
      
      // Hemen ana sayfadan etkilenen sağlayıcıları yenileyelim
      await Provider.of<ActivityProvider>(context, listen: false).refreshActivities();
    } else {
      await _removeMorningExercise(context);
      
      // Hemen ana sayfadan etkilenen sağlayıcıları yenileyelim
      await Provider.of<ActivityProvider>(context, listen: false).refreshActivities();
    }
  }
  
  Future<void> _toggleLunch() async {
    setState(() {
      isLunchDone = !isLunchDone;
    });
    
    if (isLunchDone) {
      await _recordLunch(context);
      
      // Hemen ana sayfadan etkilenen sağlayıcıları yenileyelim
      await Provider.of<NutritionProvider>(context, listen: false).refreshMeals();
    } else {
      await _removeLunch(context);
      
      // Hemen ana sayfadan etkilenen sağlayıcıları yenileyelim
      await Provider.of<NutritionProvider>(context, listen: false).refreshMeals();
    }
  }
  
  Future<void> _toggleEveningExercise() async {
    setState(() {
      isEveningExerciseDone = !isEveningExerciseDone;
    });
    
    if (isEveningExerciseDone) {
      await _recordEveningExercise(context);
      
      // Hemen ana sayfadan etkilenen sağlayıcıları yenileyelim
      await Provider.of<ActivityProvider>(context, listen: false).refreshActivities();
    } else {
      await _removeEveningExercise(context);
      
      // Hemen ana sayfadan etkilenen sağlayıcıları yenileyelim
      await Provider.of<ActivityProvider>(context, listen: false).refreshActivities();
    }
  }
  
  Future<void> _toggleDinner() async {
    setState(() {
      isDinnerDone = !isDinnerDone;
    });
    
    if (isDinnerDone) {
      await _recordDinner(context);
      
      // Hemen ana sayfadan etkilenen sağlayıcıları yenileyelim
      await Provider.of<NutritionProvider>(context, listen: false).refreshMeals();
    } else {
      await _removeDinner(context);
      
      // Hemen ana sayfadan etkilenen sağlayıcıları yenileyelim
      await Provider.of<NutritionProvider>(context, listen: false).refreshMeals();
    }
  }
  
  // Sabah Egzersizi kaydı
  Future<void> _recordMorningExercise(BuildContext context) async {
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    
    // Bugün için egzersiz kaydı ekle
    final now = DateTime.now();
    final durationMinutes = 30; // Varsayılan süre
    
    final morningActivity = ActivityRecord(
      type: FitActivityType.walking,
      durationMinutes: durationMinutes,
      date: now,
      notes: 'Sabah egzersizi tamamlandı',
    );
    
    morningExerciseId = await activityProvider.addActivity(morningActivity);
    
    // Görev durumunu kaydet
    _savingTaskStates();
  }
  
  // Sabah egzersizini sil
  Future<void> _removeMorningExercise(BuildContext context) async {
    if (morningExerciseId != null) {
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      await activityProvider.deleteActivity(morningExerciseId!);
      setState(() {
        morningExerciseId = null;
        _savingTaskStates(); // Durumu kaydet
      });
    }
  }
  
  // Öğle yemeği kaydı
  Future<void> _recordLunch(BuildContext context) async {
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    
    // Bugün için öğle yemeği kaydı ekle
    final now = DateTime.now();
    final calories = 600; // Varsayılan kalori miktarı
    
    final lunchMeal = MealRecord(
      type: FitMealType.lunch,
      foods: ['Protein', 'Karbonhidrat', 'Sebze'],
      date: now,
      calories: calories,
      notes: 'Öğle yemeği tamamlandı',
    );
    
    lunchMealId = await nutritionProvider.addMeal(lunchMeal);
    
    // Görev durumunu kaydet
    _savingTaskStates();
  }
  
  // Öğle yemeğini sil
  Future<void> _removeLunch(BuildContext context) async {
    if (lunchMealId != null) {
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      await nutritionProvider.deleteMeal(lunchMealId!);
      setState(() {
        lunchMealId = null;
        _savingTaskStates(); // Durumu kaydet
      });
    }
  }
  
  // Akşam Egzersizi kaydı
  Future<void> _recordEveningExercise(BuildContext context) async {
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    
    // Bugün için egzersiz kaydı ekle
    final now = DateTime.now();
    final durationMinutes = 45; // Varsayılan süre
    
    final eveningActivity = ActivityRecord(
      type: FitActivityType.weightTraining,
      durationMinutes: durationMinutes,
      date: now,
      notes: 'Akşam egzersizi tamamlandı',
    );
    
    eveningExerciseId = await activityProvider.addActivity(eveningActivity);
    
    // Görev durumunu kaydet
    _savingTaskStates();
  }
  
  // Akşam egzersizini sil
  Future<void> _removeEveningExercise(BuildContext context) async {
    if (eveningExerciseId != null) {
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      await activityProvider.deleteActivity(eveningExerciseId!);
      setState(() {
        eveningExerciseId = null;
        _savingTaskStates(); // Durumu kaydet
      });
    }
  }
  
  // Akşam yemeği kaydı
  Future<void> _recordDinner(BuildContext context) async {
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    
    // Bugün için akşam yemeği kaydı ekle
    final now = DateTime.now();
    final calories = 450; // Varsayılan kalori miktarı
    
    final dinnerMeal = MealRecord(
      type: FitMealType.dinner,
      foods: ['Protein', 'Sebze', 'Salatalar'],
      date: now,
      calories: calories,
      notes: 'Akşam yemeği tamamlandı',
    );
    
    dinnerMealId = await nutritionProvider.addMeal(dinnerMeal);
    
    // Görev durumunu kaydet
    _savingTaskStates();
  }
  
  // Akşam yemeğini sil
  Future<void> _removeDinner(BuildContext context) async {
    if (dinnerMealId != null) {
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      await nutritionProvider.deleteMeal(dinnerMealId!);
      setState(() {
        dinnerMealId = null;
        _savingTaskStates(); // Durumu kaydet
      });
    }
  }

  Future<void> _initTasks() async {
    try {
      // ProgramService üzerinden günün programını al
      final programService = Provider.of<DatabaseProvider>(context, listen: false).programService;
      final today = DateTime.now().weekday - 1; // 0-Pazartesi, 6-Pazar
      
      final dailyProgram = await programService.getDailyProgram(today);
      if (dailyProgram != null) {
        setState(() {
          // Günün programını açıklama metinlerine uygula
          final morningExercise = dailyProgram.morningExercise;
          final lunch = dailyProgram.lunch;
          final eveningExercise = dailyProgram.eveningExercise;
          final dinner = dailyProgram.dinner;
          
          if (morningExercise.description.isNotEmpty) {
            morningProgram = morningExercise.description;
          }
          
          if (lunch.description.isNotEmpty) {
            lunchMenu = lunch.description;
          }
          
          if (eveningExercise.description.isNotEmpty) {
            eveningProgram = eveningExercise.description;
          }
          
          if (dinner.description.isNotEmpty) {
            dinnerMenu = dinner.description;
          }
        });
      }
    } catch (e) {
      print('Program başlatma hatası: $e');
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // DatabaseProvider değişikliklerini dinle
    final databaseProvider = Provider.of<DatabaseProvider>(context);
    databaseProvider.addListener(_refreshProgram);
  }
  
  // Program güncellendiğinde çağrılacak metot
  void _refreshProgram() {
    _initTasks();
  }

  void _onTaskChanged(Task task, bool isCompleted) {
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    
    // Görev durumunu güncelle
    activityProvider.updateTask(task);
    
    if (isCompleted) {
      // Eğer görev tamamlandıysa, ilgili aktivite veya yemek kaydını ekle
      if (task.type == TaskType.morningExercise || task.type == TaskType.eveningExercise) {
        final FitActivityType activityType = task.type == TaskType.morningExercise 
          ? FitActivityType.walking 
          : FitActivityType.running;
        
        activityProvider.addActivity(ActivityRecord(
          type: activityType,
          durationMinutes: 30, // Varsayılan değer
          date: DateTime.now(),
          notes: 'Günlük görev: ${task.title}',
          taskId: task.id,
        ));
      } else if (task.type == TaskType.lunch || task.type == TaskType.dinner) {
        final FitMealType mealType = task.type == TaskType.lunch 
          ? FitMealType.lunch 
          : FitMealType.dinner;
        
        nutritionProvider.addMeal(MealRecord(
          type: mealType,
          foods: ['Günlük öğün'],
          calories: 0, // Varsayılan değer
          date: DateTime.now(),
          taskId: task.id,
        ));
      }
    } else {
      // Görev tamamlanmadı olarak işaretlendiyse, ilgili aktivite veya yemek kaydını sil
      if (task.type == TaskType.morningExercise || task.type == TaskType.eveningExercise) {
        // İlgili taskId'ye sahip aktiviteyi bul ve sil
        activityProvider.deleteActivityByTaskId(task.id);
      } else if (task.type == TaskType.lunch || task.type == TaskType.dinner) {
        // İlgili taskId'ye sahip yemeği bul ve sil
        nutritionProvider.deleteMealByTaskId(task.id);
      }
    }
  }

  Widget _buildTaskCard(Task task) {
    final isDone = task.isCompleted;
    final type = task.type;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      color: isDone ? AppTheme.completedTaskColor : _getTaskColor(type),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          _getTaskIcon(type),
          color: isDone ? Colors.grey : Colors.white,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            decoration: isDone ? TextDecoration.lineThrough : null,
            decorationThickness: 2.0,
          ),
        ),
        subtitle: Text(
          task.description,
          style: TextStyle(
            color: Colors.white70,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: isDone
            ? const Icon(Icons.check_circle, color: Colors.white70)
            : const Icon(Icons.circle_outlined, color: Colors.white70),
        onTap: () {
          _onTaskChanged(task, !isDone);
        },
      ),
    );
  }
  
  Color _getTaskColor(TaskType type) {
    switch (type) {
      case TaskType.morningExercise:
        return AppTheme.morningExerciseColor;
      case TaskType.lunch:
        return AppTheme.lunchColor;
      case TaskType.eveningExercise:
        return AppTheme.eveningExerciseColor;
      case TaskType.dinner:
        return AppTheme.dinnerColor;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getTaskIcon(TaskType type) {
    switch (type) {
      case TaskType.morningExercise:
        return Icons.fitness_center;
      case TaskType.lunch:
        return Icons.lunch_dining;
      case TaskType.eveningExercise:
        return Icons.sports_gymnastics;
      case TaskType.dinner:
        return Icons.dinner_dining;
      default:
        return Icons.check_circle;
    }
  }

  Widget _buildGreetingCard() {
    final userName = Provider.of<UserProvider>(context).user?.name ?? 'Kaplan';
    final formattedDate = DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Merhaba, $userName',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          formattedDate,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _buildMotivationalBox(),
      ],
    );
  }

  Widget _buildMotivationalBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedMotivationalMessage,
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 