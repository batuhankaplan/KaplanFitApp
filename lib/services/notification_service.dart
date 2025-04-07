import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  final String _channelId = 'basic_channel';
  final String _channelName = 'Basic Notifications';
  final String _channelDescription = 'KaplanFit uygulama bildirimleri';

  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  
  bool _isInitialized = false;
  
  NotificationService._();

  Future<void> init() async {
    if (_isInitialized) return;
    
    tz_data.initializeTimeZones();
    
    // Bildirim simgesi ve bildirim ayarları
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      // Bildirimleri başlat
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Bildirim tıklandı: ${response.payload}');
          // Bildirime tıklandığında yapılacak işlemler buraya eklenebilir
        },
      );
      
      // Android için bildirimleri ayarla
      if (Platform.isAndroid) {
        await _configureAndroidNotifications();
      }
      
      // İzinleri kontrol et ve iste
      await _checkAndRequestPermissions();
      
      _isInitialized = true;
      debugPrint('Bildirim servisi başarıyla başlatıldı.');
    } catch (e) {
      debugPrint('Bildirim servisi başlatılırken hata: $e');
    }
  }
  
  Future<void> _configureAndroidNotifications() async {
    try {
      // Android bildirimi için kanal oluştur
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
              
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
      
      debugPrint('Android bildirimleri yapılandırıldı.');
    } catch (e) {
      debugPrint('Android bildirimleri yapılandırılırken hata: $e');
    }
  }
  
  Future<bool> _checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Android 13+ (SDK 33+) için özel izin kontrolü
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          final status = await Permission.notification.status;
          if (status.isDenied) {
            final result = await Permission.notification.request();
            return result.isGranted;
          }
          return status.isGranted;
        }
        return true; // Android 13 altında otomatik izin var
      } else if (Platform.isIOS) {
        final settings = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        return settings ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('İzin kontrolü sırasında hata: $e');
      return false;
    }
  }

  // Anında bir test bildirimi gönder
  Future<void> sendTestNotification() async {
    try {
      // Önce izinleri kontrol et
      final bool hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        debugPrint('Bildirim izni reddedildi.');
        return;
      }
      
      if (!_isInitialized) {
        await init();
      }
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'basic_channel', // Kanal ID
        'Basic Notifications', // Kanal adı
        channelDescription: 'KaplanFit uygulama bildirimleri',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        color: Color(0xFF5D69BE),
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Ana test bildirimi
      await _flutterLocalNotificationsPlugin.show(
        Random().nextInt(1000), // Bildirim ID'si rastgele
        'Test Bildirimi',
        'Bu bir test bildirimidir. Bildirim sistemi çalışıyor!',
        notificationDetails,
      );

      // Android'de exact alarms izni kontrolü
      bool canScheduleExactAlarms = true;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        if (androidInfo.version.sdkInt >= 31) { // Android 12+
          canScheduleExactAlarms = await _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.canScheduleExactNotifications() ?? false;
        }
      }
      
      // Eğer tam zamanlı bildirim planlayabiliyorsak zamanlanmış test bildirimleri de ekle
      if (canScheduleExactAlarms) {
        // Test amacıyla 5 adet zamanlı test bildirimi oluştur
        final now = DateTime.now();
        
        for (int i = 1; i <= 5; i++) {
          await scheduleNotification(
            id: 2000 + i,
            title: '$i Dakika Sonra Bildirim',
            body: 'Bu bildirim şu andan $i dakika sonrası için planlandı.',
            scheduledDate: now.add(Duration(minutes: i)),
          );
        }
        
        debugPrint('Test bildirimleri başarıyla gönderildi. 5 adet zamanlı bildirim de planlandı.');
      } else {
        debugPrint('Test bildirimi gönderildi. Tam zamanlı bildirim izni olmadığından zamanlanmış bildirimler eklenmedi.');
      }
    } catch (e) {
      debugPrint('Test bildirimi gönderilirken hata: $e');
      throw Exception('Bildirim gönderilirken hata: $e');
    }
  }

  // Zamanlanmış bildirim gönder
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      // Önce izinleri kontrol et
      final bool hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        debugPrint('Bildirim izni reddedildi.');
        return;
      }
      
      if (!_isInitialized) {
        await init();
      }
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        color: Color(0xFF5D69BE),
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Android'de exact alarms izni kontrolü
      bool canScheduleExactAlarms = true;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        if (androidInfo.version.sdkInt >= 31) { // Android 12+
          try {
            canScheduleExactAlarms = await _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                ?.canScheduleExactNotifications() ?? false;
          } catch (e) {
            debugPrint('Exact alarms izni kontrol edilirken hata: $e');
            canScheduleExactAlarms = false;
          }
        }
      }
      
      // Eğer tam zamanlı bildirim planlama izni yoksa normal bildirim göster
      if (!canScheduleExactAlarms && Platform.isAndroid) {
        // Tam zamanlı bildirimler yerine normal bildirim gönder
        await _flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          notificationDetails,
          payload: payload,
        );
        debugPrint('Tam zamanlı bildirim izni olmadığından normal bildirim gönderildi: $title');
        return;
      }
      
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        debugPrint('Bildirim zamanlandı: $title - $scheduledDate');
      } catch (e) {
        // Eğer zamanlanmış bildirim çalışmazsa, anında bildirim göster
        debugPrint('Zamanlanmış bildirim gönderilirken hata: $e. Anında bildirim gönderiliyor.');
        await _flutterLocalNotificationsPlugin.show(
          id,
          title, 
          body,
          notificationDetails,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('Bildirim zamanlanırken hata: $e');
      throw Exception('Bildirim zamanlanırken hata: $e');
    }
  }

  // Günlük bildirim ayarla (her gün belirli bir saatte)
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay timeOfDay,
    String? payload,
  }) async {
    try {
      // Önce izinleri kontrol et
      final bool hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        debugPrint('Bildirim izni reddedildi.');
        return;
      }
      
      if (!_isInitialized) {
        await init();
      }
      
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      
      // Eğer belirtilen saat geçtiyse, bir sonraki güne ayarla
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        color: Color(0xFF5D69BE),
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Android'de exact alarms izni kontrolü
      bool canScheduleExactAlarms = true;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        if (androidInfo.version.sdkInt >= 31) { // Android 12+
          try {
            canScheduleExactAlarms = await _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                ?.canScheduleExactNotifications() ?? false;
          } catch (e) {
            debugPrint('Exact alarms izni kontrol edilirken hata: $e');
            canScheduleExactAlarms = false;
          }
        }
      }
      
      // TZDateTime oluştur
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
      );

      // Eğer tam zamanlı bildirim planlama izni yoksa anında bildirim göster
      if (!canScheduleExactAlarms && Platform.isAndroid) {
        // Tam zamanlı bildirimler yerine normal bildirim gönder
        await _flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          notificationDetails,
          payload: payload,
        );
        
        // Kullanıcı bilgilendirmesi için saati kaydet, ancak zamanlanmadığını bildir
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('notification_time', '${timeOfDay.hour}:${timeOfDay.minute} (Yaklaşık)');
        
        debugPrint('Tam zamanlı bildirim izni olmadığından normal bildirim gönderildi: $title');
        return;
      }

      try {
        // Tekrarlayan bildirim için matchDateTimeComponents kullanılır
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
        
        // Kullanıcı bilgilendirmesi için saati kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('notification_time', '${timeOfDay.hour}:${timeOfDay.minute}');
        
        debugPrint('Günlük bildirim ayarlandı: $title - ${timeOfDay.hour}:${timeOfDay.minute}');
      } catch (e) {
        debugPrint('Günlük bildirim ayarlanırken hata: $e');
        
        // Hata durumunda anında bildirim göster
        await _flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          notificationDetails,
          payload: payload,
        );
        
        // Hatayı yeniden fırlat, ancak önce bir normal bildirim göster
        throw Exception('Günlük bildirim ayarlanırken hata: $e');
      }
    } catch (e) {
      debugPrint('Günlük bildirim ayarlanırken hata: $e');
      throw Exception('Günlük bildirim ayarlanırken hata: $e');
    }
  }

  // Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      
      // Kullanıcı bilgilendirmesi için saati temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_time');
      
      debugPrint('Tüm bildirimler iptal edildi.');
    } catch (e) {
      debugPrint('Bildirimler iptal edilirken hata: $e');
      throw Exception('Bildirimler iptal edilirken hata: $e');
    }
  }

  // Belirli bir bildirimi iptal et
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('$id ID\'li bildirim iptal edildi.');
    } catch (e) {
      debugPrint('Bildirim iptal edilirken hata: $e');
      throw Exception('Bildirim iptal edilirken hata: $e');
    }
  }
  
  // Bildirimlerin etkin olup olmadığını kontrol et
  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          return await Permission.notification.isGranted;
        }
        return true;
      } else if (Platform.isIOS) {
        // iOS için bildirimlerin etkin olup olmadığını kontrol etme yöntemi
        final settings = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.getNotificationAppLaunchDetails();
        return settings?.didNotificationLaunchApp ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Bildirim durumu kontrol edilirken hata: $e');
      return false;
    }
  }
  
  // Mevcut zamanlanmış bildirimleri getir
  Future<String?> getScheduledNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('notification_time');
    } catch (e) {
      debugPrint('Bildirim zamanı alınırken hata: $e');
      return null;
    }
  }
} 