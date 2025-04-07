import 'package:flutter/material.dart';
import 'dart:math' show min;
import '../theme.dart';
import '../widgets/kaplan_appbar.dart';
import '../services/notification_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:provider/provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _workoutReminderEnabled = true;
  bool _mealReminderEnabled = true;
  bool _waterReminderEnabled = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);
      
      // Bildirimlerin etkin olup olmadığını kontrol et
      final enabled = await NotificationService.instance.areNotificationsEnabled();
      setState(() {
        _notificationsEnabled = enabled;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ayarlar yüklenirken hata oluştu: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: KaplanAppBar(
        title: 'Bildirim Ayarları',
        isDarkMode: isDarkMode,
      ),
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : const Color(0xFFF8F8FC),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadSettings,
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bildirimler Header'ı
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: isDarkMode ? AppTheme.darkCardBackgroundColor : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48, 
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.notifications,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Bildirimler',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ana bildirim ayarı
                              _buildSectionTitle('Genel Bildirim Ayarları'),
                              _buildNotificationSwitch(
                                'Tüm Bildirimler',
                                _notificationsEnabled,
                                (value) async {
                                  if (value) {
                                    // Bildirimleri etkinleştirmek için izinleri kontrol et
                                    await NotificationService.instance.init();
                                    // Bildirimleri otomatik olarak planla
                                    await _scheduleNotifications();
                                  } else {
                                    // Bildirimleri devre dışı bırak (mevcut bildirimleri iptal et)
                                    await NotificationService.instance.cancelAllNotifications();
                                  }
                                  setState(() {
                                    _notificationsEnabled = value;
                                  });
                                },
                              ),
                              
                              // Bildirim türleri
                              if (_notificationsEnabled) ...[
                                const SizedBox(height: 16),
                                _buildSectionTitle('Bildirim Türleri ve Saatleri'),
                                
                                // Sabah antrenman hatırlatması - 08:00
                                _buildNotificationSwitchWithTime(
                                  'Antrenman Hatırlatmaları',
                                  _workoutReminderEnabled,
                                  "08:00",
                                  (value) {
                                    setState(() {
                                      _workoutReminderEnabled = value;
                                    });
                                    _scheduleNotifications();
                                  },
                                ),
                                
                                // Öğle yemeği hatırlatması - 12:00
                                _buildNotificationSwitchWithTime(
                                  'Beslenme Hatırlatmaları',
                                  _mealReminderEnabled,
                                  "12:00",
                                  (value) {
                                    setState(() {
                                      _mealReminderEnabled = value;
                                    });
                                    _scheduleNotifications();
                                  },
                                ),
                                
                                // Su içme hatırlatması - 10:00, 13:00, 16:00
                                _buildNotificationSwitchWithTime(
                                  'Su İçme Hatırlatmaları',
                                  _waterReminderEnabled,
                                  "10:00, 13:00, 16:00",
                                  (value) {
                                    setState(() {
                                      _waterReminderEnabled = value;
                                    });
                                    _scheduleNotifications();
                                  },
                                ),
                                
                                // Bildirim seçenekleri
                                const SizedBox(height: 16),
                                _buildSectionTitle('Bildirim Seçenekleri'),
                                _buildNotificationSwitch(
                                  'Ses',
                                  _soundEnabled,
                                  (value) {
                                    setState(() {
                                      _soundEnabled = value;
                                    });
                                    _scheduleNotifications();
                                  },
                                ),
                                _buildNotificationSwitch(
                                  'Titreşim',
                                  _vibrationEnabled,
                                  (value) {
                                    setState(() {
                                      _vibrationEnabled = value;
                                    });
                                    _scheduleNotifications();
                                  },
                                ),
                                
                                // Bildirim bilgisi
                                const SizedBox(height: 16),
                                Card(
                                  color: isDarkMode ? AppTheme.darkCardBackgroundColor : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.info_outline, color: AppTheme.primaryColor),
                                            SizedBox(width: 8),
                                            Text(
                                              'Bildirim Saatleri',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Bildirimlerin günün belirli saatlerinde gönderilmesi için ayarlanmıştır. Her bildirim türü kendine özgü saatinde gönderilecektir.',
                                          style: TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Test bildirimi gönder
                                const SizedBox(height: 20),
                                Center(
                                  child: _buildSecondaryButton(
                                    'Test Bildirimi Gönder',
                                    () => _sendTestNotification(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildNotificationSwitch(
      String title, bool value, void Function(bool) onChanged) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? const Color(0xFF243355) // Koyu tema için
            : Colors.white, // Açık tema için
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accentColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  Widget _buildNotificationSwitchWithTime(
      String title, bool value, String time, void Function(bool) onChanged) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? const Color(0xFF243355) // Koyu tema için
            : Colors.white, // Açık tema için
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Saat: $time',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accentColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        minimumSize: const Size(200, 45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: AppTheme.primaryColor),
        ),
        elevation: 2,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  // Bildirimleri ayarla ve planla
  Future<void> _scheduleNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      if (_notificationsEnabled) {
        // Önce mevcut bildirimleri temizle
        await NotificationService.instance.cancelAllNotifications();
        
        try {
          // Sabit saatlerde bildirimleri planla
          
          // Antrenman hatırlatması - Sabah 8:00
          if (_workoutReminderEnabled) {
            await NotificationService.instance.scheduleDailyNotification(
              id: 1001,
              title: 'Antrenman Zamanı',
              body: 'Bugünkü antrenmanınızı tamamlamayı unutmayın!',
              timeOfDay: TimeOfDay(hour: 8, minute: 0),
            );
          }
          
          // Beslenme hatırlatması - Öğle 12:00
          if (_mealReminderEnabled) {
            await NotificationService.instance.scheduleDailyNotification(
              id: 1002,
              title: 'Beslenme Hatırlatması',
              body: 'Sağlıklı beslenmeyi unutmayın!',
              timeOfDay: TimeOfDay(hour: 12, minute: 0),
            );
          }
          
          // Su hatırlatmaları - 10:00, 13:00, 16:00
          if (_waterReminderEnabled) {
            await NotificationService.instance.scheduleDailyNotification(
              id: 1003,
              title: 'Su İçme Vakti',
              body: 'Sağlığınız için su içmeyi unutmayın!',
              timeOfDay: TimeOfDay(hour: 10, minute: 0),
            );
            
            await NotificationService.instance.scheduleDailyNotification(
              id: 1004,
              title: 'Su İçme Vakti',
              body: 'Sağlığınız için su içmeyi unutmayın!',
              timeOfDay: TimeOfDay(hour: 13, minute: 0),
            );
            
            await NotificationService.instance.scheduleDailyNotification(
              id: 1005,
              title: 'Su İçme Vakti',
              body: 'Sağlığınız için su içmeyi unutmayın!',
              timeOfDay: TimeOfDay(hour: 16, minute: 0),
            );
          }
          
          // Genel günlük hatırlatma - Sabah 9:00
          await NotificationService.instance.scheduleDailyNotification(
            id: 1006,
            title: 'Günlük Hatırlatma',
            body: 'Bugünkü hedefleriniz için KaplanFit yanınızda!',
            timeOfDay: TimeOfDay(hour: 9, minute: 0),
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bildirim ayarları kaydedildi ve bildirimler planlandı.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          String errorMsg = e.toString();
          if (errorMsg.contains('exact_alarms_not_permitted')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bildirimler kaydedildi ancak tam zamanlı bildirimler için izin gerekmektedir. Ayarlar > Uygulamalar > KaplanFit > Bildirimler > Tam zamanlı bildirimlere izin ver'),
                duration: Duration(seconds: 5),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            // Diğer hatalar için orijinal hata mesajını göster
            setState(() {
              _errorMessage = 'Bildirimler ayarlanırken hata oluştu: $e';
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hata: ${_errorMessage?.substring(0, min(100, _errorMessage?.length ?? 0))}...'),
                duration: const Duration(seconds: 5),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirimler devre dışı bırakıldı.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bildirimler ayarlanırken hata oluştu: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $_errorMessage'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Test bildirimi gönder
  Future<void> _sendTestNotification() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        await NotificationService.instance.sendTestNotification();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test bildirimi gönderildi. Bildirim panelinizi kontrol edin.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        String errorMsg = e.toString();
        if (errorMsg.contains('exact_alarms_not_permitted')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bildirim gönderildi ancak tam zamanlı bildirimler için izin gerekmektedir. Ayarlar > Uygulamalar > KaplanFit > Bildirimler > Tam zamanlı bildirimlere izin ver'),
              duration: Duration(seconds: 5),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Test bildirimi gönderilirken hata: $e';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $_errorMessage'),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Test bildirimi gönderilirken hata: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $_errorMessage'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 