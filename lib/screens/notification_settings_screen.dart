import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' show min;
import '../theme.dart';
import '../widgets/kaplan_appbar.dart';
import '../services/notification_service.dart';
// import 'package:awesome_notifications/awesome_notifications.dart'; // Kaldırıldı
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

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
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    _errorMessage = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _workoutReminderEnabled =
          prefs.getBool('workout_reminder_enabled') ?? true;
      _mealReminderEnabled = prefs.getBool('meal_reminder_enabled') ?? true;
      _waterReminderEnabled = prefs.getBool('water_reminder_enabled') ?? true;

      // Sistem seviyesinde izinleri de kontrol et (ilk yüklemede önemli)
      final bool systemEnabled =
          await NotificationService.instance.areNotificationsEnabled();
      if (!systemEnabled && _notificationsEnabled) {
        // Eğer ayarlarda açık ama sistemde kapalıysa, ayarı da kapat
        _notificationsEnabled = false;
        await _saveSettings(); // Durumu kaydet
      }
    } catch (e) {
      _errorMessage = "Ayarlar yüklenirken bir hata oluştu: $e";
      debugPrint(_errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('workout_reminder_enabled', _workoutReminderEnabled);
      await prefs.setBool('meal_reminder_enabled', _mealReminderEnabled);
      await prefs.setBool('water_reminder_enabled', _waterReminderEnabled);
    } catch (e) {
      debugPrint("Ayarlar kaydedilirken hata: $e");
      // Kullanıcıya hata gösterilebilir
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
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
                                    await _rescheduleNotifications();

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Bildirimler etkinleştirildi.'),
                                          duration: Duration(seconds: 3),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } else {
                                    // Bildirimleri devre dışı bırak (mevcut bildirimleri iptal et)
                                    await NotificationService.instance
                                        .cancelAllNotifications();

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Bildirimler devre dışı bırakıldı.'),
                                          duration: Duration(seconds: 3),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    }
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
                                    _rescheduleNotifications();
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
                                    _rescheduleNotifications();
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
                                    _rescheduleNotifications();
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
                                    _rescheduleNotifications();
                                  },
                                ),
                                _buildNotificationSwitch(
                                  'Titreşim',
                                  _vibrationEnabled,
                                  (value) {
                                    setState(() {
                                      _vibrationEnabled = value;
                                    });
                                    _rescheduleNotifications();
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

                                // Yeni "Özel Bildirim Ekle" Butonu
                                const SizedBox(height: 24),
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _showCustomNotificationDialog,
                                    icon: const Icon(Icons.add_alarm,
                                        color: Colors.white),
                                    label: const Text('Özel Bildirim Ekle',
                                        style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme
                                          .accentColor, // Farklı bir renk
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30, vertical: 15),
                                      textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
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
            color: Colors.black.withValues(alpha: 0.05),
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
            color: Colors.black.withValues(alpha: 0.05),
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

  // Planlı bildirimleri SharedPreferences'daki ayarlara göre yeniden planla
  Future<void> _rescheduleNotifications() async {
    if (!_notificationsEnabled) {
      // Genel bildirimler kapalıysa tümünü iptal et
      await NotificationService.instance.cancelAllNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tüm bildirimler devre dışı bırakıldı.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    int plannedCount = 0;
    try {
      // Önce mevcutları temizle
      await NotificationService.instance.cancelAllNotifications();

      // Workout Reminder (ID 1001, 08:00)
      if (_workoutReminderEnabled) {
        await NotificationService.instance.scheduleDailyNotification(
            id: 1001,
            title: 'Antrenman Zamanı',
            body: 'Bugünkü antrenmanını unutma!',
            timeOfDay: const TimeOfDay(hour: 8, minute: 0),
            payload: 'workout');
        plannedCount++;
      }

      // Meal Reminder (ID 1002, 12:00)
      if (_mealReminderEnabled) {
        await NotificationService.instance.scheduleDailyNotification(
            id: 1002,
            title: 'Beslenme Vakti',
            body: 'Öğle yemeği zamanı yaklaşıyor!',
            timeOfDay: const TimeOfDay(hour: 12, minute: 0),
            payload: 'meal');
        plannedCount++;
      }

      // Water Reminders (ID 1003-1005, 10:00, 13:00, 16:00)
      if (_waterReminderEnabled) {
        await NotificationService.instance.scheduleDailyNotification(
            id: 1003,
            title: 'Su İç',
            body: 'Vücudunu susuz bırakma!',
            timeOfDay: const TimeOfDay(hour: 10, minute: 0),
            payload: 'water10');
        await NotificationService.instance.scheduleDailyNotification(
            id: 1004,
            title: 'Su İç',
            body: 'Bir bardak daha su?',
            timeOfDay: const TimeOfDay(hour: 13, minute: 0),
            payload: 'water13');
        await NotificationService.instance.scheduleDailyNotification(
            id: 1005,
            title: 'Su İç',
            body: 'Günün son su hatırlatması!',
            timeOfDay: const TimeOfDay(hour: 16, minute: 0),
            payload: 'water16');
        plannedCount += 3;
      }

      if (plannedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$plannedCount adet günlük bildirim planlandı.'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Aktif günlük bildirim ayarı yok.'),
              backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      _errorMessage = "Bildirimler planlanırken hata: $e";
      debugPrint(_errorMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Bildirimler planlanamadı: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- YENİ: Tek Seferlik Bildirim Planlama Fonksiyonu ---
  Future<void> _scheduleOneTimeNotification(
      String title, String body, DateTime dateTime) async {
    // Parametre DateTime oldu
    setState(() => _isLoading = true);
    try {
      // --- Anlık test kodu kaldırıldı, orijinal zamanlama kodu geri getirildi ---
      await NotificationService.instance.scheduleOneTimeNotification(
        title: title,
        body: body,
        scheduledDateTime: dateTime, // DateTime olarak gönderiliyor
      );

      final formattedTime = TimeOfDay.fromDateTime(dateTime).format(context);
      final formattedDate =
          "${dateTime.day}/${dateTime.month}/${dateTime.year}";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '"$title" bildirimi $formattedDate $formattedTime için planlandı.'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      _errorMessage = "Özel bildirim planlanırken hata: $e";
      debugPrint(_errorMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Özel bildirim planlanamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Özel bildirim ekleme dialogu
  void _showCustomNotificationDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    DateTime? selectedDate; // Başlangıçta null
    TimeOfDay? selectedTime; // Başlangıçta null

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Özel Bildirim Planla'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Başlık',
                        hintText: 'Ne hatırlatmamı istersin?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama (İsteğe Bağlı)',
                        hintText: 'Ek detaylar...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        selectedDate == null // Null kontrolü
                            ? 'Tarih Seç' // Seçilmediyse uyarı
                            : 'Tarih: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ??
                              DateTime
                                  .now(), // Seçiliyse onu, değilse bugünü göster
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time_filled),
                      title: Text(
                        selectedTime == null
                            ? 'Saat Seç'
                            : 'Saat: ${selectedTime!.format(context)}',
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: (selectedDate == null ||
                          selectedTime == null ||
                          titleController.text.isEmpty)
                      ? null // Saat VEYA Tarih VEYA Başlık boşsa pasif
                      : () {
                          // Seçilen tarih ve saati birleştir
                          final DateTime finalDateTime = DateTime(
                            selectedDate!.year, // Null olamaz (buton aktifse)
                            selectedDate!.month,
                            selectedDate!.day,
                            selectedTime!.hour, // Null olamaz (buton aktifse)
                            selectedTime!.minute,
                          );

                          Navigator.of(context).pop(); // Dialog'u kapat
                          _scheduleOneTimeNotification(
                            titleController.text,
                            bodyController.text.isEmpty
                                ? "Hatırlatma"
                                : bodyController.text,
                            finalDateTime,
                          );
                        },
                  child: const Text('Planla'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
