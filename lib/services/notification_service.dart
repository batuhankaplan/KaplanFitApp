import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
// import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart' as fln_platform_interface; // Bu importu kaldırıyoruz veya yorumluyoruz, çünkü enum doğrudan ana paketten gelebilir

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

    try {
      // Timezone başlatma
      tz_data.initializeTimeZones();
      try {
        final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
        debugPrint("Saat dilimi ayarlandı: $currentTimeZone");
      } catch (e) {
        debugPrint("Yerel saat dilimi alınamadı: $e. UTC kullanılıyor.");
        tz.setLocalLocation(tz.getLocation('Etc/UTC'));
      }

      // Platform spesifik initialization
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

      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Android için kanalları oluştur
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      // İzinleri kontrol et ve ister
      final bool permissionsGranted = await _checkAndRequestPermissions();
      debugPrint("Bildirim izinleri durumu: $permissionsGranted");

      _initialized = true;
      debugPrint(
          '✅ Bildirim servisi başarıyla başlatıldı. Yerel Saat Dilimi: ${tz.local}');

      // Başlatma sonrası test bildirimi gönder
      await _sendInitializationTestNotification();
    } catch (e) {
      debugPrint('❌ Bildirim servisi başlatılırken hata: $e');
      throw Exception('Bildirim servisi başlatılamadı: $e');
    }
  }

  /// Başlatma sonrası test bildirimi (devre dışı)
  Future<void> _sendInitializationTestNotification() async {
    // Bu fonksiyon devre dışı bırakıldı - her uygulama açılışında bildirim göndermesin
    debugPrint('ℹ️ Başlatma test bildirimi devre dışı');
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 Bildirim tıklandı! Payload: ${response.payload}');
    // TODO: Payload'a göre uygulama içi yönlendirme
  }

  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      debugPrint('❌ Android plugin bulunamadı');
      return;
    }

    try {
      // Ana hatırlatma kanalı (Yüksek Öncelik)
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: false, // LED'i kapatıyoruz çünkü sorun çıkarıyor
          showBadge: true,
        ),
      );

      // Test bildirimleri kanalı (Normal Öncelik)
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _testChannelId,
          _testChannelName,
          description: _testChannelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );

      debugPrint('✅ Android bildirim kanalları başarıyla oluşturuldu');
    } catch (e) {
      debugPrint('❌ Android bildirim kanalları oluşturulurken hata: $e');
    }
  }

  /// Bildirim izinlerini kontrol eder ve ister
  Future<bool> _checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        bool allPermissionsGranted = true;

        debugPrint("Android SDK versiyon: ${androidInfo.version.sdkInt}");

        // Android 13+ (SDK 33+) için bildirim izni
        if (androidInfo.version.sdkInt >= 33) {
          var notificationStatus = await Permission.notification.status;
          debugPrint(
              "🔔 Android 13+ Bildirim İzin Durumu: $notificationStatus");

          if (notificationStatus.isDenied ||
              notificationStatus.isPermanentlyDenied) {
            if (notificationStatus.isPermanentlyDenied) {
              debugPrint(
                  "⚠️ Bildirim izni kalıcı olarak reddedilmiş. Ayarlar sayfasından açılması gerekiyor.");
              allPermissionsGranted = false;
            } else {
              notificationStatus = await Permission.notification.request();
              debugPrint("🔔 Bildirim İzin İsteği Sonucu: $notificationStatus");
              if (!notificationStatus.isGranted) {
                allPermissionsGranted = false;
              }
            }
          }
        }

        // Android 12+ (SDK 31+) için tam zamanlı alarm izni
        if (androidInfo.version.sdkInt >= 31) {
          var exactAlarmStatus = await Permission.scheduleExactAlarm.status;
          debugPrint(
              "⏰ Android 12+ Tam Zamanlı Alarm İzin Durumu: $exactAlarmStatus");

          if (exactAlarmStatus.isDenied) {
            exactAlarmStatus = await Permission.scheduleExactAlarm.request();
            debugPrint(
                "⏰ Tam Zamanlı Alarm İzin İsteği Sonucu: $exactAlarmStatus");
          }

          if (!exactAlarmStatus.isGranted) {
            debugPrint(
                "⚠️ Tam zamanlı alarm izni yok. Bildirimler gecikebilir.");
            debugPrint(
                "⚠️ Kullanıcının el ile sistem ayarlarından açması gerekebilir.");
          } else {
            debugPrint(
                "✅ Tam zamanlı alarm izni aktif - Bildiriler zamanında gelecek");
          }
        } else {
          debugPrint("ℹ️ Android 12 altı - Exact alarm izni gerekmiyor");
        }

        return allPermissionsGranted;
      } else if (Platform.isIOS) {
        // iOS izinleri
        final settings = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        debugPrint("🍎 iOS Bildirim İzin Durumu: $settings");
        return settings ?? false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ İzin kontrolü/isteme sırasında hata: $e');
      return false;
    }
  }

  /// Günlük bildirimleri planla
  Future<int> scheduleDailyNotifications() async {
    int count = 0;

    try {
      // Bildirim türleri ve saatleri
      final notifications = [
        // Antrenman Hatırlatmaları - Sabah 08:00
        {
          'id': 1,
          'hour': 8,
          'minute': 0,
          'title': '🏋️ Antrenman Zamanı!',
          'body': 'Sabah antrenmanın seni bekliyor! Hazır mısın?',
          'type': 'workout'
        },
        // Antrenman Hatırlatmaları - Akşam 20:00
        {
          'id': 11,
          'hour': 20,
          'minute': 0,
          'title': '🔥 Akşam Antrenmanı!',
          'body': 'Günün son antrenmanı! Enerji dolu bitir!',
          'type': 'workout_evening'
        },
        // Beslenme Hatırlatmaları - Öğle 12:00
        {
          'id': 2,
          'hour': 12,
          'minute': 0,
          'title': '🍽️ Öğle Yemeği Zamanı!',
          'body': 'Günün ortasında güzel bir mola ve sağlıklı beslenme!',
          'type': 'meal_lunch'
        },
        // Beslenme Hatırlatmaları - Akşam 18:00
        {
          'id': 12,
          'hour': 18,
          'minute': 0,
          'title': '🍽️ Akşam Yemeği Zamanı!',
          'body': 'Gününü sağlıklı ve lezzetli bir akşam yemeğiyle tamamla!',
          'type': 'meal_dinner'
        },
        // Su İçme Hatırlatmaları - Birden fazla saat
        {
          'id': 3,
          'hour': 10,
          'minute': 0,
          'title': '💧 Su İçme Zamanı!',
          'body': 'Hidratasyonunu koru! Su içmeyi unutma.',
          'type': 'water'
        },
        {
          'id': 13,
          'hour': 12,
          'minute': 0,
          'title': '💧 Su Hatırlatması!',
          'body': 'Öğle arası su molası! Vücudun teşekkür edecek.',
          'type': 'water'
        },
        {
          'id': 14,
          'hour': 14,
          'minute': 0,
          'title': '💧 Su İç!',
          'body': 'Öğleden sonra hidratasyonu! Su içmeyi unutma.',
          'type': 'water'
        },
        {
          'id': 15,
          'hour': 16,
          'minute': 0,
          'title': '💧 Su Zamanı!',
          'body': 'İkindi molası! Bir bardak su nasıl olur?',
          'type': 'water'
        },
        {
          'id': 16,
          'hour': 18,
          'minute': 0,
          'title': '💧 Su Hatırlatması!',
          'body': 'Akşam öncesi su molası! Hedefine yaklaş.',
          'type': 'water'
        },
        {
          'id': 17,
          'hour': 20,
          'minute': 0,
          'title': '💧 Su İç!',
          'body': 'Akşam saatleri! Su içmeyi unutma.',
          'type': 'water'
        },
        {
          'id': 18,
          'hour': 22,
          'minute': 0,
          'title': '💧 Gece Su Molası!',
          'body': 'Günü tamamlarken son bir su molası!',
          'type': 'water'
        },
        {
          'id': 19,
          'hour': 0,
          'minute': 0,
          'title': '💧 Gece Yarısı Su!',
          'body': 'Gece yarısı da hidratasyonu unutma!',
          'type': 'water'
        },
      ];

      // Her bildirim için planla
      for (final notification in notifications) {
        final scheduledDate = _getNextScheduledDate(
          notification['hour'] as int,
          notification['minute'] as int,
        );

        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notification['id'] as int,
          notification['title'] as String,
          notification['body'] as String,
          tz.TZDateTime.from(scheduledDate, tz.local),
          await _createNotificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );

        count++;
        debugPrint(
            '✅ Günlük bildirim planlandı: ID ${notification['id']} - Saat ${notification['hour']}:${notification['minute'].toString().padLeft(2, '0')} - Zaman: $scheduledDate');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Günlük bildirimler planlanırken hata: $e');
      debugPrint('Stack trace: $stackTrace');
    }

    return count;
  }

  /// Özel programlı bildirimler planla (antrenman ve beslenme içeriği ile)
  Future<int> scheduleContentBasedNotifications() async {
    int count = 0;

    try {
      // Bugünün haftanın hangi günü olduğunu bul
      final today = DateTime.now();
      final weekday = today.weekday; // 1=Pazartesi, 7=Pazar

      // Program servisinden günlük programı al
      // Not: Bu kısım ProgramService'e erişim gerektirir
      // Şimdilik basit bir yapı kullanıyoruz

      // Akşam antrenman bildirimi (20:00)
      final eveningWorkoutTime = _getNextScheduledDate(20, 0);
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        21, // Özel ID
        '🔥 Antreman Zamanı Geldi!',
        'Akşam antrenmanın seni bekliyor! Başlamaya hazır mısın?',
        tz.TZDateTime.from(eveningWorkoutTime, tz.local),
        await _createNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      count++;

      // Akşam yemeği bildirimi (18:00)
      final dinnerTime = _getNextScheduledDate(18, 0);
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        22, // Özel ID
        '🍽️ Akşam Yemeği Zamanı!',
        'Sağlıklı ve lezzetli akşam yemeğin hazır!',
        tz.TZDateTime.from(dinnerTime, tz.local),
        await _createNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      count++;

      debugPrint('✅ İçerik bazlı bildirimler planlandı: $count adet');
    } catch (e) {
      debugPrint('❌ İçerik bazlı bildirimler planlanırken hata: $e');
    }

    return count;
  }

  /// Su içme hatırlatmaları için kalan miktarı hesapla
  Future<String> _calculateRemainingWater() async {
    try {
      // Bu kısım WaterService'e erişim gerektirir
      // Şimdilik basit bir yapı kullanıyoruz
      const dailyGoal = 3000; // ml
      const consumedToday = 1500; // ml (örnek)
      final remaining = dailyGoal - consumedToday;

      if (remaining > 0) {
        return '${(remaining / 1000).toStringAsFixed(1)} litre daha su içmelisin!';
      } else {
        return 'Günlük su hedefini tamamladın! Tebrikler! 🎉';
      }
    } catch (e) {
      return 'Su içmeyi unutma! Vüçudun için önemli! 💧';
    }
  }

  /// Belirtilen saat için bir sonraki planlanacak tarihi hesapla
  DateTime _getNextScheduledDate(int hour, int minute) {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // Eğer geçmiş bir saat ise ertesi güne al
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Bildirim detaylarını oluştur
  Future<NotificationDetails> _createNotificationDetails() async {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        playSound: true,
        enableVibration: true,
        enableLights: false,
        showWhen: true,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  /// Günlük tekrarlayan bildirim planlar
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay timeOfDay,
    String? payload,
  }) async {
    if (!_initialized) await init();

    try {
      // Android için schedule mode belirleme
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
                "⚠️ Bildirim $id için tam zamanlı alarm izni yok, yaklaşık modda planlanacak");
          }
        }
      }

      // Planlama zamanını hesapla
      final tz.TZDateTime scheduledTime = _nextInstanceOfTime(timeOfDay);

      // Bildirim detayları
      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          when: scheduledTime.millisecondsSinceEpoch,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: const BigTextStyleInformation(''),
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
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
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      debugPrint(
          '✅ Günlük bildirim planlandı: ID $id - Saat ${timeOfDay.hour}:${timeOfDay.minute.toString().padLeft(2, '0')} - Zaman: $scheduledTime');
    } catch (e) {
      debugPrint('❌ Günlük bildirim (ID: $id) planlanırken hata: $e');
      throw Exception('Günlük bildirim planlanamadı: $e');
    }
  }

  /// Saatin bir sonraki tekrarını hesaplar
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Tek seferlik bildirim planlar
  Future<void> scheduleOneTimeNotification({
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    if (!_initialized) await init();

    try {
      final int notificationId = 20000 + Random().nextInt(10000);

      print('=== KAplanFit NOTIFICATION DEBUG ===');
      print('Bildirim planlama başlıyor...');
      print('ID: $notificationId');
      print('Başlık: $title');
      print('Zaman: $scheduledDateTime');
      print('===================================');

      // Eğer 1 dakikadan az ise hemen göster (test için)
      final now = DateTime.now();
      final difference = scheduledDateTime.difference(now);

      if (difference.inSeconds < 60) {
        print('=== 1 DAKİKADAN AZ - HEMEN GÖSTERİLİYOR ===');
        await sendNowTestNotification(
          title: '⚡ $title (Hemen)',
          body: '$body - Hemen gönderildi çünkü 1dk altı',
        );
        return;
      }

      final tz.TZDateTime scheduledTime =
          tz.TZDateTime.from(scheduledDateTime, tz.local);
      final tz.TZDateTime nowTz = tz.TZDateTime.now(tz.local);

      print('Timezone kontrolü:');
      print('   Hedef TZ: $scheduledTime');
      print('   Şimdi TZ: $nowTz');
      print('   Fark: ${difference.inMinutes} dakika');

      if (scheduledTime.isBefore(nowTz)) {
        print('❌ GEÇMİŞ ZAMAN HATASI');
        throw Exception('Geçmiş bir zaman için bildirim planlanamaz.');
      }

      // Basit schedule mode - exact alarm kontrolü yapmayalım
      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.exactAllowWhileIdle;

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        print('Android SDK: ${androidInfo.version.sdkInt}');

        // Android 12+ exact alarm kontrolü
        if (androidInfo.version.sdkInt >= 31) {
          final bool canScheduleExact = await _flutterLocalNotificationsPlugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.canScheduleExactNotifications() ??
              false;
          print('Exact Alarm İzni: $canScheduleExact');

          if (!canScheduleExact) {
            // Exact alarm izni yoksa inexact kullan
            scheduleMode = AndroidScheduleMode.inexact;
            print('⚠️ INEXACT MODE kullanılacak');
          }
        }
      }

      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          playSound: true,
          enableVibration: true,
          enableLights: false, // LED'i kapatıyoruz
          showWhen: true,
          when: scheduledTime.millisecondsSinceEpoch,
          visibility: NotificationVisibility.public,
          autoCancel: false,
          ongoing: false,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

      print('Zone schedule başlıyor...');
      print('Schedule Mode: $scheduleMode');

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload ?? 'custom_one_time_$notificationId',
      );

      print('✅ ZONEDSCHEDULE BAŞARILI!');
      print('   ID: $notificationId');
      print('   Başlık: "$title"');
      print('   Zaman: $scheduledTime');

      // Planlanmış bildirimleri kontrol et
      final pendingNotifications =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      print('   📊 PLANLANAN BİLDİRİM SAYISI: ${pendingNotifications.length}');

      // Planlanmış bildirimleri listele
      for (final pending in pendingNotifications) {
        print('   - ID: ${pending.id}, Başlık: ${pending.title}');
      }
    } catch (e) {
      debugPrint('❌ Tek seferlik bildirim planlanırken hata: $e');
      throw Exception('Tek seferlik bildirim planlanamadı: $e');
    }
  }

  /// Anında test bildirimi gönderir
  Future<void> sendNowTestNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    try {
      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _testChannelId,
          _testChannelName,
          channelDescription: _testChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'KaplanFit',
          ),
          ticker: title,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        notificationDetails,
        payload: payload ?? 'test_payload',
      );

      debugPrint('✅ Anlık test bildirimi başarıyla gönderildi: "$title"');
    } catch (e) {
      debugPrint('❌ Anlık test bildirimi gönderilirken hata: $e');
      throw Exception('Test bildirimi gönderilemedi: $e');
    }
  }

  /// Tüm bildirimleri iptal eder
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('✅ Tüm planlanmış bildirimler iptal edildi');
    } catch (e) {
      debugPrint('❌ Bildirimler iptal edilirken hata: $e');
    }
  }

  /// Belirli ID'li bildirimi iptal eder
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('✅ $id ID\'li bildirim iptal edildi');
    } catch (e) {
      debugPrint('❌ Bildirim ($id) iptal edilirken hata: $e');
    }
  }

  /// Bildirimlerin etkin olup olmadığını kontrol eder
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) {
      try {
        await init();
      } catch (e) {
        debugPrint('❌ Bildirim servisi başlatılamadı: $e');
        return false;
      }
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          final status = await Permission.notification.status;
          return status.isGranted;
        }
        return true; // Android 13 altında varsayılan true
      } else if (Platform.isIOS) {
        // iOS için plugin üzerinden kontrol
        return true; // iOS için basitleştirilmiş
      }
      return false;
    } catch (e) {
      debugPrint('❌ Bildirim durumu kontrol edilirken hata: $e');
      return false;
    }
  }

  /// Planlanmış bildirim zamanını getirir
  Future<String?> getScheduledNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('notification_time');
    } catch (e) {
      debugPrint('❌ Bildirim zamanı alınırken hata: $e');
      return null;
    }
  }

  /// Planlanmış bildirimleri listeler (Debug amaçlı)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Planlanmış bildirimler alınırken hata: $e');
      return [];
    }
  }
}
