import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../providers/nutrition_provider.dart';
import '../theme.dart';
import '../models/activity_record.dart';
import '../models/meal_record.dart';
import '../models/task_type.dart';
import '../utils/animations.dart';
import '../widgets/kaplan_appbar.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  String _selectedTimeRange = 'Haftalık';
  TimeRange _selectedTimeRangeEnum = TimeRange.week;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    _updateDateRange(TimeRange.week);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _updateDateRange(TimeRange range) {
    setState(() {
      _selectedTimeRangeEnum = range;
      final now = DateTime.now();
      
      switch (range) {
        case TimeRange.week:
          _selectedTimeRange = 'Haftalık';
          _startDate = now.subtract(const Duration(days: 6));
          _endDate = now;
          break;
        case TimeRange.month:
          _selectedTimeRange = 'Aylık';
          _startDate = DateTime(now.year, now.month - 1, now.day);
          _endDate = now;
          break;
        case TimeRange.year:
          _selectedTimeRange = 'Yıllık';
          _startDate = DateTime(now.year - 1, now.month, now.day);
          _endDate = now;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context);
    final nutritionProvider = Provider.of<NutritionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Aktivite ve beslenme verilerini provider'dan alıyoruz
    // Seçilen tarih aralığına göre filtreleme yapılacak
    activityProvider.setDateRange(_startDate, _endDate);
    nutritionProvider.setDateRange(_startDate, _endDate);
    
    // Aktiviteler - tüm aktiviteleri alalım, filtrelemeyi provider yapacak
    final allActivities = activityProvider.getAllActivities();
    final filteredActivities = allActivities.where((activity) => 
      activity.date.isAfter(_startDate) && 
      activity.date.isBefore(_endDate.add(Duration(days: 1)))
    ).toList();
    
    final totalDuration = filteredActivities.fold<int>(0, (sum, activity) => sum + activity.durationMinutes);
    final avgDuration = filteredActivities.isEmpty ? 0 : totalDuration ~/ filteredActivities.length;
    
    // Beslenme
    final allMeals = nutritionProvider.getAllMeals();
    final filteredMeals = allMeals.where((meal) => 
      meal.date.isAfter(_startDate) && 
      meal.date.isBefore(_endDate.add(Duration(days: 1)))
    ).toList();
    
    final totalCalories = filteredMeals.fold<int>(0, (sum, meal) => sum + (meal.calories ?? 0));
    final avgCalories = filteredMeals.isEmpty ? 0 : totalCalories ~/ filteredMeals.length;
    
    // Aktivite türlerine göre gruplandırma
    Map<DateTime, Map<FitActivityType, int>> activityDataByDate = {};
    for (var activity in filteredActivities) {
      final date = DateTime(activity.date.year, activity.date.month, activity.date.day);
      if (!activityDataByDate.containsKey(date)) {
        activityDataByDate[date] = {};
      }
      activityDataByDate[date]![activity.type] = 
        (activityDataByDate[date]![activity.type] ?? 0) + activity.durationMinutes;
    }
    
    // Öğün türlerine göre gruplandırma
    Map<DateTime, Map<FitMealType, int>> mealDataByDate = {};
    for (var meal in filteredMeals) {
      final date = DateTime(meal.date.year, meal.date.month, meal.date.day);
      if (!mealDataByDate.containsKey(date)) {
        mealDataByDate[date] = {};
      }
      mealDataByDate[date]![meal.type] = 
        (mealDataByDate[date]![meal.type] ?? 0) + (meal.calories ?? 0);
    }
    
    // Kilo değişimi
    final user = userProvider.user;
    final weightHistory = user?.weightHistory ?? [];
    final filteredWeightHistory = weightHistory.where((record) => 
      record.date.isAfter(_startDate) && 
      record.date.isBefore(_endDate.add(Duration(days: 1)))
    ).toList();
    
    return Scaffold(
      appBar: KaplanAppBar(
        title: 'İstatistikler',
        isDarkMode: isDarkMode,
        isRequiredPage: true,
      ),
      body: Container(
        color: AppTheme.primaryColor.withOpacity(0.05),
        child: Column(
          children: [
            // Üst panel - Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Material(
                  color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.9),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: isDarkMode ? Colors.white60 : Colors.black54,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentColor,
                          AppTheme.accentColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                    tabs: [
                      Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant_menu, size: 16),
                              SizedBox(width: 4),
                              Text('Beslenme'),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_run, size: 16),
                              SizedBox(width: 4),
                              Text('Aktivite'),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.monitor_weight, size: 16),
                              SizedBox(width: 4),
                              Text('Kilo'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Zaman aralığı seçici
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _buildTimeRangeSelector(),
            ),
            
            // Tarih aralığı gösterimi
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${DateFormat('d MMM yyyy', 'tr_TR').format(_startDate)} - ${DateFormat('d MMM yyyy', 'tr_TR').format(_endDate)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab içeriği
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // BESLENME İSTATİSTİKLERİ
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Toplam kalori ve günlük ortalama
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryColor.withOpacity(0.7),
                                          AppTheme.primaryColor.withOpacity(0.9),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.restaurant, color: Colors.white, size: 32),
                                        SizedBox(height: 8),
                                        Text(
                                          'Toplam Kalori',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '$totalCalories kcal',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryColor.withOpacity(0.7),
                                          AppTheme.primaryColor.withOpacity(0.9),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.calendar_today, color: Colors.white, size: 32),
                                        SizedBox(height: 8),
                                        Text(
                                          'Günlük Ortalama',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '$avgCalories kcal',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 24),
                          Text(
                            'Kalori Alımı',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          KFSlideAnimation(
                            offsetBegin: const Offset(0, 0.3),
                            child: Container(
                              height: 300,
                              padding: EdgeInsets.all(8),
                              child: filteredMeals.isEmpty
                                  ? Center(child: Text('Veri bulunamadı'))
                                  : _buildNutritionLineChart(mealDataByDate, isDarkMode),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // AKTİVİTE İSTATİSTİKLERİ
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Toplam süre ve günlük ortalama
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryColor.withOpacity(0.7),
                                          AppTheme.primaryColor.withOpacity(0.9),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.timer, color: Colors.white, size: 32),
                                        SizedBox(height: 8),
                                        Text(
                                          'Toplam Süre',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '$totalDuration dk',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryColor.withOpacity(0.7),
                                          AppTheme.primaryColor.withOpacity(0.9),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.trending_up, color: Colors.white, size: 32),
                                        SizedBox(height: 8),
                                        Text(
                                          'Günlük Ortalama',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '$avgDuration dk/gün',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 24),
                          Text(
                            'Aktivite Türlerine Göre Süreler',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          KFSlideAnimation(
                            offsetBegin: const Offset(0, 0.3),
                            child: Container(
                              height: 300,
                              padding: EdgeInsets.all(8),
                              child: _buildActivityLineChart(activityDataByDate, isDarkMode),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // KİLO İSTATİSTİKLERİ
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (user != null) ...[
                            // Mevcut kilo ve BMI durumu
                            Row(
                              children: [
                                Expanded(
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.primaryColor.withOpacity(0.7),
                                            AppTheme.primaryColor.withOpacity(0.9),
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Mevcut Kilo',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '${user.weight.toStringAsFixed(1)} kg',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.primaryColor.withOpacity(0.7),
                                            AppTheme.primaryColor.withOpacity(0.9),
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'BMI',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '${user.bmi.toStringAsFixed(1)}',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            user.bmiCategory,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          SizedBox(height: 24),
                          Text(
                            'Kilo Değişimi',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          KFSlideAnimation(
                            offsetBegin: const Offset(0, 0.3),
                            child: Container(
                              height: 300,
                              padding: EdgeInsets.all(8),
                              child: _buildWeightChart(filteredWeightHistory, isDarkMode),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Zaman aralığı butonları için yeni widget
  Widget _buildTimeRangeSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTimeRangeButton('Haftalık', TimeRange.week, Icons.calendar_view_week),
          _buildTimeRangeButton('Aylık', TimeRange.month, Icons.calendar_view_month),
          _buildTimeRangeButton('Yıllık', TimeRange.year, Icons.calendar_today),
        ],
      ),
    );
  }
  
  // Tek zaman butonu
  Widget _buildTimeRangeButton(String title, TimeRange range, IconData icon) {
    final isSelected = _selectedTimeRangeEnum == range;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _updateDateRange(range),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    AppTheme.accentColor,
                    AppTheme.accentColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected 
              ? null
              : isDarkMode 
                  ? Colors.transparent
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected 
                  ? Colors.white 
                  : isDarkMode 
                      ? Colors.white70 
                      : Colors.black54,
            ),
            SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : isDarkMode 
                        ? Colors.white70 
                        : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Aktivite çizgi grafiği
  Widget _buildActivityLineChart(Map<DateTime, Map<FitActivityType, int>> activityDataByDate, bool isDarkMode) {
    if (activityDataByDate.isEmpty) {
      return Center(
        child: Text(
          'Henüz aktivite verisi yok',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
      );
    }
    
    // Tüm tarihleri sırala
    final dates = activityDataByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    // Tüm aktivite türleri
    final activityTypes = FitActivityType.values.toList();
    
    // Her aktivite türü için ayrı çizgi oluştur
    final lineBarData = <LineChartBarData>[];
    
    for (final type in activityTypes) {
      final spots = <FlSpot>[];
      
      for (int i = 0; i < dates.length; i++) {
        final date = dates[i];
        final minutes = activityDataByDate[date]?[type] ?? 0;
        
        if (minutes > 0) {
          spots.add(FlSpot(i.toDouble(), minutes.toDouble()));
        }
      }
      
      if (spots.isNotEmpty) {
        lineBarData.add(
          LineChartBarData(
            spots: spots,
            color: _getColorForActivityType(type),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: _getColorForActivityType(type).withOpacity(0.2),
            ),
          ),
        );
      }
    }
    
    // Eğer hiç veri yoksa, boş bir grafik göster
    if (lineBarData.isEmpty) {
      return Center(
        child: Text(
          'Seçili tarih aralığında aktivite verisi yok',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
      );
    }
    
    return LineChart(
      LineChartData(
        lineBarsData: lineBarData,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= dates.length || value.toInt() < 0) {
                  return const SizedBox();
                }
                
                final date = dates[value.toInt()];
                String text;
                
                if (_selectedTimeRangeEnum == TimeRange.week) {
                  text = DateFormat('E', 'tr_TR').format(date); // Gün kısaltması
                } else if (_selectedTimeRangeEnum == TimeRange.month) {
                  text = DateFormat('d MMM', 'tr_TR').format(date); // 15 Oca
                } else {
                  text = DateFormat('MMM', 'tr_TR').format(date); // Oca
                }
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()} dk',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDarkMode ? Colors.white24 : Colors.black12,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: isDarkMode ? Colors.white24 : Colors.black12,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: isDarkMode ? Colors.white38 : Colors.black38,
            width: 1,
          ),
        ),
      ),
    );
  }
  
  // Beslenme çizgi grafiği
  Widget _buildNutritionLineChart(Map<DateTime, Map<FitMealType, int>> mealDataByDate, bool isDarkMode) {
    if (mealDataByDate.isEmpty) {
      return Center(
        child: Text(
          'Henüz beslenme verisi yok',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
      );
    }
    
    // Tüm tarihleri sırala
    final dates = mealDataByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    // Tüm öğün türleri
    final mealTypes = FitMealType.values.toList();
    
    // Her öğün türü için ayrı çizgi oluştur
    final lineBarData = <LineChartBarData>[];
    
    for (final type in mealTypes) {
      final spots = <FlSpot>[];
      
      for (int i = 0; i < dates.length; i++) {
        final date = dates[i];
        final calories = mealDataByDate[date]?[type] ?? 0;
        
        if (calories > 0) {
          spots.add(FlSpot(i.toDouble(), calories.toDouble()));
        }
      }
      
      if (spots.isNotEmpty) {
        lineBarData.add(
          LineChartBarData(
            spots: spots,
            color: _getColorForMealType(type),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: _getColorForMealType(type).withOpacity(0.2),
            ),
          ),
        );
      }
    }
    
    // Eğer hiç veri yoksa, boş bir grafik göster
    if (lineBarData.isEmpty) {
      return Center(
        child: Text(
          'Seçili tarih aralığında beslenme verisi yok',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
      );
    }
    
    return LineChart(
      LineChartData(
        lineBarsData: lineBarData,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= dates.length || value.toInt() < 0) {
                  return const SizedBox();
                }
                
                final date = dates[value.toInt()];
                String text;
                
                if (_selectedTimeRangeEnum == TimeRange.week) {
                  text = DateFormat('E', 'tr_TR').format(date); // Gün kısaltması
                } else if (_selectedTimeRangeEnum == TimeRange.month) {
                  text = DateFormat('d MMM', 'tr_TR').format(date); // 15 Oca
                } else {
                  text = DateFormat('MMM', 'tr_TR').format(date); // Oca
                }
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()} kcal',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 50,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 200,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDarkMode ? Colors.white24 : Colors.black12,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: isDarkMode ? Colors.white24 : Colors.black12,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: isDarkMode ? Colors.white38 : Colors.black38,
            width: 1,
          ),
        ),
      ),
    );
  }
  
  // Kilo grafiği
  Widget _buildWeightChart(List<WeightRecord> weightRecords, bool isDarkMode) {
    if (weightRecords.isEmpty) {
      return Center(
        child: Text(
          'Henüz kilo değişimi verisi yok',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
      );
    }
    
    // Kayıtları tarihe göre sırala
    weightRecords.sort((a, b) => a.date.compareTo(b.date));
    
    // Nokta verileri oluştur
    final spots = <FlSpot>[];
    
    for (int i = 0; i < weightRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), weightRecords[i].weight));
    }
    
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: Colors.teal,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.teal.withOpacity(0.2),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= weightRecords.length || value.toInt() < 0) {
                  return const SizedBox();
                }
                
                final date = weightRecords[value.toInt()].date;
                String text;
                
                if (_selectedTimeRangeEnum == TimeRange.week) {
                  text = DateFormat('E', 'tr_TR').format(date); // Gün kısaltması
                } else if (_selectedTimeRangeEnum == TimeRange.month) {
                  text = DateFormat('d MMM', 'tr_TR').format(date); // 15 Oca
                } else {
                  text = DateFormat('MMM', 'tr_TR').format(date); // Oca
                }
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()} kg',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDarkMode ? Colors.white24 : Colors.black12,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: isDarkMode ? Colors.white24 : Colors.black12,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: isDarkMode ? Colors.white38 : Colors.black38,
            width: 1,
          ),
        ),
      ),
    );
  }
  
  Color _getColorForActivityType(FitActivityType type) {
    switch (type) {
      case FitActivityType.walking:
        return Colors.orange;
      case FitActivityType.running:
        return Colors.red;
      case FitActivityType.cycling:
        return Colors.green;
      case FitActivityType.swimming:
        return Colors.blue;
      case FitActivityType.weightTraining:
        return Colors.purple;
      case FitActivityType.yoga:
        return Colors.teal;
      case FitActivityType.other:
        return Colors.grey;
    }
  }
  
  Color _getColorForMealType(FitMealType type) {
    switch (type) {
      case FitMealType.breakfast:
        return Colors.amber;
      case FitMealType.lunch:
        return Colors.orange.shade800;
      case FitMealType.dinner:
        return Colors.deepOrange;
      case FitMealType.snack:
        return Colors.lightGreen;
      case FitMealType.other:
        return Colors.grey;
    }
  }
}

enum TimeRange {
  week,
  month,
  year,
} 