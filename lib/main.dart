import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/ai_coach_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/program_screen.dart';
import 'screens/stats_screen.dart';
import 'providers/user_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/nutrition_provider.dart';
import 'providers/gamification_provider.dart';
import 'services/program_service.dart';
import 'services/exercise_service.dart';
import 'services/database_service.dart';
import 'widgets/kaplan_appbar.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:animations/animations.dart';
import 'splash/custom_splash_screen.dart';
import 'providers/workout_provider.dart';
import 'screens/profile_screen.dart';
import 'screens/goal_tracking_screen.dart';
import 'screens/goal_settings_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/workout_program_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ana ekran
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = const [
    HomeScreen(),
    ActivityScreen(),
    NutritionScreen(),
    AICoachScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = [
    'Ana Sayfa',
    'Aktiviteler',
    'Beslenme',
    'AI Koç',
    'Ayarlar'
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: KaplanAppBar(
        title: _titles[_selectedIndex],
        isDarkMode: isDarkMode,
        isRequiredPage: false,
        showBackButton: false,
        actions: [],
      ),
      body: PageTransitionSwitcher(
        transitionBuilder: (
          Widget child,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : const Color(0xFFF8F8FC),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: GNav(
              rippleColor: isDarkMode
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.grey.shade300,
              hoverColor: isDarkMode
                  ? AppTheme.primaryColor.withOpacity(0.15)
                  : Colors.grey.shade200,
              gap: 4,
              activeColor: isDarkMode ? Colors.white : Colors.white,
              iconSize: 24,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              duration: Duration(milliseconds: 400),
              tabBackgroundColor:
                  isDarkMode ? AppTheme.primaryColor : AppTheme.primaryColor,
              color: isDarkMode
                  ? AppTheme.darkSecondaryTextColor
                  : Colors.grey.shade600,
              tabs: [
                GButton(
                  icon: Icons.home_rounded,
                  text: 'Ana Sayfa',
                ),
                GButton(
                  icon: Icons.directions_run_rounded,
                  text: 'Aktiviteler',
                ),
                GButton(
                  icon: Icons.restaurant_menu_rounded,
                  text: 'Beslenme',
                ),
                GButton(
                  icon: Icons.psychology_rounded,
                  text: 'AI Koç',
                ),
                GButton(
                  icon: Icons.settings_rounded,
                  text: 'Ayarlar',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}

// Location plugin için gerekli düzeltme
void initPlatformSpecificFeatures() {
  if (Platform.isWindows) {
    // Windows platformunda konum servisleri devre dışı bırakıldı
    debugPrint('Windows platformunda konum servisleri devre dışı bırakıldı');
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          print(
              "[AuthWrapper build] Kullanıcı yükleniyor (Consumer isLoading).");
          return const CustomSplashScreen();
        }

        // isLoading false ise buraya gelinir.
        final bool userExists = userProvider.user != null;
        print(
            "[AuthWrapper build] Kullanıcı var mı (Provider kontrolü)? $userExists");

        if (userExists) {
          print("[AuthWrapper build] Kullanıcı var, MainScreen gösteriliyor.");
          return const MainScreen();
        } else {
          print(
              "[AuthWrapper build] Kullanıcı yok, ProfileScreen gösteriliyor.");
          return const ProfileScreen();
        }
      },
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await Firebase.initializeApp(); // Firebase başlatma tekrar aktif.
  // await NotificationService().init(); // Bildirim servisi (şimdilik yorumda)

  // --- GEÇİCİ: Veritabanı İçe Aktarma (Sadece 1 Kez Çalıştır ve SİL!) ---
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFoodDbImported =
        prefs.getBool('food_db_imported_v1') ?? false; // Kontrol tekrar AKTİF
    if (!isFoodDbImported) {
      // Kontrol tekrar AKTİF
      print(
          "[Firestore Import] İlk çalıştırma: Besin veritabanı Firestore'a aktarılıyor...");
      // Şimdilik Firebase kullanılmadığı için yorum satırı haline getirildi
      // DatabaseService tempDbService = DatabaseService();
      // await tempDbService
      //     .importFoodDatabaseFromAsset('assets/besinveritabanı.txt');
      await prefs.setBool('food_db_imported_v1', true); // Kontrol tekrar AKTİF
      print(
          "[Firestore Import] Firestore'a besin aktarma işlemi tamamlandı ve işaretlendi.");
    } else {
      print("[Firestore Import] Besin veritabanı zaten içe aktarılmış.");
    }
  } catch (e) {
    print("SharedPreferences veya DB import hatası: $e");
  }
  // --- GEÇİCİ KOD SONU -> YORUM SATIRLARI KALDIRILDI ---

  // Servisleri oluştur
  final databaseService = DatabaseService();
  final exerciseService = ExerciseService();
  // ProgramService positional parametreler bekliyor
  final programService = ProgramService(
    databaseService, // named parameter yerine positional
    // exerciseService // initialize metodu ExerciseService bekliyor, constructor değil
  );

  // UserProvider'ı oluştur ve kullanıcıyı yükle
  final userProvider = UserProvider(databaseService); // DatabaseService geç
  // await userProvider.loadUser(); // UserProvider constructor'ında zaten çağrılıyor.

  // ProgramService'i initialize et (User ID varsa)
  try {
    // initialize ExerciseService bekliyor
    await programService.initialize(exerciseService);
    print("ProgramService initialize edildi.");
    // if (userProvider.user?.id != null) {
    //   print("ProgramService initialize edildi (User ID: ${userProvider.user!.id!})");
    // } else {
    //   print("ProgramService initialize edildi (Kullanıcı ID'si olmadan).");
    // }
  } catch (e) {
    print("ProgramService initialize hatası: $e");
  }

  // GamificationProvider'ı oluştur ve initialize et
  final gamificationProvider = GamificationProvider();
  try {
    await gamificationProvider.initialize();
    print("GamificationProvider initialize edildi.");
  } catch (e) {
    print("GamificationProvider initialize hatası: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        // ... (Provider listesi önceki düzeltmedeki gibi)
        Provider<DatabaseService>.value(value: databaseService),
        Provider<ExerciseService>.value(value: exerciseService),
        ChangeNotifierProvider<ProgramService>(
          create: (context) => programService,
        ),

        ChangeNotifierProvider<UserProvider>.value(
            value: userProvider), // value ile verelim

        ChangeNotifierProvider<ActivityProvider>(
          create: (context) => ActivityProvider(databaseService),
        ),
        ChangeNotifierProvider<WorkoutProvider>(
          create: (context) => WorkoutProvider(databaseService),
        ),
        ChangeNotifierProxyProvider<UserProvider, NutritionProvider>(
          create: (context) => NutritionProvider(databaseService),
          update: (context, userProvider, previousNutritionProvider) {
            previousNutritionProvider?.updateUserId(userProvider.user?.id);
            return previousNutritionProvider ??
                NutritionProvider(databaseService);
          },
        ),
        ChangeNotifierProvider<GamificationProvider>.value(
          value: gamificationProvider,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// Uygulama ana sınıfı
class MyApp extends StatelessWidget {
  // Servis parametreleri kaldırıldı
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KaplanFit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      routes: {
        '/home': (context) => MainScreen(),
        '/profile': (context) => ProfileScreen(),
        '/goal-settings': (context) => GoalSettingsScreen(),
        '/goal-tracking': (context) => GoalTrackingScreen(),
        '/program': (context) => ProgramScreen(),
        '/stats': (context) => StatsScreen(),
        '/settings': (context) => SettingsScreen(),
        '/notification-settings': (context) => NotificationSettingsScreen(),
        '/workout-program': (context) => WorkoutProgramScreen(),
      },
    );
  }
}

class KaplanSplashScreen extends StatefulWidget {
  const KaplanSplashScreen({Key? key}) : super(key: key);

  @override
  State<KaplanSplashScreen> createState() => _KaplanSplashScreenState();
}

class _KaplanSplashScreenState extends State<KaplanSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Logo animasyonunu başlat
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Icon(
                Icons.fitness_center_rounded,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              // Uygulama adı
              Text(
                'KAPLAN FIT',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              // Alt metin
              Text(
                'Sağlıklı Yaşam, Güçlü Gelecek',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 48),
              // Yükleniyor göstergesi
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PermissionHandlerScreen extends StatefulWidget {
  const PermissionHandlerScreen({Key? key}) : super(key: key);

  @override
  State<PermissionHandlerScreen> createState() =>
      _PermissionHandlerScreenState();
}

class _PermissionHandlerScreenState extends State<PermissionHandlerScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMainApp();
  }

  void _navigateToMainApp() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => KaplanSplashScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// Kullanıcı profil oluşturma ekranı (Placeholder)
class ProfileCreationScreen extends StatelessWidget {
  const ProfileCreationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // YENİ: Manuel yönlendirme butonu
    return Scaffold(
      appBar: AppBar(title: Text('Profil Oluştur')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Profiliniz bulunamadı.'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
              child: Text('Profil Oluşturmaya Başla (Ayarlar)'),
            ),
          ],
        ),
      ),
    );
  }
}
