import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final String _channelId = 'kaplanfit_daily_reminders';
  final String _channelName = 'Günlük Hatırlatmalar';
  final String _channelDescription = 'Antrenman, beslenme ve su hatırlatmaları';

  final String _testChannelId = 'kaplanfit_test_notifications';
  final String _testChannelName = 'Test Bildirimleri';
  final String _testChannelDescription = 'Anlık test bildirimleri için kanal';

  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  static bool _initialized = false;

  NotificationService._();

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // Sistem saat dilimini al (ör: Europe/Istanbul)
    // Eğer alınamazsa varsayılan olarak UTC kullanılacak
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (e) {
      debugPrint("Yerel saat dilimi alınamadı: $e. UTC kullanılıyor.");
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }

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
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      await _checkAndRequestPermissions();

      _initialized = true;
      debugPrint(
          'Bildirim servisi başarıyla başlatıldı. Yerel Saat Dilimi: ${tz.local}');
    } catch (e) {
      debugPrint('Bildirim servisi başlatılırken hata: $e');
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Bildirim tıklandı! Payload: ${response.payload}');
    // TODO: Payload'a göre uygulama içi yönlendirme yapılabilir.
    // Örneğin: if (response.payload == 'workout_reminder') { // Antrenman ekranına git }
  }

  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    try {
      // Günlük Hatırlatmalar Kanalı (Yüksek Öncelik)
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max, // Yüksek öncelik
          playSound: true,
          enableVibration: true,
          sound: const RawResourceAndroidNotificationSound(
              'alarm_sound'), // raw/alarm_sound.mp3 dosyası olmalı
          enableLights: true,
          ledColor: const Color(0xFF5D69BE),
        ),
      );

      // Test Bildirimleri Kanalı (Normal Öncelik)
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _testChannelId,
          _testChannelName,
          description: _testChannelDescription,
          importance: Importance.high, // Yüksek ama max değil
          playSound: true,
          enableVibration: true,
        ),
      );
      debugPrint('Android bildirim kanalları oluşturuldu.');
    } catch (e) {
      debugPrint('Android bildirim kanalları oluşturulurken hata: $e');
    }
  }

  /// Gerekli bildirim izinlerini kontrol eder ve ister.
  Future<bool> _checkAndRequestPermissions() async {
    bool allPermissionsGranted = true;
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;

        // Android 13+ (SDK 33+) Bildirim İzni
        if (androidInfo.version.sdkInt >= 33) {
          var notificationStatus = await Permission.notification.status;
          debugPrint(
              "[Permissions] Android 13+ Notification Status: $notificationStatus");
          if (notificationStatus.isDenied) {
            notificationStatus = await Permission.notification.request();
            debugPrint(
                "[Permissions] Android 13+ Notification Request Result: $notificationStatus");
          }
          if (!notificationStatus.isGranted) {
            debugPrint("[Permissions] Android 13+ bildirim izni verilmedi.");
            allPermissionsGranted = false;
            // İzin verilmediyse bile devam edebiliriz, ama loglamak önemli.
          }
        }

        // Android 12+ (SDK 31+) Tam Zamanlı Alarm İzni (SCHEDULE_EXACT_ALARM)
        if (androidInfo.version.sdkInt >= 31) {
          var exactAlarmStatus = await Permission.scheduleExactAlarm.status;
          debugPrint(
              "[Permissions] Android 12+ Exact Alarm Status: $exactAlarmStatus");
          if (exactAlarmStatus.isDenied) {
            // Bu izin için request() genellikle doğrudan ayarlar sayfasını açar.
            exactAlarmStatus = await Permission.scheduleExactAlarm.request();
            debugPrint(
                "[Permissions] Android 12+ Exact Alarm Request Result: $exactAlarmStatus");
            // Kullanıcı ayarlardan geri döndükten sonra durumu tekrar kontrol etmek gerekebilir.
            // Şimdilik sadece isteği yapıyoruz.
          }
          if (!exactAlarmStatus.isGranted) {
            debugPrint(
                "[Permissions] Tam zamanlı alarm (SCHEDULE_EXACT_ALARM) izni yok. Bildirimler gecikebilir.");
            // Bu iznin kritik olduğunu kullanıcıya bildirebiliriz.
            // allPermissionsGranted = false; // Bu iznin olmaması app'i durdurmaz.
          } else {
            debugPrint("[Permissions] Tam zamanlı alarm izni verilmiş.");
          }
        }
        return allPermissionsGranted; // Şimdilik sadece temel bildirim izninin durumunu döndürüyoruz.
        // Exact alarm olmasa da uygulama çalışır.
      } else if (Platform.isIOS) {
        // iOS izinleri başlatmada istendi, burada tekrar kontrol edilebilir veya sadece true dönülebilir.
        final settings = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        // settings?.alert artık geçerli değil, genel olarak izin verilip verilmediğine bakılır.
        // FlutterLocalNotificationsPlugin 17+ ile requestPermissions bool döndürür.
        return settings ?? false; // İzin verildiyse true döner.
      }
      return false; // Desteklenmeyen platform
    } catch (e) {
      debugPrint('İzin kontrolü/isteme sırasında hata: $e');
      return false;
    }
  }

  /// Her gün belirtilen saatte tekrarlayan bildirim planlar.
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay timeOfDay,
    String? payload,
  }) async {
    if (!_initialized) await init();

    try {
      // Tam zamanlı alarm iznini ve modunu belirle (Android 12+)
      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.exactAllowWhileIdle;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        if (androidInfo.version.sdkInt >= 31) {
          final bool canScheduleExact = await _flutterLocalNotificationsPlugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.canScheduleExactNotifications() ??
              false;
          if (!canScheduleExact) {
            scheduleMode = AndroidScheduleMode.inexact;
            debugPrint(
                "Bildirim $id için tam zamanlı alarm izni yok, kesin olmayan modda planlanacak.");
          }
        }
      }

      // Planlanacak zamanı hesapla (bir sonraki tekrar)
      final tz.TZDateTime scheduledTime = _nextInstanceOfTime(timeOfDay);

      // Bildirim detayları
      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, // Günlük hatırlatmalar için ana kanal
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          // sound: RawResourceAndroidNotificationSound('alarm_sound'), // Kanalda tanımlı
          // icon: '@mipmap/ic_launcher', // Başlatmada tanımlı
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive, // Önemli bildirim
        ),
      );

      // Bildirimi planla
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            DateTimeComponents.time, // Her gün bu saatte tekrarla
        payload: payload,
      );

      debugPrint(
          'Günlük bildirim planlandı: ID $id - Saat ${timeOfDay.hour}:${timeOfDay.minute.toString().padLeft(2, '0')} - Zaman: $scheduledTime');
    } catch (e) {
      debugPrint('Günlük bildirim (ID: $id) planlanırken hata: $e');
    }
  }

  /// Belirtilen saatin bir sonraki tekrarını (bugün veya yarın) hesaplar.
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    // Eğer planlanan saat geçmişte kaldıysa, yarına planla
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Belirtilen **tarih ve saatte** tek seferlik bildirim planlar.
  Future<void> scheduleOneTimeNotification({
    required String title,
    required String body,
    required DateTime scheduledDateTime, // TimeOfDay yerine DateTime
    String? payload,
  }) async {
    if (!_initialized) await init();

    try {
      // ID oluşturma (aynı kalabilir)
      final int notificationId = 20000 + Random().nextInt(10000);

      // Planlanacak zamanı hesapla (artık doğrudan DateTime kullanıyoruz)
      // _nextInstanceOfTime fonksiyonuna gerek kalmadı.
      final tz.TZDateTime scheduledTime =
          tz.TZDateTime.from(scheduledDateTime, tz.local);
      debugPrint(
          '[scheduleOneTimeNotification] Hesaplanan Planlama Zamanı (TZ): $scheduledTime'); // LOG

      // Geçmiş zaman kontrolü (isteğe bağlı ama iyi pratik)
      if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint(
            "Geçmiş bir zaman ($scheduledTime) için bildirim planlanamaz (ID: $notificationId).");
        return; // Geçmişse planlama yapma
      }

      // Android için alarm modunu belirle (aynı kalabilir)
      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.exactAllowWhileIdle;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        if (androidInfo.version.sdkInt >= 31) {
          final bool canScheduleExact = await _flutterLocalNotificationsPlugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.canScheduleExactNotifications() ??
              false;
          if (!canScheduleExact) {
            scheduleMode = AndroidScheduleMode.inexact;
            debugPrint(
                "Bildirim $notificationId için tam zamanlı alarm izni yok, kesin olmayan modda planlanacak.");
          }
        }
      }
      debugPrint(
          '[scheduleOneTimeNotification] Kullanılacak Android Schedule Mode: $scheduleMode'); // LOG

      // Bildirim detayları (Günlük hatırlatmalarla aynı kanalı kullanabiliriz)
      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, // Ana hatırlatma kanalı
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );
      debugPrint(
          '[scheduleOneTimeNotification] zonedSchedule çağrısı yapıldı. ID: $notificationId'); // LOG

      // Bildirimi planla (matchDateTimeComponents OLMADAN)
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // matchDateTimeComponents: DateTimeComponents.time, // Kaldırıldı, tek seferlik
        payload: payload ?? 'custom_one_time_${notificationId}',
      );

      // debugPrint('Tek seferlik bildirim planlandı: ID $notificationId - "$title" - Zaman: $scheduledTime');
    } catch (e, stacktrace) {
      // Hata ile birlikte stacktrace'i de yakala
      debugPrint(
          '[scheduleOneTimeNotification] Tek seferlik bildirim planlanırken HATA: $e'); // LOG
      debugPrint(
          '[scheduleOneTimeNotification] Stacktrace: $stacktrace'); // LOG
    }
  }

  /// Anında bir test bildirimi gönderir.
  Future<void> sendNowTestNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    try {
      // Bildirim detayları (test için farklı kanal)
      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _testChannelId, // Testler için ayrı kanal
          _testChannelName,
          channelDescription: _testChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Bildirimi göster
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 100000, // Anlık, rastgele ID
        title,
        body,
        notificationDetails,
        payload: payload ?? 'test_payload',
      );
      debugPrint('Anlık test bildirimi gönderildi: "$title"');
    } catch (e) {
      debugPrint('Anlık test bildirimi gönderilirken hata: $e');
    }
  }

  /// Tüm planlanmış bildirimleri iptal eder.
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('Tüm planlanmış bildirimler iptal edildi.');
    } catch (e) {
      debugPrint('Bildirimler iptal edilirken hata: $e');
    }
  }

  /// Belirli bir ID'ye sahip planlanmış bildirimi iptal eder.
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('$id ID\'li bildirim iptal edildi.');
    } catch (e) {
      debugPrint('Bildirim ($id) iptal edilirken hata: $e');
    }
  }

  /// Bildirimlerin etkin olup olmadığını kontrol eder (izin bazlı).
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await init(); // Başlatılmadıysa başlat
    return await _checkAndRequestPermissions(); // İzin durumunu döndür
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
