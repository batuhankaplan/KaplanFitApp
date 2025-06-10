import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart'; // UserProvider'a erişim için eklendi
import '../utils/animations.dart'; // Animasyonlar için eklendi (gerekirse)
import '../models/user_model.dart'; // UserModel'i kullanmak için eklendi
import 'package:flutter/services.dart'; // Sayısal giriş için
import '../theme.dart'; // AppTheme renkleri için eklendi
import '../services/database_service.dart'; // DatabaseService'e erişim için eklendi
import '../providers/gamification_provider.dart'; // GamificationProvider importu

class GoalSettingsScreen extends StatefulWidget {
  const GoalSettingsScreen({super.key}) ;

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
  String? _selectedGender;

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
  bool _isInitialLoad = true; // İlk yükleme kontrolü için

  // Geçici BMI state'leri, sadece anlık gösterim için
  double _currentBmiValue = 0.0;
  String _currentBmiCategory = "";

  @override
  void initState() {
    super.initState();
    // Listener'lar BMI için artık doğrudan _buildBodyInfoCard içinde veya onChanged ile yönetilecek.
    // _heightController.addListener(_calculateAndDisplayBMI); // KALDIRILDI
    // _weightController.addListener(_calculateAndDisplayBMI); // KALDIRILDI
    _ageController.addListener(_autoCalculateIfNeeded);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData().then((_) {
        if (mounted) {
          // mounted kontrolü eklendi
          setState(() {
            _isInitialLoad = false;
            // Kullanıcı verileri yüklendikten sonra BMI'yı hesapla ve göster
            _calculateAndDisplayBMI();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    // _heightController.removeListener(_calculateAndDisplayBMI); // KALDIRILDI
    // _weightController.removeListener(_calculateAndDisplayBMI); // KALDIRILDI
    _ageController.removeListener(_autoCalculateIfNeeded);
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _waterIntakeController.dispose();
    _weeklyActivityGoalController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // setState(() { _isLoading = true; }); // build içinde Consumer yönetiyor
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // if (userProvider.user == null && !_isInitialLoad) { // KALDIRILDI
    //   // _isInitialLoad sırasında zaten yükleniyor olabilir
    //   await userProvider.loadUser(); // KALDIRILDI
    // } // KALDIRILDI
    final user = userProvider.user;

    if (mounted) {
      setState(() {
        if (user != null) {
          _heightController.text = user.height?.toString() ?? '';
          _weightController.text = user.weight?.toString() ?? '';
          _ageController.text = user.age?.toString() ?? '';
          _targetWeightController.text = user.targetWeight?.toString() ?? '';
          _selectedWeeklyGoal = user.weeklyWeightGoal;
          _selectedActivityLevel = user.activityLevel;
          _selectedGender = user.gender;
          _waterIntakeController.text =
              user.targetWaterIntake?.toString() ?? '';
          _weeklyActivityGoalController.text =
              user.weeklyActivityGoal?.toString() ?? '';

          _caloriesController.text =
              user.targetCalories?.toStringAsFixed(0) ?? '';
          _proteinController.text =
              user.targetProtein?.toStringAsFixed(0) ?? '';
          _carbsController.text = user.targetCarbs?.toStringAsFixed(0) ?? '';
          _fatController.text = user.targetFat?.toStringAsFixed(0) ?? '';
          _autoCalculateNutrition = user.autoCalculateNutrition;

          // _calculateBMI(); // YENİ YAPI: _calculateAndDisplayBMI ile değiştirildi
          _calculateAndDisplayBMI(); // Yükleme sonrası BMI'yı hemen hesapla
          if (_autoCalculateNutrition &&
              _areRequiredFieldsFilledForAutoCalc()) {
            _autoCalculateNutritionTargets();
          }
        } else {
          _selectedGender = null;
          _selectedWeeklyGoal = null;
          _autoCalculateNutrition = false;
        }
        // _isLoading = false; // build içinde Consumer yönetiyor
      });
    }
    debugPrint(
        "[GoalSettings] Kullanıcı verileri yüklendi: ActivityLevel=$_selectedActivityLevel, Gender=$_selectedGender, WeeklyGoal=$_selectedWeeklyGoal, AutoCalc=$_autoCalculateNutrition");
  }

  // YENİ: BMI Hesaplama ve Gösterme Fonksiyonu (State Güncellemesi ile)
  void _calculateAndDisplayBMI() {
    final heightText = _heightController.text;
    final weightText = _weightController.text;

    if (heightText.isNotEmpty && weightText.isNotEmpty) {
      final double height = double.tryParse(heightText) ?? 0;
      final double weight = double.tryParse(weightText) ?? 0;

      if (height > 0 && weight > 0) {
        double bmi = weight / ((height / 100) * (height / 100));
        String category = "";
        Color color = Colors.grey;

        if (_selectedGender == 'Kadın') {
          if (bmi < 17.5) {
            category = 'Zayıf';
            color = Colors.blue;
          } else if (bmi < 23.5) {
            category = 'Normal';
            color = Colors.green;
          } else if (bmi < 28.5) {
            category = 'Kilolu';
            color = Colors.orange;
          } else {
            category = 'Obez';
            color = Colors.red;
          }
        } else {
          // Erkek veya belirtilmemişse
          if (bmi < 18.5) {
            category = 'Zayıf';
            color = Colors.blue;
          } else if (bmi < 25.0) {
            category = 'Normal';
            color = Colors.green;
          } else if (bmi < 30.0) {
            category = 'Kilolu';
            color = Colors.orange;
          } else {
            category = 'Obez';
            color = Colors.red;
          }
        }

        if (mounted) {
          setState(() {
            _currentBmiValue = bmi;
            _currentBmiCategory = category;
          });
        }
        _autoCalculateIfNeeded(); // BMI değiştiğinde besin ihtiyaçları da değişebilir.
      } else {
        if (mounted) {
          setState(() {
            _currentBmiValue = 0.0;
            _currentBmiCategory = "";
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _currentBmiValue = 0.0;
          _currentBmiCategory = "";
        });
      }
    }
  }

  // _calculateBMI, _getBMICategory, _getBMIColor fonksiyonları KALDIRILDI.
  // Yeni BMI mantığı _calculateAndDisplayBMI içinde ve _buildBodyInfoCard widget'ında olacak.

// ... (Mevcut _calculateBMR, _calculateTDEE, _adjustCaloriesForGoal, _autoCalculateNutritionTargets, _areRequiredFieldsFilledForAutoCalc, _calculateMacroTargetsFromCalories, _autoCalculateIfNeeded fonksiyonları burada kalacak)
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
    debugPrint("[GoalSettings] BMR Hesaplandı: $bmr"); // Debug log
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
    debugPrint(
        "[GoalSettings] TDEE Hesaplandı: $tdee (BMR: $bmr, Multiplier: $activityMultiplier)"); // Debug log
    return tdee;
  }

  // YENİ: Hedef kiloya göre kalori ayarlaması yap
  double _adjustCaloriesForGoal(double tdee) {
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
      debugPrint(
          "[GoalSettings] Minimum kalori limitine ulaşıldı: $targetCalories"); // Debug log
    }
    debugPrint(
        "[GoalSettings] Hedef Kalori Hesaplandı: $targetCalories (TDEE: $tdee, Adjustment: $dailyCalorieAdjustment)"); // Debug log
    return targetCalories;
  }

  // YENİ: Beslenme hedeflerini otomatik hesapla ve ilgili alanları doldur
  void _autoCalculateNutritionTargets() {
    // 1. Adım: Hedef Kaloriyi Hesapla
    double targetCalories = _adjustCaloriesForGoal(_calculateTDEE());
    if (targetCalories <= 0) {
      if (mounted) {
        // ScaffoldMessenger için mounted kontrolü
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Hesaplama için boy, kilo, yaş ve cinsiyet bilgilerinizi kontrol edin')),
        );
      }
      debugPrint("[GoalSettings] Otomatik hesaplama başarısız: Hedef kalori <= 0");
      return;
    }

    Map<String, double> macros =
        _calculateMacroTargetsFromCalories(targetCalories);

    if (mounted) {
      setState(() {
        _caloriesController.text = targetCalories.round().toString();
        _proteinController.text = macros['protein']!.round().toString();
        _carbsController.text = macros['carbs']!.round().toString();
        _fatController.text = macros['fat']!.round().toString();
        debugPrint(
            "[GoalSettings] Otomatik hesaplama tamamlandı ve alanlar güncellendi.");
      });
    }
  }

  bool _areRequiredFieldsFilledForAutoCalc() {
    return _weightController.text.isNotEmpty &&
        _heightController.text.isNotEmpty &&
        _ageController.text.isNotEmpty &&
        _selectedGender != null &&
        _selectedActivityLevel != null;
  }

  Map<String, double> _calculateMacroTargetsFromCalories(
      double targetCalories) {
    double weight = double.tryParse(_weightController.text) ?? 0;

    if (targetCalories <= 0 || weight <= 0) {
      debugPrint(
          "[GoalSettings] Makro hesaplama için geçersiz girdi (Kalori: $targetCalories, Kilo: $weight)");
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }

    double proteinGrams = weight * 2.2;
    double proteinCalories = proteinGrams * 4;

    double fatCalories = targetCalories * 0.25;
    double fatGrams = fatCalories / 9;

    double carbCalories = targetCalories - proteinCalories - fatCalories;
    double carbGrams = carbCalories / 4;

    if (carbGrams < 0) {
      debugPrint("[GoalSettings] Karbonhidrat negatif çıktı, 0\'a ayarlanıyor.");
      carbGrams = 0;
    }

    debugPrint(
        "[GoalSettings] Makrolar Hesaplandı: P: ${proteinGrams.round()}g, C: ${carbGrams.round()}g, F: ${fatGrams.round()}g");
    return {
      'protein': proteinGrams,
      'carbs': carbGrams,
      'fat': fatGrams,
    };
  }

  void _autoCalculateIfNeeded() {
    if (_autoCalculateNutrition && !_isInitialLoad) {
      if (_areRequiredFieldsFilledForAutoCalc()) {
        _autoCalculateNutritionTargets();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // final userProvider = Provider.of<UserProvider>(context); // Consumer içinde yönetiliyor
    // final user = userProvider.user; // Consumer içinde yönetiliyor
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
          IconButton(
            icon: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ))
                : const Icon(Icons.save),
            tooltip: 'Hedefleri Kaydet',
            onPressed: _isLoading ? null : _saveGoals,
          ),
        ],
      ),
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : const Color(0xFFF8F8FC),
      body: SafeArea(
        child: Consumer<UserProvider>(
          // UserProvider'ı burada dinleyelim
          builder: (context, userProvider, child) {
            final user = userProvider.user;
            // GoalSettingsScreen'in kendi _isLoading state'i var, onu kullanalım.
            // Provider'ın isLoading'i genel veri yükleme durumu için.
            // Sayfanın kendi içindeki _isLoading, _saveGoals sırasındaki yüklemeyi gösterir.
            // İlk yükleme için SplashScreen veya benzeri bir yapı daha uygun olabilir.
            // Şimdilik, user null ise veya _isInitialLoad true ise yükleme gösterelim.
            if (_isInitialLoad && user == null) {
              // userProvider.isLoading yerine _isInitialLoad
              debugPrint(
                  "[GoalSettings Build] İlk yükleme veya kullanıcı null, yükleniyor...");
              return const Center(child: CircularProgressIndicator());
            } else if (user == null && !_isInitialLoad) {
              debugPrint(
                  "[GoalSettings Build] Kullanıcı null ve ilk yükleme değil, profil oluşturmaya yönlendirilebilir veya hata mesajı gösterilebilir.");
              // return Center(child: Text("Kullanıcı bulunamadı. Lütfen profil oluşturun."));
              // Bu durumda SplashScreen'e geri dönmek veya bir hata mesajı göstermek daha iyi olabilir.
              // Şimdilik boş bir form gösterelim, _loadUserData'nın halletmesi beklenir.
              return _buildFormContent(
                  isDarkMode, null); // Kullanıcı null olsa da formu göster
            } else {
              debugPrint(
                  "[GoalSettings Build] Kullanıcı yüklendi veya form gösteriliyor.");
              return _buildFormContent(isDarkMode, user);
            }
          },
        ),
      ),
    );
  }

  Widget _buildFormContent(bool isDarkMode, UserModel? user) {
    // Bu fonksiyon build metodunun içindeki SingleChildScrollView ve sonrasını içerir.
    // _isInitialLoad false olduktan sonra bu widget çağrılır.
    // _loadUserData içinde user null ise bile controller'lar boş kalır,
    // _calculateAndDisplayBMI da _bmi ve _bmiCategory'yi sıfırlar.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Vücut Bilgileri', Icons.person, isDarkMode),
            _buildBodyInfoCard(isDarkMode, user), // user null olabilir
            const SizedBox(height: 24),
            _buildSectionHeader(
                'Kilo ve Su Hedefleri', Icons.monitor_weight, isDarkMode),
            _buildWeightAndWaterCard(isDarkMode, user), // user null olabilir
            const SizedBox(height: 24),
            _buildSectionHeader(
                'Aktivite Hedefleri', Icons.directions_run, isDarkMode),
            _buildActivityGoalsCard(isDarkMode, user), // user null olabilir
            const SizedBox(height: 24),
            _buildSectionHeader(
                'Beslenme Hedefleri', Icons.restaurant, isDarkMode),
            _buildNutritionTargetsCard(isDarkMode, user), // user null olabilir
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 28),
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

  Widget _buildBodyInfoCard(bool isDarkMode, UserModel? user) {
    // Anlık BMI değeri için yerel değişkenler veya doğrudan _currentBmiValue kullanılabilir.
    // Renk ve kategori de _calculateAndDisplayBMI içinde state'e set ediliyor.
    Color bmiColor = Colors.grey;
    if (_currentBmiValue > 0) {
      if (_selectedGender == 'Kadın') {
        if (_currentBmiValue < 17.5) {
          bmiColor = Colors.blue;
        } else if (_currentBmiValue < 23.5) {
          bmiColor = Colors.green;
        } else if (_currentBmiValue < 28.5) {
          bmiColor = Colors.orange;
        } else {
          bmiColor = Colors.red;
        }
      } else {
        if (_currentBmiValue < 18.5) {
          bmiColor = Colors.blue;
        } else if (_currentBmiValue < 25.0) {
          bmiColor = Colors.green;
        } else if (_currentBmiValue < 30.0) {
          bmiColor = Colors.orange;
        } else {
          bmiColor = Colors.red;
        }
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                  child: Text('Cinsiyet',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                ToggleButtons(
                  onPressed: (int index) {
                    setState(() {
                      _selectedGender = index == 0 ? 'Erkek' : 'Kadın';
                      _calculateAndDisplayBMI(); // Cinsiyet değişince BMI'yı yeniden hesapla
                      if (_autoCalculateNutrition) {
                        _autoCalculateNutritionTargets();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  selectedBorderColor: AppTheme.primaryColor,
                  selectedColor: Colors.white,
                  fillColor: AppTheme.primaryColor,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  constraints:
                      const BoxConstraints(minHeight: 36.0, minWidth: 90.0),
                  isSelected: [
                    _selectedGender == 'Erkek',
                    _selectedGender == 'Kadın'
                  ],
                  children: const [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Erkek')),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Kadın')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                if (value == null || value.isEmpty)
                  return 'Lütfen boyunuzu girin';
                return null;
              },
              onChanged: (value) {
                _calculateAndDisplayBMI(); // Boy değişince BMI'yı yeniden hesapla
                if (_autoCalculateNutrition && value.isNotEmpty) {
                  _autoCalculateNutritionTargets();
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              // Yaş controller'ı buraya eklendi
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
                // Yaş değişince otomatik besin hesaplamasını tetikle (BMI direkt etkilenmez ama TDEE etkilenir)
                _autoCalculateIfNeeded();
              },
            ),
            const SizedBox(height: 16),
            // YENİ BMI GÖSTERİMİ
            if (_currentBmiValue > 0)
              Container(width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bmiColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: bmiColor.withValues(alpha:0.5), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Vücut Kitle İndeksi (BMI)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: bmiColor),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentBmiValue.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: bmiColor),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentBmiCategory,
                          style: TextStyle(fontSize: 18, color: bmiColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedGender == 'Kadın'
                          ? 'Kadın BMI Aralıkları: Zayıf (<17.5), Normal (17.5-23.5), Kilolu (23.5-28.5), Obez (>28.5)'
                          : 'Erkek BMI Aralıkları: Zayıf (<18.5), Normal (18.5-25), Kilolu (25-30), Obez (>30)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

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
                _calculateAndDisplayBMI(); // Kilo değişince BMI'yı yeniden hesapla
                if (_autoCalculateNutrition && value.isNotEmpty) {
                  _autoCalculateNutritionTargets();
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
                    _autoCalculateNutritionTargets();
                  }
                } else if (value.isNotEmpty &&
                    _weightController.text.isNotEmpty) {
                  _calculateWeeklyGoal(); // Haftalık hedefi yine de hesapla
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
                            '${value.abs()} kg Ver'; // (Yaklaşık ${(value * -7700).round()} kcal/hafta)
                      } else {
                        label =
                            '$value kg Al'; //(Yaklaşık ${(value * 7700).round()} kcal/hafta)
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
                          _autoCalculateNutritionTargets();
                        }
                      });
                    },
                    isExpanded: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha:0.1),
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
            ),
          ],
        ),
      ),
    );
  }

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
            DropdownButtonFormField<String>(
              value: _selectedActivityLevel,
              decoration: const InputDecoration(
                labelText: 'Aktivite Seviyesi',
                prefixIcon: Icon(Icons.fitness_center),
                border: OutlineInputBorder(),
              ),
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
                  if (_autoCalculateNutrition) {
                    if (newValue == 'Hareketsiz')
                      _weeklyActivityGoalController.text = '90';
                    else if (newValue == 'Az Aktif')
                      _weeklyActivityGoalController.text = '120';
                    else if (newValue == 'Orta Aktif')
                      _weeklyActivityGoalController.text = '150';
                    else if (newValue == 'Çok Aktif')
                      _weeklyActivityGoalController.text = '225';
                    else if (newValue == 'Ekstra Aktif')
                      _weeklyActivityGoalController.text = '300';
                    _autoCalculateNutritionTargets();
                  }
                  debugPrint("[GoalSettings] Aktivite Seviyesi değişti: $newValue");
                });
              },
              isExpanded: true,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppTheme.infoColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aktivite seviyeniz günlük kalori ihtiyacınızı etkiler. Daha aktif bir yaşam tarzı, daha yüksek kalori ihtiyacı gerektirir.',
                      style: TextStyle(fontSize: 12, color: AppTheme.infoColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weeklyActivityGoalController,
              enabled: true,
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
                if (value == null || value.isEmpty)
                  return 'Lütfen haftalık aktivite hedefinizi girin';
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
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

  Widget _buildNutritionTargetsCard(bool isDarkMode, UserModel? user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _nutritionTargetsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Otomatik Hesapla'),
                subtitle: const Text(
                    'Aktivite seviyesi ve hedeflerinize göre beslenme hedeflerinizi hesaplayın'),
                value: _autoCalculateNutrition,
                activeColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.zero,
                onChanged: (bool value) {
                  setState(() {
                    _autoCalculateNutrition = value;
                    if (value) {
                      _autoCalculateNutritionTargets();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(
                  labelText: 'Günlük Kalori Hedefi (kcal)',
                  prefixIcon: Icon(Icons.local_fire_department),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                enabled: !_autoCalculateNutrition,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppTheme.infoColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: AppTheme.infoColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Minimum güvenli günlük kalori alımı kadınlarda 1200 kcal, erkeklerde 1500 kcal olmalıdır.',
                        style:
                            TextStyle(fontSize: 12, color: AppTheme.infoColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppTheme.primaryColor.withValues(alpha:0.1)
                      : AppTheme.primaryColor.withValues(alpha:0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.primaryColor.withValues(alpha:0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Makro Besin Değerleri Hakkında',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor)),
                    const SizedBox(height: 8),
                    Text(
                        '• Protein: Kas yapımı ve onarımı için gereklidir.\n'
                        '• Karbonhidrat: Ana enerji kaynağıdır.\n'
                        '• Yağ: Hormon üretimi ve vitamin emilimi için önemlidir.',
                        style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    Text('Kalori Eşdeğerleri:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                        '• 1g Protein = 4 kalori\n'
                        '• 1g Karbonhidrat = 4 kalori\n'
                        '• 1g Yağ = 9 kalori',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _calculateWeeklyGoal() {
    if (_weightController.text.isEmpty || _targetWeightController.text.isEmpty)
      return;
    try {
      double currentWeight = double.parse(_weightController.text);
      double targetWeight = double.parse(_targetWeightController.text);
      double difference = targetWeight - currentWeight;
      if (mounted) {
        // setState için mounted kontrolü
        setState(() {
          if (difference.abs() < 0.1)
            _selectedWeeklyGoal = 0.0;
          else if (difference < 0) {
            _selectedWeeklyGoal = (difference.abs() <= 5) ? -0.5 : -0.75;
          } else {
            _selectedWeeklyGoal = (difference <= 5) ? 0.25 : 0.5;
          }
        });
      }
    } catch (e) {
      debugPrint("Haftalık hedef hesaplama hatası: $e");
    }
  }

  // Yaş controller ekliyoruz - yukarıdaki TextFormField'de kullanmak için
  final TextEditingController _ageController = TextEditingController();

  // Hedefleri kaydet ve UserModel'i güncelle
  Future<void> _saveGoals() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        !_nutritionTargetsFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm gerekli alanları doldurun.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final gamificationProvider = Provider.of<GamificationProvider>(context,
        listen: false); // GamificationProvider'ı al
    final currentUser = userProvider.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mevcut kullanıcı bulunamadı.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Kullanıcı bilgilerini güncelle
      final updatedUser = currentUser.copyWith(
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        age: int.tryParse(_ageController.text),
        targetWeight: double.tryParse(_targetWeightController.text),
        weeklyWeightGoal: _selectedWeeklyGoal,
        activityLevel: _selectedActivityLevel,
        gender: _selectedGender,
        targetWaterIntake: double.tryParse(_waterIntakeController.text),
        weeklyActivityGoal: double.tryParse(_weeklyActivityGoalController.text),
        targetCalories: double.tryParse(_caloriesController.text),
        targetProtein: double.tryParse(_proteinController.text),
        targetCarbs: double.tryParse(_carbsController.text),
        targetFat: double.tryParse(_fatController.text),
        autoCalculateNutrition: _autoCalculateNutrition,
        // lastWeightUpdate, updateUser içinde otomatik olarak güncelleniyor
      );

      debugPrint("[GoalSettings] Hedefler kaydediliyor...");
      debugPrint(
          "[GoalSettings] Kaydedilecek Kullanıcı Verisi: ${updatedUser.toMap()}");

      await userProvider.saveUser(updatedUser);

      // Kilo verme rozetlerini kontrol et
      await gamificationProvider.checkWeightLossBadges(currentUser.id!);
      debugPrint("[GoalSettings] Kilo verme rozetleri kontrol edildi.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hedefler başarıyla kaydedildi!')),
        );
        // İsteğe bağlı: Bir önceki ekrana dön
        // Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint("[GoalSettings] Hedefler kaydedilirken hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hedefler kaydedilirken bir hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint("[GoalSettings] Kaydetme işlemi tamamlandı (finally bloğu).");
      }
    }
  }

  // _updateGender ve _buildGenderSelection fonksiyonları KALDIRILDI, ToggleButtons kullanılıyor.
}

// UserModelGender extension KALDIRILDI, UserModel içinde gender zaten var varsayılıyor.
// Eğer UserModel'de gender yoksa, UserModel tanımına eklenmeli.
// Varsayılan olarak UserModel'de String? gender; olduğu kabul edildi.



