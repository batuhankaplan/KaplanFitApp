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
import 'services/program_service.dart';
import 'utils/animations.dart';
import 'widgets/kaplan_appbar.dart';
import 'services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

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

// Bildirimler için global tanımlama
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Platform'a göre uygun SQLite yapılandırması
  if (Platform.isAndroid || Platform.isIOS) {
    // Mobil cihazlarda yerel SQLite kütüphanesini kullan
    // Açık bir şekilde varsayılan yapılandırmayı kullan
    // FFI kullanmaya gerek yok
  } else {
    // Windows, macOS, Linux vb. platformlarda FFI kullan
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
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
  
  // Bildirim ayarları
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false, // Bildirim izinlerini sonradan isteyeceğiz
      );
  
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  try {
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  } catch (e) {
    print('Bildirim ayarları başlatılamadı: $e');
    // Bildirim hatası olsa bile uygulamanın çalışmasına izin ver
  }
  
  // Program servisini başlat
  final programService = ProgramService();
  await programService.initialize();
  
  // Bildirimleri başlat
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
        Provider<ProgramService>.value(value: programService),
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
      home: const PermissionHandlerScreen(),
    );
  }
}

class PermissionHandlerScreen extends StatefulWidget {
  const PermissionHandlerScreen({Key? key}) : super(key: key);

  @override
  State<PermissionHandlerScreen> createState() => _PermissionHandlerScreenState();
}

class _PermissionHandlerScreenState extends State<PermissionHandlerScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    // Doğrudan splash screen'e gidip izinleri daha sonra isteyelim
    _navigateToMainApp();
  }
  
  void _navigateToMainApp() {
    // Kısa bir gecikme ekleyerek splash ekranının daha uzun görünmesini sağlayalım
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SplashScreen(nextScreen: MainScreen())),
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
    try {
      // Kullanıcı bilgisi yoksa profil sayfasına yönlendir
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUser();
      
      // Eğer uygulama ilk kez açılıyorsa özel bir işlem yapılabilir
      
      setState(() {
        _selectedIndex = 0; // Anasayfanın indeksi
      });
    } catch (e) {
      print('Veri yükleme hatası: $e');
      // Hata durumunda varsayılan değerlere geri dön
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KaplanAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0), 
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _screens[_selectedIndex],
      ),
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
