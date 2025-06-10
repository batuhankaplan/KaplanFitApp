import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
import 'providers/theme_provider.dart';
import 'services/program_service.dart';
import 'services/exercise_service.dart';
import 'services/food_service.dart';
import 'services/database_service.dart';
import 'widgets/kaplan_appbar.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:animations/animations.dart';
import 'providers/workout_provider.dart';
import 'screens/profile_screen.dart';
import 'screens/goal_tracking_screen.dart';
import 'screens/goal_settings_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/workout_program_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'services/ai_coach_service.dart';

// Ana ekran
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

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
    debugPrint("🔄 Tab tıklandı: $index (${_titles[index]})");
    try {
      if (mounted && index >= 0 && index < _widgetOptions.length) {
        setState(() {
          _selectedIndex = index;
        });
        debugPrint("✅ Tab değişimi başarılı: ${_titles[index]}");
      } else {
        debugPrint("❌ Geçersiz tab index: $index");
      }
    } catch (e) {
      debugPrint("❌ Tab değişimi hatası: $e");
    }
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
              color: Colors.black.withValues(alpha: .1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: GNav(
              rippleColor: isDarkMode
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.shade300,
              hoverColor: isDarkMode
                  ? AppTheme.primaryColor.withValues(alpha: 0.15)
                  : Colors.grey.shade200,
              gap: 4,
              activeColor: isDarkMode ? Colors.white : Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor:
                  isDarkMode ? AppTheme.primaryColor : AppTheme.primaryColor,
              color: isDarkMode
                  ? AppTheme.darkSecondaryTextColor
                  : Colors.grey.shade600,
              tabs: const [
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          debugPrint(
              "[AuthWrapper build] Kullanıcı yükleniyor (Consumer isLoading).");
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final bool userExists = userProvider.user != null;
        debugPrint(
            "[AuthWrapper build] Kullanıcı var mı (Provider kontrolü)? $userExists");

        if (userExists) {
          debugPrint(
              "[AuthWrapper build] Kullanıcı var, MainScreen gösteriliyor.");
          return const MainScreen();
        } else {
          debugPrint(
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
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase başlatma hatası: $e");
  }
  await NotificationService.instance.init();

  final databaseService = DatabaseService();
  final exerciseService = ExerciseService();
  final foodService = FoodService();
  final programService = ProgramService(databaseService);
  final userProvider = UserProvider(databaseService);
  final gamificationProvider =
      GamificationProvider(databaseService, userProvider);
  final themeProvider = ThemeProvider();
  final workoutProvider = WorkoutProvider(databaseService);

  try {
    await programService.initialize(exerciseService);
    await userProvider.loadUser();
    await gamificationProvider.initialize();
  } catch (e) {
    debugPrint("Servisler başlatılırken genel bir hata oluştu: $e");
  }

  runApp(
    MyApp(
      userProvider: userProvider,
      databaseService: databaseService,
      exerciseService: exerciseService,
      foodService: foodService,
      programService: programService,
      gamificationProvider: gamificationProvider,
      themeProvider: themeProvider,
      workoutProvider: workoutProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  final UserProvider userProvider;
  final DatabaseService databaseService;
  final ExerciseService exerciseService;
  final FoodService foodService;
  final ProgramService programService;
  final GamificationProvider gamificationProvider;
  final ThemeProvider themeProvider;
  final WorkoutProvider workoutProvider;

  const MyApp({
    super.key,
    required this.userProvider,
    required this.databaseService,
    required this.exerciseService,
    required this.foodService,
    required this.programService,
    required this.gamificationProvider,
    required this.themeProvider,
    required this.workoutProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        Provider<DatabaseService>.value(value: databaseService),
        Provider<ExerciseService>.value(value: exerciseService),
        Provider<FoodService>.value(value: foodService),
        ChangeNotifierProvider<ProgramService>.value(value: programService),
        Provider<AICoachService>(
          create: (context) => AICoachService(
            databaseService,
            Provider.of<GamificationProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider.value(value: gamificationProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider<NutritionProvider>(
          create: (context) => NutritionProvider(
            Provider.of<DatabaseService>(context, listen: false),
            Provider.of<UserProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<ActivityProvider>(
          create: (context) => ActivityProvider(
            Provider.of<DatabaseService>(context, listen: false),
            Provider.of<UserProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider.value(value: workoutProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProviderInstance, child) {
          return MaterialApp(
            title: 'KaplanFit',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProviderInstance.themeMode,
            debugShowCheckedModeBanner: false,
            // Localization eklendi
            locale: const Locale('tr', 'TR'),
            supportedLocales: const [
              Locale('tr', 'TR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthWrapper(),
            routes: {
              '/home': (context) => const MainScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/activity': (context) => const ActivityScreen(),
              '/nutrition': (context) => const NutritionScreen(),
              '/coach': (context) => const AICoachScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/program': (context) => const ProgramScreen(),
              '/workout_program': (context) => const WorkoutProgramScreen(),
              '/stats': (context) => const StatsScreen(),
              '/goal_tracking': (context) => const GoalTrackingScreen(),
              '/goal_settings': (context) => const GoalSettingsScreen(),
              '/notification_settings': (context) =>
                  const NotificationSettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

class KaplanSplashScreen extends StatefulWidget {
  const KaplanSplashScreen({super.key});

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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
  const PermissionHandlerScreen({super.key});

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
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
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
  const ProfileCreationScreen({super.key});

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
