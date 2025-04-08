import 'package:flutter/material.dart';
import 'dart:math' show min;
import '../theme.dart';
import '../widgets/kaplan_appbar.dart';
import '../services/notification_service.dart';
// import 'package:awesome_notifications/awesome_notifications.dart'; // Kaldırıldı
import 'package:provider/provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
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
      final enabled =
          await NotificationService.instance.areNotificationsEnabled();
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
      appBar: AppBar(
        title: Text('Bildirimler'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : const Color(0xFFF8F8FC),
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
                        // Header ekleme
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Text(
                            'Bildirim Ayarları',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
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

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Bildirimler etkinleştirildi.'),
                                        duration: Duration(seconds: 3),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    // Bildirimleri devre dışı bırak (mevcut bildirimleri iptal et)
                                    await NotificationService.instance
                                        .cancelAllNotifications();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Bildirimler devre dışı bırakıldı.'),
                                        duration: Duration(seconds: 3),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  }
                                  setState(() {
                                    _notificationsEnabled = value;
                                  });
                                },
                              ),

                              // Bildirim türleri
                              if (_notificationsEnabled) ...[
                                const SizedBox(height: 16),
                                _buildSectionTitle(
                                    'Bildirim Türleri ve Saatleri'),

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
                                  color: isDarkMode
                                      ? AppTheme.darkCardBackgroundColor
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.info_outline,
                                                color: AppTheme.primaryColor),
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

                        // Bildirim test düğmesini oluştur
                        _buildTestNotificationsCard(isDarkMode),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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

          // Kullanıcı tarafından istenen özel bildirimler kaldırıldı
          // 22:55 - Yemek bildirimi
          // 22:58 - Su bildirimi
          // 23:02 - Hareket bildirimi
          // 23:54 - Test bildirimi
          // 0:01 - Ek test bildirimi (23:59'dan hemen sonra)
          // 0:03 - Ek test bildirimi
          // 0:05 - Ek test bildirimi
          // 00:20 - Yeni Test
          // 00:22 - Yeni Test
          // 00:24 - Yeni Test
          // 00:26 - Yeni Test
        } catch (e) {
          String errorMsg = e.toString();
          if (errorMsg.contains('exact_alarms_not_permitted')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Bildirimler kaydedildi ancak tam zamanlı bildirimler için izin gerekmektedir. Ayarlar > Uygulamalar > KaplanFit > Bildirimler > Tam zamanlı bildirimlere izin ver'),
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
                content: Text(
                    'Hata: ${_errorMessage?.substring(0, min(100, _errorMessage?.length ?? 0))}...'),
                duration: const Duration(seconds: 5),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
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
            content: Text(
                'Test bildirimi gönderildi. Bildirim panelinizi kontrol edin.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        String errorMsg = e.toString();
        if (errorMsg.contains('exact_alarms_not_permitted')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Bildirim gönderildi ancak tam zamanlı bildirimler için izin gerekmektedir. Ayarlar > Uygulamalar > KaplanFit > Bildirimler > Tam zamanlı bildirimlere izin ver'),
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

  // Bildirim test düğmesini oluştur
  Widget _buildTestNotificationsCard(bool isDarkMode) {
    return Card(
      color: isDarkMode ? AppTheme.darkCardBackgroundColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Planlı Bildirimlerin Zamanları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aşağıdaki bildirimlerin tümü otomatik olarak planlanmıştır. Uygulama kapalı olsa bile bildirimleri alacaksınız.',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            _buildNotificationTimeInfo(
                'Antrenman Hatırlatması', '08:00', isDarkMode),
            _buildNotificationTimeInfo(
                'Günlük Hatırlatma', '09:00', isDarkMode),
            _buildNotificationTimeInfo(
                'Su İçme Hatırlatmaları', '10:00, 13:00, 16:00', isDarkMode),
            _buildNotificationTimeInfo(
                'Beslenme Hatırlatması', '12:00', isDarkMode),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _showAddNotificationDialog();
              },
              icon: Icon(Icons.add, color: Colors.white),
              label: Text(
                'Yeni Bildirim Ekle',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bildirim zamanı bilgisi widget'ı
  Widget _buildNotificationTimeInfo(
      String title, String time, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Yeni bildirim ekleme dialog'u
  void _showAddNotificationDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController bodyController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Yeni Bildirim Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Bildirim Başlığı',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: bodyController,
                  decoration: InputDecoration(
                    labelText: 'Bildirim İçeriği',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                ListTile(
                  title:
                      Text('Bildirim Saati: ${selectedTime.format(context)}'),
                  trailing: Icon(Icons.access_time),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      selectedTime = picked;
                      Navigator.of(context).pop();
                      _showAddNotificationDialog();
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    bodyController.text.isNotEmpty) {
                  // Yeni bir ID oluştur
                  final int newId =
                      3000 + DateTime.now().millisecondsSinceEpoch % 1000;

                  await NotificationService.instance.scheduleDailyNotification(
                    id: newId,
                    title: titleController.text,
                    body: bodyController.text,
                    timeOfDay: selectedTime,
                  );

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Yeni bildirim eklendi: ${selectedTime.format(context)}'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Ayarları yeniden yükle
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Başlık ve içerik boş olamaz!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Ekle'),
            ),
          ],
        );
      },
    );
  }
}
