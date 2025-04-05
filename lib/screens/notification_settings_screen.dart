import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _lightEnabled = true;
  bool _exerciseReminderEnabled = true;
  bool _mealReminderEnabled = true;
  bool _waterReminderEnabled = true;
  bool _goalReminderEnabled = true;
  
  bool _isLoading = true;
  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _notificationService.initialize(); // Bildirimleri başlat
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    _notificationsEnabled = await _notificationService.areNotificationsEnabled();
    _soundEnabled = await _notificationService.isSoundEnabled();
    _vibrationEnabled = await _notificationService.isVibrationEnabled();
    _lightEnabled = await _notificationService.isLightEnabled();
    _exerciseReminderEnabled = await _notificationService.isWorkoutReminderEnabled();
    _mealReminderEnabled = await _notificationService.isMealReminderEnabled();
    _waterReminderEnabled = await _notificationService.isWaterReminderEnabled();
    _goalReminderEnabled = await _notificationService.isGoalReminderEnabled();

    setState(() {
      _isLoading = false;
    });
  }

  // Bildirim izinlerini kontrol et
  Future<void> _checkNotificationPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      // İzinleri kontrol et
      await _notificationService.initialize();
      
      // Bildirimler etkinleştirilmiş mi kontrol et
      setState(() {
        _notificationsEnabled = true;
        _isCheckingPermissions = false;
      });
    } catch (e) {
      setState(() {
        _notificationsEnabled = false;
        _isCheckingPermissions = false;
      });
      
      print('Bildirim izinleri kontrol edilirken hata: $e');
    }
  }

  // Değişkenleri tanımla
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _soundEnabledKey = 'notifications_sound_enabled';
  static const String _vibrationEnabledKey = 'notifications_vibration_enabled';
  static const String _lightEnabledKey = 'notifications_light_enabled';
  static const String _exerciseReminderEnabledKey = 'exercise_reminder_enabled';
  static const String _mealReminderEnabledKey = 'meal_reminder_enabled';
  static const String _waterReminderEnabledKey = 'water_reminder_enabled';
  static const String _goalReminderEnabledKey = 'goal_reminder_enabled';
  
  // Ayarları kaydet
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
    await prefs.setBool(_soundEnabledKey, _soundEnabled);
    await prefs.setBool(_vibrationEnabledKey, _vibrationEnabled);
    await prefs.setBool(_lightEnabledKey, _lightEnabled);
    await prefs.setBool(_exerciseReminderEnabledKey, _exerciseReminderEnabled);
    await prefs.setBool(_mealReminderEnabledKey, _mealReminderEnabled);
    await prefs.setBool(_waterReminderEnabledKey, _waterReminderEnabled);
    await prefs.setBool(_goalReminderEnabledKey, _goalReminderEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ana bildirim ayarı
                  _buildMainNotificationSwitch(),
                  
                  const SizedBox(height: 20),
                  
                  // Bildirim türleri bölümü
                  _notificationsEnabled
                      ? _buildNotificationTypesSection()
                      : _buildNotificationsDisabledMessage(),
                  
                  const SizedBox(height: 20),
                  
                  // Test bildirimi butonu
                  if (_notificationsEnabled)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _notificationsEnabled ? _sendTestNotification : null,
                        child: _isLoading 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Text('Test Bildirimi Gönder'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                    
                  // Haftalık bildirimleri ayarlama butonu
                  if (_notificationsEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.schedule),
                        label: const Text('Haftalık Bildirimleri Ayarla'),
                        onPressed: _notificationsEnabled ? _setupWeeklyNotifications : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                    
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildMainNotificationSwitch() {
    return SwitchListTile(
      title: const Text('Bildirimlere İzin Ver'),
      subtitle: const Text('Tüm bildirimleri aç veya kapat'),
      value: _notificationsEnabled,
      onChanged: (bool value) async {
        setState(() {
          _notificationsEnabled = value;
        });
        
        // SharedPreferences'e kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_notificationsEnabledKey, value);
        
        // Diğer ayarları güncelle
        await _saveSettings();
      },
    );
  }

  Widget _buildNotificationTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Bildirim Görünümü'),
        
        SwitchListTile(
          title: const Text('Ses'),
          subtitle: const Text('Bildirim geldiğinde ses çal'),
          value: _soundEnabled,
          onChanged: _notificationsEnabled 
              ? (value) async {
                  await _notificationService.setSoundEnabled(value);
                  setState(() {
                    _soundEnabled = value;
                  });
                }
              : null,
        ),
        
        SwitchListTile(
          title: const Text('Titreşim'),
          subtitle: const Text('Bildirim geldiğinde titreşim olsun'),
          value: _vibrationEnabled,
          onChanged: _notificationsEnabled 
              ? (value) async {
                  await _notificationService.setVibrationEnabled(value);
                  setState(() {
                    _vibrationEnabled = value;
                  });
                }
              : null,
        ),
        
        SwitchListTile(
          title: const Text('Bildirim Işığı'),
          subtitle: const Text('Bildirim geldiğinde cihaz ışığı yansın'),
          value: _lightEnabled,
          onChanged: _notificationsEnabled 
              ? (value) async {
                  await _notificationService.setLightEnabled(value);
                  setState(() {
                    _lightEnabled = value;
                  });
                }
              : null,
        ),
        
        const Divider(),
        
        _buildSectionHeader('Bildirim Türleri'),
        
        SwitchListTile(
          title: const Text('Egzersiz Hatırlatmaları'),
          subtitle: const Text('Egzersiz zamanınızı bildirir'),
          value: _exerciseReminderEnabled,
          onChanged: _notificationsEnabled 
              ? (value) async {
                  await _notificationService.setWorkoutReminderEnabled(value);
                  setState(() {
                    _exerciseReminderEnabled = value;
                  });
                }
              : null,
        ),
        
        SwitchListTile(
          title: const Text('Öğün Hatırlatmaları'),
          subtitle: const Text('Öğün zamanınızı bildirir'),
          value: _mealReminderEnabled,
          onChanged: _notificationsEnabled 
              ? (value) async {
                  await _notificationService.setMealReminderEnabled(value);
                  setState(() {
                    _mealReminderEnabled = value;
                  });
                }
              : null,
        ),
        
        SwitchListTile(
          title: const Text('Su İçme Hatırlatmaları'),
          subtitle: const Text('Düzenli su içmenizi hatırlatır'),
          value: _waterReminderEnabled,
          onChanged: _notificationsEnabled 
              ? (value) async {
                  await _notificationService.setWaterReminderEnabled(value);
                  setState(() {
                    _waterReminderEnabled = value;
                  });
                }
              : null,
        ),
        
        SwitchListTile(
          title: const Text('Hedef Hatırlatmaları'),
          subtitle: const Text('Günlük hedeflerinizi hatırlatır'),
          value: _goalReminderEnabled,
          onChanged: _notificationsEnabled 
              ? (value) async {
                  await _notificationService.setGoalReminderEnabled(value);
                  setState(() {
                    _goalReminderEnabled = value;
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildNotificationsDisabledMessage() {
    return const Text(
      'Bildirimler devre dışı bırakıldı. Lütfen bildirimleri açınız.',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  // Test bildirimi gönderme
  Future<void> _sendTestNotification() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _notificationService.sendTestNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test bildirimi gönderildi! Bildirim paneline bakın.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Hata mesajını düzenle ve daha açıklayıcı hale getir
      String errorMessage = 'Bildirim gönderilirken hata oluştu';
      
      if (e.toString().contains('invalid_icon') || e.toString().contains('app_icon')) {
        errorMessage = 'Bildirim simgesi hatası: Android projesinde simge dosyası eksik. Geliştirici hatası olabilir.';
      } else {
        errorMessage = 'Bildirim gönderilirken hata oluştu: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
      print('Test bildirim hatası: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Haftalık bildirimleri ayarlama
  Future<void> _setupWeeklyNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Haftalık bildirimleri ayarla
      await _notificationService.setupWeeklyNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Haftalık bildirimler başarıyla ayarlandı!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bildirimler ayarlanırken hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
      print('Haftalık bildirim ayarlama hatası: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 