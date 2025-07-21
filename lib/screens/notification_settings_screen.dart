import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/kaplan_appbar.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with AutomaticKeepAliveClientMixin<NotificationSettingsScreen> {
  @override
  bool get wantKeepAlive => true;

  bool _notificationsEnabled = false;
  bool _permissionsGranted = false;
  bool _workoutReminderEnabled = false;
  bool _mealReminderEnabled = false;
  bool _waterReminderEnabled = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoading = false;
  String? _errorMessage;
  int _pendingNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Bildirim izinlerini kontrol et
      await NotificationService.instance.init();
      final permissions =
          await NotificationService.instance.areNotificationsEnabled();

      // Ayarları yükle
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
        _permissionsGranted = permissions;
        _workoutReminderEnabled =
            prefs.getBool('workout_reminder_enabled') ?? false;
        _mealReminderEnabled = prefs.getBool('meal_reminder_enabled') ?? false;
        _waterReminderEnabled = prefs.getBool('water_reminder_enabled') ?? false;
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      });

      // Planlanmış bildirim sayısını al
      final pending =
          await NotificationService.instance.getPendingNotifications();
      setState(() => _pendingNotificationsCount = pending.length);

      debugPrint(
          '✅ Bildirim ayarları yüklendi - İzinler: $_permissionsGranted, Aktif: $_notificationsEnabled, Planlanmış: $_pendingNotificationsCount');

      // Eğer izinler varsa ve ayarlar aktifse bildirimleri planla
      if (_permissionsGranted && _notificationsEnabled) {
        await _rescheduleNotifications();
      }
    } catch (e) {
      debugPrint('❌ Bildirim ayarları yüklenirken hata: $e');
      setState(() {
        _errorMessage = 'Ayarlar yüklenemedi: $e';
      });
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
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
      debugPrint('✅ Bildirim ayarları kaydedildi');
    } catch (e) {
      debugPrint('❌ Bildirim ayarları kaydedilirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey.shade50,
      appBar: KaplanAppBar(
        title: 'Bildirim Ayarları',
        isDarkMode: isDarkMode,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettings,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Bildirim ayarları yükleniyor...'),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadSettings,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tekrar Dene'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // İzin uyarısı (gerekirse)
                        if (!_permissionsGranted) _buildPermissionWarning(),

                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Genel bildirim toggle
                              _buildSectionTitle('Genel Bildirim Ayarları'),
                              _buildMainNotificationToggle(),

                              // Bildirim türleri
                              if (_notificationsEnabled &&
                                  _permissionsGranted) ...[
                                const SizedBox(height: 24),
                                _buildSectionTitle(
                                    'Bildirim Türleri ve Saatleri'),

                                _buildNotificationSwitchWithTime(
                                  'Antrenman Hatırlatmaları',
                                  _workoutReminderEnabled,
                                  "08:00, 20:00",
                                  Icons.fitness_center,
                                  (value) {
                                    setState(() {
                                      _workoutReminderEnabled = value;
                                    });
                                    _saveSettings();
                                    _rescheduleNotifications();
                                  },
                                ),

                                _buildNotificationSwitchWithTime(
                                  'Beslenme Hatırlatmaları',
                                  _mealReminderEnabled,
                                  "12:00, 18:00",
                                  Icons.restaurant,
                                  (value) {
                                    setState(() {
                                      _mealReminderEnabled = value;
                                    });
                                    _saveSettings();
                                    _rescheduleNotifications();
                                  },
                                ),

                                _buildNotificationSwitchWithTime(
                                  'Su İçme Hatırlatmaları',
                                  _waterReminderEnabled,
                                  "11:00, 15:00, 19:00, 22:00",
                                  Icons.water_drop,
                                  (value) {
                                    setState(() {
                                      _waterReminderEnabled = value;
                                    });
                                    _saveSettings();
                                    _rescheduleNotifications();
                                  },
                                ),

                                // Bildirim seçenekleri
                                const SizedBox(height: 24),
                                _buildSectionTitle('Bildirim Seçenekleri'),

                                _buildNotificationSwitch(
                                  'Ses',
                                  _soundEnabled,
                                  Icons.volume_up,
                                  (value) {
                                    setState(() {
                                      _soundEnabled = value;
                                    });
                                    _saveSettings();
                                    _rescheduleNotifications();
                                  },
                                ),

                                _buildNotificationSwitch(
                                  'Titreşim',
                                  _vibrationEnabled,
                                  Icons.vibration,
                                  (value) {
                                    setState(() {
                                      _vibrationEnabled = value;
                                    });
                                    _saveSettings();
                                    _rescheduleNotifications();
                                  },
                                ),

                                // Özel bildirim ekleme
                                const SizedBox(height: 24),
                                _buildCustomNotificationSection(),
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

  Widget _buildMainNotificationToggle() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF243355) : Colors.white,
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
        title: Row(
          children: [
            Icon(Icons.notifications, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Tüm Bildirimler',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        subtitle: Text(
          _permissionsGranted
              ? 'Planlanmış: $_pendingNotificationsCount bildirim'
              : 'İzin gerekli',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
        value: _notificationsEnabled && _permissionsGranted,
        onChanged: _toggleMainNotifications,
        activeColor: AppTheme.accentColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPermissionWarning() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF243355) : Colors.orange.shade50,
        border: Border.all(
            color:
                isDarkMode ? Colors.orange.shade400 : Colors.orange.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber,
                  color: isDarkMode
                      ? Colors.orange.shade300
                      : Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Bildirim İzni Gerekli',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.orange.shade300
                      : Colors.orange.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bildirimlerin çalışması için sistem ayarlarından bildirim izni verilmelidir.',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.orange.shade700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _checkPermissions,
            icon: const Icon(Icons.settings),
            label: const Text('İzinleri Kontrol Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNotificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_alarm, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'Özel Bildirim',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Kendinize özel bir hatırlatma oluşturun.',
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showCustomNotificationDialog,
                icon: const Icon(Icons.add),
                label: const Text('Özel Bildirim Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch(
      String title, bool value, IconData icon, void Function(bool) onChanged) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF243355) : Colors.white,
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
        title: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accentColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildNotificationSwitchWithTime(String title, bool value, String time,
      IconData icon, void Function(bool) onChanged) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF243355) : Colors.white,
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
        title: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Ana bildirim toggle işlevi
  Future<void> _toggleMainNotifications(bool value) async {
    setState(() => _isLoading = true);

    try {
      if (value) {
        // Bildirimleri etkinleştir
        await NotificationService.instance.init();
        
        // İzin iste - bu kullanıcı isteği olduğu için dialog göster
        final permissions = await NotificationService.instance.requestPermissions();

        if (permissions) {
          setState(() {
            _notificationsEnabled = true;
            _permissionsGranted = true;
          });
          await _saveSettings();
          await _rescheduleNotifications();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Bildirimler başarıyla etkinleştirildi!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _notificationsEnabled = false;
            _permissionsGranted = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '⚠️ Bildirim izni verilmedi. Sistem ayarlarını kontrol edin.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Bildirimleri devre dışı bırak
        await NotificationService.instance.cancelAllNotifications();
        setState(() {
          _notificationsEnabled = false;
        });
        await _saveSettings();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔕 Tüm bildirimler devre dışı bırakıldı'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Ana bildirim toggle hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // İzinleri kontrol et ve iste
  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    try {
      await NotificationService.instance.init();
      
      // İzin iste - bu kullanıcı isteği olduğu için dialog göster  
      final permissions = await NotificationService.instance.requestPermissions();

      setState(() {
        _permissionsGranted = permissions;
      });

      if (permissions) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bildirim izinleri başarıyla alındı!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '❌ Bildirim izinleri verilmemiş. Sistem ayarlarını kontrol edin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ İzin kontrolü hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Bildirimleri yeniden planla
  Future<void> _rescheduleNotifications() async {
    if (!_notificationsEnabled || !_permissionsGranted) {
      await NotificationService.instance.cancelAllNotifications();
      setState(() => _pendingNotificationsCount = 0);
      return;
    }

    try {
      await NotificationService.instance.cancelAllNotifications();
      debugPrint('✅ Tüm planlanmış bildirimler iptal edildi');

      int plannedCount = 0;

      // Yeni geliştirilmiş bildirim sistemi kullan
      if (_workoutReminderEnabled ||
          _mealReminderEnabled ||
          _waterReminderEnabled) {
        plannedCount =
            await NotificationService.instance.scheduleDailyNotifications();

        // İçerik bazlı bildirimler
        final contentCount = await NotificationService.instance
            .scheduleContentBasedNotifications();
        plannedCount += contentCount;
      }

      // Planlanmış bildirim sayısını güncelle
      final pending =
          await NotificationService.instance.getPendingNotifications();
      setState(() => _pendingNotificationsCount = pending.length);

      if (plannedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $plannedCount adet günlük bildirim planlandı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Bildirimler planlanırken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Bildirimler planlanamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Özel bildirim ekleme dialogu
  void _showCustomNotificationDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

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
                        labelText: 'Başlık *',
                        hintText: 'Ne hatırlatmamı istersin?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      textCapitalization: TextCapitalization.sentences,
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
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Tarih seçimi
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(selectedDate == null
                          ? 'Tarih Seç'
                          : 'Tarih: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() => selectedDate = date);
                        }
                      },
                    ),

                    // Saat seçimi
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(selectedTime == null
                          ? 'Saat Seç'
                          : 'Saat: ${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setDialogState(() => selectedTime = time);
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
                  onPressed: (titleController.text.isNotEmpty &&
                          selectedDate != null &&
                          selectedTime != null)
                      ? () async {
                          Navigator.of(context).pop();
                          await _scheduleCustomNotification(
                            titleController.text,
                            bodyController.text.isEmpty
                                ? 'KaplanFit hatırlatması'
                                : bodyController.text,
                            DateTime(
                              selectedDate!.year,
                              selectedDate!.month,
                              selectedDate!.day,
                              selectedTime!.hour,
                              selectedTime!.minute,
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Planla'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Özel bildirim planlama
  Future<void> _scheduleCustomNotification(
      String title, String body, DateTime dateTime) async {
    try {
      debugPrint('📅 Özel bildirim planlanıyor...');
      debugPrint('   📝 Başlık: $title');
      debugPrint('   📄 İçerik: $body');
      debugPrint('   🕒 Zaman: $dateTime');

      debugPrint('=== ÖZEL BİLDİRİM PLANLIYOR ===');
      debugPrint('Başlık: $title');
      debugPrint('Zaman: $dateTime');
      debugPrint('==============================');

      // Eğer geçmiş tarih seçildiyse hata ver
      final now = DateTime.now();
      if (dateTime.isBefore(now)) {
        final difference = now.difference(dateTime);
        debugPrint(
            '❌ Geçmiş zaman seçildi - Fark: ${difference.inMinutes} dakika');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '❌ Geçmiş bir zaman için bildirim planlanamaz! (${difference.inMinutes} dakika geçmiş)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // İzinleri kontrol et
      final permissions =
          await NotificationService.instance.areNotificationsEnabled();
      debugPrint('🔐 Bildirim izinleri: $permissions');

      if (!permissions) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Bildirim izinleri aktif değil!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final difference = dateTime.difference(now);
      debugPrint('   ⏳ ${difference.inMinutes} dakika sonra gelecek');

      await NotificationService.instance.scheduleOneTimeNotification(
        title: title,
        body: body,
        scheduledDateTime: dateTime,
      );

      final formattedTime = TimeOfDay.fromDateTime(dateTime).format(context);
      final formattedDate =
          "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";

      // Planlanmış bildirim sayısını güncelle
      final pending =
          await NotificationService.instance.getPendingNotifications();
      setState(() => _pendingNotificationsCount = pending.length);

      debugPrint(
          '✅ Özel bildirim planlandı: "$title" - $formattedDate $formattedTime');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ "$title" bildirimi $formattedDate $formattedTime için planlandı'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Özel bildirim planlanırken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Özel bildirim planlanamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
