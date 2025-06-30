import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/activity_provider.dart';
import '../services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user_model.dart'; // WeightRecord için
import '../theme.dart'; // AppTheme'i ekledik
import 'package:collection/collection.dart'; // lastWhereOrNull ve whereNotNull için eklendi
// import '../providers/activity_provider.dart'; // ActivityProvider'ı dinlemek alternatif olabilir

// Zaman aralığı seçenekleri için enum
enum TimeRange { week, month, threeMonths, year }

// YENİ: Takip türü için enum
enum TrackingType { water, weight, calories, activity }

// YENİ: Görünüm modu için enum
enum TrackingViewMode { list, graph }

class GoalTrackingScreen extends StatefulWidget {
  const GoalTrackingScreen({super.key});

  @override
  State<GoalTrackingScreen> createState() => _GoalTrackingScreenState();
}

// WidgetsBindingObserver'ı ekleyelim
class _GoalTrackingScreenState extends State<GoalTrackingScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  Map<DateTime, int> _waterLogData = {};
  List<WeightRecord> _weightLogData = []; // Tüm ağırlık verisini tutacağız
  Map<DateTime, NutritionSummary> _calorieData = {};
  Map<DateTime, int> _activityData = {};

  // Seçili zaman aralığı state'i
  TimeRange _selectedRange = TimeRange.week; // Varsayılan 7 gün

  // YENİ: Seçili takip türü state'i
  TrackingType _selectedTrackingType = TrackingType.water; // Varsayılan Su

  // YENİ: Seçili görünüm modu state'i
  TrackingViewMode _selectedViewMode =
      TrackingViewMode.list; // Varsayılan Liste

  // Scroll konum yönetimi için (sayfanın başa atlamasını önlemek için)
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this); // Observer'ı ekle
    // Kullanıcı yüklendiğinde verileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user != null && userProvider.user!.id != null) {
        debugPrint(
            "[GoalTrackingScreen] initState: User found, calling _loadTrackingData."); // Log eklendi
        _loadTrackingData();
      } else {
        debugPrint(
            "[GoalTrackingScreen] initState: User not found yet."); // Log eklendi
        // Kullanıcı yüklenince dinlemek için listener eklenebilir veya build'de kontrol edilir.
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Observer'ı kaldır
    _scrollController.dispose();
    super.dispose();
  }

  // Ekran tekrar görünür olduğunda veya uygulama ön plana geldiğinde
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Uygulama ön plana geldiğinde verileri yeniden yükle
      // Bu biraz agresif olabilir, .then() kullanımı daha hedefe yönelik
      // Ancak genel bir yenileme sağlar
      if (mounted) {
        _loadTrackingData();
      }
    }
  }

  Future<void> _loadTrackingData() async {
    if (!mounted) return;
    debugPrint("[GoalTrackingScreen] _loadTrackingData started.");

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user != null && user.id != null) {
        debugPrint(
            "[GoalTrackingScreen] User found (ID: ${user.id}). Fetching data...");
        final dbService = DatabaseService();
        final now = DateTime.now();
        DateTime queryStartDate = DateTime(now.year - 1, now.month, now.day);
        DateTime queryEndDate =
            DateTime(now.year, now.month, now.day, 23, 59, 59);

        // Veri yükleme işlemleri
        await Future.wait([
          // Su verilerini yükle
          dbService
              .getWaterLogInRange(queryStartDate, queryEndDate, user.id!)
              .then((data) {
            _waterLogData = data;
            debugPrint(
                "[GoalTrackingScreen] Water data loaded: ${data.length} entries");
          }).catchError((e) {
            debugPrint("[GoalTrackingScreen] Error loading water data: $e");
          }),

          // Kilo verilerini yükle
          dbService.getWeightHistory(user.id!).then((data) {
            _weightLogData = data..sort((a, b) => a.date.compareTo(b.date));
            debugPrint(
                "[GoalTrackingScreen] Weight data loaded: ${data.length} entries");

            // Kullanıcının mevcut kilosunu gösteren yeni bir kilo kaydı ekleyelim
            // ancak sadece hiç kayıt yoksa veya son kayıt güncel değilse
            if (data.isEmpty ||
                (data.isNotEmpty &&
                    data.last.date.difference(DateTime.now()).inDays.abs() >
                        0 &&
                    user.weight != null)) {
              final currentWeightRecord = WeightRecord(
                weight: user.weight!,
                date: DateTime.now(),
              );
              _weightLogData.add(currentWeightRecord);
              debugPrint(
                  "[GoalTrackingScreen] Added current weight record from user data");
            }
          }).catchError((e) {
            debugPrint("[GoalTrackingScreen] Error loading weight data: $e");
          }),

          // Kalori verilerini yükle
          dbService
              .getDailyNutritionSummaryInRange(
                  queryStartDate, queryEndDate, user.id!)
              .then((data) {
            _calorieData = data;
            debugPrint(
                "[GoalTrackingScreen] Calorie data loaded: ${data.length} entries");
          }).catchError((e) {
            debugPrint("[GoalTrackingScreen] Error loading calorie data: $e");
          }),

          // Aktivite verilerini yükle
          dbService
              .getDailyActivitySummaryInRange(
                  queryStartDate, queryEndDate, user.id!)
              .then((data) {
            _activityData = data;
            debugPrint(
                "[GoalTrackingScreen] Activity data loaded: ${data.length} entries");
          }).catchError((e) {
            debugPrint("[GoalTrackingScreen] Error loading activity data: $e");
          }),
        ]);
      } else {
        debugPrint(
            "[GoalTrackingScreen] User not found or invalid. Clearing data.");
        _waterLogData = {};
        _weightLogData = [];
        _calorieData = {};
        _activityData = {};
      }
    } catch (e) {
      debugPrint("[GoalTrackingScreen] Error during data loading: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Veriler yüklenirken bir hata oluştu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint("[GoalTrackingScreen] _loadTrackingData finished.");
    }
  }

  // Zaman aralığına göre başlangıç/bitiş tarihlerini döndüren yardımcı fonksiyon
  ({DateTime startDate, DateTime endDate}) _getDatesForRange(TimeRange range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime startDate;

    switch (range) {
      case TimeRange.week:
        startDate = today.subtract(const Duration(days: 6));
        break;
      case TimeRange.month:
        // Ayın ilk gününü almak daha mantıklı olabilir
        startDate = DateTime(today.year, today.month, 1);
        // Veya tam 1 ay öncesi:
        // startDate = DateTime(today.year, today.month - 1, today.day);
        break;
      case TimeRange.threeMonths:
        //startDate = DateTime(today.year, today.month - 3, today.day);
        startDate =
            DateTime(today.year, today.month - 2, 1); // Son 3 ayın başlangıcı
        break;
      case TimeRange.year:
        //startDate = DateTime(today.year - 1, today.month, today.day);
        startDate = DateTime(today.year, 1, 1); // Yılın başı
        break;
    }
    // endDate her zaman bugünün sonu olmalı
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return (startDate: startDate, endDate: endDate);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "[GoalTrackingScreen] build called. isLoading: $_isLoading"); // Log eklendi
    final userProvider = Provider.of<UserProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = userProvider.user; // user'ı buradan alalım

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hedef Takibi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/goal_settings').then((_) {
                // Ayarlar sayfasından dönünce hem kullanıcı verisi (Provider ile güncellenmiş olmalı)
                // hem de log verilerini (manuel) yeniden yükle
                _loadTrackingData();
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        // Aşağı çekerek yenileme
        onRefresh: _loadTrackingData,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics:
              const AlwaysScrollableScrollPhysics(), // RefreshIndicator için her zaman kaydırılabilir yap
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Yükleme göstergesi veya Kullanıcı yok mesajı
              if (_isLoading &&
                  _waterLogData.isEmpty &&
                  _weightLogData.isEmpty &&
                  _calorieData.isEmpty &&
                  _activityData.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ))
              else if (user == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50.0),
                    child: Text(
                      'İlerlemenizi görmek için lütfen profilinizi oluşturun veya giriş yapın.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else ...[
                // Ana hedefler kartı
                _buildCardWithGradient(
                  title: 'Ana Hedefler',
                  icon: Icons.flag_outlined,
                  gradientColors: [
                    AppTheme.primaryColor.withValues(alpha: 0.7),
                    AppTheme.primaryColor,
                  ],
                  child: Column(
                    children: [
                      _buildProgressItem(
                        title: 'Günlük Su',
                        icon: Icons.opacity,
                        iconColor: const Color.fromARGB(255, 28, 141, 194),
                        progress: _calculateWaterProgress(user),
                        value:
                            '${_getTodayWater()} / ${_getWaterTarget(user)} ml',
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      _buildProgressItem(
                        title: 'Kilo Hedefi',
                        icon: Icons.monitor_weight_outlined,
                        iconColor: AppTheme.categoryWorkoutColor,
                        progress: _calculateWeightProgress(user),
                        value:
                            '${user.weight?.toStringAsFixed(1) ?? "-"} / ${user.targetWeight?.toStringAsFixed(1) ?? "-"} kg',
                        isDarkMode: isDarkMode,
                        isReverse: (user.targetWeight ?? 0) <
                            (_weightLogData.firstOrNull?.weight ??
                                user.weight ??
                                0), // Kilo verme hedefi mi?
                      ),
                      const SizedBox(height: 16),
                      _buildProgressItem(
                        title: 'Haftalık Aktivite',
                        icon: Icons.directions_run,
                        iconColor: AppTheme.eveningExerciseColor,
                        progress: _calculateActivityProgress(user),
                        value:
                            '${_getTotalWeeklyActivity()} / ${user.weeklyActivityGoal?.toInt() ?? 0} dk',
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Beslenme hedefleri kartı
                _buildCardWithGradient(
                  title: 'Beslenme Hedefleri',
                  icon: Icons.restaurant_outlined,
                  gradientColors: [
                    AppTheme.nutritionColor.withValues(alpha: 0.7),
                    AppTheme.nutritionColor,
                  ],
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutritionStatNew(
                              title: 'Kalori',
                              icon: Icons.local_fire_department,
                              current: _getTodayNutrition().calories.toInt(),
                              target: user.targetCalories?.toInt() ?? 0,
                              unit: 'kcal',
                              color: Colors.orange,
                              isDarkMode: isDarkMode,
                            ),
                          ),
                          Expanded(
                            child: _buildNutritionStatNew(
                              title: 'Protein',
                              icon: Icons.egg_alt_outlined,
                              current: _getTodayNutrition().protein.toInt(),
                              target: user.targetProtein?.toInt() ?? 0,
                              unit: 'g',
                              color: Colors.redAccent,
                              isDarkMode: isDarkMode,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutritionStatNew(
                              title: 'Karbonhidrat',
                              icon: Icons.rice_bowl_outlined,
                              current: _getTodayNutrition().carbs.toInt(),
                              target: user.targetCarbs?.toInt() ?? 0,
                              unit: 'g',
                              color: Colors.amber,
                              isDarkMode: isDarkMode,
                            ),
                          ),
                          Expanded(
                            child: _buildNutritionStatNew(
                              title: 'Yağ',
                              icon: Icons.oil_barrel_outlined,
                              current: _getTodayNutrition().fat.toInt(),
                              target: user.targetFat?.toInt() ?? 0,
                              unit: 'g',
                              color: Colors.lightBlueAccent,
                              isDarkMode: isDarkMode,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // İlerleme Verileri Kartı
                _buildTrackingDataCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- YENİ KART YAPISI ---
  Widget _buildTrackingDataCard() {
    // Gradyan rengini seçili türe göre belirleyelim
    List<Color> gradientColors;
    switch (_selectedTrackingType) {
      case TrackingType.water:
        gradientColors = [
          AppTheme.waterReminderColor.withValues(alpha: 0.7),
          AppTheme.waterReminderColor
        ];
        break;
      case TrackingType.weight:
        gradientColors = [
          AppTheme.categoryWorkoutColor.withValues(alpha: 0.7),
          AppTheme.categoryWorkoutColor
        ];
        break;
      case TrackingType.calories:
        gradientColors = [
          AppTheme.lunchColor.withValues(alpha: 0.7),
          AppTheme.lunchColor
        ];
        break;
      case TrackingType.activity:
        gradientColors = [
          AppTheme.eveningExerciseColor.withValues(alpha: 0.7),
          AppTheme.eveningExerciseColor
        ];
        break;
      default: // Fallback
        gradientColors = [
          AppTheme.primaryColor.withValues(alpha: 0.7),
          AppTheme.primaryColor
        ];
    }
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // _buildCardWithGradient yerine manuel Container
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  AppTheme.darkCardBackgroundColor,
                  AppTheme.darkCardBackgroundColor.withValues(alpha: 0.8),
                ]
              : [Colors.white, Colors.white],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık kısmı - gradyan arka planlı
          Container(
            width: double.infinity, // Genişliği doldur
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors, // Seçili türe göre renk
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.timeline,
                    color: Colors.white, size: 24), // Sabit ikon
                const SizedBox(width: 10),
                Text(
                  'Süreç Takip', // Sabit başlık
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(), // Sağa yaslamak için
                _buildViewModeSelector(), // Liste/Grafik seçiciyi başlığa taşıyalım
              ],
            ),
          ),
          // İçerik kısmı
          Padding(
            padding: const EdgeInsets.all(16.0), // Padding'i azalttık
            child: Column(
              children: [
                // Takip Türü Seçici (Görünüm İyileştirmesi)
                _buildTrackingTypeSelectorImproved(), // İyileştirilmiş widget
                const SizedBox(height: 12),
                // Zaman Aralığı Seçici
                _buildTimeRangeSelector(),
                const SizedBox(height: 16),
                // İçerik (Liste veya Grafik) - Yükleniyor durumu eklendi
                _buildTrackingContentView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Madde: İyileştirilmiş Takip Türü Seçici (Daha kompakt ToggleButtons)
  Widget _buildTrackingTypeSelectorImproved() {
    final colorScheme = Theme.of(context).colorScheme;

    // Ekran genişliğine göre daha kompakt görünüm ayarla
    final screenWidth = MediaQuery.of(context).size.width;

    // Yükleme sırasında butonların etkin olup olmadığını kontrol et
    final bool interactionDisabled = _isLoading;

    // Tıklanınca gösterilecek tooltip mesajları
    final List<String> tooltipMessages = [
      'Su Takibi',
      'Kilo Takibi',
      'Kalori Takibi',
      'Aktivite Takibi',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(TrackingType.values.length, (index) {
        final type = TrackingType.values[index];
        final bool isSelected = _selectedTrackingType == type;

        // Her buton için ikon tanımlaması
        IconData icon;
        switch (type) {
          case TrackingType.water:
            icon = Icons.opacity_outlined;
            break;
          case TrackingType.weight:
            icon = Icons.monitor_weight_outlined;
            break;
          case TrackingType.calories:
            icon = Icons.local_fire_department_outlined;
            break;
          case TrackingType.activity:
            icon = Icons.directions_run_outlined;
            break;
        }

        return Expanded(
          child: Tooltip(
            message: tooltipMessages[index],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: InkWell(
                onTap: interactionDisabled
                    ? null
                    : () {
                        setState(() {
                          _selectedTrackingType = type;
                        });
                      },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? colorScheme.primary : colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // Toggle button içeriğini oluşturan yardımcı fonksiyon
  Widget _buildToggleButton(
      IconData icon, String label, TrackingType type, bool compact) {
    final bool isSelected = _selectedTrackingType == type;
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withValues(alpha: 0.7);

    return Tooltip(
      message: label, // Tooltip ile etiketi göster
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // 6. Madde: Zaman Aralığı Seçici (SegmentedButton)
  Widget _buildTimeRangeSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool useCompactLabels = screenWidth < 380;

    // Yükleme sırasında butonların etkin olup olmadığını kontrol et
    final bool interactionDisabled = _isLoading;

    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _selectedTrackingType == TrackingType.water
            ? AppTheme.waterReminderColor.withValues(alpha: 0.1)
            : _selectedTrackingType == TrackingType.weight
                ? AppTheme.weightColor.withValues(alpha: 0.1)
                : _selectedTrackingType == TrackingType.calories
                    ? AppTheme.calorieColor.withValues(alpha: 0.1)
                    : AppTheme.activityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTimeRangeButton('Hafta', TimeRange.week),
          ),
          Expanded(
            child: _buildTimeRangeButton('Ay', TimeRange.month),
          ),
          Expanded(
            child: _buildTimeRangeButton('3 Ay', TimeRange.threeMonths),
          ),
          Expanded(
            child: _buildTimeRangeButton('Yıl', TimeRange.year),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String text, TimeRange range) {
    final isSelected = _selectedRange == range;
    final color = _selectedTrackingType == TrackingType.water
        ? AppTheme.waterReminderColor
        : _selectedTrackingType == TrackingType.weight
            ? AppTheme.weightColor
            : _selectedTrackingType == TrackingType.calories
                ? AppTheme.calorieColor
                : AppTheme.activityColor;

    return GestureDetector(
      onTap: () => setState(() => _selectedRange = range),
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? color : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Görünüm Modu Seçici (Liste/Grafik - ToggleButtons)
  Widget _buildViewModeSelector() {
    final color = Colors.white; // İkonların rengini beyaz yapıyoruz

    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.list,
            color: _selectedViewMode == TrackingViewMode.list
                ? Colors.white // Seçili ikon beyaz
                : Colors.white.withValues(
                    alpha: 0.6), // Seçili olmayan ikon biraz saydam beyaz
          ),
          onPressed: () =>
              setState(() => _selectedViewMode = TrackingViewMode.list),
        ),
        IconButton(
          icon: Icon(
            Icons.show_chart,
            color: _selectedViewMode == TrackingViewMode.graph
                ? Colors.white // Seçili ikon beyaz
                : Colors.white.withValues(
                    alpha: 0.6), // Seçili olmayan ikon biraz saydam beyaz
          ),
          onPressed: () =>
              setState(() => _selectedViewMode = TrackingViewMode.graph),
        ),
      ],
    );
  }

  // Seçili moda göre içeriği oluşturan fonksiyon
  Widget _buildTrackingContentView() {
    switch (_selectedViewMode) {
      case TrackingViewMode.list:
        // Liste görünümünü seçilen aralığa göre filtrele
        return _buildDataListViewFiltered();
      case TrackingViewMode.graph:
        // Grafik görünümünü seçilen aralığa göre ayarla
        return _buildGraphViewFiltered();
    }
  }

  // 6. Madde: Filtrelenmiş Liste Görünümü
  Widget _buildDataListViewFiltered() {
    List<Widget> listItems = [];
    final DateFormat formatter = DateFormat('dd MMM yyyy', 'tr_TR');
    final user = Provider.of<UserProvider>(context, listen: false).user;
    // user null kontrolü build metodu başında yapıldı.
    if (user == null)
      return _buildEmptyDataPlaceholder('Kullanıcı bulunamadı.');

    final dates = _getDatesForRange(_selectedRange);
    final DateFormat timeFormatter = DateFormat('HH:mm'); // Saat göstermek için

    switch (_selectedTrackingType) {
      case TrackingType.water:
        final filteredData = _waterLogData.entries
            .where((entry) =>
                !entry.key.isBefore(dates.startDate) &&
                !entry.key.isAfter(dates.endDate))
            .toList()
          ..sort((a, b) => b.key.compareTo(a.key)); // En yeniden eskiye sırala

        if (filteredData.isEmpty) return _buildEmptyDataPlaceholder();

        filteredData.forEach((entry) {
          listItems.add(ListTile(
            leading: Icon(Icons.opacity,
                color: AppTheme.waterReminderColor, size: 20),
            title: Text(formatter.format(entry.key)),
            trailing: Text('${entry.value} / ${_getWaterTarget(user)} ml',
                style: TextStyle(fontWeight: FontWeight.w500)),
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
          ));
        });
        break;

      case TrackingType.weight:
        // Ağırlık verisi _weightLogData içinde zaten sıralı
        final filteredData = _weightLogData
            .where((record) =>
                !record.date.isBefore(dates.startDate) &&
                !record.date.isAfter(dates.endDate))
            .toList()
            .reversed // En yeniden eskiye göstermek için ters çevir
            .toList();

        if (filteredData.isEmpty) return _buildEmptyDataPlaceholder();

        filteredData.forEach((record) {
          listItems.add(ListTile(
            leading: Icon(Icons.monitor_weight,
                color: AppTheme.categoryWorkoutColor, size: 20),
            title: Text(formatter.format(record.date)),
            // Saati de ekleyelim (opsiyonel)
            // subtitle: Text(timeFormatter.format(record.date)),
            trailing: Text('${record.weight?.toStringAsFixed(1) ?? '-'} kg',
                style: TextStyle(fontWeight: FontWeight.w500)),
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
          ));
        });
        break;

      case TrackingType.calories:
        final filteredData = _calorieData.entries
            .where((entry) =>
                !entry.key.isBefore(dates.startDate) &&
                !entry.key.isAfter(dates.endDate))
            .toList()
          ..sort((a, b) => b.key.compareTo(a.key));

        if (filteredData.isEmpty) return _buildEmptyDataPlaceholder();

        filteredData.forEach((entry) {
          listItems.add(ListTile(
            leading: Icon(Icons.local_fire_department,
                color: AppTheme.lunchColor, size: 20),
            title: Text(formatter.format(entry.key)),
            trailing: Text(
                '${entry.value.calories.toInt()} / ${user.targetCalories?.toInt() ?? '-'} kcal',
                style: TextStyle(fontWeight: FontWeight.w500)),
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
          ));
        });
        break;

      case TrackingType.activity:
        final filteredData = _activityData.entries
            .where((entry) =>
                !entry.key.isBefore(dates.startDate) &&
                !entry.key.isAfter(dates.endDate))
            .toList()
          ..sort((a, b) => b.key.compareTo(a.key));

        if (filteredData.isEmpty) return _buildEmptyDataPlaceholder();

        filteredData.forEach((entry) {
          listItems.add(ListTile(
            leading: Icon(Icons.directions_run,
                color: AppTheme.eveningExerciseColor, size: 20),
            title: Text(formatter.format(entry.key)),
            trailing: Text('${entry.value} dk',
                style: TextStyle(fontWeight: FontWeight.w500)),
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
          ));
        });
        break;
    }

    if (listItems.isEmpty) {
      return _buildEmptyDataPlaceholder();
    }

    // Listeyi sarmalayıp yükseklik sınırı ve kenarlık verelim
    return Container(
      constraints: BoxConstraints(maxHeight: 350), // Yüksekliği artırdık
      width: double.infinity, // Genişliği ekrana uygun şekilde maksimum yap
      decoration: BoxDecoration(
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        // Kenarlığı içeriye uygulamak için
        borderRadius: BorderRadius.circular(8),
        child: ListView.separated(
          // Ayrıştırıcı ekleyelim
          shrinkWrap: true,
          itemCount: listItems.length,
          itemBuilder: (context, index) => listItems[index],
          separatorBuilder: (context, index) =>
              Divider(height: 1, thickness: 0.5),
        ),
      ),
    );
  }

  // Boş veri durumu için placeholder
  Widget _buildEmptyDataPlaceholder(
      [String message = "Seçili tür ve zaman aralığı için veri bulunamadı."]) {
    return SizedBox(
      height: 150, // Sabit yükseklik verelim
      child: Center(
          child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey[600]),
      )),
    );
  }

  // 6. Madde: Filtrelenmiş ve Ayarlanmış Grafik Görünümü
  Widget _buildGraphViewFiltered() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null)
      return _buildEmptyDataPlaceholder(
          'Grafik için kullanıcı verisi gereklidir.');

    final dates = _getDatesForRange(_selectedRange);
    final startDate = dates.startDate;
    final endDate = dates.endDate;
    // Gün sayısını startDate ve endDate arasındaki farktan hesapla
    final numberOfDays = endDate.difference(startDate).inDays + 1;

    List<FlSpot> spots = [];
    double minY = 0;
    double maxY = 100; // Varsayılan
    double? targetLineY;

    // X ekseni için tarihleri map edelim (0'dan numberOfDays-1'e)
    // Her zaman 0'dan başlasın ve gün sayısına göre scale edilsin
    Map<int, DateTime> dateMap = {};
    for (int i = 0; i < numberOfDays; i++) {
      dateMap[i] = startDate.add(Duration(days: i));
    }

    // Günlük bir debug log ekleyelim
    debugPrint(
        "[GoalTracking] Grafik oluşturuluyor: Tür=$_selectedTrackingType, Aralık=$_selectedRange, Günler=$numberOfDays");
    debugPrint(
        "[GoalTracking] WeightData: ${_weightLogData.length} kayıt, WaterData: ${_waterLogData.length} kayıt");
    debugPrint(
        "[GoalTracking] CalorieData: ${_calorieData.length} kayıt, ActivityData: ${_activityData.length} kayıt");

    // Verileri filtrele ve spotları oluştur
    switch (_selectedTrackingType) {
      case TrackingType.water:
        targetLineY = (_getWaterTarget(user)).toDouble();
        maxY = (targetLineY == 0 ? 2000 : targetLineY) *
            1.5; // Hedef yoksa varsayılan
        minY = 0;
        spots = _generateSpotsForGraph(dateMap, _waterLogData,
            (data, date) => data[date]?.toDouble() ?? 0);
        maxY = _calculateMaxYForGraph(spots, targetLineY, maxY);
        break;

      case TrackingType.weight:
        targetLineY = user.targetWeight?.toDouble();

        // WeightLogData'yı günlere göre organize edelim ve haritaya dönüştürelim
        Map<DateTime, double> dailyWeightValue = {};

        // Eğer kullanıcının mevcut kilosu varsa bugünün değeri olarak gösterelim
        if (user.weight != null) {
          final today = DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day);

          // _weightLogData içinde bugün için veri var mı kontrol edelim
          bool hasTodayRecord = _weightLogData.any((record) =>
              record.date.year == today.year &&
              record.date.month == today.month &&
              record.date.day == today.day);

          // Bugün için kayıt yoksa, mevcut kiloyu bugünün verisi olarak ekleyelim
          if (!hasTodayRecord) {
            dailyWeightValue[today] = user.weight!;
          }
        }

        // Tüm kayıtları günlere göre organize edelim
        for (final record in _weightLogData) {
          if (record.weight != null) {
            // Sadece tarih kısmını alalım (saat bilgisi olmadan)
            final dateKey =
                DateTime(record.date.year, record.date.month, record.date.day);
            dailyWeightValue[dateKey] = record.weight!;
          }
        }

        // Veri boşluklarını doldur (güncel değerleri koru)
        DateTime? lastDate;
        double? lastWeight;

        // Önce kayıtları sıralayalım (eski tarihten yeniye)
        final sortedDates = dailyWeightValue.keys.toList()
          ..sort((a, b) => a.compareTo(b));

        if (sortedDates.isNotEmpty) {
          lastDate = sortedDates.last;
          lastWeight = dailyWeightValue[lastDate];

          // Tarih aralığımızdaki her gün için veri olduğundan emin olalım
          for (int i = 0; i < numberOfDays; i++) {
            final currentDate = dateMap[i]!;

            // Zaten bu tarih için veri mevcutsa, bir şey yapmaya gerek yok
            if (dailyWeightValue.containsKey(currentDate)) {
              continue;
            }

            // Bu tarih eğer en son veri olan tarihten sonraysa, son veriyi kullan
            if (lastDate != null &&
                lastWeight != null &&
                currentDate.isAfter(lastDate)) {
              dailyWeightValue[currentDate] = lastWeight;
            }
            // Önceki tarihleri doldurmaya gerek yok, çizilmeyecekler
          }
        }

        spots = _generateSpotsForGraph(
            dateMap, dailyWeightValue, (data, date) => data[date]);

        // Min/Max Y ayarı - gerçek veriye göre
        if (spots.isNotEmpty) {
          double currentMinY = spots
              .where((s) => s.y != null)
              .map((s) => s.y!)
              .reduce((min, y) => y < min ? y : min);
          double currentMaxY = spots
              .where((s) => s.y != null)
              .map((s) => s.y!)
              .reduce((max, y) => y > max ? y : max);

          // Sınırları biraz genişlet
          minY = currentMinY - (currentMaxY - currentMinY) * 0.1;
          maxY = currentMaxY + (currentMaxY - currentMinY) * 0.1;

          // Minimum 1 kg fark olsun
          if (maxY - minY < 1) {
            minY = currentMinY - 0.5;
            maxY = currentMaxY + 0.5;
          }
        } else if (targetLineY != null) {
          minY = targetLineY - 5;
          maxY = targetLineY + 5;
        } else if (user.weight != null) {
          // Fallback
          minY = user.weight! - 5.0;
          maxY = user.weight! + 5.0;
        } else {
          minY = 50;
          maxY = 100;
        }

        // Target çizgisi görünür olsun diye min/max ayarla
        if (targetLineY != null) {
          if (targetLineY > maxY) maxY = targetLineY + (maxY - minY) * 0.1;
          if (targetLineY < minY) minY = targetLineY - (maxY - minY) * 0.1;
        }

        break;

      case TrackingType.calories:
        targetLineY = user.targetCalories?.toDouble();
        maxY = (targetLineY == 0 || targetLineY == null ? 2500 : targetLineY) *
            1.5; // Hedef yoksa varsayılan
        minY = 0;

        // Bugünün kalori verisini ekleyelim (eğer nutrition provider'daki güncel veriler varsa)
        Map<DateTime, NutritionSummary> updatedCalorieData =
            Map.from(_calorieData);

        // Bugünün beslenme verilerini alalım
        final todayNutrition = _getTodayNutrition();
        final today = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day);

        // Eğer bugün için veri varsa ve bu veri _calorieData içinde yoksa veya farklıysa ekleyelim
        if (todayNutrition.calories > 0 &&
            (!updatedCalorieData.containsKey(today) ||
                updatedCalorieData[today]?.calories !=
                    todayNutrition.calories)) {
          updatedCalorieData[today] = todayNutrition;
        }

        spots = _generateSpotsForGraph(dateMap, updatedCalorieData,
            (data, date) => data[date]?.calories ?? 0);
        maxY = _calculateMaxYForGraph(spots, targetLineY, maxY);
        break;

      case TrackingType.activity:
        debugPrint("🏃 Aktivite grafik verisi hazırlanıyor...");
        // Günlük aktivite hedefi (varsa) veya haftalık hedefin 7'ye bölümü
        double dailyTarget = (user.weeklyActivityGoal ?? 0) / 7.0;
        targetLineY = dailyTarget > 0 ? dailyTarget : null;
        debugPrint("   - Günlük hedef: $dailyTarget dk");

        maxY = (user.weeklyActivityGoal == null || user.weeklyActivityGoal == 0
            ? 180
            : user.weeklyActivityGoal! /
                7 *
                1.5); // Günlük ortalama hedefin 1.5 katı
        if (maxY < 60) maxY = 60; // Minimum 60 dk olsun
        minY = 0;

        // Mevcut _activityData'dan önce provider'dan güncel veriyi al
        final activityProvider =
            Provider.of<ActivityProvider>(context, listen: false);
        Map<DateTime, int> enhancedActivityData = Map.from(_activityData);

        debugPrint(
            "   - Mevcut _activityData kayıt sayısı: ${_activityData.length}");

        // ActivityProvider'dan güncel veriyi al ve entegre et
        try {
          final todayActivities =
              activityProvider.getAllActivities().where((activity) {
            final activityDate = DateTime(
                activity.date.year, activity.date.month, activity.date.day);
            final today = DateTime(
                DateTime.now().year, DateTime.now().month, DateTime.now().day);
            return activityDate.isAtSameMomentAs(today);
          }).toList();

          if (todayActivities.isNotEmpty) {
            final todayTotal = todayActivities.fold<int>(
                0, (sum, activity) => sum + activity.durationMinutes);
            final today = DateTime(
                DateTime.now().year, DateTime.now().month, DateTime.now().day);
            enhancedActivityData[today] = todayTotal;
            debugPrint("   - Bugünün toplam aktivitesi: $todayTotal dk");
          }
        } catch (e) {
          debugPrint("   - ActivityProvider'dan veri alınırken hata: $e");
        }

        debugPrint(
            "   - Geliştirilmiş activityData kayıt sayısı: ${enhancedActivityData.length}");

        List<FlSpot> activitySpots = [];

        // dateMap sistemi yerine daha geniş tarih aralığı kullanalım
        final startDate =
            DateTime.now().subtract(Duration(days: numberOfDays ~/ 2));
        final endDate = DateTime.now().add(Duration(days: numberOfDays ~/ 2));

        debugPrint("🗓️ Grafik tarih aralığı: $startDate - $endDate");

        for (int i = 0; i < numberOfDays; i++) {
          final date = startDate.add(Duration(days: i));
          final dateKey = DateTime(date.year, date.month, date.day);

          // Hem mevcut verileri hem de gelecek verileri kontrol et
          double value = 0.0;

          // Activity data'dan kontrol et
          if (enhancedActivityData.containsKey(dateKey)) {
            value = enhancedActivityData[dateKey]!.toDouble();
          }

          if (value > 0) {
            activitySpots.add(FlSpot(i.toDouble(), value));
            debugPrint(
                "   - Gün $i (${dateKey.toString().split(' ')[0]}): $value dk");
          }
        }
        spots = activitySpots;

        debugPrint("   - Toplam grafik noktası: ${spots.length}");

        maxY = _calculateMaxYForGraph(spots, targetLineY, maxY);
        break;
    }

    // Grafiği çizmek için en az 1 nokta yeterli olabilir mi? Test edelim.
    // Kilo için null değerler de dahil edildiği için farklı kontrol
    final bool hasEnoughData = (_selectedTrackingType == TrackingType.weight &&
            spots.any((s) => s.y != null)) ||
        (_selectedTrackingType != TrackingType.weight && spots.length >= 1);

    if (!hasEnoughData) {
      return _buildEmptyDataPlaceholder("Grafik çizmek için yeterli veri yok.");
    }

    LineChartBarData lineChartBarData = LineChartBarData(
      spots: spots.where((s) => s.y != null).toList(), // null olmayanları çiz
      isCurved: true,
      gradient: LinearGradient(
        colors: [
          _getChartColor(_selectedTrackingType).withValues(alpha: 0.5),
          _getChartColor(_selectedTrackingType),
        ],
      ),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData:
          FlDotData(show: spots.length < 20), // Çok veri varsa noktaları gizle
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            _getChartColor(_selectedTrackingType).withValues(alpha: 0.3),
            _getChartColor(_selectedTrackingType).withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );

    return Container(
      height: 300, // Sabit yükseklik
      padding: const EdgeInsets.only(
          top: 16, right: 16, bottom: 12), // Alt padding eklendi
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxY > minY)
                ? (maxY - minY) / 4
                : 10, // Sıfır aralığını kontrol et
            verticalInterval: (numberOfDays / 6.0)
                .ceilToDouble(), // Dikey çizgi aralığını dinamik yap
            getDrawingHorizontalLine: (value) {
              return FlLine(
                  color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1);
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                  color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30, // Yer ayır
                interval: (numberOfDays / 6.0)
                    .ceilToDouble(), // Etiket aralığını dinamik yap
                getTitlesWidget: (value, meta) =>
                    _buildBottomTitles(value, meta, dateMap, numberOfDays),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: _buildLeftTitles,
                reservedSize: 42, // Yer ayır
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          lineBarsData: [lineChartBarData],
          // Hedef çizgisi
          extraLinesData: targetLineY == null
              ? null
              : ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: targetLineY,
                      color: _getChartColor(_selectedTrackingType)
                          .withValues(alpha: 0.8),
                      strokeWidth: 2,
                      dashArray: [5, 5], // Kesikli çizgi
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 5, bottom: 2),
                        style: TextStyle(
                          color: _getChartColor(_selectedTrackingType),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        labelResolver: (line) => 'Hedef',
                      ),
                    ),
                  ],
                ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots
                    .map((LineBarSpot touchedSpot) {
                      if (touchedSpot.spotIndex < 0 ||
                          touchedSpot.spotIndex >=
                              touchedSpot.bar.spots.length) {
                        return null;
                      }
                      final flSpot =
                          touchedSpot.bar.spots[touchedSpot.spotIndex];
                      if (flSpot == null || flSpot.y == null) {
                        return null;
                      }
                      DateTime? date = dateMap[flSpot.x.toInt()];
                      if (date == null) return null;

                      String dateStr =
                          DateFormat('d MMM yyyy', 'tr_TR').format(date);
                      String valueStr;
                      switch (_selectedTrackingType) {
                        case TrackingType.water:
                          valueStr = '${flSpot.y!.toInt()} ml';
                          break;
                        case TrackingType.weight:
                          valueStr = '${flSpot.y!.toStringAsFixed(1)} kg';
                          break;
                        case TrackingType.calories:
                          valueStr = '${flSpot.y!.toInt()} kcal';
                          break;
                        case TrackingType.activity:
                          valueStr = '${flSpot.y!.toInt()} dk';
                          break;
                      }
                      return LineTooltipItem(
                        valueStr,
                        TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                        children: [
                          TextSpan(
                            text: '\n$dateStr',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12),
                          ),
                        ],
                        textAlign: TextAlign.center,
                      );
                    })
                    .whereNotNull()
                    .toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }

  // Yardımcı: Grafik için Spot listesi oluşturma (null değerleri atlayabilir)
  List<FlSpot> _generateSpotsForGraph<T>(
      Map<int, DateTime> dateMap,
      Map<DateTime, T> data,
      double? Function(Map<DateTime, T>, DateTime) valueExtractor) {
    List<FlSpot> spots = [];
    for (int i = 0; i < dateMap.length; i++) {
      final date = dateMap[i]!;
      // Veri map'indeki anahtarın da sadece tarih kısmı olmalı (saatsiz)
      final dateKey = DateTime(date.year, date.month, date.day);
      final value = valueExtractor(data, dateKey); // dateKey ile ara
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value.toDouble()));
      }
      // Null değerler için FlSpot(i.toDouble(), null) eklemiyoruz, grafik bunları çizmez.
      // Kilo için özel mantık _buildGraphViewFiltered içinde halledildi.
    }
    return spots;
  }

  // Yardımcı: Grafik için Maksimum Y değerini hesaplama
  double _calculateMaxYForGraph(
      List<FlSpot> spots, double? targetLineY, double defaultMax) {
    double maxSpotY = spots.map((s) => s.y ?? 0).fold(
        0.0, (prev, element) => element > prev ? element : prev); // Null check
    double potentialMax = maxSpotY;
    if (targetLineY != null && targetLineY > potentialMax) {
      potentialMax = targetLineY;
    }
    // Max değeri çok küçükse veya 0 ise default kullan, yoksa %20 pay ekle
    return (potentialMax < 10 ? defaultMax : potentialMax * 1.2);
  }

  // Grafik Renklerini Döndür
  Color _getChartColor(TrackingType type) {
    switch (type) {
      case TrackingType.water:
        return AppTheme.waterReminderColor;
      case TrackingType.weight:
        return AppTheme.categoryWorkoutColor;
      case TrackingType.calories:
        return AppTheme.lunchColor;
      case TrackingType.activity:
        return AppTheme.eveningExerciseColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  // Grafiğin Alt Başlıkları (X Ekseni - Tarihler)
  Widget _buildBottomTitles(double value, TitleMeta meta,
      Map<int, DateTime> dateMap, int numberOfDays) {
    final style = TextStyle(
      color: Theme.of(context)
          .textTheme
          .bodySmall
          ?.color
          ?.withValues(alpha: 0.7), // Tema rengi
      fontWeight: FontWeight.normal, // Normal yaptık
      fontSize: 10,
    );
    Widget text = const Text('');
    int index = value.toInt();

    // Çok fazla günü tek seferde göstermek yerine aralıklarla gösterelim
    // Yaklaşık 5-7 etiket sığdırmaya çalışalım
    int interval = (numberOfDays / 6.0).ceil();
    // İlk ve son etiketi her zaman gösterelim
    if (index >= 0 &&
        index < dateMap.length &&
        (index % interval == 0 || index == dateMap.length - 1 || index == 0)) {
      DateTime? date = dateMap[index];
      if (date != null) {
        // Aralığa göre formatı ayarla
        String format;
        if (numberOfDays > 90) {
          // 3 Ay veya Yıl ise sadece Ay
          format = 'MMM'; // Örn: Oca, Şub
        } else if (numberOfDays > 7) {
          // Ay ise Gün.Ay
          format = 'd.MM'; // Örn: 15.01
        } else {
          // Hafta ise sadece Gün
          format = 'd'; // Örn: 15
        }
        // Ayın ilk günü ise Ay adını da göster (Hafta hariç)
        if (date.day == 1 && numberOfDays > 7) {
          format = 'd MMM'; // Örn: 1 Oca
        }

        text = Text(DateFormat(format, 'tr_TR').format(date), style: style);
      }
    }

    // SideTitleWidget yerine doğrudan Text döndürerek meta parametresi sorununu aşmayı deniyoruz.
    // Eğer SideTitleWidget'ın space gibi özelliklerine ihtiyaç varsa, Text widget'ı Padding ile sarılabilir.
    // return SideTitleWidget(
    //   space: 8.0,
    //   child: text,
    // );
    return text; // text zaten bir Widget (Text widget'ı)
  }

  // Grafiğin Sol Başlıkları (Y Ekseni - Değerler)
  Widget _buildLeftTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Theme.of(context)
          .textTheme
          .bodySmall
          ?.color
          ?.withValues(alpha: 0.7), // Tema rengi
      fontWeight: FontWeight.normal,
      fontSize: 10,
    );

    // Değeri okunabilir formata getir
    String text;
    // Çok küçük veya çok büyük değerlerde okunaksızlığı önle
    if (value == meta.min || value == meta.max) {
      // Kilo için ondalık göster
      if (_selectedTrackingType == TrackingType.weight) {
        text = value.toStringAsFixed(1); // Bir ondalık
      } else if (value >= 1000) {
        // 1000 ve üzeri için 'k'
        text = '${(value / 1000).toStringAsFixed(value % 1000 != 0 ? 1 : 0)}k';
      } else {
        text = value.toInt().toString(); // Tam sayı göster
      }
    } else {
      // Ara değerleri göstermeyebiliriz veya daha az sıklıkta gösterebiliriz
      // Şimdilik boş bırakalım
      text = '';
      // Veya aralığa göre göster:
      // final interval = meta.appliedInterval;
      // if(value % interval == 0) { text = value.toInt().toString(); } else { text = '';}
    }

    return Text(text, style: style, textAlign: TextAlign.right); // Sağa yaslı
  }

  // --- Yardımcı Hesaplama Metotları (Güncellemeler) ---
  double _calculateWaterProgress(UserModel user) {
    final waterTarget = _getWaterTarget(user);
    final currentWater = _getTodayWater();
    return waterTarget > 0 ? (currentWater / waterTarget).clamp(0.0, 1.0) : 0.0;
  }

  // Bugün içilen suyu _waterLogData'dan alır
  int _getTodayWater() {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return _waterLogData[today] ?? 0;
  }

  // Hedef suyu L cinsinden alır, ml'ye çevirir
  int _getWaterTarget(UserModel user) {
    return ((user.targetWaterIntake ?? 0) * 1000).toInt();
  }

  // Kilo ilerlemesi (ilk kayda veya başlangıca göre)
  double _calculateWeightProgress(UserModel user) {
    final currentWeight = user.weight ?? 0;
    final targetWeight = user.targetWeight ?? 0;
    if (targetWeight == 0) return 0.0;

    // İlk kilo kaydını _weightLogData'dan al (liste zaten sıralı)
    final firstWeightRecord =
        _weightLogData.firstWhereOrNull((r) => r.weight != null);
    // Başlangıç ağırlığı olarak ilk kaydı veya mevcut ağırlığı kullan
    final initialWeight = firstWeightRecord?.weight ?? currentWeight;

    if (initialWeight == 0) return 0.0;

    // Kilo verme veya alma hedefine göre ilerleme
    if (targetWeight >= initialWeight) {
      // Kilo alma hedefi
      final totalWeightToGain = targetWeight - initialWeight;
      if (totalWeightToGain <= 0)
        return currentWeight >= targetWeight
            ? 1.0
            : 0.0; // Zaten hedefte veya üstünde
      final gainedWeight = currentWeight - initialWeight;
      return (gainedWeight / totalWeightToGain).clamp(0.0, 1.0);
    } else {
      // Kilo verme hedefi
      final totalWeightToLose = initialWeight - targetWeight;
      if (totalWeightToLose <= 0)
        return currentWeight <= targetWeight
            ? 1.0
            : 0.0; // Zaten hedefte veya altında
      final lostWeight = initialWeight - currentWeight;
      return (lostWeight / totalWeightToLose).clamp(0.0, 1.0);
    }
  }

  double _calculateActivityProgress(UserModel user) {
    final weeklyActivityTarget = user.weeklyActivityGoal?.toInt() ?? 0;
    final totalWeeklyActivity = _getTotalWeeklyActivity();
    return weeklyActivityTarget > 0
        ? (totalWeeklyActivity / weeklyActivityTarget).clamp(0.0, 1.0)
        : 0.0;
  }

  // Son 7 günün aktivitesini hesapla
  int _getTotalWeeklyActivity() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final oneWeekAgo =
        today.subtract(const Duration(days: 6)); // Bugün dahil 7 gün
    int totalMinutes = 0;

    _activityData.forEach((date, minutes) {
      final loopDateKey =
          DateTime(date.year, date.month, date.day); // Sadece tarih kısmı
      if (!loopDateKey.isBefore(oneWeekAgo) && !loopDateKey.isAfter(today)) {
        totalMinutes += minutes;
      }
    });
    return totalMinutes;
  }

  // Bugünün besin özetini al
  NutritionSummary _getTodayNutrition() {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    // _calorieData map'inden bugünün anahtarını kullanarak veriyi al
    final todayData = _calorieData[today];

    if (todayData == null) {
      // Eğer veri yoksa, beslenme sayfasından gelen verileri kullan
      final nutritionProvider =
          Provider.of<NutritionProvider>(context, listen: false);
      final todayMeals = nutritionProvider.getMealsForDate(today);

      if (todayMeals.isEmpty) {
        return NutritionSummary(); // Hiç veri yoksa boş özet dön
      }

      // Beslenme sayfasındaki öğünlerden toplam değerleri hesapla
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final meal in todayMeals) {
        totalCalories += meal.calories ?? 0;
        totalProtein += meal.proteinGrams ?? 0;
        totalCarbs += meal.carbsGrams ?? 0;
        totalFat += meal.fatGrams ?? 0;
      }

      return NutritionSummary(
        calories: totalCalories,
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat,
      );
    }

    return todayData;
  }

  // --- YARDIMCI WIDGET'LAR (Ana Hedefler ve Beslenme Kartları için) ---

  // Gradyan arkaplanı olan kart tasarımı (Tekrar kullanılabilir)
  Widget _buildCardWithGradient({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required Widget child,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Kartlar arası boşluk
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Hafif gölge
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: LinearGradient(
          // Arka plan rengi
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  AppTheme.darkCardBackgroundColor,
                  AppTheme.darkCardBackgroundColor.withValues(alpha: 0.8),
                ]
              : [Colors.white, Colors.white],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık kısmı - gradyan arka planlı
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // İçerik kısmı
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: child,
          ),
        ],
      ),
    );
  }

  // İlerleme çubuğu ile görev öğesi
  Widget _buildProgressItem({
    required String title,
    required IconData icon,
    required Color iconColor,
    required double progress,
    required String value,
    required bool isDarkMode,
    bool isReverse = false, // Kilo verme gibi ters ilerlemeler için
  }) {
    // İlerleme rengini belirle
    Color progressColor = iconColor;
    if (isReverse && progress < 1.0) {
      // Kilo verme hedefi ve henüz tamamlanmamışsa
      // Hedeften ne kadar uzaklaşıldığına göre renk değişimi yapılabilir
      // Şimdilik sadece hedefe yaklaşınca renk değişimi yapalım
      progressColor = progress > 0.5
          ? Colors.orangeAccent
          : Colors.redAccent; // Örnek renkler
    } else if (!isReverse && progress < 0.5) {
      // Normal hedef ve yarının altındaysa
      // progressColor = iconColor.withValues(alpha:0.7); // Daha soluk
    }
    // Hedefe ulaşıldıysa veya geçildiyse
    if (progress >= 1.0) {
      progressColor = Colors.green; // Yeşil renk
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.isNaN ? 0 : progress, // NaN kontrolü
          backgroundColor: iconColor.withValues(alpha: 0.2),
          color: progressColor, // Dinamik renk
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  // Beslenme istatistiği gösterim tasarımı
  Widget _buildNutritionStatNew({
    required String title,
    required IconData icon,
    required int current,
    required int target,
    required String unit,
    required Color color,
    required bool isDarkMode,
  }) {
    final progress = (target > 0)
        ? (current / target).clamp(0.0, 1.5)
        : 0.0; // 1.5'e kadar gitsin (aşımı göstermek için)
    final bool exceeded = progress > 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Ortala
        children: [
          // İkon ve Başlık
          Row(
            mainAxisSize: MainAxisSize.min, // İçeriğe göre boyutlan
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Padding'i azalttık
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15), // Biraz daha belirgin
                  borderRadius: BorderRadius.circular(8), // Daha az yuvarlak
                ),
                child: Icon(icon, color: color, size: 16), // İkonu küçülttük
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14, // Yazıyı küçülttük
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10), // Boşluğu azalttık
          // Mevcut / Hedef Değer
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Ortala
            crossAxisAlignment: CrossAxisAlignment.baseline, // Baseline hizala
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$current',
                style: TextStyle(
                  fontSize: 20, // Boyutu azalttık
                  fontWeight: FontWeight.bold,
                  color: exceeded
                      ? Colors.redAccent
                      : Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color, // Aşım varsa kırmızı
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '/',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '$target',
                style: TextStyle(
                  fontSize: 14, // Hedefi küçülttük
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit, // Birimi sona ekle
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // İlerleme Çubuğu
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0), // Gösterge 1.0'ı geçmesin
            backgroundColor: color.withValues(alpha: 0.2),
            color: exceeded
                ? Colors.redAccent.withValues(alpha: 0.8)
                : color, // Aşım varsa kırmızı
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}
