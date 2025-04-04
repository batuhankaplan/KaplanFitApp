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
    _tabController = TabController(length: 2, vsync: this);
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
    final now = DateTime.now();
    
    setState(() {
      _selectedTimeRangeEnum = range;
      
      switch (range) {
        case TimeRange.week:
          _selectedTimeRange = 'Haftalık';
          _startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6));
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case TimeRange.month:
          _selectedTimeRange = 'Aylık';
          // Bir ay öncesi
          _startDate = DateTime(now.year, now.month - 1, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case TimeRange.year:
          _selectedTimeRange = 'Yıllık';
          // Bir yıl öncesi
          _startDate = DateTime(now.year - 1, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context);
    final nutritionProvider = Provider.of<NutritionProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Aktiviteler
    final activities = activityProvider.activities;
    final totalDuration = activities.fold<int>(0, (sum, activity) => sum + activity.durationMinutes);
    final avgDuration = activities.isEmpty ? 0 : totalDuration ~/ activities.length;
    
    // Beslenme
    final meals = nutritionProvider.meals;
    final totalCalories = meals.fold<int>(0, (sum, meal) => sum + (meal.calories ?? 0));
    final avgCalories = meals.isEmpty ? 0 : totalCalories ~/ meals.length;
    
    // Aktivite türlerine göre gruplandırma
    Map<FitActivityType, int> activityMinutesByType = {};
    for (var activity in activities) {
      activityMinutesByType[activity.type] = (activityMinutesByType[activity.type] ?? 0) + activity.durationMinutes;
    }
    
    // Öğün türlerine göre gruplandırma
    Map<FitMealType, int> caloriesByMealType = {};
    for (var meal in meals) {
      caloriesByMealType[meal.type] = (caloriesByMealType[meal.type] ?? 0) + (meal.calories ?? 0);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('İstatistikler'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Beslenme'),
            Tab(text: 'Aktivite'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Zaman aralığı seçici
          Container(
            color: _selectedTabIndex == 0 ? AppTheme.lunchColor : AppTheme.eveningExerciseColor,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => _updateDateRange(TimeRange.week),
                  child: Text(
                    'Haftalık',
                    style: TextStyle(
                      color: _selectedTimeRange == 'Haftalık' ? Colors.white : Colors.white70,
                      fontWeight: _selectedTimeRange == 'Haftalık' ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _updateDateRange(TimeRange.month),
                  child: Text(
                    'Aylık',
                    style: TextStyle(
                      color: _selectedTimeRange == 'Aylık' ? Colors.white : Colors.white70,
                      fontWeight: _selectedTimeRange == 'Aylık' ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _updateDateRange(TimeRange.year),
                  child: Text(
                    'Yıllık',
                    style: TextStyle(
                      color: _selectedTimeRange == 'Yıllık' ? Colors.white : Colors.white70,
                      fontWeight: _selectedTimeRange == 'Yıllık' ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // İstatistik kartları
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Beslenme istatistikleri sayfası
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
                                      colors: [Color(0xFFFFA726), Color(0xFFFFCC80)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
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
                                      colors: [Color(0xFF7E57C2), Color(0xFFB39DDB)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.local_fire_department, color: Colors.white, size: 32),
                                      SizedBox(height: 8),
                                      Text(
                                        'Günlük Ortalama',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '$avgCalories kcal/gün',
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
                        
                        SizedBox(height: 20),
                        
                        // Beslenme dağılımı
                        Text(
                          'Beslenme Dağılımı',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Aktivite türlerine göre dağılım grafiği
                        Container(
                          height: 300,
                          padding: EdgeInsets.all(8),
                          child: _buildNutritionChart(caloriesByMealType, isDarkMode),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Aktivite istatistikleri sayfası
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
                                      colors: [Color(0xFF26A69A), Color(0xFF80CBC4)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
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
                                      colors: [Color(0xFF5C6BC0), Color(0xFF9FA8DA)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
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
                        
                        SizedBox(height: 20),
                        
                        // Aktivite dağılımı
                        Text(
                          'Aktivite Dağılımı',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Aktivite türlerine göre dağılım grafiği
                        Container(
                          height: 300,
                          padding: EdgeInsets.all(8),
                          child: _buildActivityChart(activityMinutesByType, isDarkMode),
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
    );
  }
  
  Widget _buildActivityChart(Map<FitActivityType, int> activityByType, bool isDarkMode) {
    if (activityByType.isEmpty) {
      return Center(
        child: Text(
          'Henüz aktivite verisi yok',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
      );
    }
    
    // Grafik verilerini hazırla
    List<BarChartGroupData> barGroups = [];
    int index = 0;
    
    activityByType.forEach((type, minutes) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: minutes.toDouble(),
              color: _getColorForActivityType(type),
              width: 20,
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
      index++;
    });
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: activityByType.values.fold(0, (max, value) => value > max ? value : max) * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text = '';
                if (value < activityByType.length) {
                  text = _getActivityTypeLabel(activityByType.keys.elementAt(value.toInt()));
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()} dk',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
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
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDarkMode ? Colors.white24 : Colors.black12,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
  
  Widget _buildNutritionChart(Map<FitMealType, int> caloriesByType, bool isDarkMode) {
    if (caloriesByType.isEmpty) {
      return Center(
        child: Text(
          'Henüz beslenme verisi yok',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
      );
    }
    
    // Grafik verilerini hazırla
    List<BarChartGroupData> barGroups = [];
    int index = 0;
    
    caloriesByType.forEach((type, calories) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: calories.toDouble(),
              color: _getColorForMealType(type),
              width: 20,
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
      index++;
    });
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: caloriesByType.values.fold(0, (max, value) => value > max ? value : max) * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text = '';
                if (value < caloriesByType.length) {
                  text = _getMealTypeLabel(caloriesByType.keys.elementAt(value.toInt()));
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()} kcal',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
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
          horizontalInterval: 200,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDarkMode ? Colors.white24 : Colors.black12,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
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
  
  String _getActivityTypeLabel(FitActivityType type) {
    switch (type) {
      case FitActivityType.walking:
        return 'Yürüyüş';
      case FitActivityType.running:
        return 'Koşu';
      case FitActivityType.cycling:
        return 'Bisiklet';
      case FitActivityType.swimming:
        return 'Yüzme';
      case FitActivityType.weightTraining:
        return 'Ağırlık';
      case FitActivityType.yoga:
        return 'Yoga';
      case FitActivityType.other:
        return 'Diğer';
    }
  }
  
  String _getMealTypeLabel(FitMealType type) {
    switch (type) {
      case FitMealType.breakfast:
        return 'Kahvaltı';
      case FitMealType.lunch:
        return 'Öğle';
      case FitMealType.dinner:
        return 'Akşam';
      case FitMealType.snack:
        return 'Atıştırma';
      case FitMealType.other:
        return 'Diğer';
    }
  }
}

enum TimeRange {
  week,
  month,
  year,
} 