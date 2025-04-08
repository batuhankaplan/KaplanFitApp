import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final String _channelId = 'basic_channel';
  final String _channelName = 'Basic Notifications';
  final String _channelDescription = 'KaplanFit uygulama bildirimleri';

  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  static bool _initialized = false;

  NotificationService._();

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    // Bildirim simgesi ve bildirim ayarları
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
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

      // Uygulama kapandığında bildirimlerin çalışması için ayarla
      await _setupNotificationsForAppClose();

      _initialized = true;
      debugPrint('Bildirim servisi başarıyla başlatıldı.');
    } catch (e) {
      debugPrint('Bildirim servisi başlatılırken hata: $e');
    }
  }

  Future<void> _configureAndroidNotifications() async {
    try {
      // Android bildirimi için kanal oluştur
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          sound: const RawResourceAndroidNotificationSound('alarm_sound'),
          enableLights: true,
          ledColor: const Color(0xFF5D69BE),
        ),
      );

      // Ek bir yüksek öncelikli kanal oluştur
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'Yüksek Öncelikli Bildirimler',
          description: 'Bu kanal kritik bildirimleri göstermek için kullanılır',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
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

            // Kullanıcı izin verdiyse exact alarm izni de kontrol et
            if (result.isGranted && androidInfo.version.sdkInt >= 31) {
              await _checkScheduleExactNotificationsPermission();
            }

            return result.isGranted;
          }

          // İzin varsa exact alarm izni de kontrol et
          if (status.isGranted && androidInfo.version.sdkInt >= 31) {
            await _checkScheduleExactNotificationsPermission();
          }

          return status.isGranted;
        } else if (androidInfo.version.sdkInt >= 31) {
          // Android 12 için exact alarm izni kontrolü
          await _checkScheduleExactNotificationsPermission();
          return true;
        }
        return true; // Android 12 altında otomatik izin var
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

  // Tam zamanlı bildirim izinlerini kontrol et (Android 12+)
  Future<bool> _checkScheduleExactNotificationsPermission() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin == null) return false;

      // Tam zamanlı bildirim iznini kontrol et
      final bool hasExactAlarmPermission =
          await androidPlugin.canScheduleExactNotifications() ?? false;

      // Bildirim sisteminin önceliğini yükselt
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();

      // Eğer izin yoksa kullanıcıya bildirimle bilgilendirme
      if (!hasExactAlarmPermission) {
        await _flutterLocalNotificationsPlugin.show(
          9999, // Özel ID
          'Tam Bildirim Zamanlaması İçin İzin Gerekli',
          'Bildirimlerin zamanında gelmesi için ayarlara giderek tam zamanlı bildirim iznini etkinleştirin.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Yüksek Öncelikli Bildirimler',
              channelDescription:
                  'Bu kanal kritik bildirimleri göstermek için kullanılır',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              enableVibration: true,
            ),
          ),
        );

        // Ek bir bildirim daha göndererek dikkat çek
        await Future.delayed(Duration(seconds: 2));
        await _flutterLocalNotificationsPlugin.show(
          9998, // Farklı ID
          'Bildirim İzni Eksik',
          'Ayarlar > Uygulamalar > KaplanFit > Bildirimler > Tam zamanlı bildirimlere izin ver',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'basic_channel',
              'Basic Notifications',
              channelDescription: 'KaplanFit uygulama bildirimleri',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              enableVibration: true,
            ),
          ),
        );
      }

      return hasExactAlarmPermission;
    } catch (e) {
      debugPrint('Exact alarms izni kontrol edilirken hata: $e');
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

      if (!_initialized) {
        await init();
      }

      // Birden fazla kanaldan bildirimler göndererek daha güvenilir bildirim sağla
      const AndroidNotificationDetails basicAndroidDetails =
          AndroidNotificationDetails(
        'basic_channel', // Kanal ID
        'Basic Notifications', // Kanal adı
        channelDescription: 'KaplanFit uygulama bildirimleri',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        color: Color(0xFF5D69BE),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('open', 'Aç'),
        ],
      );

      const AndroidNotificationDetails highImportanceAndroidDetails =
          AndroidNotificationDetails(
        'high_importance_channel', // Kanal ID
        'Yüksek Öncelikli Bildirimler', // Kanal adı
        channelDescription:
            'Bu kanal kritik bildirimleri göstermek için kullanılır',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        color: Color(0xFF5D69BE),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('open', 'Aç'),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails basicNotificationDetails = NotificationDetails(
        android: basicAndroidDetails,
        iOS: iosDetails,
      );

      const NotificationDetails highImportanceNotificationDetails =
          NotificationDetails(
        android: highImportanceAndroidDetails,
        iOS: iosDetails,
      );

      // Ana test bildirimi
      await _flutterLocalNotificationsPlugin.show(
        Random().nextInt(1000), // Bildirim ID'si rastgele
        'Test Bildirimi',
        'Bu bir test bildirimidir. Bildirim sistemi çalışıyor!',
        basicNotificationDetails,
      );

      // Yüksek öncelikli kanaldan da bildirim gönder
      await _flutterLocalNotificationsPlugin.show(
        Random().nextInt(1000) + 5000, // Farklı ID
        'Yüksek Öncelikli Test Bildirimi',
        'Bu yüksek öncelikli bir test bildirimidir!',
        highImportanceNotificationDetails,
      );

      // Android'de exact alarms izni kontrolü
      bool canScheduleExactAlarms = true;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        if (androidInfo.version.sdkInt >= 31) {
          // Android 12+
          canScheduleExactAlarms = await _flutterLocalNotificationsPlugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.canScheduleExactNotifications() ??
              false;
        }
      }

      // Anlık test bildirimleri gönder
      final now = DateTime.now();

      // Hemen gösterilecek olan bildirimler
      for (int i = 1; i <= 3; i++) {
        await _flutterLocalNotificationsPlugin.show(
          3000 + i, // Farklı ID
          'Anlık Test $i',
          'Bu bildirim hemen gösteriliyor - Test $i',
          i % 2 == 0
              ? basicNotificationDetails
              : highImportanceNotificationDetails,
        );
      }

      // Eğer tam zamanlı bildirim planlayabiliyorsak zamanlanmış test bildirimleri de ekle
      if (canScheduleExactAlarms) {
        // Test amacıyla zamanlı test bildirimleri oluştur - daha kısa aralıklarla
        for (int i = 1; i <= 10; i++) {
          await scheduleNotification(
            id: 2000 + i,
            title: '$i Dakika Sonra Bildirim',
            body: 'Bu bildirim şu andan $i dakika sonrası için planlandı.',
            scheduledDate:
                now.add(Duration(seconds: i * 30)), // 30 saniye aralıklarla
          );
        }

        debugPrint(
            'Test bildirimleri başarıyla gönderildi. 10 adet zamanlı bildirim de planlandı.');
      } else {
        debugPrint(
            'Test bildirimi gönderildi. Tam zamanlı bildirim izni olmadığından zamanlanmış bildirimler eklenmedi.');
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

      if (!_initialized) {
        await init();
      }

      // Kanallar arası dönüşümlü olarak bildirimler gönderelim
      final bool useHighImportance =
          id % 2 == 0; // Çift ID'ler için yüksek öncelikli kanal

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        useHighImportance ? 'high_importance_channel' : 'basic_channel',
        useHighImportance
            ? 'Yüksek Öncelikli Bildirimler'
            : 'Basic Notifications',
        channelDescription: useHighImportance
            ? 'Bu kanal kritik bildirimleri göstermek için kullanılır'
            : 'KaplanFit uygulama bildirimleri',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        color: Color(0xFF5D69BE),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('open', 'Aç'),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Android'de exact alarms izni kontrolü
      bool canScheduleExactAlarms = true;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        if (androidInfo.version.sdkInt >= 31) {
          // Android 12+
          try {
            canScheduleExactAlarms = await _flutterLocalNotificationsPlugin
                    .resolvePlatformSpecificImplementation<
                        AndroidFlutterLocalNotificationsPlugin>()
                    ?.canScheduleExactNotifications() ??
                false;
          } catch (e) {
            debugPrint('Exact alarms izni kontrol edilirken hata: $e');
            canScheduleExactAlarms = false;
          }
        }
      }

      // Bildirim yakın zamanlı ise (5 dakika içinde) hemen normal bildirim olarak göster
      final now = DateTime.now();
      final difference = scheduledDate.difference(now).inMinutes;
      if (difference <= 5) {
        await _flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          notificationDetails,
          payload: payload,
        );
        debugPrint('Bildirim zamanı yakın olduğundan hemen gönderildi: $title');
        return;
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
        debugPrint(
            'Tam zamanlı bildirim izni olmadığından normal bildirim gönderildi: $title');
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

        // Hemen bir hatırlatma bildirimi de gönder
        await _flutterLocalNotificationsPlugin.show(
          id + 10000,
          'Bildirim Ayarlandı',
          '$title bildirimi ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')} için planlandı.',
          notificationDetails,
        );

        debugPrint('Bildirim zamanlandı: $title - $scheduledDate');
      } catch (e) {
        // Eğer zamanlanmış bildirim çalışmazsa, anında bildirim göster
        debugPrint(
            'Zamanlanmış bildirim gönderilirken hata: $e. Anında bildirim gönderiliyor.');
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
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        locked: true,
        criticalAlert: true,
      ),
      schedule: NotificationCalendar(
        hour: timeOfDay.hour,
        minute: timeOfDay.minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
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

  // Uygulama kapandığında bildirimlerin çalışması için gerekli ayarlar
  Future<void> _setupNotificationsForAppClose() async {
    try {
      // Android için wake lock ve tam zamanlı bildirim izinleri
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          // Bildirim izinlerini garanti et
          await androidPlugin.requestNotificationsPermission();

          // Tam zamanlı bildirim izinlerini iste
          await androidPlugin.requestExactAlarmsPermission();

          debugPrint('✅ Bildirim izinleri ayarlandı');
        }
      }
    } catch (e) {
      debugPrint('❌ Bildirim izinleri ayarlanırken hata: $e');
    }
  }

  // Uygulama kapatıldığında çağrılabilecek metot
  Future<void> setupNotificationsOnAppClose() async {
    try {
      if (!_initialized) {
        await init();
      }

      debugPrint(
          '✅ Bildirim sistemi aktif, kapanma bildirimleri devre dışı bırakıldı');
    } catch (e) {
      debugPrint('❌ Bildirim sistemi hazırlanırken hata: $e');
    }
  }

  Future<void> scheduleTestNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      if (!_initialized) {
        await init();
      }

      // Test bildirimi için izinleri kontrol et
      if (!(await checkNotificationPermissions())) {
        throw Exception(
            'Bildirim izinleri reddedildi. Ayarlardan izin vermeniz gerekiyor.');
      }

      // Test bildirimi ayarları - En yüksek öncelik, titreşim, ses ve lock screen görünürlüğü
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Yüksek Öncelikli Bildirimler',
          channelDescription:
              'Bu kanal kritik bildirimleri göstermek için kullanılır',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'notification.aiff',
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

      try {
        // TZ yerel DateTime'ın zonedSchedule'a çevrilmesi
        final tz.TZDateTime zonedScheduleTime =
            tz.TZDateTime.from(scheduledDate, tz.local);

        // Zamanlanmış bildirimi ayarla
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          zonedScheduleTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'test_notification',
        );

        debugPrint('Bildirim zamanlandı: $title - $scheduledDate');
      } catch (e) {
        // Eğer zamanlanmış bildirim çalışmazsa, anında bildirim göster
        debugPrint(
            'Zamanlanmış bildirim gönderilirken hata: $e. Anında bildirim deneniyor.');

        // AwesomeNotifications ile deneyelim
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id,
            channelKey: 'basic_channel',
            title: title,
            body: body,
            category: NotificationCategory.Alarm,
            wakeUpScreen: true,
            fullScreenIntent: true,
            criticalAlert: true,
          ),
          schedule: NotificationCalendar.fromDate(
            date: scheduledDate,
            preciseAlarm: true,
            allowWhileIdle: true,
          ),
        );

        // Son çare olarak standart bildirimi deneyelim
        await _flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          notificationDetails,
          payload: 'test_notification',
        );
      }
    } catch (e) {
      debugPrint('Bildirim zamanlanırken hata: $e');
      throw Exception('Bildirim zamanlanırken hata: $e');
    }
  }

  Future<bool> checkNotificationPermissions() async {
    // Bu metodun içeriği, mevcut _checkAndRequestPermissions metodunun içeriğiyle aynıdır.
    // İzinleri kontrol etmek için _checkAndRequestPermissions metodunu kullanabilirsiniz.
    return await _checkAndRequestPermissions();
  }
}
