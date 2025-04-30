import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/ai_coach_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/program_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/splash_screen.dart';
import 'providers/user_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/nutrition_provider.dart';
import 'models/providers/database_provider.dart';
import 'services/program_service.dart';
import 'services/notification_service.dart';
import 'widgets/kaplan_appbar.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:animations/animations.dart';
import 'splash/custom_splash_screen.dart';

// Tema sağlayıcı sınıfı
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

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
              gap: 8,
              activeColor: isDarkMode ? Colors.white : Colors.white,
              iconSize: 24,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildExtraMenuSheet(BuildContext context) {
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
}

// Location plugin için gerekli düzeltme
void initPlatformSpecificFeatures() {
  if (Platform.isWindows) {
    // Windows platformunda konum servisleri devre dışı bırakıldı
    debugPrint('Windows platformunda konum servisleri devre dışı bırakıldı');
  }
}

void main() async {
  // Uygulama çökme durumunda hata yakalama
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('HATA: ${details.exception}');
    debugPrint('HATA DETAYI: ${details.stack}');
  };

  try {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Platform özel özelliklerini başlatma
    initPlatformSpecificFeatures();

    // Platform'a göre uygun SQLite yapılandırması
    if (Platform.isAndroid || Platform.isIOS) {
      // Mobil cihazlar için varsayılan SQLite
    } else {
      // Desktop için FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    await initializeDateFormatting('tr_TR', null);

    // Program servisini başlat
    final programService = ProgramService();
    await programService.initialize();

    // Bildirimleri başlat
    final notificationService = NotificationService.instance;
    await notificationService.init();

    // Veritabanı sağlayıcısını hazırla
    final databaseProvider = DatabaseProvider();
    await databaseProvider.initialize();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => UserProvider()),
          ChangeNotifierProvider(create: (context) => ActivityProvider()),
          ChangeNotifierProvider(create: (context) => NutritionProvider()),
          ChangeNotifierProvider.value(value: databaseProvider),
          Provider<ProgramService>.value(value: programService),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('UYGULAMA BAŞLATMA HATASI: $e');
    debugPrint('HATA DETAYI: $stack');

    // Hata durumunda minimal uygulama
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              SizedBox(height: 20),
              Text('Uygulama başlatılırken bir hata oluştu.'),
              Text('Lütfen uygulamayı yeniden başlatın.'),
              SizedBox(height: 8),
              Text('Hata: $e', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    ));
  }
}

// Uygulama ana sınıfı
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'KaplanFIT',
          theme: lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: CustomSplashScreen(nextScreen: MainScreen()),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('tr', 'TR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('tr', 'TR'),
          debugShowCheckedModeBanner: false,
        );
      },
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _navigateToMainApp();
  }

  void _navigateToMainApp() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => SplashScreen(nextScreen: MainScreen())),
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

// ThemeData oluşturuyoruz
final lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppTheme.primaryColor,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFE8E8E8),
  primaryColor: AppTheme.primaryColor,
  appBarTheme: AppBarTheme(
    backgroundColor: AppTheme.primaryColor,
    foregroundColor: Colors.white,
  ),
  cardTheme: CardTheme(
    color: const Color(0xFFF0F0F0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
  ),
  dialogBackgroundColor: const Color(0xFFEDEDED),
  canvasColor: const Color(0xFFEAEAEA),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: const Color(0xFFF5F5F5),
    filled: true,
  ),
  useMaterial3: true,
  fontFamily: 'Montserrat',
  visualDensity: VisualDensity.adaptivePlatformDensity,
);
