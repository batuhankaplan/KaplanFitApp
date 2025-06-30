import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../theme.dart';
import '../models/task_type.dart';
import '../utils/animations.dart';
import '../models/user_model.dart';
import '../services/program_service.dart';
import '../services/database_service.dart';
import 'goal_tracking_screen.dart';
import 'program_screen.dart';
import 'workout_program_screen.dart';
import '../widgets/home_mini_dashboard.dart';
import '../widgets/badges_showcase.dart';
import '../providers/gamification_provider.dart';
import '../widgets/badge_detail_dialog.dart';
import '../models/badge_model.dart';
import 'all_badges_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  // YENİ: Motivasyon Sözleri
  final List<String> _motivationalMessages = [
    "Bugün harika bir gün olacak!",
    "Küçük adımlar, büyük başarılara götürür.",
    "Kendine inan, başarabilirsin!",
    "Her yeni gün, yeni bir başlangıçtır.",
    "Pes etme, hayallerinin peşinden git!",
    "Sağlıklı yaşam, mutlu yaşamdır.",
    "Hareket et, enerjini yükselt!",
    "En büyük yatırım, kendine yaptığın yatırımdır.",
    "Zorluklar seni daha güçlü yapar.",
    "Gülümse, hayat daha güzel olacak!"
  ];
  String _selectedMotivationalMessage = "";

  // Sayfa kontrolcüsü
  late PageController _pageController;

  // Yeni animasyon controller
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..forward();

    _loadData();
    _loadMotivationalMessage(); // Motivasyon sözünü yükle
  }

  @override
  void dispose() {
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

  // YENİ: Günlük motivasyon mesajını yükle
  Future<void> _loadMotivationalMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String? lastMessageDate = prefs.getString('lastMotivationalMessageDate');
    int lastMessageIndex = prefs.getInt('lastMotivationalMessageIndex') ?? -1;

    if (lastMessageDate == today &&
        lastMessageIndex != -1 &&
        lastMessageIndex < _motivationalMessages.length) {
      // Aynı gün, kaydedilmiş mesajı kullan
      if (mounted) {
        setState(() {
          _selectedMotivationalMessage =
              _motivationalMessages[lastMessageIndex];
        });
      }
    } else {
      // Yeni gün veya ilk açılış, yeni mesaj seç
      final randomIndex = (lastMessageIndex + 1) %
          _motivationalMessages.length; // Sırayla gitmesi için
      // final randomIndex = Random().nextInt(_motivationalMessages.length); // Rastgele seçmek için
      if (mounted) {
        setState(() {
          _selectedMotivationalMessage = _motivationalMessages[randomIndex];
        });
      }
      await prefs.setString('lastMotivationalMessageDate', today);
      await prefs.setInt('lastMotivationalMessageIndex', randomIndex);
    }
    debugPrint(
        "[HomeScreen] Motivational message loaded: $_selectedMotivationalMessage");
  }

  // YENİDEN EKLENEN: Tek bir görev kartını oluşturan widget
  Widget _TaskItem({
    required IconData icon,
    required String title,
    required String time,
    required bool isDone,
    required Color color,
    required String description,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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

    final backgroundColor = isDarkMode
        ? cardColor.withValues(alpha: 0.2)
        : cardColor.withValues(alpha: 0.1);
    final iconColor = isDone ? Colors.grey : cardColor;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
      color: isDone
          ? (isDarkMode
              ? AppTheme.completedTaskColor
              : Colors.grey.withValues(alpha: 0.1))
          : backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withValues(alpha: 0.8),
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
                      description.isEmpty || description == '-'
                          ? 'Henüz program detayı yüklenmedi'
                          : description == 'Program Yok'
                              ? 'Bugün için program bulunamadı'
                              : description == 'Hata'
                                  ? 'Program yüklenirken hata oluştu'
                                  : description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDone
                            ? Colors.grey
                            : textColor.withValues(alpha: 0.7),
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
                      color: isDone
                          ? Colors.grey
                          : textColor.withValues(alpha: 0.7),
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Kullanıcıyı al (null olabilir, güvenli erişim önemli)
    final userProvider = Provider.of<UserProvider>(context);
    final UserModel? user = userProvider.user;
    debugPrint(
        "[HomeScreen] build: User fetched from provider. User is ${user == null ? 'null' : 'not null'}."); // LOG

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [
                  AppTheme.darkBackgroundColor,
                  AppTheme.darkBackgroundColor.withValues(alpha: 0.9),
                ]
              : [
                  Color(0xFFF8F9FA),
                  Color(0xFFE9ECEF).withValues(alpha: 0.3),
                ],
        ),
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

            // YENİ: Günlük Görevler Kartı
            SliverToBoxAdapter(
              child: KFSlideAnimation(
                offsetBegin: Offset(0, 0.1),
                delay: Duration(milliseconds: 150),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 8.0),
                  decoration: AppTheme.glassContainer(
                    context: context,
                    borderRadius: 24.0,
                    blur: 15.0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Günlük Görevler',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            _buildCompletionBadge(context),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: [
                            _TaskItem(
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
                            _TaskItem(
                              icon: Icons.restaurant_menu_rounded,
                              title: 'Öğle Yemeği',
                              time: '13:00',
                              isDone: isLunchDone,
                              color: AppTheme.lunchColor,
                              description: lunchMenu,
                              onTap: () {
                                _toggleTaskCompletion(TaskType.lunch);
                              },
                            ),
                            _TaskItem(
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
                            _TaskItem(
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // YENİ: Günlük Hedef Takip Paneli (Mini Dashboard)
            SliverToBoxAdapter(
              child: KFSlideAnimation(
                offsetBegin: Offset(0, 0.1),
                delay: Duration(milliseconds: 400),
                child: HomeMiniDashboard(),
              ),
            ),

            // YENİ: Rozet Vitrini
            SliverToBoxAdapter(
              child: KFSlideAnimation(
                offsetBegin: Offset(0, 0.1),
                delay: Duration(milliseconds: 500),
                child: BadgesShowcase(
                  onViewAllPressed: () {
                    _showAllBadgesScreen();
                  },
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
    final userName =
        user?.name ?? 'Kullanıcı'; // Eğer user null ise 'Kullanıcı' yaz
    debugPrint(
        "[HomeScreen] _buildWelcomeHeader: User name is '$userName'."); // LOG

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE', 'tr_TR').format(now);
    final dateFormatted = DateFormat('d MMMM yyyy', 'tr_TR').format(now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Dikeyde ortala
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
                // YENİ: Motivasyon Sözü
                if (_selectedMotivationalMessage.isNotEmpty)
                  KFSlideAnimation(
                    offsetBegin: const Offset(0, 0.2),
                    delay: const Duration(
                        milliseconds: 100), // Karşılama mesajından biraz sonra
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 8.0), // Üstten biraz boşluk
                      child: Text(
                        _selectedMotivationalMessage,
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.85)
                              : Colors.black.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                const SizedBox(
                    height: 6), // Motivasyon sözü ile tarih arasına boşluk
                KFSlideAnimation(
                  offsetBegin: const Offset(0, 0.2),
                  delay:
                      const Duration(milliseconds: 150), // Motivasyondan sonra
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
                        ? AppTheme.primaryColor.withValues(alpha: 0.3)
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
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

    return SafeArea(
      child: Container(
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
                color: Colors.grey.withValues(alpha: 0.3),
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
          ],
        ),
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
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
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

  Widget _buildMotivationalBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.color
                ?.withValues(alpha: 0.7),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '',
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
    if (!mounted) {
      return;
    }
    setState(() {
      isLoading = true;
    });

    try {
      await _loadSavedTaskStates();

      await _loadDailyTasks();

      await _loadWaterIntake();

      await _loadActivitySummary();
    } catch (e, stacktrace) {
      // Hata durumunda kullanıcıya bilgi verilebilir
      // ScaffoldMessenger.of(context).showSnackBar(...);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          debugPrint(
              "[HomeScreen] _loadData: isLoading set to false (finally)."); // LOG
        });
      }
    }
  }

  // Günlük görevleri ve programı yükle
  Future<void> _loadDailyTasks() async {
    if (!mounted) return;

    final programService = Provider.of<ProgramService>(context, listen: false);
    final today = DateTime.now();
    final todayWeekday = today.weekday;

    try {
      // ProgramService'den haftalık programı al
      debugPrint(
          "[HomeScreen] _loadDailyTasks: Getting weekly program from ProgramService"); // LOG
      final weeklyProgram =
          await programService.getWeeklyProgram(); // Haftalık programı al

      if (weeklyProgram.isNotEmpty && mounted) {
        // Bugünün indeksini bul (0=Pzt, 6=Paz)
        final todayIndex = todayWeekday - 1;
        if (todayIndex >= 0 && todayIndex < weeklyProgram.length) {
          final dailyProgram = weeklyProgram[todayIndex];
          debugPrint(
              "[HomeScreen] _loadDailyTasks: Daily program found for index $todayIndex. Updating state."); // LOG
          setState(() {
            morningProgram = dailyProgram.morningExercise.title;
            lunchMenu = dailyProgram.lunch.description ?? 'Belirtilmedi';
            eveningProgram = dailyProgram.eveningExercise.title;
            dinnerMenu = dailyProgram.dinner.description ?? 'Belirtilmedi';
          });
          debugPrint(
              "Yüklenen görevler: Sabah: $morningProgram, Öğle: $lunchMenu, Akşam: $eveningProgram, Akşam Yemeği: $dinnerMenu"); // LOG
        } else {
          debugPrint(
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
        debugPrint(
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
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user?.id == null) {
      debugPrint(
          "[HomeScreen] _loadWaterIntake: User ID is null, cannot load water intake."); // LOG
      return;
    }
    final dbService = DatabaseService();
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      debugPrint(
          "[HomeScreen] _loadWaterIntake: Getting water log for user ${userProvider.user!.id}"); // LOG
      final waterData = await dbService.getWaterLogInRange(
          startOfDay, endOfDay, userProvider.user!.id!);
      if (mounted) {
        setState(() {
          _waterIntake =
              waterData[startOfDay] ?? 0; // Sadece bugünün değerini al
          debugPrint(
              "[HomeScreen] _loadWaterIntake: Water intake loaded: $_waterIntake ml."); // LOG
        });
      }
    } catch (e, stacktrace) {
      debugPrint(
          "[HomeScreen] _loadWaterIntake Stacktrace: $stacktrace"); // LOG
    }
  }

  // Bugünkü aktivite özetini yükle (adım sayısı vb.)
  Future<void> _loadActivitySummary() async {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user?.id == null) {
      debugPrint(
          "[HomeScreen] _loadActivitySummary: User ID is null, cannot load summary."); // LOG
      return;
    }
    // final dbService = DatabaseService(); // Şimdilik devre dışı
    // try {
    //    final today = DateTime.now();
    //   final startOfDay = DateTime(today.year, today.month, today.day);
    //   final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    //   // Bu kısım DatabaseService'e bağlı, varsayılan bir fonksiyon olduğunu varsayalım
    //   // final summary = await dbService.getTodayActivitySummary(userProvider.user!.id!); // Varsayımsal fonksiyon
    //   // if (mounted && summary != null) {
    //   //   setState(() {
    //   //     // Adım sayısı veya aktif dakika gibi değerleri burada state'e atayın
    //   //     // _todaySteps = summary['steps'] ?? 0;
    //   //     // _todayActiveMinutes = summary['activeMinutes'] ?? 0;

    //   //   });
    //   // } else {

    //   // }
    debugPrint(
        "[HomeScreen] _loadActivitySummary: Temporarily disabled."); // LOG
  }

  // Görev tamamlama durumunu değiştir
  Future<void> _toggleTaskCompletion(TaskType taskType) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null || user.id == null) {
      debugPrint("Görev tamamlama işlemi için kullanıcı bulunamadı.");
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

    // Görev tamamlama durumuna göre GamificationProvider'ı güncelle
    _updateGameProgressForTask(taskType, newState);
  }

  // Oyunlaştırma sistemini güncelleyen yardımcı metot
  void _updateGameProgressForTask(TaskType taskType, bool isCompleted) {
    try {
      final gamificationProvider =
          Provider.of<GamificationProvider>(context, listen: false);

      // Günlük görev seri takibi
      if (isCompleted) {
        // Tüm günlük görevler tamamlandı mı kontrol et
        final allDailyTasksCompleted = isMorningExerciseDone &&
            isLunchDone &&
            isEveningExerciseDone &&
            isDinnerDone;

        if (allDailyTasksCompleted) {
          // Tüm günlük görevler tamamlandıysa daily streak'i güncelle
          gamificationProvider.updateStreak('daily', true);

          // Puan ekle
          gamificationProvider
              .addPoints(50); // Günlük tüm görevleri tamamlama puanı

          // Günlük seri rozeti kazanıldı mı kontrol et
          final currentStreak = gamificationProvider.streaks['daily'] ?? 0;
          final unlockedBadge = _checkForNewBadge(
              gamificationProvider, BadgeType.dailyStreak, currentStreak);

          if (unlockedBadge != null) {
            _showGameReward("Günlük görevleri tamamladınız!",
                unlockedBadge: unlockedBadge);
          } else {
            _showGameReward(
                "Günlük görevleri tamamladınız! +50 puan kazandınız!");
          }
        }
      }

      // Spesifik görev türüne göre rozet ve puan işlemleri
      switch (taskType) {
        case TaskType.morningExercise:
        case TaskType.eveningExercise:
          // ANASAYFA GÖREVLERİ ARTIK ANTRENMAN SAYISINI ETKİLEMEYECEK.
          // if (isCompleted) {
          //   // Antrenman sayısını artır ve kaydet
          //   gamificationProvider.updateWorkoutCount(1);

          //   // Rozet kontrol et
          //   final workoutCount = gamificationProvider.workoutCount;
          //   final unlockedBadge = _checkForNewBadge(
          //       gamificationProvider, BadgeType.workoutCount, workoutCount);

          //   if (unlockedBadge != null) {
          //     _showGameReward("Antrenman tamamlandı!",
          //         unlockedBadge: unlockedBadge);
          //   } else {
          //     _showGameReward("Antrenman tamamlandı! +10 puan kazandınız!");
          //   }
          // }
          // Sadece puan verilebilir veya hiçbir şey yapılmayabilir.
          // Şimdilik, bu görevler için özel bir puan/rozet işlemi yapmayalım,
          // genel günlük görev tamamlama zaten puan veriyor.
          if (isCompleted) {
            gamificationProvider
                .addPoints(5); // Sabah/Akşam egzersizi için küçük bir puan
            _showGameReward("Günlük egzersiz görevi tamamlandı! +5 puan.");
          }
          break;

        case TaskType.lunch:
        case TaskType.dinner:
          if (isCompleted) {
            // Beslenme puanı ekle
            gamificationProvider.addPoints(5); // Her beslenme için +5 puan
            _showGameReward("Beslenme kaydedildi! +5 puan kazandınız!");
          }
          break;
        case TaskType.other:
          // Diğer görev türleri için özel bir işlem yapılmıyor
          break;
      }
    } catch (e) {
      debugPrint("Oyunlaştırma güncellemesi sırasında hata: $e");
    }
  }

  // Yeni rozet kazanıldı mı kontrol eden yardımcı metot
  BadgeModel? _checkForNewBadge(
      GamificationProvider provider, BadgeType type, int currentValue) {
    // Belirli türdeki kilitli rozetleri bul
    final relevantBadges =
        provider.badges.where((b) => b.type == type && !b.isUnlocked).toList();

    // Threshold'a göre sırala
    relevantBadges.sort((a, b) => a.threshold.compareTo(b.threshold));

    // Mevcut değere göre kilidini açabileceğimiz rozeti bul
    for (var badge in relevantBadges) {
      if (currentValue >= badge.threshold) {
        // Rozet kilidini aç ve bildirim için döndür
        provider.unlockBadge(badge.id);
        // Kilidini yeni açtığımız rozeti al
        final unlockedBadge =
            provider.badges.firstWhere((b) => b.id == badge.id);
        return unlockedBadge;
      }
    }

    return null;
  }

  // Oyun ödüllerini göstermek için yardımcı metot
  void _showGameReward(String message, {BadgeModel? unlockedBadge}) {
    // Eğer bir rozet açıldıysa, bu bildirimi rozet bilgisiyle zenginleştir
    Widget content;

    if (unlockedBadge != null) {
      // Rozet kazanımı bildirimi
      content = Row(
        children: [
          CircleAvatar(
            backgroundColor: unlockedBadge.color.withValues(alpha: 0.8),
            radius: 20,
            child: Icon(
              _getBadgeIconForNotification(unlockedBadge),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni rozet kazandınız!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${unlockedBadge.name} - ${unlockedBadge.points} puan',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Standart ödül bildirimi
      content = Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: unlockedBadge != null
            ? unlockedBadge.color.withValues(alpha: 0.9)
            : AppTheme.primaryColor.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: unlockedBadge != null
            ? SnackBarAction(
                label: 'DETAYLAR',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        BadgeDetailDialog(badge: unlockedBadge),
                  );
                },
              )
            : null,
      ),
    );
  }

  // Bildirim için rozet ikonunu döndüren yardımcı metot
  IconData _getBadgeIconForNotification(BadgeModel badge) {
    switch (badge.type) {
      case BadgeType.dailyStreak:
        switch (badge.threshold) {
          case 3:
            return Icons.looks_3_rounded; // 3 günlük seri
          case 7:
            return Icons.calendar_view_week_rounded; // 7 günlük seri
          case 30:
            return Icons.calendar_month_rounded; // 30 günlük seri
          case 90:
            return Icons.calendar_view_month_rounded; // 90 günlük seri
          case 365:
            return Icons.emoji_events_rounded; // 365 günlük seri
          default:
            return Icons.calendar_today_rounded;
        }
      case BadgeType.weeklyGoal:
        return Icons.flag_rounded;
      case BadgeType.monthlyGoal:
        return Icons.insert_invitation_rounded;
      case BadgeType.yearlyGoal:
        return Icons.workspace_premium_rounded;
      case BadgeType.workoutCount:
        switch (badge.threshold) {
          case 1:
            return Icons.fitness_center_rounded; // İlk antrenman
          case 10:
            return Icons.sports_gymnastics_rounded; // 10 antrenman
          case 50:
            return Icons.sports_martial_arts_rounded; // 50 antrenman
          case 100:
            return Icons.directions_run_rounded; // 100 antrenman
          case 500:
            return Icons.sports_score_rounded; // 500 antrenman
          default:
            return Icons.fitness_center_rounded;
        }
      case BadgeType.waterStreak:
        switch (badge.threshold) {
          case 5:
            return Icons.water_drop_rounded; // 5 günlük su serisi
          case 20:
            return Icons.water_rounded; // 20 günlük su serisi
          default:
            return Icons.water_drop_rounded;
        }
      case BadgeType.weightLoss:
        switch (badge.threshold) {
          case 1:
            return Icons.monitor_weight_rounded; // 1 kg
          case 5:
            return Icons.trending_down_rounded; // 5 kg
          case 10:
            return Icons.balance_rounded; // 10 kg
          default:
            return Icons.monitor_weight_rounded;
        }
      case BadgeType.chatInteraction:
        switch (badge.threshold) {
          case 1:
            return Icons.chat_bubble_outline_rounded; // İlk sohbet
          case 50:
            return Icons.forum_rounded; // 50 sohbet
          case 100:
            return Icons.psychology_rounded; // 100 sohbet
          default:
            return Icons.chat_rounded;
        }
      case BadgeType.beginner:
        return Icons.rocket_launch_rounded;
      case BadgeType.consistent:
        return Icons.repeat_rounded;
      case BadgeType.expert:
        return Icons.auto_awesome_rounded;
      case BadgeType.master:
        return Icons.workspace_premium_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
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
      ],
    );
  }

  // Tüm rozetleri gösteren ekranı aç
  void _showAllBadgesScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AllBadgesScreen(),
      ),
    );
  }
}
