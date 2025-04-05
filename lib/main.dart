import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/program_screen.dart';
import 'screens/ai_coach_screen.dart';
import 'screens/conversations_screen.dart';
import 'providers/user_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/nutrition_provider.dart';
import 'models/providers/database_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_size/window_size.dart';

// Tema sağlayıcı sınıfı
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;
  
  ThemeData get themeData => _isDarkMode ? _darkTheme : _lightTheme;
  
  final _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.orange,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFF9800),
      foregroundColor: Colors.white,
    ),
  );
  
  final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.orange,
    primaryColor: const Color(0xFFFF9800),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF303030),
      foregroundColor: Colors.white,
    ),
  );

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }

  Future<void> _loadThemePreference() async {
    // SharedPreferences kullanılarak tema ayarı yüklenebilir
    // Örnek: _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> _saveThemePreference() async {
    // SharedPreferences kullanılarak tema ayarı kaydedilebilir
    // Örnek: prefs.setBool('isDarkMode', _isDarkMode);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // SQLite için FFI kullanılacak (Windows desteği için)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  await initializeDateFormatting('tr_TR', null);
  
  // Windows'ta belirli ekran boyutunu ayarla
  if (Platform.isWindows) {
    // Samsung A73 çözünürlüğü: 1080 x 2040
    const double width = 1080 / 3; // Pixel oranını ayarlamak için 3'e böldük
    const double height = 2040 / 3;
    
    // Pencere boyutu için düzenlemeler yapılacak
    // Not: Bu fonksiyonlar window_size paketinde mevcut değilse eklenmeli
    // veya başka bir çözüm kullanılmalı
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'KaplanFIT',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('tr', 'TR'),
      ],
      home: SplashScreen(nextScreen: MainScreen()),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  final List<Widget> _screens = [
    HomeScreen(),
    ProgramScreen(),
    ActivityScreen(),
    NutritionScreen(),
    StatsScreen(),
    ConversationsScreen(),
    SettingsScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeData();
      _isInitialized = true;
    }
  }

  Future<void> _initializeData() async {
    // Kullanıcı bilgisi yoksa profil sayfasına yönlendir
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUser();
    
    if (userProvider.user == null) {
      setState(() {
        _selectedIndex = 0; // Anasayfanın indeksi
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: AppTheme.navBarColor, // Tema dosyasından navigasyon barı rengi
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Anasayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Program',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_run),
              label: 'Spor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: 'Beslenme',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'İstatistik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'AI Koç',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }
}
