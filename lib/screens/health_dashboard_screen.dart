import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../widgets/kaplan_appbar.dart';
import '../theme.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _setupHealthConnect() async {
    try {
      final healthProvider =
          Provider.of<HealthProvider>(context, listen: false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Health Connect kurulumu başlatılıyor...'),
          backgroundColor: Colors.blue,
        ),
      );
      
      await healthProvider.refreshConnection();
      
      if (!healthProvider.hasPermissions) {
        await healthProvider.requestPermissions();
      }
      
      if (healthProvider.hasPermissions) {
        await healthProvider.syncHistoricalData(months: 3);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Health Connect başarıyla kuruldu!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      setState(() {});
    } catch (e) {
      debugPrint('Health Connect kurulum hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Health Connect kurulumunda hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cleanupDuplicateRecords() async {
    try {
      final healthProvider =
          Provider.of<HealthProvider>(context, listen: false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tekrarlayan veriler temizleniyor...'),
          backgroundColor: Colors.blue,
        ),
      );
      
      await healthProvider.cleanupDuplicateRecords();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Tekrarlayan veriler temizlendi!'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {});
    } catch (e) {
      debugPrint('Veri temizleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veri temizlemede hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final healthProvider =
          Provider.of<HealthProvider>(context, listen: false);
      await healthProvider.refreshConnection();

      if (healthProvider.hasPermissions) {
        // Sync last 3 months of data
        await healthProvider.syncHistoricalData(months: 3);
        await healthProvider.syncAllData();
      }
    } catch (e) {
      debugPrint('Veri yenileme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Widget _buildHeaderBox(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Entegrasyonu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Akıllı cihaz ve uygulama entegrasyonları',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: KaplanAppBar(
        title: 'App Entegrasyonu',
        isDarkMode: isDarkMode,
        isRequiredPage: false,
        showBackButton: true,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkMode ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    color: isDarkMode ? Colors.white : AppTheme.primaryColor,
                  ),
            onPressed: _isRefreshing ? null : _refreshData,
            tooltip: 'Verileri Yenile',
          ),
        ],
      ),
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      body: Consumer<HealthProvider>(
        builder: (context, healthProvider, child) {
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bağlantı Durumu
                  _buildConnectionStatusCard(healthProvider, isDarkMode),
                  const SizedBox(height: 16),

                  // Cihaz Bilgileri
                  _buildDeviceInfoCard(healthProvider, isDarkMode),
                  const SizedBox(height: 16),

                  if (healthProvider.isConnected &&
                      healthProvider.hasPermissions) ...[
                    // Ana Metrikler
                    _buildMainMetricsRow(healthProvider, isDarkMode),
                    const SizedBox(height: 16),

                    // Kalp Atış Hızı
                    _buildHeartRateCard(healthProvider, isDarkMode),
                    const SizedBox(height: 16),

                    // Antreman Verileri
                    _buildWorkoutCard(healthProvider, isDarkMode),
                    const SizedBox(height: 16),

                    // Uyku Verileri
                    _buildSleepCard(healthProvider, isDarkMode),
                    const SizedBox(height: 16),

                    // Samsung Watch Özel Sensörler
                    if (healthProvider.activeProvider == 'samsungHealth') ...[
                      _buildSamsungSensorsCard(healthProvider, isDarkMode),
                      const SizedBox(height: 16),
                    ],

                    // Antreman Takibi
                    _buildWorkoutTrackingCard(healthProvider, isDarkMode),
                    const SizedBox(height: 16),
                  ] else if (healthProvider.isConnected &&
                      !healthProvider.hasPermissions) ...[
                    // İzin İsteme
                    _buildPermissionCard(healthProvider, isDarkMode),
                    const SizedBox(height: 16),
                  ],

                  // Management Tools
                  _buildManagementToolsCard(healthProvider, isDarkMode),
                  const SizedBox(height: 16),

                  // Debug Bilgileri
                  _buildDebugCard(healthProvider, isDarkMode),
                  const SizedBox(height: 80), // Alt boşluk
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatusCard(
      HealthProvider healthProvider, bool isDarkMode) {
    final isConnected = healthProvider.isConnected;
    final statusColor = isConnected ? Colors.green : Colors.red;

    return Card(
      elevation: 4,
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cihaz Bağlantısı',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected
                        ? '✅ Bağlı (${healthProvider.connectedDeviceType})'
                        : '❌ Bağlantı Yok',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  if (isConnected) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Provider: ${healthProvider.activeProvider}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard(HealthProvider healthProvider, bool isDarkMode) {
    return Card(
      elevation: 4,
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.watch,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cihaz Bilgileri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
                'Cihaz Türü', healthProvider.connectedDeviceType, isDarkMode),
            _buildInfoRow(
                'Aktif Provider', healthProvider.activeProvider, isDarkMode),
            _buildInfoRow(
                'İzin Durumu',
                healthProvider.hasPermissions ? 'Verildi' : 'Verilmedi',
                isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMetricsRow(HealthProvider healthProvider, bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Adımlar',
            '${healthProvider.todaySteps}',
            Icons.directions_walk,
            Colors.blue,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Kalori',
            '${healthProvider.todayCalories}',
            Icons.local_fire_department,
            Colors.orange,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Uyku Skoru',
            '${healthProvider.sleepScore}',
            Icons.bedtime,
            Colors.purple,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Card(
      elevation: 3,
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.05),
              color.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeartRateCard(HealthProvider healthProvider, bool isDarkMode) {
    final latestHeartRate = healthProvider.latestHeartRate;

    return Card(
      elevation: 4,
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Kalp Atış Hızı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (latestHeartRate != null) ...[
              Text(
                '$latestHeartRate BPM',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Text(
                'Son ölçüm',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ] else ...[
              Text(
                'Veri bulunamadı',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(HealthProvider healthProvider, bool isDarkMode) {
    final workoutData = healthProvider.workoutData;

    return Card(
      elevation: 4,
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Antreman Verileri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (workoutData.isNotEmpty) ...[
              _buildInfoRow('Toplam Egzersiz',
                  '${workoutData['totalExercises'] ?? 0}', isDarkMode),
              _buildInfoRow(
                  'Süre',
                  '${(workoutData['totalDuration'] ?? 0) / 60000} dk',
                  isDarkMode),
              _buildInfoRow('Ortalama Nabız',
                  '${workoutData['averageHeartRate'] ?? 0} BPM', isDarkMode),
              _buildInfoRow('Yakılan Kalori',
                  '${workoutData['caloriesBurned'] ?? 0}', isDarkMode),
            ] else ...[
              Text(
                'Antreman verisi bulunamadı',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard(HealthProvider healthProvider, bool isDarkMode) {
    final sleepData = healthProvider.sleepData;

    return Card(
      elevation: 4,
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bedtime,
                  color: Colors.indigo,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Uyku Verileri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sleepData.isNotEmpty) ...[
              _buildInfoRow(
                  'Toplam Uyku',
                  '${(sleepData['totalSleepMinutes'] ?? 0) / 60} saat',
                  isDarkMode),
              _buildInfoRow('Derin Uyku',
                  '${sleepData['deepSleepMinutes'] ?? 0} dk', isDarkMode),
              _buildInfoRow('REM Uyku',
                  '${sleepData['remSleepMinutes'] ?? 0} dk', isDarkMode),
              _buildInfoRow('Uyku Skoru', '${sleepData['sleepScore'] ?? 0}/100',
                  isDarkMode),
            ] else ...[
              Text(
                'Uyku verisi bulunamadı',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSamsungSensorsCard(
      HealthProvider healthProvider, bool isDarkMode) {
    return Card(
      elevation: 4,
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sensors,
                  color: Colors.teal,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Samsung Sensörleri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (healthProvider.stressLevel != null)
              _buildInfoRow(
                  'Stres Seviyesi',
                  '${healthProvider.stressLevel!.toStringAsFixed(1)}/100',
                  isDarkMode),
            if (healthProvider.bloodOxygenLevel != null)
              _buildInfoRow(
                  'Kan Oksijeni',
                  '${healthProvider.bloodOxygenLevel!.toStringAsFixed(1)}%',
                  isDarkMode),
            if (healthProvider.bodyComposition != null) ...[
              const SizedBox(height: 8),
              Text(
                'Vücut Kompozisyonu:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              _buildInfoRow('Vücut Yağı',
                  '${healthProvider.bodyComposition!['bodyFat']}%', isDarkMode),
              _buildInfoRow(
                  'Kas Kütlesi',
                  '${healthProvider.bodyComposition!['muscleMass']} kg',
                  isDarkMode),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutTrackingCard(
      HealthProvider healthProvider, bool isDarkMode) {
    return Card(
      elevation: 4,
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Antreman Takibi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (healthProvider.isTrackingWorkout) ...[
              Text(
                'Aktif: ${healthProvider.currentWorkoutType}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await healthProvider.stopWorkoutTracking();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Antrenmanı Durdur'),
              ),
            ] else ...[
              Text(
                'Antreman takibi aktif değil',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await healthProvider.startWorkoutTracking('Genel Antreman');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Antreman Başlat'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(HealthProvider healthProvider, bool isDarkMode) {
    return Card(
      elevation: 4,
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'İzin Gerekli',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Provider bilgilendirmesi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (isDarkMode ? Colors.blue.shade800 : Colors.blue.shade50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        healthProvider.activeProvider == 'healthConnect'
                            ? Icons.health_and_safety
                            : Icons.watch,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        healthProvider.activeProvider == 'healthConnect'
                            ? 'Health Connect (Önerilen)'
                            : 'Samsung Health',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    healthProvider.activeProvider == 'healthConnect'
                        ? 'Android\'in yerleşik sağlık sistemi kullanılacak. Açılacak sayfada "KaplanFIT" uygulamasını bulun ve sağlık verilerine erişim izni verin.'
                        : 'Samsung Health uygulaması açılacak. Samsung Health > Ayarlar > Veri paylaşımı menüsünden KaplanFIT\'e izin verin.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'Samsung Watch\'ınızdan sağlık verilerini almak için izin vermeniz gerekiyor.',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),

            // Ana izin verme butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await healthProvider.requestPermissions();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.shield_outlined),
                label: Text(
                  healthProvider.activeProvider == 'healthConnect'
                      ? 'Health Connect İzinlerini Ver'
                      : 'Samsung Health İzinlerini Ver',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Alternatif permission sistemleri
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _requestSamsungHealthDirect(healthProvider),
                    icon: const Icon(Icons.favorite,
                        size: 16, color: Colors.green),
                    label: const Text('Samsung Health Direct',
                        style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.green, width: 1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _requestGoogleFit(healthProvider),
                    icon: const Icon(Icons.fitness_center,
                        size: 16, color: Colors.blue),
                    label: const Text('Google Fit',
                        style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.blue, width: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Alternatif provider seçeneği
            if (healthProvider.activeProvider != 'healthConnect')
              TextButton(
                onPressed: () {
                  // Provider değiştirme seçeneği göster
                  _showProviderSelectionDialog(healthProvider, isDarkMode);
                },
                child: Text(
                  'Health Connect kullanmayı tercih ederim',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showProviderSelectionDialog(
      HealthProvider healthProvider, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        title: Text(
          'Sağlık Veri Kaynağı',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Health Connect Android\'in yerleşik sağlık sistemidir ve daha kullanıcı dostu izin süreci sunar. Samsung Health yerine Health Connect\'i kullanmak ister misiniz?',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Health Connect'e geçiş yapmak için provider'ı yenile
              await healthProvider.refreshConnection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Health Connect Kullan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Alternatif permission request metodları
  Future<void> _requestSamsungHealthDirect(
      HealthProvider healthProvider) async {
    try {
      debugPrint('🔥 Samsung Health Direct permission request başlatılıyor...');

      _showSnackBar(
          'Samsung Health açılıyor... İzin verdikten sonra geri dönün',
          Colors.blue);

      final success =
          await healthProvider.requestSamsungHealthDirectPermissions();

      if (success) {
        _showSnackBar('✅ İzinler başarıyla verildi!', Colors.green);
        // Sayfayı yenile
        setState(() {});
      } else {
        _showSnackBar(
            'Samsung Health açılamadı. Lütfen manuel olarak izin verin.',
            Colors.orange);
      }
    } catch (e) {
      debugPrint('Samsung Health Direct error: $e');
      _showSnackBar('Samsung Health hatası: $e', Colors.red);
    }
  }

  Future<void> _requestGoogleFit(HealthProvider healthProvider) async {
    try {
      debugPrint('🔥 Google Fit permission request başlatılıyor...');

      final success = await healthProvider.requestGoogleFitPermissions();

      if (success) {
        _showSnackBar(
            'Google Fit uygulamasında KaplanFIT\'e izin verin', Colors.blue);
      } else {
        _showSnackBar(
            'Google Fit açılamadı. Play Store\'dan indirin.', Colors.orange);
      }
    } catch (e) {
      debugPrint('Google Fit error: $e');
      _showSnackBar('Google Fit hatası: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildDebugCard(HealthProvider healthProvider, bool isDarkMode) {
    final debugInfo = healthProvider.getDebugInfo();

    return Card(
      elevation: 4,
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(
          Icons.bug_report,
          color: Colors.grey,
          size: 20,
        ),
        title: Text(
          'Debug Bilgileri',
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: debugInfo.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isDarkMode ? Colors.white60 : Colors.black45,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementToolsCard(HealthProvider healthProvider, bool isDarkMode) {
    return Card(
      elevation: 4,
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build_circle,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Yönetim Araçları',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Health Connect Setup Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _setupHealthConnect,
                icon: const Icon(Icons.health_and_safety, size: 20),
                label: const Text('Health Connect Kurulumu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Cleanup Duplicate Records Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cleanupDuplicateRecords,
                icon: const Icon(Icons.cleaning_services, size: 20),
                label: const Text('Tekrarlayan Verileri Temizle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Sync Historical Data Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Son 3 ayın verileri senkronize ediliyor...'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                    
                    await healthProvider.syncHistoricalData(months: 3);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Son 3 ayın verileri başarıyla senkronize edildi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    
                    setState(() {});
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Senkronizasyon hatası: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.sync, size: 20),
                label: const Text('Son 3 Ayın Verilerini Çek'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
