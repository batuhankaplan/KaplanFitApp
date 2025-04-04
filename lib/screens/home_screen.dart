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
  
  // Sayfa kontrolcüsü
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initTasks();
    _loadSavedTaskStates();
  }
  
  @override
  void dispose() {
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
    
    // Plan.txt içeriğinden haftanın gününe göre program içeriğini al
    String morningProgram = '';
    String lunchMenu = '';
    String eveningProgram = '';
    String dinnerMenu = '';
    
    // Haftanın gününe göre program bilgilerini ekle
    switch (today.weekday) {
      case DateTime.monday: // Pazartesi
        morningProgram = '🏊‍♂️ Havuz kapalı. Dinlen veya evde esneme yap.';
        lunchMenu = '🍗 Izgara tavuk, 🍚 pirinç pilavı, 🥗 yağlı salata, 🥛 yoğurt, 🍌 muz, badem/ceviz';
        eveningProgram = '🛑 Spor salonu kapalı. Dinlen veya hafif yürüyüş.';
        dinnerMenu = '🥗 Ton balıklı salata, yoğurt, 🥖 tahıllı ekmek';
        break;
      case DateTime.tuesday: // Salı
        morningProgram = '🏊‍♂️ 08:45 - 09:15 yüzme';
        lunchMenu = '🥣 Yulaf + süt + muz veya Pazartesi menüsü';
        eveningProgram = '(18:00 - 18:45 Ağırlık): Squat, Leg Press, Bench Press, Lat Pull-Down';
        dinnerMenu = '🍗 Izgara tavuk veya 🐟 ton balıklı salata, yoğurt';
        break;
      case DateTime.wednesday: // Çarşamba
        morningProgram = '🏊‍♂️ 08:45 - 09:15 yüzme';
        lunchMenu = '🥣 Yulaf + süt + muz veya Pazartesi menüsü';
        eveningProgram = '(18:00 - 18:45 Ağırlık): Row, Goblet Squat, Core Çalışmaları';
        dinnerMenu = '🐔 Tavuk veya 🐟 ton balık, 🥗 yağlı salata, yoğurt';
        break;
      case DateTime.thursday: // Perşembe
        morningProgram = '🏊‍♂️ 08:45 - 09:15 yüzme';
        lunchMenu = '🍗 Izgara tavuk, 🍚 pirinç pilavı, 🥗 yağlı salata, 🥛 yoğurt, 🍌 muz, badem/ceviz veya yulaf alternatifi';
        eveningProgram = '(18:00 - 18:45 Ağırlık): 🔄 Salı antrenmanı tekrarı';
        dinnerMenu = '🐔 Tavuk veya 🐟 ton balık, 🥗 salata, yoğurt';
        break;
      case DateTime.friday: // Cuma
        morningProgram = '🚶‍♂️ İsteğe bağlı yüzme veya yürüyüş';
        lunchMenu = '🥚 Tavuk, haşlanmış yumurta, 🥗 yoğurt, salata, kuruyemiş';
        eveningProgram = '🤸‍♂️ Dinlenme veya esneme';
        dinnerMenu = '🍳 Menemen, 🥗 ton balıklı salata, yoğurt';
        break;
      case DateTime.saturday: // Cumartesi
        morningProgram = '🚶‍♂️ Hafif yürüyüş, esneme veya yüzme';
        lunchMenu = '🐔 Tavuk, yumurta, pilav, salata';
        eveningProgram = '⚡️ İsteğe bağlı egzersiz';
        dinnerMenu = '🍽️ Sağlıklı serbest menü';
        break;
      case DateTime.sunday: // Pazar
        morningProgram = '🧘‍♂️ Tam dinlenme veya 20-30 dk yürüyüş';
        lunchMenu = '🔄 Hafta içi prensipteki öğünler';
        eveningProgram = '💤 Dinlenme';
        dinnerMenu = '🍴 Hafif ve dengeli öğün';
        break;
    }
    
    // Genel tavsiyeler
    final String additionalNote = '💧 Günde en az 2-3 litre su içmeyi unutmayın!\n'
        '❌ Şekerli içeceklerden uzak durun.\n'
        '🍌 Her gün 1 muz tüketin (potasyum kaynağı).';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('KaplanFIT', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? AppTheme.backgroundColor
            : AppTheme.primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık kısmı - tema uyumlu
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Theme.of(context).scaffoldBackgroundColor // Ana ekranın arka planıyla aynı rengi kullan
                    : Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba${user != null ? ' ${user.name}' : ''}!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ayağa kalk ve harekete geç!',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
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
              GestureDetector(
                onTap: () {
                  setState(() {
                    isMorningExerciseDone = !isMorningExerciseDone;
                  });
                  
                  if (isMorningExerciseDone) {
                    _recordMorningExercise(context);
                  } else {
                    _removeMorningExercise(context);
                  }
                },
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
              
              // Öğle Yemeği kartı
              GestureDetector(
                onTap: () {
                  setState(() {
                    isLunchDone = !isLunchDone;
                  });
                  
                  if (isLunchDone) {
                    _recordLunch(context);
                  } else {
                    _removeLunch(context);
                  }
                },
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
                        Icon(
                          Icons.lunch_dining,
                          color: Colors.white,
                          size: 18,
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
              
              // Akşam Egzersizi kartı
              GestureDetector(
                onTap: () {
                  setState(() {
                    isEveningExerciseDone = !isEveningExerciseDone;
                  });
                  
                  if (isEveningExerciseDone) {
                    _recordEveningExercise(context);
                  } else {
                    _removeEveningExercise(context);
                  }
                },
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
                          Icons.directions_run,
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
              
              // Akşam Yemeği kartı
              GestureDetector(
                onTap: () {
                  setState(() {
                    isDinnerDone = !isDinnerDone;
                  });
                  
                  if (isDinnerDone) {
                    _recordDinner(context);
                  } else {
                    _removeDinner(context);
                  }
                },
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
  
  // Sabah egzersizini kaydet
  void _recordMorningExercise(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    final today = DateTime.now();
    
    // Sabah egzersizi için aktivite kaydı ekle
    final morningActivity = ActivityRecord(
      type: FitActivityType.walking, // Yürüyüş aktivitesi
      durationMinutes: 30, // 30 dakika süre
      date: DateTime(today.year, today.month, today.day, 8, 0), // Sabah 8:00
      notes: 'Sabah tempolu yürüyüş',
    );
    
    activityProvider.addActivity(morningActivity).then((id) {
      setState(() {
        morningExerciseId = id;
        _savingTaskStates(); // Durumu kaydet
      });
    });
  }
  
  // Sabah egzersizini sil
  void _removeMorningExercise(BuildContext context) {
    if (morningExerciseId != null) {
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      activityProvider.deleteActivity(morningExerciseId!);
      setState(() {
        morningExerciseId = null;
        _savingTaskStates(); // Durumu kaydet
      });
    }
  }
  
  // Öğle yemeğini kaydet
  void _recordLunch(BuildContext context) {
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    final today = DateTime.now();
    
    // Öğle yemeği için öğün kaydı ekle
    final lunchMeal = MealRecord(
      type: FitMealType.lunch,
      foods: ['Tavuk', 'Pilav', 'Salata', 'Yoğurt'],
      date: DateTime(today.year, today.month, today.day, 13, 0), // Öğle 13:00
      calories: 550,
    );
    
    nutritionProvider.addMeal(lunchMeal).then((id) {
      setState(() {
        lunchMealId = id;
        _savingTaskStates(); // Durumu kaydet
      });
    });
  }
  
  // Öğle yemeğini sil
  void _removeLunch(BuildContext context) {
    if (lunchMealId != null) {
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      nutritionProvider.deleteMeal(lunchMealId!);
      setState(() {
        lunchMealId = null;
        _savingTaskStates(); // Durumu kaydet
      });
    }
  }
  
  // Akşam egzersizini kaydet
  void _recordEveningExercise(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    final today = DateTime.now();
    
    // Akşam egzersizi için aktivite kaydı ekle
    final eveningActivity = ActivityRecord(
      type: FitActivityType.weightTraining, // Ağırlık aktivitesi
      durationMinutes: 45, // 45 dakika süre
      date: DateTime(today.year, today.month, today.day, 18, 0), // Akşam 18:00
      notes: 'Ağırlık antrenmanı',
    );
    
    activityProvider.addActivity(eveningActivity).then((id) {
      setState(() {
        eveningExerciseId = id;
        _savingTaskStates(); // Durumu kaydet
      });
    });
  }
  
  // Akşam egzersizini sil
  void _removeEveningExercise(BuildContext context) {
    if (eveningExerciseId != null) {
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      activityProvider.deleteActivity(eveningExerciseId!);
      setState(() {
        eveningExerciseId = null;
        _savingTaskStates(); // Durumu kaydet
      });
    }
  }
  
  // Akşam yemeğini kaydet
  void _recordDinner(BuildContext context) {
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    final today = DateTime.now();
    
    // Akşam yemeği için öğün kaydı ekle
    final dinnerMeal = MealRecord(
      type: FitMealType.dinner,
      foods: ['Hafif protein', 'Sebze', 'Tahıl'],
      date: DateTime(today.year, today.month, today.day, 19, 0), // Akşam 19:00
      calories: 450,
    );
    
    nutritionProvider.addMeal(dinnerMeal).then((id) {
      setState(() {
        dinnerMealId = id;
        _savingTaskStates(); // Durumu kaydet
      });
    });
  }
  
  // Akşam yemeğini sil
  void _removeDinner(BuildContext context) {
    if (dinnerMealId != null) {
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      nutritionProvider.deleteMeal(dinnerMealId!);
      setState(() {
        dinnerMealId = null;
        _savingTaskStates(); // Durumu kaydet
      });
    }
  }

  void _initTasks() {
    final now = DateTime.now();
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    
    // Günlük görevleri oluştur veya var olanları getir
    final String today = DateFormat('yyyy-MM-dd').format(now);
    if (activityProvider.dailyTasksDate != today) {
      activityProvider.resetDailyTasks(today);
    }
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
} 