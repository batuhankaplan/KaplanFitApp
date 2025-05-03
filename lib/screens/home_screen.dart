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
import '../providers/database_provider.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:io';
import 'program_screen.dart';
import 'stats_screen.dart';
import '../models/program_model.dart';
import '../models/user_model.dart';
import '../services/program_service.dart';
import 'goal_tracking_screen.dart';
import '../services/database_service.dart';
import '../services/exercise_service.dart';
import 'profile_screen.dart';
import 'workout_program_screen.dart';

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
  String morningProgram = 'Program yükleniyor...';
  String lunchMenu = 'Program yükleniyor...';
  String eveningProgram = 'Program yükleniyor...';
  String dinnerMenu = 'Program yükleniyor...';

  // Su tüketimi için state
  int _waterIntake = 0;

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
    print("[HomeScreen] initState started."); // LOG
    _pageController = PageController();
    // Animasyon controller'ı başlat
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..forward();

    // Rastgele bir motivasyon mesajı seç
    _selectedMotivationalMessage = _motivationalMessages[
        DateTime.now().millisecondsSinceEpoch % _motivationalMessages.length];

    // Verileri yükle (görevler, su vb.)
    print("[HomeScreen] initState calling _loadData()."); // LOG
    _loadData();

    // Artık kullanıcı kontrolünü burada yapmıyoruz, Splash Screen hallediyor.
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _checkUserAndNavigate();
    // });
    print("[HomeScreen] initState finished."); // LOG
  }

  @override
  void dispose() {
    print("[HomeScreen] dispose called."); // LOG
    // Listener'ı temizleme kısmını güncelliyoruz
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /* // ESKİ: DatabaseProvider kaldırıldığı için bu kod artık geçerli değil.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // DatabaseProvider değişikliklerini dinle
    final databaseProvider = Provider.of<DatabaseProvider>(context);

    // Eski listener'ı kaldır ve yenisini ekle
    databaseProvider.removeListener(_refreshProgram);
    databaseProvider.addListener(_refreshProgram);
  }
  */

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
    print("[HomeScreen] _savingTaskStates called."); // LOG
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
    print("[HomeScreen] build started. isLoading: $isLoading"); // LOG
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Kullanıcıyı al (null olabilir, güvenli erişim önemli)
    final userProvider = Provider.of<UserProvider>(context);
    final UserModel? user = userProvider.user;
    print(
        "[HomeScreen] build: User fetched from provider. User is ${user == null ? 'null' : 'not null'}."); // LOG

    if (isLoading) {
      print("[HomeScreen] build: Showing loading indicator."); // LOG
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
                child: _buildWelcomeHeader(context, user),
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
                  child: _TaskItem(
                    icon: Icons.directions_run_rounded,
                    title: 'Sabah Egzersizi',
                    time: '08:00',
                    isDone: isMorningExerciseDone,
                    color: AppTheme.morningExerciseColor,
                    description: morningProgram,
                    onTap: () {
                      _toggleTaskCompletion(TaskType.morningExercise);
                    },
                  ),
                ),
                KFSlideAnimation(
                  offsetBegin: Offset(0, 0.1),
                  delay: Duration(milliseconds: 250),
                  child: _TaskItem(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Sağlıklı Öğle Yemeği',
                    time: '13:00',
                    isDone: isLunchDone,
                    color: AppTheme.lunchColor,
                    description: lunchMenu,
                    onTap: () {
                      _toggleTaskCompletion(TaskType.lunch);
                    },
                  ),
                ),
                KFSlideAnimation(
                  offsetBegin: Offset(0, 0.1),
                  delay: Duration(milliseconds: 300),
                  child: _TaskItem(
                    icon: Icons.fitness_center_rounded,
                    title: 'Akşam Antrenmanı',
                    time: '18:00',
                    isDone: isEveningExerciseDone,
                    color: AppTheme.eveningExerciseColor,
                    description: eveningProgram,
                    onTap: () {
                      _toggleTaskCompletion(TaskType.eveningExercise);
                    },
                  ),
                ),
                KFSlideAnimation(
                  offsetBegin: Offset(0, 0.1),
                  delay: Duration(milliseconds: 350),
                  child: _TaskItem(
                    icon: Icons.dinner_dining_rounded,
                    title: 'Akşam Yemeği',
                    time: '20:00',
                    isDone: isDinnerDone,
                    color: AppTheme.dinnerColor,
                    description: dinnerMenu,
                    onTap: () {
                      _toggleTaskCompletion(TaskType.dinner);
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

  Widget _buildWelcomeHeader(BuildContext context, UserModel? user) {
    print("[HomeScreen] _buildWelcomeHeader called."); // LOG
    // Kullanıcı adını güvenli bir şekilde al
    final userName =
        user?.name ?? 'Kullanıcı'; // Eğer user null ise 'Kullanıcı' yaz
    print("[HomeScreen] _buildWelcomeHeader: User name is '$userName'."); // LOG

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE', 'tr_TR').format(now);
    final dateFormatted = DateFormat('d MMMM yyyy', 'tr_TR').format(now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Dikeyde ortala
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize
                  .min, // Column'un dikeyde minimum yer kaplamasını sağla
              children: [
                KFSlideAnimation(
                  offsetBegin: const Offset(0, 0.2),
                  child: _buildWelcomeTitle(),
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
          // Menü butonu - Padding'i Row içinde tutalım
          KFSlideAnimation(
            offsetBegin: const Offset(0, 0.1),
            delay: const Duration(milliseconds: 100),
            child: Material(
              color: Colors.transparent, // Arka plan rengini şeffaf yap
              shape: CircleBorder(), // Şeklini daire yap
              clipBehavior:
                  Clip.antiAlias, // Tıklama efektinin taşmasını engelle
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
              Icons.fitness_center_rounded,
              color: AppTheme.primaryColor,
            ),
            title: Text('Antrenman Programı'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkoutProgramScreen(),
                  settings: RouteSettings(name: "WorkoutProgramScreen"),
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
          ListTile(
            leading: Icon(
              Icons.check_circle_outline_rounded,
              color: AppTheme.primaryColor,
            ),
            title: Text('Hedef Takibi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalTrackingScreen(),
                  settings: RouteSettings(name: "GoalTrackingScreen"),
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
    // Provider'ları güvenli bir şekilde kontrol edelim
    ActivityProvider? activityProvider;
    NutritionProvider? nutritionProvider;
    UserModel? user = Provider.of<UserProvider>(context, listen: false)
        .user; // Kullanıcıyı al

    try {
      activityProvider = Provider.of<ActivityProvider>(context);
      print(
          "[HomeScreen] _buildStatCards: ActivityProvider accessed successfully."); // LOG
    } catch (e, stacktrace) {
      print(
          "[HomeScreen] _buildStatCards: Error accessing ActivityProvider: $e"); // LOG
      print(
          "[HomeScreen] _buildStatCards: ActivityProvider Stacktrace: $stacktrace"); // LOG
      // activityProvider null kalacak
    }

    try {
      nutritionProvider = Provider.of<NutritionProvider>(context);
      print(
          "[HomeScreen] _buildStatCards: NutritionProvider accessed successfully."); // LOG
    } catch (e, stacktrace) {
      print(
          "[HomeScreen] _buildStatCards: Error accessing NutritionProvider: $e"); // LOG
      print(
          "[HomeScreen] _buildStatCards: NutritionProvider Stacktrace: $stacktrace"); // LOG
      // nutritionProvider null kalacak
    }

    // Bugünün tarihi
    final today = DateTime.now();

    // Bugünkü toplam kalori alımını hesapla
    int totalCalories = 0;
    if (nutritionProvider != null) {
      final meals = nutritionProvider.meals;
      for (var meal in meals) {
        totalCalories += meal.calories?.toInt() ?? 0;
      }
    }

    // Bugünkü toplam aktivite dakikasını hesapla
    int totalActivityMinutes = 0;
    if (activityProvider != null) {
      final activities = activityProvider.activities;
      for (var activity in activities) {
        totalActivityMinutes += activity.durationMinutes?.toInt() ?? 0;
      }
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
    final user = Provider.of<UserProvider>(context, listen: false).user;

    // Hedefi UserProvider'dan al (Litre ise ml'ye çevir), null ise varsayılan 2000 ml
    final double targetWaterLiters =
        user?.targetWaterIntake ?? 2.0; // Varsayılan 2 Litre
    final int waterGoalMl =
        (targetWaterLiters * 1000).toInt().clamp(1, 100000); // Min 1 ml hedef

    final percentage = (waterIntake / waterGoalMl).clamp(0.0, 1.0);

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
                '$_waterIntake / $waterGoalMl ml',
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
    final buttonText = amount > 0 ? '+' + amount.toString() : amount.toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Su ekleme/çıkarma işlemi
          HapticFeedback.lightImpact();
          if (amount > 0) {
            _addWater(amount);
          } else if (amount < 0) {
            _removeWater(amount.abs());
          }

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

  // Görevleri ProgramService'ten yükle ve durumu başlat
  // Bu metot artık _loadData içine entegre edildi, kullanılmıyor
  // Future<void> _initTasks() async {
  //   setState(() {
  //     isLoading = true; // Yükleme başlıyor
  //   });
  //
  //   try {
  //     // UserProvider'dan kullanıcı bilgisini al
  //     final userProvider = Provider.of<UserProvider>(context, listen: false);
  //     final user = userProvider.user;
  //
  //     // ProgramService'i Provider'dan al
  //     final programService =
  //         Provider.of<ProgramService>(context, listen: false);
  //
  //     // Haftalık programı al (initialize zaten main'de çağrılmış olmalı)
  //     final weeklyProgram = await programService.getWeeklyProgram();
  //     final today = DateTime.now();
  //     final todayIndex = today.weekday - 1; // Pzt=0, Sal=1, ..., Paz=6
  //
  //     print("Bugünün indeksi: $todayIndex");
  //
  //     // WeeklyProgram listesi null değilse ve bugünün indexi geçerliyse devam et
  //     if (weeklyProgram.length > todayIndex) {
  //       final dailyProgram = weeklyProgram[todayIndex];
  //       print("Günlük program bulundu");
  //
  //       // Görevleri state'e ata (ProgramItem'dan description veya title al)
  //       if (mounted) {
  //         setState(() {
  //           // Sabah görevi (Antrenman ise title, değilse description veya title)
  //           morningProgram = (dailyProgram.morningExercise.type ==
  //                   ProgramItemType.workout
  //               ? dailyProgram.morningExercise.title
  //               : dailyProgram.morningExercise.description?.isNotEmpty == true
  //                   ? dailyProgram.morningExercise.description!
  //                   : dailyProgram.morningExercise.title);
  //           // Öğle Yemeği (Description veya title)
  //           lunchMenu = dailyProgram.lunch.description?.isNotEmpty == true
  //               ? dailyProgram.lunch.description!
  //               : dailyProgram.lunch.title;
  //           // Akşam görevi (Antrenman ise title, değilse description veya title)
  //           eveningProgram = (dailyProgram.eveningExercise.type ==
  //                   ProgramItemType.workout
  //               ? dailyProgram.eveningExercise.title
  //               : dailyProgram.eveningExercise.description?.isNotEmpty == true
  //                   ? dailyProgram.eveningExercise.description!
  //                   : dailyProgram.eveningExercise.title);
  //           // Akşam Yemeği (Description veya title)
  //           dinnerMenu = dailyProgram.dinner.description?.isNotEmpty == true
  //               ? dailyProgram.dinner.description!
  //               : dailyProgram.dinner.title;
  //         });
  //         print("Sabah görevi: $morningProgram");
  //         print("Öğle görevi: $lunchMenu");
  //         print("Akşam görevi: $eveningProgram");
  //         print("Akşam yemeği görevi: $dinnerMenu");
  //       } else {
  //         print("Bugün için program bulunamadı veya program eksik.");
  //         if (mounted) {
  //           setState(() {
  //             morningProgram = 'Program Yok';
  //             lunchMenu = 'Program Yok';
  //             eveningProgram = 'Program Yok';
  //             dinnerMenu = 'Program Yok';
  //           });
  //         }
  //       }
  //
  //       // Kaydedilmiş görev durumlarını yükle
  //       await _loadSavedTaskStates(); // Program yüklendikten sonra durumları yükle
  //     } else {
  //       print(
  //           "[HomeScreen] _loadDailyTasks: Invalid todayIndex: $todayIndex"); // LOG
  //       // Hata durumu veya varsayılanları ayarla
  //       setState(() {
  //         morningProgram = 'Program günü bulunamadı';
  //         lunchMenu = 'Program günü bulunamadı';
  //         eveningProgram = 'Program günü bulunamadı';
  //         dinnerMenu = 'Program günü bulunamadı';
  //       });
  //     }
  //   } catch (e, stacktrace) {
  //     print("[HomeScreen] _loadDailyTasks Error: $e"); // LOG
  //     print("[HomeScreen] _loadDailyTasks Stacktrace: $stacktrace"); // LOG
  //     if (mounted) {
  //       setState(() {
  //         morningProgram = 'Hata oluştu';
  //         lunchMenu = 'Hata oluştu';
  //         eveningProgram = 'Hata oluştu';
  //         dinnerMenu = 'Hata oluştu';
  //       });
  //     }
  //   }
  //
  //   // YENİ: Görevleri _loadData içinde yükle
  //   final userProvider = Provider.of<UserProvider>(context, listen: false);
  //   final user = userProvider.user;
  //   await _loadDailyTasks(user?.id ?? 0); // UserId geçildi
  //
  //   // Bugün için su tüketimini veritabanından yükle
  //   final today = DateTime.now();
  //   final dbService = DatabaseService();
  //   final savedIntake = await dbService.getWaterLogForDay(today, user?.id ?? 0);
  //   if (mounted) {
  //     setState(() {
  //       _waterIntake = savedIntake;
  //     });
  //   }
  //
  //   // Yükleme bitti
  //   if (mounted) {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  // Program güncellendiğinde görevleri yenilemek için (DatabaseProvider dinleyicisi)
  void _refreshProgram() {
    print("Veritabanı değişikliği algılandı, program yenileniyor...");
    _loadData();
  }

  // Aktivite türüne, süreye ve kiloya göre yakılan kaloriyi hesapla
  double? _calculateCaloriesBurned(
      FitActivityType type, int durationMinutes, double? userWeightKg) {
    if (userWeightKg == null || userWeightKg <= 0 || durationMinutes <= 0) {
      return null; // Geçersiz girdi
    }

    // MET değerleri (Metabolic Equivalent of Task) - Yaklaşık değerler
    // Kaynak: Çeşitli fitness kaynakları, ortalama değerler alınmıştır.
    double metValue = 3.0; // Varsayılan (other için)
    switch (type) {
      case FitActivityType.walking:
        metValue = 3.5;
        break;
      case FitActivityType.running:
        metValue = 7.0; // Hıza göre değişir
        break;
      case FitActivityType.swimming:
        metValue = 7.0; // Tempoya göre değişir
        break;
      case FitActivityType.weightTraining:
        metValue = 4.5; // Yoğunluğa göre değişir
        break;
      case FitActivityType.cycling:
        metValue = 6.0; // Hıza/Dirence göre değişir
        break;
      case FitActivityType.yoga:
        metValue = 2.5;
        break;
      case FitActivityType.other:
        metValue = 3.0;
        break;
    }

    // Kalori = MET * Kilo (kg) * Süre (saat)
    double calories = metValue * userWeightKg * (durationMinutes / 60.0);
    return calories;
  }

  // Görev tamamlama durumunu değiştir
  Future<void> _toggleTaskCompletion(TaskType taskType) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null || user.id == null) {
      print("Görev tamamlama işlemi için kullanıcı bulunamadı.");
      return;
    }

    bool currentState;
    // int? recordId; // Kayıt ID'sine artık gerek yok
    // String recordKey; // Kayıt ID'sine artık gerek yok

    switch (taskType) {
      case TaskType.morningExercise:
        currentState = isMorningExerciseDone;
        // recordId = morningExerciseId; // Kaldırıldı
        // recordKey = 'morningExerciseId'; // Kaldırıldı
        break;
      case TaskType.lunch:
        currentState = isLunchDone;
        // recordId = lunchMealId; // Kaldırıldı
        // recordKey = 'lunchMealId'; // Kaldırıldı
        break;
      case TaskType.eveningExercise:
        currentState = isEveningExerciseDone;
        // recordId = eveningExerciseId; // Kaldırıldı
        // recordKey = 'eveningExerciseId'; // Kaldırıldı
        break;
      case TaskType.dinner:
        currentState = isDinnerDone;
        // recordId = dinnerMealId; // Kaldırıldı
        // recordKey = 'dinnerMealId'; // Kaldırıldı
        break;
      default:
        return;
    }

    final newState = !currentState;
    // final dbService = DatabaseService(); // DB servisine gerek kalmadı (şimdilik)
    // final prefs = await SharedPreferences.getInstance(); // _savingTaskStates içinde zaten var

    // Durumu güncelle
    setState(() {
      switch (taskType) {
        case TaskType.morningExercise:
          isMorningExerciseDone = newState;
          break;
        case TaskType.lunch:
          isLunchDone = newState;
          break;
        case TaskType.eveningExercise:
          isEveningExerciseDone = newState;
          break;
        case TaskType.dinner:
          isDinnerDone = newState;
          break;
        default:
          break;
      }
    });

    // SharedPreferences'e SADECE görev durumunu kaydet
    await _savingTaskStates(); // Bu fonksiyon zaten ID'leri kaydetmiyordu, sadece bool durumları

    // Aktivite veya Öğün kaydını ekle/sil KISMI KALDIRILDI
    /* // Bu bölüm tamamen kaldırıldı
    try {
      if (taskType == TaskType.morningExercise ||
          taskType == TaskType.eveningExercise) {
         // ... Aktivite ekleme/silme kodu ...
      } else if (taskType == TaskType.lunch || taskType == TaskType.dinner) {
        // ... Öğün ekleme/silme kodu ...
      }
    } catch (e) {
       // ... Hata yönetimi ...
    }
    */

    print("Görev durumu güncellendi: $taskType -> $newState"); // Loglama
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

  // Tüm verileri yükle
  Future<void> _loadData() async {
    print("[HomeScreen] _loadData started."); // LOG
    if (!mounted) {
      print("[HomeScreen] _loadData: Not mounted, returning."); // LOG
      return;
    }
    setState(() {
      isLoading = true;
      print("[HomeScreen] _loadData: isLoading set to true."); // LOG
    });

    try {
      print("[HomeScreen] _loadData: Loading saved task states..."); // LOG
      await _loadSavedTaskStates();
      print("[HomeScreen] _loadData: Loading daily tasks..."); // LOG
      await _loadDailyTasks();
      print("[HomeScreen] _loadData: Loading water intake..."); // LOG
      await _loadWaterIntake();
      print("[HomeScreen] _loadData: Loading activity summary..."); // LOG
      await _loadActivitySummary();
    } catch (e, stacktrace) {
      print("[HomeScreen] _loadData Error: $e"); // LOG
      print("[HomeScreen] _loadData Stacktrace: $stacktrace"); // LOG
      // Hata durumunda kullanıcıya bilgi verilebilir
      // ScaffoldMessenger.of(context).showSnackBar(...);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          print(
              "[HomeScreen] _loadData: isLoading set to false (finally)."); // LOG
        });
      }
    }
  }

  // Günlük görevleri ve programı yükle
  Future<void> _loadDailyTasks() async {
    print("[HomeScreen] _loadDailyTasks started."); // LOG
    if (!mounted) return;

    final programService = Provider.of<ProgramService>(context, listen: false);
    final today = DateTime.now();
    final todayWeekday = today.weekday;

    try {
      // ProgramService'den haftalık programı al
      print(
          "[HomeScreen] _loadDailyTasks: Getting weekly program from ProgramService"); // LOG
      final weeklyProgram =
          await programService.getWeeklyProgram(); // Haftalık programı al

      if (weeklyProgram.isNotEmpty && mounted) {
        // Bugünün indeksini bul (0=Pzt, 6=Paz)
        final todayIndex = todayWeekday - 1;
        if (todayIndex >= 0 && todayIndex < weeklyProgram.length) {
          final dailyProgram = weeklyProgram[todayIndex];
          print(
              "[HomeScreen] _loadDailyTasks: Daily program found for index $todayIndex. Updating state."); // LOG
          setState(() {
            morningProgram = dailyProgram.morningExercise.title;
            lunchMenu = dailyProgram.lunch.description ?? 'Belirtilmedi';
            eveningProgram = dailyProgram.eveningExercise.title;
            dinnerMenu = dailyProgram.dinner.description ?? 'Belirtilmedi';
          });
          print(
              "Yüklenen görevler: Sabah: $morningProgram, Öğle: $lunchMenu, Akşam: $eveningProgram, Akşam Yemeği: $dinnerMenu"); // LOG
        } else {
          print(
              "[HomeScreen] _loadDailyTasks: Invalid todayIndex: $todayIndex"); // LOG
          // Hata durumu veya varsayılanları ayarla
          setState(() {
            morningProgram = 'Program günü bulunamadı';
            lunchMenu = 'Program günü bulunamadı';
            eveningProgram = 'Program günü bulunamadı';
            dinnerMenu = 'Program günü bulunamadı';
          });
        }
      } else {
        print(
            "[HomeScreen] _loadDailyTasks: Weekly program is empty or widget not mounted."); // LOG
        if (mounted) {
          setState(() {
            morningProgram = 'Program bulunamadı';
            lunchMenu = 'Program bulunamadı';
            eveningProgram = 'Program bulunamadı';
            dinnerMenu = 'Program bulunamadı';
          });
        }
      }
    } catch (e, stacktrace) {
      print("[HomeScreen] _loadDailyTasks Error: $e"); // LOG
      print("[HomeScreen] _loadDailyTasks Stacktrace: $stacktrace"); // LOG
      if (mounted) {
        setState(() {
          morningProgram = 'Hata oluştu';
          lunchMenu = 'Hata oluştu';
          eveningProgram = 'Hata oluştu';
          dinnerMenu = 'Hata oluştu';
        });
      }
    }
  }

  // Bugün içilen suyu yükle
  Future<void> _loadWaterIntake() async {
    print("[HomeScreen] _loadWaterIntake started."); // LOG
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user?.id == null) {
      print(
          "[HomeScreen] _loadWaterIntake: User ID is null, cannot load water intake."); // LOG
      return;
    }
    final dbService = DatabaseService();
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      print(
          "[HomeScreen] _loadWaterIntake: Getting water log for user ${userProvider.user!.id}"); // LOG
      final waterData = await dbService.getWaterLogInRange(
          startOfDay, endOfDay, userProvider.user!.id!);
      if (mounted) {
        setState(() {
          _waterIntake =
              waterData[startOfDay] ?? 0; // Sadece bugünün değerini al
          print(
              "[HomeScreen] _loadWaterIntake: Water intake loaded: $_waterIntake ml."); // LOG
        });
      }
    } catch (e, stacktrace) {
      print("[HomeScreen] _loadWaterIntake Error: $e"); // LOG
      print("[HomeScreen] _loadWaterIntake Stacktrace: $stacktrace"); // LOG
    }
  }

  // Bugünkü aktivite özetini yükle (adım sayısı vb.)
  Future<void> _loadActivitySummary() async {
    print("[HomeScreen] _loadActivitySummary started."); // LOG
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user?.id == null) {
      print(
          "[HomeScreen] _loadActivitySummary: User ID is null, cannot load summary."); // LOG
      return;
    }
    // final dbService = DatabaseService(); // Şimdilik devre dışı
    // try {
    //    final today = DateTime.now();
    //   final startOfDay = DateTime(today.year, today.month, today.day);
    //   final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    //   print("[HomeScreen] _loadActivitySummary: Getting activity summary for user ${userProvider.user!.id}"); // LOG
    //   // Bu kısım DatabaseService'e bağlı, varsayılan bir fonksiyon olduğunu varsayalım
    //   // final summary = await dbService.getTodayActivitySummary(userProvider.user!.id!); // Varsayımsal fonksiyon
    //   // if (mounted && summary != null) {
    //   //   setState(() {
    //   //     // Adım sayısı veya aktif dakika gibi değerleri burada state'e atayın
    //   //     // _todaySteps = summary['steps'] ?? 0;
    //   //     // _todayActiveMinutes = summary['activeMinutes'] ?? 0;
    //   //     print("[HomeScreen] _loadActivitySummary: Activity summary loaded."); // LOG - Gerçek değerleri loglayın
    //   //   });
    //   // } else {
    //   //   print("[HomeScreen] _loadActivitySummary: No activity summary found for today."); // LOG
    //   // }
    // } catch (e, stacktrace) {
    //   print("[HomeScreen] _loadActivitySummary Error: $e"); // LOG
    //   print("[HomeScreen] _loadActivitySummary Stacktrace: $stacktrace"); // LOG
    // }
    print("[HomeScreen] _loadActivitySummary: Temporarily disabled."); // LOG
  }

  // Su ekle
  Future<void> _addWater(int amount) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null || user.id == null)
      return; // Kullanıcı veya ID yoksa işlem yapma

    final newIntake = _waterIntake + amount;
    if (mounted) {
      setState(() {
        _waterIntake = newIntake;
      });
    }
    // Veritabanına kaydet
    final dbService = DatabaseService();
    await dbService.insertOrUpdateWaterLog(DateTime.now(), newIntake, user.id!);
  }

  // Su çıkar (opsiyonel, yanlış ekleme durumu için)
  Future<void> _removeWater(int amount) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null || user.id == null) return;

    final newIntake =
        (_waterIntake - amount).clamp(0, 100000); // Negatif olmasın
    if (mounted) {
      setState(() {
        _waterIntake = newIntake;
      });
    }
    // Veritabanına kaydet
    final dbService = DatabaseService();
    await dbService.insertOrUpdateWaterLog(DateTime.now(), newIntake, user.id!);
  }

  // Günlük görevler listesini oluşturan widget
  Widget _buildTaskList(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user; // Null olabilir

    // Görevleri tutacak liste
    List<Widget> taskItems = [];

    // Sabah Egzersizi
    taskItems.add(
      KFSlideAnimation(
        offsetBegin: Offset(0, 0.1),
        delay: Duration(milliseconds: 200),
        child: _TaskItem(
          icon: Icons.directions_run_rounded,
          title: 'Sabah Egzersizi',
          time: '08:00', // Zamanı programdan alabiliriz?
          isDone: isMorningExerciseDone,
          color: AppTheme.morningExerciseColor,
          description: morningProgram, // YENİ: Açıklamayı ekle
          onTap: () {
            _toggleTaskCompletion(TaskType.morningExercise);
          },
        ),
      ),
    );

    // Öğle Yemeği
    taskItems.add(
      KFSlideAnimation(
        offsetBegin: Offset(0, 0.1),
        delay: Duration(milliseconds: 250),
        child: _TaskItem(
          icon: Icons.restaurant_menu_rounded,
          title: 'Sağlıklı Öğle Yemeği',
          time: '13:00',
          isDone: isLunchDone,
          color: AppTheme.lunchColor,
          description: lunchMenu, // YENİ: Açıklamayı ekle
          onTap: () {
            _toggleTaskCompletion(TaskType.lunch);
          },
        ),
      ),
    );

    // Akşam Antrenmanı
    taskItems.add(
      KFSlideAnimation(
        offsetBegin: Offset(0, 0.1),
        delay: Duration(milliseconds: 300),
        child: _TaskItem(
          icon: Icons.fitness_center_rounded,
          title: 'Akşam Antrenmanı',
          time: '18:00',
          isDone: isEveningExerciseDone,
          color: AppTheme.eveningExerciseColor,
          description: eveningProgram, // YENİ: Açıklamayı ekle
          onTap: () {
            _toggleTaskCompletion(TaskType.eveningExercise);
          },
        ),
      ),
    );

    // Akşam Yemeği
    taskItems.add(
      KFSlideAnimation(
        offsetBegin: Offset(0, 0.1),
        delay: Duration(milliseconds: 350),
        child: _TaskItem(
          icon: Icons.dinner_dining_rounded,
          title: 'Akşam Yemeği',
          time: '20:00',
          isDone: isDinnerDone,
          color: AppTheme.dinnerColor,
          description: dinnerMenu, // YENİ: Açıklamayı ekle
          onTap: () {
            _toggleTaskCompletion(TaskType.dinner);
          },
        ),
      ),
    );

    // Su Takip Widget'ı
    taskItems.add(
      KFSlideAnimation(
        offsetBegin: Offset(0, 0.1),
        delay: Duration(milliseconds: 400),
        child: _buildWaterTrackingCard(
            context, (user?.targetWaterIntake ?? 2500).toInt()),
      ),
    );

    return Column(children: taskItems);
  }

  // Tek bir görev kartını oluşturan widget
  Widget _TaskItem({
    required IconData icon,
    required String title,
    required String time,
    required bool isDone,
    required Color color,
    required String description, // YENİ: Açıklama parametresi
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Görev türüne göre AppTheme'den renkleri kullan
    Color cardColor;
    if (title.contains('Sabah Egzersizi')) {
      cardColor = AppTheme.morningExerciseColor;
    } else if (title.contains('Öğle Yemeği')) {
      cardColor = AppTheme.lunchColor;
    } else if (title.contains('Akşam Antrenmanı')) {
      cardColor = AppTheme.eveningExerciseColor;
    } else if (title.contains('Akşam Yemeği')) {
      cardColor = AppTheme.dinnerColor;
    } else {
      cardColor = color;
    }

    final backgroundColor =
        isDarkMode ? cardColor.withOpacity(0.2) : cardColor.withOpacity(0.1);
    final iconColor = isDone ? Colors.grey : cardColor;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isDone
          ? (isDarkMode
              ? AppTheme.completedTaskColor
              : Colors.grey.withOpacity(0.1))
          : backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.8),
                radius: 24,
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDone ? Colors.grey : textColor,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Açıklama kısmını daha iyi göstermek için düzenliyoruz
                      // "-" veya "Bu görev için detay yok" yerine daha anlamlı bir mesaj göster
                      description.isEmpty || description == '-'
                          ? 'Henüz program detayı yüklenmedi'
                          : description == 'Program Yok'
                              ? 'Bugün için program bulunamadı'
                              : description == 'Hata'
                                  ? 'Program yüklenirken hata oluştu'
                                  : description,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDone ? Colors.grey : textColor.withOpacity(0.7),
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDone ? Colors.grey : textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone ? cardColor : Colors.grey.shade400,
                        width: 2,
                      ),
                      color: isDone ? cardColor : Colors.transparent,
                    ),
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Su takip kartı
  Widget _buildWaterTrackingCard(BuildContext context, int targetWaterMl) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<UserProvider>(context, listen: false).user;

    final percentage = (_waterIntake / targetWaterMl).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.all(8),
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
                  const SizedBox(width: 12),
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
                '$_waterIntake / $targetWaterMl ml',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildWaterProgressBar(context, percentage),
          const SizedBox(height: 16),
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

  // Kullanıcıyı karşılayan başlık
  Widget _buildWelcomeTitle() {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final now = DateTime.now();
    int hour = now.hour;

    String greeting;
    if (hour < 12) {
      greeting = 'Günaydın';
    } else if (hour < 18) {
      greeting = 'İyi Günler';
    } else {
      greeting = 'İyi Akşamlar';
    }

    // Kullanıcı adı varsa göster, yoksa genel bir karşılama mesajı göster
    String userName = '';
    if (user != null && user.name.trim().isNotEmpty) {
      // Kullanıcının ilk adını al (boşluklara göre)
      final nameParts = user.name.split(' ');
      if (nameParts.isNotEmpty && nameParts[0].trim().isNotEmpty) {
        userName = nameParts[0];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userName.isNotEmpty ? '$userName' : 'Hoş Geldiniz',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _selectedMotivationalMessage,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
