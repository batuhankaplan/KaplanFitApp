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
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:io';
import 'program_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Günlük görevlerin durumunu tutan değişkenler
  bool isMorningExerciseDone = false;
  bool isLunchDone = false;
  bool isEveningExerciseDone = false;
  bool isDinnerDone = false;
  bool isLoading = true;

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

  // Su tüketimi için state
  int _waterIntake = 0;
  final int _waterGoal = 2000; // ml

  // Motivasyon mesajları
  final List<String> _motivationalMessages = [
    "Her gün bir adım, sağlıklı yaşama bir adım.",
    "Düzenli egzersiz, sağlıklı beslenme, daha iyi yaşam.",
    "Bugün kendine yatırım yap, yarına sağlıkla uyan.",
    "En iyi yatırım sağlığına yapılandır.",
    "Spor hayattır, hareket sağlıktır.",
    "Sağlıklı bir vücut, mutlu bir zihin demektir.",
    "Bugün başla, yarına erteleme!",
    "Zorluklar güçlü olanları yıldırmaz, vazgeçmeyenleri zafere ulaştırır.",
    "Harekete geç, değişimi başlat!",
    "Dünden daha iyi, yarından daha güçlü!",
    "Bahane üretmek için harcadığın enerjiyi egzersize harca.",
  ];

  // Seçilen motivasyon mesajı
  late String _selectedMotivationalMessage;

  // Sayfa kontrolcüsü
  late PageController _pageController;

  // Yeni animasyon controller
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Animasyon controller'ı başlat
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..forward();

    // Rastgele bir motivasyon mesajı seç
    _selectedMotivationalMessage = _motivationalMessages[
        DateTime.now().millisecondsSinceEpoch % _motivationalMessages.length];

    // Su tüketim değerini yükle
    _loadWaterIntake();

    // Görevleri başlat
    _initTasks();
  }

  @override
  void dispose() {
    // Listener'ı temizleme kısmını güncelliyoruz
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // DatabaseProvider değişikliklerini dinle
    final databaseProvider = Provider.of<DatabaseProvider>(context);

    // Eski listener'ı kaldır ve yenisini ekle
    databaseProvider.removeListener(_refreshProgram);
    databaseProvider.addListener(_refreshProgram);
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

        isLoading = false;
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
    if (morningExerciseId != null)
      prefs.setInt('morningExerciseId', morningExerciseId!);
    if (lunchMealId != null) prefs.setInt('lunchMealId', lunchMealId!);
    if (eveningExerciseId != null)
      prefs.setInt('eveningExerciseId', eveningExerciseId!);
    if (dinnerMealId != null) prefs.setInt('dinnerMealId', dinnerMealId!);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkBackgroundColor : Color(0xFFF8F8FC),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            // Kullanıcı karşılama başlığı ve tarih
            SliverToBoxAdapter(
              child: KFSlideAnimation(
                offsetBegin: Offset(0, 0.1),
                child: _buildWelcomeHeader(context),
              ),
            ),

            // Motivasyon kartı
            SliverToBoxAdapter(
              child: KFSlideAnimation(
                offsetBegin: Offset(0, 0.1),
                delay: Duration(milliseconds: 100),
                child: _buildMotivationCard(context),
              ),
            ),

            // Günlük görevler başlığı
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: KFSlideAnimation(
                  offsetBegin: Offset(0, 0.1),
                  delay: Duration(milliseconds: 150),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Günlük Görevler',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildCompletionBadge(context),
                    ],
                  ),
                ),
              ),
            ),

            // Görev kartları
            SliverList(
              delegate: SliverChildListDelegate([
                KFSlideAnimation(
                  offsetBegin: Offset(0, 0.1),
                  delay: Duration(milliseconds: 200),
                  child: _buildTaskCard(
                    context,
                    icon: Icons.directions_run,
                    title: 'Sabah Egzersizi',
                    subtitle: morningProgram.isNotEmpty
                        ? morningProgram
                        : '30 dakika kardio',
                    time: '08:00',
                    isDone: isMorningExerciseDone,
                    color: AppTheme.morningExerciseColor,
                    onTap: () {
                      // Görev nesnesi oluştur
                      Task task = Task(
                          id: 1, // Sabit ID
                          title: 'Sabah Egzersizi',
                          description: morningProgram.isNotEmpty
                              ? morningProgram
                              : '30 dakika kardio',
                          date: DateTime.now(),
                          isCompleted:
                              !isMorningExerciseDone, // Durumu tersine çevir
                          type: TaskType.morningExercise);

                      // _onTaskChanged fonksiyonunu çağır
                      _onTaskChanged(task, !isMorningExerciseDone);
                    },
                  ),
                ),
                KFSlideAnimation(
                  offsetBegin: Offset(0, 0.1),
                  delay: Duration(milliseconds: 250),
                  child: _buildTaskCard(
                    context,
                    icon: Icons.restaurant,
                    title: 'Sağlıklı Öğle Yemeği',
                    subtitle: lunchMenu.isNotEmpty
                        ? lunchMenu
                        : 'Protein ve sebze ağırlıklı',
                    time: '13:00',
                    isDone: isLunchDone,
                    color: AppTheme.lunchColor,
                    onTap: () {
                      // Görev nesnesi oluştur
                      Task task = Task(
                          id: 2, // Sabit ID
                          title: 'Sağlıklı Öğle Yemeği',
                          description: lunchMenu.isNotEmpty
                              ? lunchMenu
                              : 'Protein ve sebze ağırlıklı',
                          date: DateTime.now(),
                          isCompleted: !isLunchDone, // Durumu tersine çevir
                          type: TaskType.lunch);

                      // _onTaskChanged fonksiyonunu çağır
                      _onTaskChanged(task, !isLunchDone);
                    },
                  ),
                ),
                KFSlideAnimation(
                  offsetBegin: Offset(0, 0.1),
                  delay: Duration(milliseconds: 300),
                  child: _buildTaskCard(
                    context,
                    icon: Icons.fitness_center,
                    title: 'Akşam Antrenmanı',
                    subtitle: eveningProgram.isNotEmpty
                        ? eveningProgram
                        : '45 dakika güç antrenmanı',
                    time: '18:00',
                    isDone: isEveningExerciseDone,
                    color: AppTheme.eveningExerciseColor,
                    onTap: () {
                      // Görev nesnesi oluştur
                      Task task = Task(
                          id: 3, // Sabit ID
                          title: 'Akşam Antrenmanı',
                          description: eveningProgram.isNotEmpty
                              ? eveningProgram
                              : '45 dakika güç antrenmanı',
                          date: DateTime.now(),
                          isCompleted:
                              !isEveningExerciseDone, // Durumu tersine çevir
                          type: TaskType.eveningExercise);

                      // _onTaskChanged fonksiyonunu çağır
                      _onTaskChanged(task, !isEveningExerciseDone);
                    },
                  ),
                ),
                KFSlideAnimation(
                  offsetBegin: Offset(0, 0.1),
                  delay: Duration(milliseconds: 350),
                  child: _buildTaskCard(
                    context,
                    icon: Icons.dinner_dining,
                    title: 'Akşam Yemeği',
                    subtitle: dinnerMenu.isNotEmpty
                        ? dinnerMenu
                        : 'Hafif ve sağlıklı',
                    time: '20:00',
                    isDone: isDinnerDone,
                    color: AppTheme.dinnerColor,
                    onTap: () {
                      // Görev nesnesi oluştur
                      Task task = Task(
                          id: 4, // Sabit ID
                          title: 'Akşam Yemeği',
                          description: dinnerMenu.isNotEmpty
                              ? dinnerMenu
                              : 'Hafif ve sağlıklı',
                          date: DateTime.now(),
                          isCompleted: !isDinnerDone, // Durumu tersine çevir
                          type: TaskType.dinner);

                      // _onTaskChanged fonksiyonunu çağır
                      _onTaskChanged(task, !isDinnerDone);
                    },
                  ),
                ),
              ]),
            ),

            // İstatistikler başlığı
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: KFSlideAnimation(
                  offsetBegin: Offset(0, 0.1),
                  delay: Duration(milliseconds: 400),
                  child: Text(
                    'Haftalık İstatistikler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // İstatistik kartları
            SliverToBoxAdapter(
              child: KFSlideAnimation(
                offsetBegin: Offset(0, 0.1),
                delay: Duration(milliseconds: 450),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildStatCards(context),
                ),
              ),
            ),

            // Alt boşluk
            SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE', 'tr_TR').format(now);
    final dateFormatted = DateFormat('d MMMM yyyy', 'tr_TR').format(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    KFSlideAnimation(
                      offsetBegin: const Offset(0, 0.2),
                      child: Text(
                        'Merhaba, ${user?.name ?? 'Kaplan'}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    KFSlideAnimation(
                      offsetBegin: const Offset(0, 0.2),
                      delay: const Duration(milliseconds: 50),
                      child: Text(
                        '$dateFormatted, $dayOfWeek',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Profil resmi yerine menü butonu eklendi
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: KFSlideAnimation(
                  offsetBegin: const Offset(0, 0.1),
                  delay: const Duration(milliseconds: 100),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => _buildMenuSheet(context),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppTheme.primaryColor.withOpacity(0.3)
                            : AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        Icons.menu,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Menü sayfasını inşa et
  Widget _buildMenuSheet(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 10),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.calendar_today_rounded,
              color: AppTheme.primaryColor,
            ),
            title: Text('Program'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProgramScreen(),
                  settings: RouteSettings(name: "ProgramScreen"),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.bar_chart_rounded,
              color: AppTheme.primaryColor,
            ),
            title: Text('İstatistikler'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatsScreen(),
                  settings: RouteSettings(name: "StatsScreen"),
                ),
              );
            },
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.all(16),
      child: Stack(
        children: [
          // Arkaplan Blur
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.8),
                      AppTheme.primaryColor.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Bugünün Motivasyonu',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '"Başarı her gün tekrarlanan küçük çabalarla elde edilir."',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '- KaplanFit',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Dekoratif daireler
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -15,
            bottom: -15,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBadge(BuildContext context) {
    final completedTasks = [
      isMorningExerciseDone,
      isLunchDone,
      isEveningExerciseDone,
      isDinnerDone
    ].where((task) => task).length;

    final totalTasks = 4;
    final completion = completedTasks / totalTasks;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KFCircularProgressIndicator(
            size: 24,
            strokeWidth: 3,
            value: completion,
            color: AppTheme.primaryColor,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
          ),
          SizedBox(width: 8),
          Text(
            '$completedTasks/$totalTasks',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required bool isDone,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDone
                  ? AppTheme.completedTaskColor
                  : isDarkMode
                      ? color.withOpacity(0.1)
                      : color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                if (!isDarkMode && !isDone)
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
              ],
              border: isDone
                  ? Border.all(color: Colors.grey.withOpacity(0.3), width: 1)
                  : Border.all(color: color.withOpacity(0.5), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.grey.withOpacity(0.2)
                        : color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isDone ? Colors.grey : color,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDone
                              ? Theme.of(context).textTheme.bodySmall?.color
                              : Theme.of(context).textTheme.bodyLarge?.color,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDone
                            ? Theme.of(context).textTheme.bodySmall?.color
                            : color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDone
                            ? color.withOpacity(0.2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isDone
                            ? null
                            : Border.all(
                                color: color.withOpacity(0.5), width: 2),
                      ),
                      child: isDone
                          ? Icon(
                              Icons.check,
                              color: color,
                              size: 16,
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context) {
    // Provider'ları al
    final activityProvider = Provider.of<ActivityProvider>(context);
    final nutritionProvider = Provider.of<NutritionProvider>(context);

    // Bugünün tarihi
    final today = DateTime.now();

    // Bugünkü toplam kalori alımını hesapla
    int totalCalories = 0;
    final meals = nutritionProvider.meals;
    for (var meal in meals) {
      totalCalories += meal.calories?.toInt() ?? 0;
    }

    // Bugünkü toplam aktivite dakikasını hesapla
    int totalActivityMinutes = 0;
    final activities = activityProvider.activities;
    for (var activity in activities) {
      totalActivityMinutes += activity.durationMinutes?.toInt() ?? 0;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.local_fire_department_rounded,
                title: 'Kalori',
                value: '$totalCalories kcal',
                color: AppTheme.lunchColor,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.directions_run_rounded,
                title: 'Aktivite',
                value: '$totalActivityMinutes dk',
                color: AppTheme.eveningExerciseColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildWaterIntakeCard(context, _waterIntake),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          SizedBox(height: 4),
          KFCounterAnimation(
            begin: 0,
            end: int.parse(value.replaceAll(RegExp(r'[^0-9]'), '')),
            suffix: value.replaceAll(RegExp(r'[0-9]'), ''),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIntakeCard(BuildContext context, int waterIntake) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final percentage = (_waterIntake / _waterGoal).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.waterReminderColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: AppTheme.waterReminderColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Su Tüketimi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '$_waterIntake / $_waterGoal ml',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildWaterProgressBar(context, percentage),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWaterButton(context, -150, Colors.red.shade300),
              _buildWaterButton(context, 150, AppTheme.waterReminderColor),
              _buildWaterButton(context, 250, AppTheme.waterReminderColor),
              _buildWaterButton(context, 500, AppTheme.waterReminderColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterProgressBar(BuildContext context, double percentage) {
    return Container(
      height: 12,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.waterReminderColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.waterReminderColor.withOpacity(0.7),
                    AppTheme.waterReminderColor,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterButton(BuildContext context, int amount, Color color) {
    final buttonText = amount > 0 ? '+$amount' : '$amount';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Su ekleme/çıkarma işlemi
          HapticFeedback.lightImpact();
          _updateWaterIntake(amount);

          final message = amount > 0
              ? '$amount ml su eklendi'
              : '${amount.abs()} ml su çıkarıldı';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            buttonText,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _initTasks() async {
    setState(() {
      isLoading = true; // Yükleme başladı
    });

    try {
      // Önce SharedPreferences'den görev durumlarını yükle
      await _loadSavedTaskStates();

      // ProgramService üzerinden günün programını al
      final programService =
          Provider.of<DatabaseProvider>(context, listen: false).programService;

      // Bugünün haftanın günü indeksini al (0-Pazartesi, 6-Pazar)
      final today = DateTime.now().weekday - 1;
      print('Bugünün indeksi: $today'); // Hata ayıklama için log

      // Günlük programı al
      final dailyProgram = await programService.getDailyProgram(today);

      if (dailyProgram != null) {
        print('Günlük program bulundu');

        setState(() {
          // Günün programını açıklama metinlerine uygula
          final morningExercise = dailyProgram.morningExercise;
          final lunch = dailyProgram.lunch;
          final eveningExercise = dailyProgram.eveningExercise;
          final dinner = dailyProgram.dinner;

          // Açıklamaları kaydet
          if (morningExercise.description.isNotEmpty) {
            morningProgram = morningExercise.description;
            print('Sabah egzersizi: $morningProgram');
          }

          if (lunch.description.isNotEmpty) {
            lunchMenu = lunch.description;
            print('Öğle yemeği: $lunchMenu');
          }

          if (eveningExercise.description.isNotEmpty) {
            eveningProgram = eveningExercise.description;
            print('Akşam egzersizi: $eveningProgram');
          }

          if (dinner.description.isNotEmpty) {
            dinnerMenu = dinner.description;
            print('Akşam yemeği: $dinnerMenu');
          }

          isLoading = false; // Yükleme tamamlandı
        });
      } else {
        print('Günlük program bulunamadı');
        setState(() {
          isLoading = false; // Yükleme tamamlandı
        });
      }
    } catch (e) {
      print('Program başlatma hatası: $e');
      setState(() {
        isLoading = false; // Yükleme tamamlandı
      });
    }
  }

  // Program güncellendiğinde çağrılacak metot
  void _refreshProgram() {
    _initTasks();
  }

  void _onTaskChanged(Task task, bool isCompleted) {
    final activityProvider =
        Provider.of<ActivityProvider>(context, listen: false);
    final nutritionProvider =
        Provider.of<NutritionProvider>(context, listen: false);

    // Görev tipine göre durumu güncelle
    if (task.type == TaskType.morningExercise) {
      setState(() {
        isMorningExerciseDone = isCompleted;
      });
    } else if (task.type == TaskType.lunch) {
      setState(() {
        isLunchDone = isCompleted;
      });
    } else if (task.type == TaskType.eveningExercise) {
      setState(() {
        isEveningExerciseDone = isCompleted;
      });
    } else if (task.type == TaskType.dinner) {
      setState(() {
        isDinnerDone = isCompleted;
      });
    }

    // Görev durumunu güncelle
    Task updatedTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        date: task.date,
        isCompleted: isCompleted,
        type: task.type);
    activityProvider.updateTask(updatedTask);

    // Durumları kaydet
    _savingTaskStates();

    if (isCompleted) {
      // Eğer görev tamamlandıysa, ilgili aktivite veya yemek kaydını ekle
      if (task.type == TaskType.morningExercise ||
          task.type == TaskType.eveningExercise) {
        final FitActivityType activityType =
            task.type == TaskType.morningExercise
                ? FitActivityType.walking
                : FitActivityType.running;

        // Yeni aktivite oluştur ve ID'sini sakla
        activityProvider
            .addActivity(ActivityRecord(
          type: activityType,
          durationMinutes: 30, // Varsayılan değer
          date: DateTime.now(),
          notes: 'Günlük görev: ${task.title}',
          taskId: task.id,
        ))
            .then((activityId) {
          if (task.type == TaskType.morningExercise) {
            setState(() {
              morningExerciseId = activityId;
            });
          } else {
            setState(() {
              eveningExerciseId = activityId;
            });
          }
          _savingTaskStates(); // ID'yi kaydedince tekrar kaydet
        });
      } else if (task.type == TaskType.lunch || task.type == TaskType.dinner) {
        final FitMealType mealType = task.type == TaskType.lunch
            ? FitMealType.lunch
            : FitMealType.dinner;

        // Yeni öğün oluştur ve ID'sini sakla
        nutritionProvider
            .addMeal(MealRecord(
          type: mealType,
          foods: ['Günlük öğün'],
          calories: 500, // Varsayılan değer
          date: DateTime.now(),
          taskId: task.id,
        ))
            .then((mealId) {
          if (task.type == TaskType.lunch) {
            setState(() {
              lunchMealId = mealId;
            });
          } else {
            setState(() {
              dinnerMealId = mealId;
            });
          }
          _savingTaskStates(); // ID'yi kaydedince tekrar kaydet
        });
      }
    } else {
      // Görev tamamlanmadı olarak işaretlendiyse, ilgili aktivite veya yemek kaydını sil
      if (task.type == TaskType.morningExercise) {
        if (morningExerciseId != null) {
          activityProvider.deleteActivityByTaskId(task.id);
          setState(() {
            morningExerciseId = null;
          });
        }
      } else if (task.type == TaskType.eveningExercise) {
        if (eveningExerciseId != null) {
          activityProvider.deleteActivityByTaskId(task.id);
          setState(() {
            eveningExerciseId = null;
          });
        }
      } else if (task.type == TaskType.lunch) {
        if (lunchMealId != null) {
          nutritionProvider.deleteMealByTaskId(task.id);
          setState(() {
            lunchMealId = null;
          });
        }
      } else if (task.type == TaskType.dinner) {
        if (dinnerMealId != null) {
          nutritionProvider.deleteMealByTaskId(task.id);
          setState(() {
            dinnerMealId = null;
          });
        }
      }
      _savingTaskStates(); // Güncellemeleri kaydet
    }
  }

  Widget _buildGreetingCard() {
    final userName = Provider.of<UserProvider>(context).user?.name ?? 'Kaplan';
    final formattedDate =
        DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now());

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
            color:
                Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
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

  // Su tüketim değerini yükle
  Future<void> _loadWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      _waterIntake = prefs.getInt('water_intake_$today') ?? 0;
    });
  }

  // Su tüketim değerini kaydet
  Future<void> _saveWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setInt('water_intake_$today', _waterIntake);
  }

  // Su tüketim değerini güncelle
  void _updateWaterIntake(int amount) {
    setState(() {
      _waterIntake =
          (_waterIntake + amount).clamp(0, 5000); // Max 5 litre olarak sınırla
    });
    _saveWaterIntake();
  }
}
