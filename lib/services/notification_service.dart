import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io' show Platform;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // Bildirim ayarları için shared preference anahtarları
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _lightEnabledKey = 'light_enabled';
  static const String _workoutReminderEnabledKey = 'workout_reminder_enabled';
  static const String _mealReminderEnabledKey = 'meal_reminder_enabled';
  static const String _waterReminderEnabledKey = 'water_reminder_enabled';
  static const String _goalReminderEnabledKey = 'goal_reminder_enabled';

  // Singleton yapı (tek bir örnek oluşturma)
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _lightEnabled = true;
  bool _workoutReminderEnabled = true;
  bool _mealReminderEnabled = true;
  bool _waterReminderEnabled = true;
  bool _goalReminderEnabled = true;

  // Bildirimleri başlatma
  Future<void> initialize() async {
    try {
      // Android için bildirim kanalı oluşturma
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'Yüksek Öncelikli Bildirimler',
          description: 'Bu kanal yüksek öncelikli bildirimler için kullanılır',
          importance: Importance.high,
        );

        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
      
      // iOS için izin isteme
      if (Platform.isIOS) {
        // İzinleri daha sonra isteyelim, hata olmaması için
        // gerektiğinde requestPermission() metodunu çağıracağız
      }
      
      // Başlangıç ayarları yükleme
      final sharedPreferences = await SharedPreferences.getInstance();
      _notificationsEnabled = sharedPreferences.getBool('notifications_enabled') ?? true;
      _soundEnabled = sharedPreferences.getBool('sound_enabled') ?? true;
      _vibrationEnabled = sharedPreferences.getBool('vibration_enabled') ?? true;
      _lightEnabled = sharedPreferences.getBool('light_enabled') ?? true;
      _workoutReminderEnabled = sharedPreferences.getBool('workout_reminder_enabled') ?? true;
      _mealReminderEnabled = sharedPreferences.getBool('meal_reminder_enabled') ?? true;
      _waterReminderEnabled = sharedPreferences.getBool('water_reminder_enabled') ?? true;
      _goalReminderEnabled = sharedPreferences.getBool('goal_reminder_enabled') ?? true;
    } catch (e) {
      print('Bildirim servisi başlatılırken hata: $e');
      // Hata olursa bildirimleri devre dışı bırak
      _notificationsEnabled = false;
    }
  }

  // Bildirim izni isteme (lazım olduğunda çağrılacak)
  Future<bool> requestPermission() async {
    bool permissionGranted = false;
    
    try {
      if (Platform.isAndroid) {
        // Şimdilik izinleri verilmiş varsayalım, Android 13 ve üzeri için
        // gerçek bir izin kontrolü gerekiyor, ama şu an için basitleştirelim
        permissionGranted = true;
        
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          // Android 13+ için özel izin kontrolü gerektiren kod burada olacak
          // Şimdilik izinleri verilmiş varsayalım
          permissionGranted = true;
        }
      } else if (Platform.isIOS) {
        // iOS için bildirim izni kontrolü
        final IOSFlutterLocalNotificationsPlugin? iOSImplementation =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
                
        if (iOSImplementation != null) {
          final bool? granted = await iOSImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          permissionGranted = granted ?? false;
        }
      }
      
      // İzin durumunu kaydet
      _notificationsEnabled = permissionGranted;
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setBool('notifications_enabled', permissionGranted);
      
      return permissionGranted;
    } catch (e) {
      print('Bildirim izni isteme hatası: $e');
      return false;
    }
  }

  // Bildirim türüne göre simge belirleme yardımcı metodu
  String _getNotificationIcon(String notificationType) {
    switch (notificationType) {
      case 'swimming':
        return 'ic_swimming';
      case 'workout':
      case 'evening_exercise':
        return 'ic_dumbbell';
      case 'running':
        return 'ic_running';
      case 'meal':
      case 'lunch':
      case 'dinner':
        return 'ic_food';
      case 'water':
        return 'ic_water';
      case 'test':
        return '@kaplan_logo'; // PNG logosu doğrudan kullan
      default:
        return 'ic_fitness'; // Varsayılan spor simgesi
    }
  }

  // Test bildirimi gönderme
  Future<void> sendTestNotification() async {
    try {
      // Basitleştirilmiş test bildirimi - Android özgü ayarlar
      final androidNotificationDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'Yüksek Öncelikli Bildirimler',
        channelDescription: 'Bu kanal yüksek öncelikli bildirimler için kullanılır',
        importance: Importance.high,
        priority: Priority.high,
        // Küçük beyaz simge (status bar için) - test bildirimi için kaplan simgesi
        icon: _getNotificationIcon('test'),
        // Büyük renkli simge (bildirim içinde gösterilir) - kaplan logo
        largeIcon: const DrawableResourceAndroidBitmap('kaplan_logo'),
        // Bildirim simgesinin rengini ayarla
        color: const Color(0xFFFF8800), // Turuncu renk
      );
      
      // Tüm platformlar için bildirim detayları
      final notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        0, // Notification ID
        'Test Bildirimi',
        'Bu bir test bildirimidir. Bildirimler çalışıyor!',
        notificationDetails,
      );
      
      print('Test bildirimi gönderildi');
    } catch (e) {
      print('Test bildirimi gönderme hatası: $e');
      rethrow;
    }
  }

  // Basit bildirim gönderme (içerik türüne göre simge seçimiyle)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String notificationType = 'default',
  }) async {
    if (!_isInitialized) await initialize();

    // Android için bildirim detayları
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'kaplanfit_channel', // id
      'KaplanFIT Bildirimleri', // title
      channelDescription: 'Egzersiz, beslenme ve su hatırlatmaları',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableLights: _lightEnabled,
      enableVibration: _vibrationEnabled,
      playSound: _soundEnabled,
      // İçerik türüne göre simge seçimi
      icon: _getNotificationIcon(notificationType),
      // Büyük renkli simge (bildirim içinde gösterilir) - kaplan logo
      largeIcon: const DrawableResourceAndroidBitmap('kaplan_logo'),
      color: const Color(0xFFFF8800), // Turuncu renk
    );

    // Genel bildirim detayları
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Bildirimi göster
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Egzersiz hatırlatma bildirimi
  Future<void> showWorkoutReminder() async {
    if (!await isWorkoutReminderEnabled()) return;

    await showNotification(
      id: 1,
      title: 'Egzersiz Zamanı',
      body: 'Bugünkü egzersizinizi tamamlamayı unutmayın!',
      payload: 'workout',
      notificationType: 'workout',
    );
  }

  // Öğün hatırlatma bildirimi
  Future<void> showMealReminder() async {
    if (!await isMealReminderEnabled()) return;

    await showNotification(
      id: 2,
      title: 'Öğün Zamanı',
      body: 'Sağlıklı bir öğün için zaman ayırmayı unutmayın!',
      payload: 'meal',
      notificationType: 'meal',
    );
  }

  // Su içme hatırlatma bildirimi
  Future<void> showWaterReminder() async {
    if (!await isWaterReminderEnabled()) return;

    await showNotification(
      id: 3,
      title: 'Su İçme Zamanı',
      body: 'Günlük su hedefine ulaşmak için biraz su için!',
      payload: 'water',
      notificationType: 'water',
    );
  }

  // Hedef hatırlatma bildirimi
  Future<void> showGoalReminder() async {
    if (!await isGoalReminderEnabled()) return;

    await showNotification(
      id: 4,
      title: 'Hedef Hatırlatması',
      body: 'Bugünkü hedeflerinize ulaşmak için çalışmayı unutmayın!',
      payload: 'goal',
      notificationType: 'default',
    );
  }

  // Tüm bildirimleri aktif/pasif yapma
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  // Bildirim sesini aktif/pasif yapma
  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  // Bildirim titreşimini aktif/pasif yapma
  Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);
  }

  // Bildirim ışığını aktif/pasif yapma
  Future<void> setLightEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lightEnabledKey, enabled);
  }

  // Egzersiz hatırlatmalarını aktif/pasif yapma
  Future<void> setWorkoutReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_workoutReminderEnabledKey, enabled);
  }

  // Öğün hatırlatmalarını aktif/pasif yapma
  Future<void> setMealReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mealReminderEnabledKey, enabled);
  }

  // Su hatırlatmalarını aktif/pasif yapma
  Future<void> setWaterReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_waterReminderEnabledKey, enabled);
  }

  // Hedef hatırlatmalarını aktif/pasif yapma
  Future<void> setGoalReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_goalReminderEnabledKey, enabled);
  }

  // Bildirimlerin aktif olup olmadığını kontrol etme
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true; // Varsayılan olarak aktif
  }

  // Bildirim sesinin aktif olup olmadığını kontrol etme
  Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  // Bildirim titreşiminin aktif olup olmadığını kontrol etme
  Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  // Bildirim ışığının aktif olup olmadığını kontrol etme
  Future<bool> isLightEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lightEnabledKey) ?? true;
  }

  // Egzersiz hatırlatmalarının aktif olup olmadığını kontrol etme
  Future<bool> isWorkoutReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_workoutReminderEnabledKey) ?? true;
  }

  // Öğün hatırlatmalarının aktif olup olmadığını kontrol etme
  Future<bool> isMealReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mealReminderEnabledKey) ?? true;
  }

  // Su hatırlatmalarının aktif olup olmadığını kontrol etme
  Future<bool> isWaterReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_waterReminderEnabledKey) ?? true;
  }

  // Hedef hatırlatmalarının aktif olup olmadığını kontrol etme
  Future<bool> isGoalReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_goalReminderEnabledKey) ?? true;
  }

  // Belirli bir zamana bildirim planlama
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
    String notificationType = 'default',
  }) async {
    if (!_isInitialized) await initialize();
    if (!_notificationsEnabled) return;

    try {
      // Zaman dilimini başlat
      tz_data.initializeTimeZones();
      
      // Yerel zaman dilimini al
      final location = tz.local;
      
      // Zamanlanmış tarih oluştur
      final scheduledDate = tz.TZDateTime.from(scheduledDateTime, location);
      
      // Android için bildirim detayları
      final androidDetails = AndroidNotificationDetails(
        'kaplanfit_channel',
        'KaplanFIT Bildirimleri',
        channelDescription: 'Egzersiz, beslenme ve su hatırlatmaları',
        importance: Importance.high,
        priority: Priority.high,
        enableLights: _lightEnabled,
        enableVibration: _vibrationEnabled,
        playSound: _soundEnabled,
        // İçerik türüne göre simge seçimi
        icon: _getNotificationIcon(notificationType),
        // Büyük renkli simge (bildirim içinde gösterilir) - kaplan logo
        largeIcon: const DrawableResourceAndroidBitmap('kaplan_logo'),
        color: const Color(0xFFFF8800),
      );
      
      // Bildirim detayları
      final notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      // Bildirimi planla
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      print('Bildirim planlandı: $scheduledDate - $title');
    } catch (e) {
      print('Bildirim planlama hatası: $e');
    }
  }
  
  // Haftalık bildirimleri ayarlama
  Future<void> setupWeeklyNotifications() async {
    if (!_isInitialized) await initialize();
    if (!_notificationsEnabled) return;
    
    // Önceki planlanmış tüm bildirimleri temizle
    await _flutterLocalNotificationsPlugin.cancelAll();
    
    try {
      // Timezone ayarları
      tz_data.initializeTimeZones();
      final location = tz.local;
      
      // Bugünün tarihini al
      final now = DateTime.now();
      
      // Haftalık program bildirimleri
      
      // 1. Sabah Yüzme Egzersizleri (Salı, Çarşamba, Perşembe - 08:30)
      for (int weekday in [DateTime.tuesday, DateTime.wednesday, DateTime.thursday]) {
        final scheduledDate = _nextInstanceOfDayAndTime(weekday, 8, 30);
        
        await scheduleNotification(
          id: 100 + weekday, // Benzersiz ID
          title: 'Sabah Yüzme Vakti!',
          body: 'Haydi yüzme saatin geldi! 08:45-09:15 arası yüzme programını unutma.',
          scheduledDateTime: scheduledDate,
          payload: 'morning_exercise',
          notificationType: 'swimming',
        );
      }
      
      // 2. Akşam Egzersizleri (Salı, Çarşamba, Perşembe - 18:15)
      for (int weekday in [DateTime.tuesday, DateTime.wednesday, DateTime.thursday]) {
        final scheduledDate = _nextInstanceOfDayAndTime(weekday, 18, 15);
        
        await scheduleNotification(
          id: 200 + weekday, // Benzersiz ID
          title: 'Akşam Spor Vakti!',
          body: 'Haydi spor vakti spor salonuna marş marş! 18:00-18:45 arası antrenmanını kaçırma.',
          scheduledDateTime: scheduledDate,
          payload: 'evening_exercise',
          notificationType: 'workout',
        );
      }
      
      // 3. Pazartesi Hatırlatmaları
      // Sabah
      await scheduleNotification(
        id: 101,
        title: 'Sabah Egzersizi Hatırlatması',
        body: 'Bugün havuz kapalı. Evde esneme egzersizleri yapabilirsin!',
        scheduledDateTime: _nextInstanceOfDayAndTime(DateTime.monday, 8, 30),
        payload: 'morning_exercise',
        notificationType: 'workout',
      );
      
      // Akşam
      await scheduleNotification(
        id: 201,
        title: 'Akşam Egzersizi Hatırlatması',
        body: 'Bugün spor salonu kapalı. Hafif bir yürüyüş yapmayı düşünebilirsin!',
        scheduledDateTime: _nextInstanceOfDayAndTime(DateTime.monday, 18, 15),
        payload: 'evening_exercise',
        notificationType: 'running',
      );
      
      // 4. Cuma, Cumartesi, Pazar Hatırlatmaları
      // Cuma
      await scheduleNotification(
        id: 105,
        title: 'Sabah Egzersizi Hatırlatması',
        body: 'İsteğe bağlı yüzme veya yürüyüş yapabilirsin.',
        scheduledDateTime: _nextInstanceOfDayAndTime(DateTime.friday, 8, 30),
        payload: 'morning_exercise',
        notificationType: 'swimming',
      );
      
      await scheduleNotification(
        id: 205,
        title: 'Akşam Egzersizi Hatırlatması',
        body: 'Bugün dinlenme veya esneme yapabilirsin.',
        scheduledDateTime: _nextInstanceOfDayAndTime(DateTime.friday, 18, 15),
        payload: 'evening_exercise',
        notificationType: 'workout',
      );
      
      // Cumartesi
      await scheduleNotification(
        id: 106,
        title: 'Sabah Egzersizi Hatırlatması',
        body: 'Hafif yürüyüş, esneme veya yüzme aktivitelerinden birini tercih edebilirsin.',
        scheduledDateTime: _nextInstanceOfDayAndTime(DateTime.saturday, 8, 30),
        payload: 'morning_exercise',
        notificationType: 'running',
      );
      
      await scheduleNotification(
        id: 206,
        title: 'Akşam Egzersizi Hatırlatması',
        body: 'İsteğe bağlı egzersiz zamanı!',
        scheduledDateTime: _nextInstanceOfDayAndTime(DateTime.saturday, 18, 15),
        payload: 'evening_exercise',
        notificationType: 'workout',
      );
      
      // Pazar
      await scheduleNotification(
        id: 107,
        title: 'Sabah Egzersizi Hatırlatması',
        body: 'Tam dinlenme günü veya 20-30 dakika yürüyüş yapabilirsin.',
        scheduledDateTime: _nextInstanceOfDayAndTime(DateTime.sunday, 8, 30),
        payload: 'morning_exercise',
        notificationType: 'running',
      );
      
      // 5. Yemek Hatırlatmaları (Her gün)
      // Öğle Yemeği (12:00)
      for (int weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
        await scheduleNotification(
          id: 300 + weekday,
          title: 'Öğle Yemeği Vakti',
          body: 'Öğle yemeği saati geldi! Sağlıklı bir öğün için zaman ayır.',
          scheduledDateTime: _nextInstanceOfDayAndTime(weekday, 12, 0),
          payload: 'lunch',
          notificationType: 'meal',
        );
      }
      
      // Akşam Yemeği (19:00)
      for (int weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
        await scheduleNotification(
          id: 400 + weekday,
          title: 'Akşam Yemeği Vakti',
          body: 'Akşam yemeği zamanı! Dengeli ve sağlıklı bir akşam yemeği ile günü tamamla.',
          scheduledDateTime: _nextInstanceOfDayAndTime(weekday, 19, 0),
          payload: 'dinner',
          notificationType: 'meal',
        );
      }
      
      print('Tüm haftalık bildirimler başarıyla planlandı!');
    } catch (e) {
      print('Haftalık bildirimleri ayarlama hatası: $e');
    }
  }
  
  // Verilen gün ve saatte bir sonraki zaman oluşturma yardımcı metodu
  tz.TZDateTime _nextInstanceOfDayAndTime(int weekday, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local, 
      now.year, 
      now.month, 
      now.day, 
      hour, 
      minute
    );
    
    // Bugün için zamanı geçtiyse veya farklı bir günse, bir sonraki uygun güne ayarla
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
} 