import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
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
import 'screens/notification_settings_screen.dart';
import 'screens/help_support_screen.dart';
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
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:animations/animations.dart';
import 'splash/custom_splash_screen.dart';

// Tema sağlayıcı sınıfı
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Varsayılan olarak koyu tema
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
  
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

// Awesome Notifications için gerekli global handler
@pragma('vm:entry-point')
Future<void> notificationActionReceivedMethod(ReceivedAction receivedAction) async {
  // Burada bildirime tıklandığında yapılacak işlemleri belirleyebiliriz
  // Örneğin belirli bir ekranı açma, verileri güncelleme vb.
  print('Bildirime tıklandı: ${receivedAction.toMap().toString()}');
}

@pragma('vm:entry-point')
Future<void> notificationCreatedMethod(ReceivedNotification receivedNotification) async {
  print('Bildirim oluşturuldu: ${receivedNotification.toMap().toString()}');
}

@pragma('vm:entry-point')
Future<void> notificationDisplayedMethod(ReceivedNotification receivedNotification) async {
  print('Bildirim gösterildi: ${receivedNotification.toMap().toString()}');
}

@pragma('vm:entry-point')
Future<void> notificationDismissedMethod(ReceivedAction receivedAction) async {
  print('Bildirim kapatıldı: ${receivedAction.toMap().toString()}');
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
  
  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: KaplanAppBar(
        title: _titles[_selectedIndex],
        isDarkMode: isDarkMode,
        isRequiredPage: _selectedIndex == 0 ? false : false,
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
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : const Color(0xFFF8F8FC),
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
              rippleColor: isDarkMode ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade300,
              hoverColor: isDarkMode ? AppTheme.primaryColor.withOpacity(0.15) : Colors.grey.shade200,
              gap: 8,
              activeColor: isDarkMode ? Colors.white : Colors.white,
              iconSize: 24,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              duration: Duration(milliseconds: 400),
              tabBackgroundColor: isDarkMode ? AppTheme.primaryColor : AppTheme.primaryColor,
              color: isDarkMode ? AppTheme.darkSecondaryTextColor : Colors.grey.shade600,
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

void main() async {
  // Flutter binding'i başlat
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
  
  // Awesome Notifications için izleyicileri ayarla
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: notificationActionReceivedMethod,
    onNotificationCreatedMethod: notificationCreatedMethod,
    onNotificationDisplayedMethod: notificationDisplayedMethod,
    onDismissActionReceivedMethod: notificationDismissedMethod
  );
  
  // Program servisini başlat
  final programService = ProgramService();
  await programService.initialize();
  
  // Bildirimleri başlat
  final notificationService = NotificationService.instance;
  await notificationService.init();
  
  // Test bildirimlerini planla - uygulama ilk açıldığında çalışmaması için devre dışı bırakıldı
  /* 
  try {
    await notificationService.sendTestNotification();
    print("Test bildirimleri başarıyla planlandı");
  } catch (e) {
    print("Test bildirimleri planlanırken hata: $e");
  }
  */
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ActivityProvider()),
        ChangeNotifierProvider(create: (context) => NutritionProvider()),
        ChangeNotifierProvider(create: (context) => DatabaseProvider()),
        // ProgramService'i sağlayıcı olarak ekle
        Provider<ProgramService>.value(value: programService),
      ],
      child: const MyApp(),
    ),
  );
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
          theme: AppTheme.lightTheme,
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
