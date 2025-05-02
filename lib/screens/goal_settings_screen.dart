import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart'; // UserProvider'a erişim için eklendi
import '../utils/animations.dart'; // Animasyonlar için eklendi (gerekirse)
import '../models/user_model.dart'; // UserModel'i kullanmak için eklendi
import 'package:flutter/services.dart'; // Sayısal giriş için
import '../theme.dart'; // AppTheme renkleri için eklendi
import '../services/database_service.dart'; // DatabaseService'e erişim için eklendi

class GoalSettingsScreen extends StatefulWidget {
  const GoalSettingsScreen({Key? key}) : super(key: key);

  @override
  State<GoalSettingsScreen> createState() => _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends State<GoalSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nutritionTargetsFormKey =
      GlobalKey<FormState>(); // Beslenme formu için ayrı key
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _targetWeightController =
      TextEditingController(); // Hedef Kilo için
  final TextEditingController _waterIntakeController =
      TextEditingController(); // Yeni: Su hedefi için
  final TextEditingController _weeklyActivityGoalController =
      TextEditingController(); // Yeni: Haftalık aktivite hedefi için

  // Beslenme Hedefleri Controller'ları (settings_screen'den taşındı)
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  // Yeni: Dropdown'lar için state değişkenleri
  double? _selectedWeeklyGoal;
  String? _selectedActivityLevel;
  String? _selectedGender =
      'Erkek'; // Yeni: Cinsiyet seçimi için varsayılan değer

  // Yeni: Dropdown seçenekleri
  final List<double> _weeklyGoalOptions = [
    -1.0,
    -0.75,
    -0.5,
    -0.25,
    0.0,
    0.25,
    0.5,
    0.75,
    1.0
  ];
  final List<String> _activityLevelOptions = [
    'Hareketsiz',
    'Az Aktif',
    'Orta Aktif',
    'Çok Aktif',
    'Ekstra Aktif'
  ];
  final List<String> _genderOptions = [
    'Erkek',
    'Kadın'
  ]; // Yeni: Cinsiyet seçenekleri

  double _bmi = 0;
  String _bmiCategory = '';
  bool _isLoading = false; // Veri kaydetme/yükleme durumu için

  bool _autoCalculateNutrition = false; // Otomatik makro hesaplama state'i

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Başlangıçta verileri yükle
    // Değişiklikleri dinle ve BMI'ı yeniden hesapla
    _heightController.addListener(_calculateBMI);
    _weightController.addListener(_calculateBMI);
  }

  @override
  void dispose() {
    _heightController.removeListener(_calculateBMI);
    _weightController.removeListener(_calculateBMI);
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _waterIntakeController.dispose();
    _weeklyActivityGoalController.dispose(); // Yeni: Dispose eklendi
    // Beslenme controller'ları dispose et
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  // Kullanıcı verilerini UserProvider'dan yükle (Beslenme hedefleri eklendi)
  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user != null) {
      setState(() {
        // Vücut Bilgileri
        _heightController.text = user.height.toString();
        _weightController.text = user.weight.toString();
        _ageController.text = user.age.toString(); // YENİ: Yaşı yükle
        _targetWeightController.text = user.targetWeight?.toString() ?? '';
        _selectedWeeklyGoal = user.weeklyWeightGoal;
        _selectedActivityLevel =
            user.activityLevel ?? 'Orta Aktif'; // Varsayılan ata
        _selectedGender = user.gender ?? 'Erkek'; // YENİ: Cinsiyeti yükle
        _waterIntakeController.text = user.targetWaterIntake?.toString() ?? '';
        _weeklyActivityGoalController.text =
            user.weeklyActivityGoal?.toString() ?? '150'; // Varsayılan 150 dk

        // Beslenme Hedefleri (settings_screen'den taşındı)
        _caloriesController.text =
            user.targetCalories?.toStringAsFixed(0) ?? '';
        _proteinController.text = user.targetProtein?.toStringAsFixed(0) ?? '';
        _carbsController.text = user.targetCarbs?.toStringAsFixed(0) ?? '';
        _fatController.text = user.targetFat?.toStringAsFixed(0) ?? '';
        _autoCalculateNutrition = user.autoCalculateNutrition; // YENİ: Yükle

        _calculateBMI();
      });
    }
    print(
        "[GoalSettings] Kullanıcı verileri yüklendi: ActivityLevel=${_selectedActivityLevel}, Gender=${_selectedGender}, AutoCalc=${_autoCalculateNutrition}"); // Debug log
  }

  // BMI Hesaplama (profile_screen.dart'tan taşındı)
  void _calculateBMI() {
    try {
      // Boş değer kontrolü eklendi
      if (_weightController.text.isEmpty || _heightController.text.isEmpty) {
        setState(() {
          _bmi = 0;
          _bmiCategory = '';
        });
        return;
      }
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);

      if (weight > 0 && height > 0) {
        final bmi = weight / ((height / 100) * (height / 100));
        setState(() {
          _bmi = bmi;
          _bmiCategory = _getBMICategory(bmi);
        });
      } else {
        setState(() {
          _bmi = 0;
          _bmiCategory = '';
        });
      }
    } catch (e) {
      // Geçersiz değerler için hesaplama yapma veya hata gösterme
      setState(() {
        _bmi = 0;
        _bmiCategory = '';
      });
    }
  }

  // BMI Kategori (profile_screen.dart'tan taşındı)
  String _getBMICategory(double bmi) {
    if (bmi <= 0) return ''; // Geçersiz BMI için boş string
    if (bmi < 18.5) {
      return "Zayıf";
    } else if (bmi < 25) {
      return "Normal";
    } else if (bmi < 30) {
      return "Fazla Kilolu";
    } else if (bmi < 35) {
      return "Obez (Sınıf I)";
    } else if (bmi < 40) {
      return "Obez (Sınıf II)";
    } else {
      return "Aşırı Obez (Sınıf III)";
    }
  }

  // BMI Renk (profile_screen.dart'tan taşındı)
  Color _getBMIColor(double bmi) {
    if (bmi <= 0) {
      return Colors.grey;
    } else if (bmi < 18.5) {
      return Colors.blue;
    } else if (bmi < 25) {
      return Colors.green;
    } else if (bmi < 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // YENİ: Harris-Benedict formülüne göre Bazal Metabolizma Hızını (BMR) hesapla
  // GÜNCELLEME: Mifflin-St Jeor formülü kullanılacak
  double _calculateBMR() {
    // Formül için gerekli değerleri al
    final double weight = double.tryParse(_weightController.text) ?? 0;
    final double height = double.tryParse(_heightController.text) ?? 0;
    final int age =
        int.tryParse(_ageController.text) ?? 0; // Yaş controller'dan alınacak
    final String gender = _selectedGender ?? 'Erkek';

    double bmr = 0;

    if (weight > 0 && height > 0 && age > 0) {
      // Mifflin-St Jeor Formülü
      if (gender == 'Erkek') {
        // Erkekler için: (10 × kilo) + (6.25 × boy) - (5 × yaş) + 5
        bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      } else {
        // Kadınlar için: (10 × kilo) + (6.25 × boy) - (5 × yaş) - 161
        bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      }
    }
    print("[GoalSettings] BMR Hesaplandı: $bmr"); // Debug log
    return bmr;
  }

  // YENİ: Aktivite seviyesine göre günlük kalori ihtiyacını hesapla (TDEE)
  double _calculateTDEE() {
    double bmr = _calculateBMR();
    if (bmr <= 0) return 0; // BMR hesaplanamadıysa TDEE 0 olur

    double activityMultiplier = 1.2; // Varsayılan (Hareketsiz)

    // Aktivite çarpanlarını belirle
    switch (_selectedActivityLevel) {
      case 'Hareketsiz':
        activityMultiplier = 1.2; // Az veya hiç egzersiz
        break;
      case 'Az Aktif':
        activityMultiplier = 1.375; // Hafif egzersiz (haftada 1-3 gün)
        break;
      case 'Orta Aktif':
        activityMultiplier = 1.55; // Orta egzersiz (haftada 3-5 gün)
        break;
      case 'Çok Aktif':
        activityMultiplier = 1.725; // Ağır egzersiz (haftada 6-7 gün)
        break;
      case 'Ekstra Aktif':
        activityMultiplier = 1.9; // Çok ağır egzersiz & fiziksel iş
        break;
    }
    double tdee = bmr * activityMultiplier;
    print(
        "[GoalSettings] TDEE Hesaplandı: $tdee (BMR: $bmr, Multiplier: $activityMultiplier)"); // Debug log
    return tdee;
  }

  // YENİ: Hedef kilo ve haftalık kilo değişimine göre günlük kalori hedefini hesapla
  // GÜNCELLEME: Hesaplama aynı kalıyor, isim daha açıklayıcı
  double _calculateTargetCaloriesBasedOnGoal() {
    double tdee = _calculateTDEE(); // Günlük enerji harcaması
    if (tdee <= 0) return 2000; // TDEE hesaplanamazsa varsayılan değer

    double weeklyGoalKg = _selectedWeeklyGoal ?? 0; // Haftalık kilo hedefi (kg)

    // 1 kg yağ yaklaşık 7700 kalori
    // Haftalık hedefi günlük kalori ayarlamasına çevir
    double dailyCalorieAdjustment = weeklyGoalKg * (7700 / 7);

    // TDEE + kalori ayarlaması (kilo verme hedefi için eksi, kilo alma hedefi için artı)
    double targetCalories = tdee + dailyCalorieAdjustment;

    // Minimum kalori sınırı (güvenli limitler)
    if ((_selectedGender == 'Erkek' && targetCalories < 1500) ||
        (_selectedGender == 'Kadın' && targetCalories < 1200)) {
      targetCalories = _selectedGender == 'Erkek' ? 1500 : 1200;
      print(
          "[GoalSettings] Minimum kalori limitine ulaşıldı: $targetCalories"); // Debug log
    }
    print(
        "[GoalSettings] Hedef Kalori Hesaplandı: $targetCalories (TDEE: $tdee, Adjustment: $dailyCalorieAdjustment)"); // Debug log
    return targetCalories;
  }

  // YENİ: Kalori hedefine göre makro besin hedeflerini hesapla
  // GÜNCELLEME: kalori.txt'deki oranlara göre hesaplama
  Map<String, double> _calculateMacroTargetsFromCalories(
      double targetCalories) {
    double weight = double.tryParse(_weightController.text) ?? 0;

    if (targetCalories <= 0 || weight <= 0) {
      print(
          "[GoalSettings] Makro hesaplama için geçersiz girdi (Kalori: $targetCalories, Kilo: $weight)"); // Debug log
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }

    // Protein: kilo × 2.2 gr (kalori.txt'den)
    double proteinGrams = weight * 2.2;
    double proteinCalories = proteinGrams * 4; // 1g protein = 4 kalori

    // Yağ: Günlük kalorinin %25'i (kalori.txt'den)
    double fatCalories = targetCalories * 0.25;
    double fatGrams = fatCalories / 9; // 1g yağ = 9 kalori

    // Karbonhidrat: Kalan kalori (kalori.txt'den)
    double carbCalories = targetCalories - proteinCalories - fatCalories;
    double carbGrams = carbCalories / 4; // 1g karbonhidrat = 4 kalori

    // Negatif karbonhidratı engelle (protein ve yağ çok yüksekse olabilir)
    if (carbGrams < 0) {
      print(
          "[GoalSettings] Karbonhidrat negatif çıktı, 0'a ayarlanıyor."); // Debug log
      carbGrams = 0;
    }

    print(
        "[GoalSettings] Makrolar Hesaplandı: P: ${proteinGrams.round()}g, C: ${carbGrams.round()}g, F: ${fatGrams.round()}g"); // Debug log
    return {
      'protein': proteinGrams,
      'carbs': carbGrams,
      'fat': fatGrams,
    };
  }

  // Beslenme hedeflerini otomatik hesapla
  void _autoCalculateTargets() {
    // 1. Adım: Hedef Kaloriyi Hesapla
    double targetCalories = _calculateTargetCaloriesBasedOnGoal();
    if (targetCalories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Hesaplama için boy, kilo, yaş ve cinsiyet bilgilerinizi kontrol edin')),
      );
      print(
          "[GoalSettings] Otomatik hesaplama başarısız: Hedef kalori <= 0"); // Debug log
      return;
    }

    // 2. Adım: Makroları Hesapla
    Map<String, double> macros =
        _calculateMacroTargetsFromCalories(targetCalories);

    setState(() {
      _caloriesController.text = targetCalories.round().toString();
      _proteinController.text = macros['protein']!.round().toString();
      _carbsController.text = macros['carbs']!.round().toString();
      _fatController.text = macros['fat']!.round().toString();

      // Aktivite seviyesine göre haftalık aktivite hedefini güncellemeye devam et
      /* Bu kısım kaldırılıyor
      if (_selectedActivityLevel == 'Hareketsiz') {
        _weeklyActivityGoalController.text = '90';
      } else if (_selectedActivityLevel == 'Az Aktif') {
        _weeklyActivityGoalController.text = '120';
      } else if (_selectedActivityLevel == 'Orta Aktif') {
        _weeklyActivityGoalController.text = '150';
      } else if (_selectedActivityLevel == 'Çok Aktif') {
        _weeklyActivityGoalController.text = '225';
      } else if (_selectedActivityLevel == 'Ekstra Aktif') {
        _weeklyActivityGoalController.text = '300';
      }
      */
      print(
          "[GoalSettings] Otomatik hesaplama tamamlandı ve alanlar güncellendi."); // Debug log
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hedef Ayarları'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        actions: [
          // AppBar'a kaydetme butonu ekliyoruz
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Hedefleri Kaydet',
            onPressed: _saveGoals,
          ),
        ],
      ),
      backgroundColor: isDarkMode
          ? AppTheme.darkBackgroundColor
          : const Color(0xFFF8F8FC), // Açık tema için arka plan rengi
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final user = userProvider.user;
            final isLoading =
                userProvider.isLoading; // UserProvider'ın kendi isLoading'i

            if (isLoading || user == null) {
              print("[GoalSettings Build] Kullanıcı yükleniyor veya null...");
              return const Center(child: CircularProgressIndicator());
            } else {
              print(
                  "[GoalSettings Build] Kullanıcı yüklendi, build devam ediyor.");
              // Kullanıcı yüklendiğinde asıl içeriği göster
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey, // Tüm formlar için tek bir anahtarı kullan
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vücut Bilgileri Başlık ve Kart
                      _buildSectionHeader(
                          'Vücut Bilgileri', Icons.person, isDarkMode),
                      _buildBodyInfoCard(isDarkMode, user),

                      const SizedBox(height: 24),

                      // Kilo ve Su Hedefleri Başlık ve Kart
                      _buildSectionHeader('Kilo ve Su Hedefleri',
                          Icons.monitor_weight, isDarkMode),
                      _buildWeightAndWaterCard(isDarkMode, user),

                      const SizedBox(height: 24),

                      // Aktivite Hedefleri Başlık ve Kart
                      _buildSectionHeader('Aktivite Hedefleri',
                          Icons.directions_run, isDarkMode),
                      _buildActivityGoalsCard(isDarkMode, user),

                      const SizedBox(height: 24),

                      // Beslenme Hedefleri Başlık ve Kart
                      _buildSectionHeader(
                          'Beslenme Hedefleri', Icons.restaurant, isDarkMode),
                      _buildNutritionTargetsCard(isDarkMode, user),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // Kart başlıkları için widget
  Widget _buildSectionHeader(String title, IconData icon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Vücut Bilgileri kartı
  Widget _buildBodyInfoCard(bool isDarkMode, UserModel? user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cinsiyet Seçimi - YENİ
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                  child: Text(
                    'Cinsiyet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                ToggleButtons(
                  onPressed: (int index) {
                    setState(() {
                      _selectedGender = index == 0 ? 'Erkek' : 'Kadın';
                      if (_autoCalculateNutrition) {
                        _autoCalculateTargets();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  selectedBorderColor: AppTheme.primaryColor,
                  selectedColor: Colors.white,
                  fillColor: AppTheme.primaryColor,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  constraints: const BoxConstraints(
                    minHeight: 36.0,
                    minWidth: 90.0,
                  ),
                  isSelected: [
                    _selectedGender == 'Erkek',
                    _selectedGender == 'Kadın',
                  ],
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Erkek'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Kadın'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Boy TextFormField
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Boy (cm)',
                prefixIcon: Icon(Icons.height),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen boyunuzu girin';
                }
                return null;
              },
              onChanged: (value) {
                if (_autoCalculateNutrition && value.isNotEmpty) {
                  _autoCalculateTargets();
                }
              },
            ),
            const SizedBox(height: 16),

            // Yaş TextFormField - Otomatik hesaplama için eklendi
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Yaş',
                prefixIcon: Icon(Icons.cake),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen yaşınızı girin';
                }
                return null;
              },
              onChanged: (value) {
                if (_autoCalculateNutrition && value.isNotEmpty) {
                  _autoCalculateTargets();
                }
              },
            ),
            const SizedBox(height: 16),

            // BMI Gösterimi
            if (_bmi > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getBMIColor(_bmi).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getBMIColor(_bmi).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Vücut Kitle İndeksi (BMI)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_bmi.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getBMIColor(_bmi),
                      ),
                    ),
                    Text(
                      _bmiCategory,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _getBMIColor(_bmi),
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

  // Kilo ve Su Hedefleri kartı
  Widget _buildWeightAndWaterCard(bool isDarkMode, UserModel? user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mevcut Kilo TextFormField
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Mevcut Kilo (kg)',
                prefixIcon: Icon(Icons.monitor_weight),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen kilonuzu girin';
                }
                return null;
              },
              onChanged: (value) {
                if (_autoCalculateNutrition && value.isNotEmpty) {
                  _autoCalculateTargets();
                }
              },
            ),
            const SizedBox(height: 16),

            // Hedef Kilo TextFormField
            TextFormField(
              controller: _targetWeightController,
              decoration: const InputDecoration(
                labelText: 'Hedef Kilo (kg)',
                prefixIcon: Icon(Icons.track_changes),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              validator: (value) {
                // Opsiyonel, boş olabilir
                return null;
              },
              onChanged: (value) {
                if (_autoCalculateNutrition &&
                    value.isNotEmpty &&
                    _weightController.text.isNotEmpty) {
                  _calculateWeeklyGoal();
                  if (_autoCalculateNutrition) {
                    _autoCalculateTargets();
                  }
                }
              },
            ),
            const SizedBox(height: 16),

            // Haftalık Kilo Hedefi Dropdown - Açıklamalı
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<double>(
                    value: _selectedWeeklyGoal,
                    decoration: const InputDecoration(
                      labelText: 'Haftalık Kilo Hedefi (kg)',
                      prefixIcon: Icon(Icons.trending_up),
                      border: OutlineInputBorder(),
                    ),
                    items: _weeklyGoalOptions.map((double value) {
                      String label;
                      if (value == 0) {
                        label = 'Kilonu Koru';
                      } else if (value < 0) {
                        label =
                            '${value.abs()} kg Ver (Yaklaşık ${(value * -7700).round()} kcal/hafta)';
                      } else {
                        label =
                            '$value kg Al (Yaklaşık ${(value * 7700).round()} kcal/hafta)';
                      }
                      return DropdownMenuItem<double>(
                        value: value,
                        child: Text(
                          label,
                          style: TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (double? newValue) {
                      setState(() {
                        _selectedWeeklyGoal = newValue;
                        if (_autoCalculateNutrition) {
                          _autoCalculateTargets();
                        }
                      });
                    },
                    isExpanded: true, // Etiketin sığması için
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Güvenli kilo kaybı/artışı hakkında bilgi
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.infoColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Güvenli kilo kaybı haftada 0.5-1 kg, kilo alma haftada 0.25-0.5 kg olmalıdır.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.infoColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Günlük Su Hedefi TextFormField
            TextFormField(
              controller: _waterIntakeController,
              decoration: const InputDecoration(
                labelText: 'Günlük Su Hedefi (litre)',
                prefixIcon: Icon(Icons.water_drop),
                helperText: 'Ortalama günlük su ihtiyacı 2-2.5 litre',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              validator: (value) {
                // Opsiyonel, boş olabilir
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // Aktivite Hedefleri kartı
  Widget _buildActivityGoalsCard(bool isDarkMode, UserModel? user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aktivite Seviyesi Dropdown - detaylı açıklamalar eklendi
            DropdownButtonFormField<String>(
              value: _selectedActivityLevel,
              decoration: const InputDecoration(
                labelText: 'Aktivite Seviyesi',
                prefixIcon: Icon(Icons.fitness_center),
                border: OutlineInputBorder(),
              ),
              // GÜNCELLEME: Seçenekleri _activityLevelOptions listesinden alalım
              items: _activityLevelOptions.map((String level) {
                String description;
                switch (level) {
                  case 'Hareketsiz':
                    description = ' (Egzersiz yok)';
                    break;
                  case 'Az Aktif':
                    description = ' (Haftada 1-3 gün egzersiz)';
                    break;
                  case 'Orta Aktif':
                    description = ' (Haftada 3-5 gün egzersiz)';
                    break;
                  case 'Çok Aktif':
                    description = ' (Haftada 6-7 gün egzersiz)';
                    break;
                  case 'Ekstra Aktif':
                    description = ' (Çok ağır egzersiz/iş)';
                    break;
                  default:
                    description = '';
                }
                return DropdownMenuItem<String>(
                  value: level,
                  child: Text(level + description,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedActivityLevel = newValue;
                  // Aktivite seviyesine göre haftalık aktivite hedefini ayarla (Otomatikse)
                  if (_autoCalculateNutrition) {
                    if (newValue == 'Hareketsiz') {
                      _weeklyActivityGoalController.text = '90';
                    } else if (newValue == 'Az Aktif') {
                      _weeklyActivityGoalController.text = '120';
                    } else if (newValue == 'Orta Aktif') {
                      // 'Orta Derecede Aktif' yerine
                      _weeklyActivityGoalController.text = '150';
                    } else if (newValue == 'Çok Aktif') {
                      _weeklyActivityGoalController.text = '225';
                    } else if (newValue == 'Ekstra Aktif') {
                      _weeklyActivityGoalController.text = '300';
                    }
                    _autoCalculateTargets(); // Aktivite değişince kaloriyi de yeniden hesapla
                  }
                  print(
                      "[GoalSettings] Aktivite Seviyesi değişti: $newValue"); // Debug log
                });
              },
              isExpanded: true, // Açıklamaların sığması için
            ),
            const SizedBox(height: 8),
            // Aktivite seviyesi bilgi metni
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.infoColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aktivite seviyeniz günlük kalori ihtiyacınızı etkiler. Daha aktif bir yaşam tarzı, daha yüksek kalori ihtiyacı gerektirir.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.infoColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Haftalık Aktivite Hedefi TextFormField
            TextFormField(
              controller: _weeklyActivityGoalController,
              enabled:
                  !_autoCalculateNutrition, // Otomatik hesaplama kapalıysa düzenlenebilir
              decoration: const InputDecoration(
                labelText: 'Haftalık Aktivite Hedefi (dakika)',
                prefixIcon: Icon(Icons.timer),
                helperText: 'Dünya Sağlık Örgütü haftada en az 150 dk öneriyor',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen haftalık aktivite hedefinizi girin';
                }
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  // Türkçe karakterler yerine İngilizce karakterler kullanıldı
                  return 'Gecerli bir sure girin (0\'dan buyuk)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // Beslenme Hedefleri kartı
  Widget _buildNutritionTargetsCard(bool isDarkMode, UserModel? user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Otomatik Hesaplama Switch
            SwitchListTile(
              title: const Text('Otomatik Hesapla'),
              subtitle: const Text(
                'Aktivite seviyesi ve hedeflerinize göre beslenme hedeflerinizi hesaplayın',
              ),
              value: _autoCalculateNutrition,
              activeColor: AppTheme.primaryColor,
              contentPadding: EdgeInsets.zero,
              onChanged: (bool value) {
                setState(() {
                  _autoCalculateNutrition = value;
                  if (value) {
                    // Otomatik hesapla active ise hesapla
                    _autoCalculateTargets();
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Kalori Hedefi TextFormField
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Günlük Kalori Hedefi (kcal)',
                prefixIcon: Icon(Icons.local_fire_department),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              enabled:
                  !_autoCalculateNutrition, // Otomatik hesaplama açıksa devre dışı
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            // Kalori bilgi kutusu
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.infoColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Minimum güvenli günlük kalori alımı kadınlarda 1200 kcal, erkeklerde 1500 kcal olmalıdır.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.infoColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Protein Hedefi TextFormField
            TextFormField(
              controller: _proteinController,
              decoration: const InputDecoration(
                labelText: 'Günlük Protein Hedefi (g)',
                prefixIcon: Icon(Icons.egg_alt),
                helperText: 'Önerilen: Kg başına 1.6-2.2g protein',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              enabled: !_autoCalculateNutrition,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Karbonhidrat Hedefi TextFormField
            TextFormField(
              controller: _carbsController,
              decoration: const InputDecoration(
                labelText: 'Günlük Karbonhidrat Hedefi (g)',
                prefixIcon: Icon(Icons.grain),
                helperText: 'Toplam kalorinin %45-65\'i',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              enabled: !_autoCalculateNutrition,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Yağ Hedefi TextFormField
            TextFormField(
              controller: _fatController,
              decoration: const InputDecoration(
                labelText: 'Günlük Yağ Hedefi (g)',
                prefixIcon: Icon(Icons.opacity),
                helperText: 'Toplam kalorinin %20-35\'i',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              enabled: !_autoCalculateNutrition,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Beslenme bilgileri kutusu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Makro Besin Değerleri Hakkında',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Protein: Kas yapımı ve onarımı için gereklidir.\n'
                    '• Karbonhidrat: Ana enerji kaynağıdır.\n'
                    '• Yağ: Hormon üretimi ve vitamin emilimi için önemlidir.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kalori Eşdeğerleri:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '• 1g Protein = 4 kalori\n'
                    '• 1g Karbonhidrat = 4 kalori\n'
                    '• 1g Yağ = 9 kalori',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hedef kiloya göre haftalık hedefi öner
  void _calculateWeeklyGoal() {
    if (_weightController.text.isEmpty ||
        _targetWeightController.text.isEmpty) {
      return;
    }

    try {
      double currentWeight = double.parse(_weightController.text);
      double targetWeight = double.parse(_targetWeightController.text);
      double difference = targetWeight - currentWeight;

      // Hedef ağırlık aynıysa kilo koruma
      if (difference.abs() < 0.1) {
        setState(() {
          _selectedWeeklyGoal = 0.0;
        });
        return;
      }

      // Kilo kaybı
      if (difference < 0) {
        // Güvenli kilo kaybı haftada 0.5-1 kg
        if (difference.abs() <= 5) {
          setState(() {
            _selectedWeeklyGoal = -0.5; // Haftalık 0.5kg kayıp
          });
        } else {
          setState(() {
            _selectedWeeklyGoal =
                -0.75; // Haftalık 0.75kg kayıp (daha fazla verilecek)
          });
        }
      }
      // Kilo alma
      else {
        // Güvenli kilo alımı haftada 0.25-0.5 kg
        if (difference <= 5) {
          setState(() {
            _selectedWeeklyGoal = 0.25; // Haftalık 0.25kg alım
          });
        } else {
          setState(() {
            _selectedWeeklyGoal =
                0.5; // Haftalık 0.5kg alım (daha fazla alınacak)
          });
        }
      }
    } catch (e) {
      print("Haftalık hedef hesaplama hatası: $e");
    }
  }

  // Yaş controller ekliyoruz - yukarıdaki TextFormField'de kullanmak için
  final TextEditingController _ageController = TextEditingController();

  // Hedefleri kaydet ve UserModel'i güncelle
  // GÜNCELLEME: Silinmiş olan fonksiyonu yeniden ekliyorum
  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) {
      print(
          "[GoalSettings] Form geçerli değil, kaydetme iptal edildi."); // Debug log
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print("[GoalSettings] Hedefler kaydediliyor..."); // Debug log

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;

      if (currentUser == null) {
        print("[GoalSettings] Mevcut kullanıcı bulunamadı."); // Debug log
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce profil bilgilerinizi oluşturun')),
        );
        setState(() {
          _isLoading = false;
        }); // Yükleniyor durumunu kapat
        return;
      }

      // Form değerlerini al ve parse et
      final double height =
          double.tryParse(_heightController.text) ?? currentUser.height;
      final double weight =
          double.tryParse(_weightController.text) ?? currentUser.weight;
      final int age = int.tryParse(_ageController.text) ??
          currentUser.age; // Yaşı da alalım
      final double? targetWeight = _targetWeightController.text.isNotEmpty
          ? double.tryParse(_targetWeightController.text)
          : currentUser.targetWeight;
      final double? waterIntakeLiters = _waterIntakeController.text.isNotEmpty
          ? double.tryParse(
              _waterIntakeController.text) // Kullanıcı litre olarak giriyor
          : currentUser.targetWaterIntake;
      final double? weeklyActivityGoal =
          _weeklyActivityGoalController.text.isNotEmpty
              ? double.tryParse(_weeklyActivityGoalController.text)
              : currentUser.weeklyActivityGoal;

      // Beslenme değerlerini al (otomatik hesaplama kapalıysa buradan alır)
      final double? calories = _caloriesController.text.isNotEmpty
          ? double.tryParse(_caloriesController.text)
          : currentUser.targetCalories;
      final double? protein = _proteinController.text.isNotEmpty
          ? double.tryParse(_proteinController.text)
          : currentUser.targetProtein;
      final double? carbs = _carbsController.text.isNotEmpty
          ? double.tryParse(_carbsController.text)
          : currentUser.targetCarbs;
      final double? fat = _fatController.text.isNotEmpty
          ? double.tryParse(_fatController.text)
          : currentUser.targetFat;

      // Kullanıcı modelini güncelle
      final updatedUser = currentUser.copyWith(
        height: height,
        weight: weight,
        age: age, // Yaşı ekle
        targetWeight: targetWeight,
        weeklyWeightGoal: _selectedWeeklyGoal,
        activityLevel: _selectedActivityLevel,
        targetWaterIntake: waterIntakeLiters, // Litre olarak kaydet
        weeklyActivityGoal: weeklyActivityGoal,
        targetCalories: calories,
        targetProtein: protein,
        targetCarbs: carbs,
        targetFat: fat,
        autoCalculateNutrition: _autoCalculateNutrition, // YENİ: Kaydet
      );

      print(
          "[GoalSettings] Kaydedilecek Kullanıcı Verisi: ${updatedUser.toMap()}"); // Debug log

      // UserProvider ile kullanıcıyı güncelle
      await userProvider.saveUser(updatedUser);

      print("[GoalSettings] Kullanıcı başarıyla kaydedildi."); // Debug log

      // Kısa gecikme ekleyerek veritabanı işlemlerinin tamamlanmasını sağlayabiliriz
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hedefleriniz kaydedildi')),
        );
        Navigator.pop(context);
      }
    } catch (e, stacktrace) {
      // Hata ve stacktrace yakala
      print("Hedef kaydetme hatası: $e");
      print("Stacktrace: $stacktrace"); // Stacktrace'i yazdır
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print(
            "[GoalSettings] Kaydetme işlemi tamamlandı (finally bloğu)."); // Debug log
      }
    }
  }
}

// UserModel'de gender alanı olmadığını varsayarak ekliyorum.
// Eğer varsa bu kısım UserModel'e taşınmalı.
extension UserModelGender on UserModel {
  String? get gender => // Bu alanı UserModel'e ekleyin veya uygun yerden alın
      null;
}
