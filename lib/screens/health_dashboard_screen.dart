import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../providers/health_provider.dart';
import '../providers/activity_provider.dart';
import '../widgets/kaplan_appbar.dart';
import '../theme.dart';
import '../models/activity_record.dart';
import '../models/task_type.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen>
    with TickerProviderStateMixin {
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isSyncing = false;
  Timer? _syncTimer;
  
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  
  Map<String, dynamic> _todayStats = {};
  List<Map<String, dynamic>> _recentWorkouts = [];
  Map<String, int> _weeklyStats = {};
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkConnectionStatus();
    _setupAutoSync();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _syncTimer?.cancel();
    super.dispose();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
  }
  
  Future<void> _checkConnectionStatus() async {
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    setState(() {
      _isConnected = healthProvider.isConnected;
    });
    
    if (_isConnected) {
      await _loadHealthData();
    }
  }
  
  void _setupAutoSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isConnected && !_isSyncing) {
        _performBackgroundSync();
      }
    });
  }
  
  Future<void> _connectToSamsungHealth() async {
    setState(() {
      _isConnecting = true;
    });
    
    try {
      final healthProvider = Provider.of<HealthProvider>(context, listen: false);
      final success = await healthProvider.connectToSamsungHealth();
      
      if (success) {
        setState(() {
          _isConnected = true;
        });
        await _loadHealthData();
        _showSuccessSnackBar('Samsung Health bağlantısı başarılı!');
      } else {
        _showErrorSnackBar('Samsung Health bağlantısı başarısız!');
      }
    } catch (e) {
      _showErrorSnackBar('Bağlantı hatası: $e');
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }
  
  Future<void> _loadHealthData() async {
    setState(() {
      _isSyncing = true;
    });
    
    _progressController.reset();
    _progressController.forward();
    
    try {
      final healthProvider = Provider.of<HealthProvider>(context, listen: false);
      
      // Bugünkü istatistikleri al
      _todayStats = await healthProvider.getTodayStats();
      
      // Son 7 günlük antrenmanları al
      _recentWorkouts = await healthProvider.getRecentWorkouts(7);
      
      // Haftalık istatistikleri al
      _weeklyStats = await healthProvider.getWeeklyStats();
      
      // Verileri aktivite provider'a da ekle
      await _syncToActivityProvider();
      
      setState(() {});
      
    } catch (e) {
      _showErrorSnackBar('Veri yükleme hatası: $e');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }
  
  Future<void> _performBackgroundSync() async {
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    try {
      await healthProvider.syncLatestData();
      await _syncToActivityProvider();
    } catch (e) {
      debugPrint('Background sync error: $e');
    }
  }
  
  Future<void> _syncToActivityProvider() async {
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    
    try {
      // Samsung Health'ten gelen antrenman verilerini ActivityProvider'a ekle
      for (var workout in _recentWorkouts) {
        final activityRecord = ActivityRecord(
          type: _mapWorkoutTypeToActivityType(workout['type']),
          durationMinutes: workout['duration'] ?? 0,
          date: DateTime.parse(workout['date']),
          notes: 'Samsung Health\'ten senkronize edildi',
          caloriesBurned: workout['calories']?.toDouble() ?? 0.0,
          userId: null, // Bu ActivityProvider'da ayarlanacak
        );
        
        await activityProvider.addOrUpdateSyncedActivity(activityRecord);
      }
    } catch (e) {
      debugPrint('Activity sync error: $e');
    }
  }
  
  FitActivityType _mapWorkoutTypeToActivityType(String? workoutType) {
    switch (workoutType?.toLowerCase()) {
      case 'walking':
      case 'yürüyüş':
        return FitActivityType.walking;
      case 'running':
      case 'koşu':
        return FitActivityType.running;
      case 'cycling':
      case 'bisiklet':
        return FitActivityType.cycling;
      case 'swimming':
      case 'yüzme':
        return FitActivityType.swimming;
      case 'strength_training':
      case 'ağırlık_antrenmanı':
        return FitActivityType.weightTraining;
      case 'yoga':
        return FitActivityType.yoga;
      default:
        return FitActivityType.walking;
    }
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final healthProvider = Provider.of<HealthProvider>(context);
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey[50],
      appBar: KaplanAppBar(
        title: 'Aktivite Entegrasyonu',
        isDarkMode: isDarkMode,
        showBackButton: true,
        actions: [
          if (_isConnected)
            IconButton(
              onPressed: _isSyncing ? null : _loadHealthData,
              icon: _isSyncing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.refresh,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
              tooltip: 'Verileri Yenile',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHealthData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConnectionCard(isDarkMode),
              const SizedBox(height: 20),
              
              if (_isConnected) ...[
                _buildSyncStatusCard(isDarkMode),
                const SizedBox(height: 20),
                _buildTodayStatsCard(isDarkMode),
                const SizedBox(height: 20),
                _buildWeeklyStatsCard(isDarkMode),
                const SizedBox(height: 20),
                _buildRecentWorkoutsCard(isDarkMode),
                const SizedBox(height: 20),
                _buildDataSourcesCard(isDarkMode),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildConnectionCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isConnected
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isConnected ? Colors.green : Colors.blue).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isConnected ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isConnected ? Icons.health_and_safety : Icons.link,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _isConnected ? 'Samsung Health Bağlı' : 'Samsung Health',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isConnected
                ? 'Veriler otomatik olarak senkronize ediliyor'
                : 'Sağlık ve aktivite verilerinizi senkronize edin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (!_isConnected)
            ElevatedButton.icon(
              onPressed: _isConnecting ? null : _connectToSamsungHealth,
              icon: _isConnecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    )
                  : const Icon(Icons.link),
              label: Text(_isConnecting ? 'Bağlanıyor...' : 'Bağlan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSyncStatusCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isSyncing ? Colors.orange.shade100 : Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isSyncing ? Icons.sync : Icons.check_circle,
              color: _isSyncing ? Colors.orange : Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSyncing ? 'Senkronize Ediliyor' : 'Senkronizasyon Tamamlandı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSyncing
                      ? 'Samsung Health verileriniz güncelleniyor...'
                      : 'Son senkronizasyon: ${DateFormat('HH:mm').format(DateTime.now())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                if (_isSyncing) ...[
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTodayStatsCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.today,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Bugünkü İstatistikler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.directions_walk,
                  title: 'Adım',
                  value: '${_todayStats['steps'] ?? 0}',
                  color: Colors.blue,
                  isDarkMode: isDarkMode,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_fire_department,
                  title: 'Kalori',
                  value: '${_todayStats['calories'] ?? 0}',
                  color: Colors.red,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.straighten,
                  title: 'Mesafe',
                  value: '${(_todayStats['distance'] ?? 0).toStringAsFixed(1)} km',
                  color: Colors.green,
                  isDarkMode: isDarkMode,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.favorite,
                  title: 'Kalp Atışı',
                  value: '${_todayStats['heartRate'] ?? 0} bpm',
                  color: Colors.pink,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeeklyStatsCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Haftalık İstatistikler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
              final steps = _weeklyStats['day_${index + 1}'] ?? 0;
              final maxSteps = _weeklyStats.values.isNotEmpty
                  ? _weeklyStats.values.reduce((a, b) => a > b ? a : b)
                  : 1;
              final percentage = maxSteps > 0 ? steps / maxSteps : 0.0;
              
              return Column(
                children: [
                  Container(
                    width: 30,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        width: 30,
                        height: 80 * percentage,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayNames[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentWorkoutsCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                'Son Antrenmanlar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentWorkouts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz antrenman verisi bulunamadı',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_recentWorkouts.take(5).map((workout) => _buildWorkoutItem(workout, isDarkMode))),
        ],
      ),
    );
  }
  
  Widget _buildWorkoutItem(Map<String, dynamic> workout, bool isDarkMode) {
    final workoutType = workout['type'] ?? 'Bilinmiyor';
    final duration = workout['duration'] ?? 0;
    final calories = workout['calories'] ?? 0;
    final date = DateTime.tryParse(workout['date'] ?? '') ?? DateTime.now();
    
    IconData workoutIcon;
    Color workoutColor;
    
    switch (workoutType.toLowerCase()) {
      case 'walking':
      case 'yürüyüş':
        workoutIcon = Icons.directions_walk;
        workoutColor = Colors.green;
        break;
      case 'running':
      case 'koşu':
        workoutIcon = Icons.directions_run;
        workoutColor = Colors.blue;
        break;
      case 'cycling':
      case 'bisiklet':
        workoutIcon = Icons.directions_bike;
        workoutColor = Colors.orange;
        break;
      case 'swimming':
      case 'yüzme':
        workoutIcon = Icons.pool;
        workoutColor = Colors.cyan;
        break;
      default:
        workoutIcon = Icons.fitness_center;
        workoutColor = Colors.purple;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: workoutColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: workoutColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(workoutIcon, color: workoutColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workoutType,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${duration}dk',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${calories} cal',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            DateFormat('dd/MM').format(date),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDataSourcesCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.source,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Veri Kaynakları',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDataSourceItem(
            'Samsung Health',
            'Adımlar, kalori, kalp atışı, antrenmanlar',
            Icons.health_and_safety,
            Colors.green,
            true,
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildDataSourceItem(
            'Samsung Watch',
            'Detaylı antrenman verileri, uyku, stres',
            Icons.watch,
            Colors.blue,
            _todayStats.containsKey('watch_connected'),
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildDataSourceItem(
            'Samsung Galaxy Fit',
            'Sürekli kalp atışı, aktivite takibi',
            Icons.fitness_center,
            Colors.purple,
            _todayStats.containsKey('band_connected'),
            isDarkMode,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDataSourceItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isConnected,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected
            ? color.withOpacity(0.1)
            : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? color.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isConnected ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isConnected ? color : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isConnected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isConnected ? Colors.green : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }
}