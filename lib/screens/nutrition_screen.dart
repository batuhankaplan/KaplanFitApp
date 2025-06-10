import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/nutrition_provider.dart';
import '../theme.dart';
import '../models/task_type.dart';
import '../models/meal_record.dart';
import '../models/food_item.dart';
import '../utils/animations.dart';
import '../utils/show_dialogs.dart';
import '../widgets/kaplan_loading.dart';
import '../providers/user_provider.dart';
import '../services/database_service.dart';
import 'add_edit_food_screen.dart';
import 'dart:async';
import 'package:flutter/services.dart'; // InputFormatters için
import '../widgets/add_or_select_food_dialog.dart'; // YENİ Import
// import '../widgets/add_edit_meal_dialog.dart'; // Kaldırıldı

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  DateTime _selectedDate = DateTime.now();
  FitMealType _selectedMealType = FitMealType.breakfast;

  @override
  void initState() {
    super.initState();
    // İlk yükleme için verileri çek
    Future.microtask(() =>
        Provider.of<NutritionProvider>(context, listen: false).refreshMeals());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NutritionProvider>(context);
    final meals = provider.meals;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Tarih seçici
          KFSlideAnimation(
            offsetBegin: const Offset(0, -0.2),
            duration: const Duration(milliseconds: 500),
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDarkMode
                        ? const Color(0xFF2C2C2C)
                        : AppTheme.primaryColor.withValues(alpha: 0.7),
                    isDarkMode
                        ? const Color(0xFF1F1F1F)
                        : AppTheme.primaryColor,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Önceki gün
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    onPressed: () {
                      _changeDate(-1);
                    },
                  ),

                  // Seçilen tarih gösterimi
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('d MMMM yyyy', 'tr_TR')
                              .format(_selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sonraki gün
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      _changeDate(1);
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(),

          // Meals list
          Expanded(
            child: provider.isLoading
                ? const KaplanLoading()
                : meals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            KFWaveAnimation(
                              color: AppTheme.lunchColor.withValues(alpha: 0.3),
                              height: 100,
                            ),
                            const SizedBox(height: 16),
                            const Icon(
                              Icons.restaurant,
                              size: 64,
                              color: AppTheme.lunchColor,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Bugün için kaydedilmiş öğün yok',
                              style: TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            KFPulseAnimation(
                              maxScale: 1.05,
                              child: _buildAddMealButton(context),
                            )
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          // Öğün listesi
                          ListView.builder(
                            padding: const EdgeInsets.only(
                                bottom: 100), // Altta buton için ekstra padding
                            itemCount: meals.length,
                            itemBuilder: (context, index) {
                              final meal = meals[index];
                              return KFAnimatedItem(
                                index: index,
                                child: _buildMealCard(meal),
                              );
                            },
                          ),

                          // Öğün ekle butonu (sabit pozisyonda)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: KFPulseAnimation(
                                maxScale: 1.05,
                                child: _buildAddMealButton(context),
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

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    Provider.of<NutritionProvider>(context, listen: false)
        .setSelectedDate(_selectedDate);
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // Seçilen tarih için verileri yükle
      Provider.of<NutritionProvider>(context, listen: false)
          .setSelectedDate(picked); // Tarihi ayarla ve yüklemeyi tetikle
    }
  }

  Widget _getMealTypeIcon(FitMealType type) {
    switch (type) {
      case FitMealType.breakfast:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.free_breakfast, color: Colors.amber),
        );
      case FitMealType.lunch:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.lunchColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.lunch_dining, color: AppTheme.lunchColor),
        );
      case FitMealType.dinner:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.dinnerColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.dinner_dining, color: AppTheme.dinnerColor),
        );
      case FitMealType.snack:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.lightGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.apple, color: Colors.lightGreen),
        );
      case FitMealType.other:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.restaurant, color: Colors.grey),
        );
    }
  }

  String _getMealTypeName(FitMealType type) {
    switch (type) {
      case FitMealType.breakfast:
        return 'Kahvaltı';
      case FitMealType.lunch:
        return 'Öğle Yemeği';
      case FitMealType.dinner:
        return 'Akşam Yemeği';
      case FitMealType.snack:
        return 'Ara Öğün';
      case FitMealType.other:
        return 'Diğer';
    }
  }

  Widget _buildMealCard(MealRecord meal) {
    Color mealColor = _getMealColor(meal.type);
    String mealTypeName = _getMealTypeName(meal.type);
    String foodsList = meal.foods.join(', ');
    String formattedDate =
        DateFormat('d MMM, HH:mm', 'tr_TR').format(meal.date);

    return Dismissible(
      key: Key('meal_${meal.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        Provider.of<NutritionProvider>(context, listen: false)
            .deleteMeal(meal.id!);
        showAnimatedSnackBar(
          context: context,
          message: '$mealTypeName öğünü silindi',
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).primaryColor,
        );
      },
      confirmDismiss: (direction) async {
        // Use the delete confirmation inside AddEditMealDialog now
        // Returning true here will allow the dismiss animation but deletion is handled in the dialog
        return true;
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showEditMealDialog(meal),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  mealColor.withValues(alpha: 0.2),
                  mealColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: mealColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getMealIcon(meal.type),
                            color: mealColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mealTypeName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.color,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${meal.calories ?? 0} kcal',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'İçerik:',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  foodsList,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Öğün ekle butonunu özelleştirilmiş tasarımla oluştur
  Widget _buildAddMealButton(BuildContext context) {
    return Container(width: 200, margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: () => _showMealTypeSelectionDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.primaryColor
              : AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
        ),
        child: Text(
          'Öğün Ekle',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Öğün rengi alma
  Color _getMealColor(FitMealType type) {
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

  // Öğün ikonu alma
  IconData _getMealIcon(FitMealType type) {
    switch (type) {
      case FitMealType.breakfast:
        return Icons.free_breakfast;
      case FitMealType.lunch:
        return Icons.restaurant;
      case FitMealType.dinner:
        return Icons.dinner_dining;
      case FitMealType.snack:
        return Icons.apple;
      case FitMealType.other:
        return Icons.restaurant;
    }
  }

  // Öğün ekleme dialogunu göster
  void _showAddMealDialog(BuildContext context) {
    // Bu fonksiyon artık kullanılmıyor, yerine _showMealTypeSelectionDialog geldi.
    // İçeriği referans olarak kalabilir veya silinebilir.
    /*
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Öğün Tipi Seç'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _showFoodSelectionDialog(context,
                    mealType: FitMealType.breakfast);
              },
              child: const Text('Kahvaltı'),
            ),
            // ... Diğer öğün tipleri ...
          ],
        );
      },
    );
    */
  }

  // YENİ: Öğün Tipi Seçim Dialogu
  void _showMealTypeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Öğün Tipi Seç'),
          children: FitMealType.values.map((type) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext); // Tipi seçince bu dialogu kapat
                // Seçilen tiple bir sonraki adımı başlat
                _startAddOrSelectFoodFlow(mealType: type);
              },
              child: Row(
                children: [
                  Icon(_getMealIcon(type), color: _getMealColor(type)),
                  const SizedBox(width: 10),
                  Text(_getMealTypeName(type)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Öğün düzenleme dialogunu göster
  void _showEditMealDialog(MealRecord meal) {
    // Düzenleme için doğrudan AddOrSelectFoodFlow'u başlat
    _startAddOrSelectFoodFlow(existingMeal: meal);
  }

  // YENİ: Besin Ekleme/Seçme Akışını Başlatan Fonksiyon
  void _startAddOrSelectFoodFlow(
      {FitMealType? mealType, MealRecord? existingMeal}) {
    // TODO: Bu fonksiyon AddOrSelectFoodDialog'u çağıracak
    // Şimdilik mevcut FoodSelectionDialog'u çağıralım (geçici)
    // debugPrint("Besin ekleme/seçme akışı başlatılıyor. MealType: $mealType, ExistingMeal: ${existingMeal?.id}");
    // _showFoodSelectionDialog(context, mealType: mealType, existingMeal: existingMeal);

    // YENİ: AddOrSelectFoodDialog'u göster
    FitMealType type = mealType ??
        existingMeal?.type ??
        FitMealType.other; // Geçerli bir tip al
    DateTime date = existingMeal?.date ?? _selectedDate; // Tarihi al

    showDialog(
        context: context,
        builder: (_) => AddOrSelectFoodDialog(
              mealType: type,
              existingMeal: existingMeal, // Düzenleme için gönder
              selectedDate: date, // İlgili tarihi gönder
            ));
  }

  // YENİ -> TODO: Bu fonksiyon AddOrSelectFoodDialog ile değiştirilecek
  // Şimdilik mevcut FoodSelectionDialog kalıyor, akışı test etmek için
  // BU FONKSİYON ARTIK KULLANILMIYOR, SİLİNEBİLİR veya YORUMDA KALABİLİR
  /*
  void _showFoodSelectionDialog(
    BuildContext context, {
    FitMealType? mealType, // Yeni ekleme için öğün tipi
    MealRecord? existingMeal, // Düzenleme için mevcut öğün
  }) {
// ... existing code ...
*/
}

// YENİ WIDGET: FoodSelectionDialog
class FoodSelectionDialog extends StatefulWidget {
  // NutritionProvider yerine doğrudan DatabaseService alabilir
  // final NutritionProvider nutritionProvider;
  final Function(Map<FoodItem, double>, double, double, double, double)
      onSelectionConfirmed;

  const FoodSelectionDialog({
    Key? key,
    // required this.nutritionProvider,
    required this.onSelectionConfirmed,
  });

  @override
  _FoodSelectionDialogState createState() => _FoodSelectionDialogState();
}

class _FoodSelectionDialogState extends State<FoodSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _searchResults = [];
  Map<String, FoodItem> _selectedFoods = {}; // FoodItem ID -> FoodItem
  Map<String, TextEditingController> _gramControllers =
      {}; // FoodItem ID -> Controller
  bool _isLoading = false; // Arama sırasında yükleme durumu
  Timer? _debounce;
  final DatabaseService _dbService =
      DatabaseService(); // DatabaseService instance

  @override
  void initState() {
    super.initState();
    // Başlangıçta arama yapmaya gerek yok, kullanıcı yazınca tetiklenecek
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _gramControllers.values) {
      controller.dispose();
    }
    _gramControllers.clear();
  }

  // Fetch foods kaldırıldı, searchFoods kullanılacak
  // Future<void> _fetchFoods() async { ... }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Gecikmeyi artırdık
      if (mounted) {
        _searchFoods(_searchController.text);
      }
    });
  }

  // Firestore'dan arama yap
  Future<void> _searchFoods(String query) async {
    if (query.length < 2) {
      // En az 2 karakter girilince ara
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await _dbService.searchFoodItems(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      debugPrint("Besin arama hatası (Dialog): $e");
      if (mounted) {
        // Hata mesajı gösterilebilir
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Besin aranırken hata oluştu.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Hesaplama fonksiyonu Firestore modeline göre güncellendi
  Map<FoodItem, double> _calculateTotals() {
    Map<FoodItem, double> selectedAmounts = {};
    _selectedFoods.forEach((id, food) {
      final controller = _gramControllers[id];
      if (controller != null) {
        final grams =
            double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
        if (grams > 0) {
          selectedAmounts[food] = grams;
        }
      }
    });
    return selectedAmounts;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Besin Listesi"),
      content: Container(width: double.maxFinite, height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true, // Otomatik odaklanma
                    decoration: InputDecoration(
                      labelText: "Besin Ara (en az 2 harf)",
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                // Arama temizlenince sonuçları da temizle
                                if (mounted) {
                                  setState(() {
                                    _searchResults = [];
                                  });
                                }
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                // YENİ: Manuel Ekleme Butonu
                TextButton.icon(
                  icon: Icon(Icons.add_box_outlined),
                  label: Text("Manuel Besin Ekle"),
                  onPressed: () async {
                    // AddEditFoodScreen'e git ve sonucu bekle
                    final result = await Navigator.of(context).push<FoodItem?>(
                      MaterialPageRoute(
                        builder: (_) =>
                            AddEditFoodScreen(), // Varsayılan yapıcı
                      ),
                    );

                    // Eğer yeni bir besin eklendiyse (ve döndürüldüyse)
                    // Navigator hatasını önlemek için UI güncellemelerini geciktir
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (result != null && mounted) {
                        // Bu besini doğrudan seçilenlere ekle (100g varsayılan?)
                        setState(() {
                          // Firestore'dan gelmediği için geçici bir ID veya farklı bir yapı kullanmak gerekebilir
                          // Şimdilik name'i ID olarak kullanalım (ideal değil)
                          final tempId = result.name;
                          _selectedFoods[tempId] = result;
                          _gramControllers[tempId] =
                              TextEditingController(text: '100');
                        });
                        // Arama sonuçlarını temizleyebilir veya kullanıcıyı bilgilendirebiliriz
                        _searchController.clear();
                        _searchResults = [];
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '${result.name} öğüne eklendi (manuel).')),
                        );
                      }
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            _isLoading
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator()))
                : _searchResults.isEmpty && _searchController.text.length < 2
                    ? Center(child: Text("Aramak için en az 2 harf girin."))
                    : _searchResults.isEmpty &&
                            _searchController.text.length >= 2
                        ? Center(
                            child: Text(
                                '"${_searchController.text}" için sonuç bulunamadı.'))
                        : Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final food = _searchResults[index];
                                final bool isSelected =
                                    _selectedFoods.containsKey(food.id);

                                // Seçili değilse ve controller varsa kaldır (hata önleme)
                                if (!isSelected &&
                                    _gramControllers.containsKey(food.id)) {
                                  _gramControllers[food.id!]?.dispose();
                                  _gramControllers.remove(food.id);
                                }
                                // Seçiliyse ve controller yoksa oluştur (ilk seçim veya state kaybı sonrası)
                                else if (isSelected &&
                                    !_gramControllers.containsKey(food.id)) {
                                  _gramControllers[food.id!] =
                                      TextEditingController(text: '100');
                                }

                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 4.0),
                                  child: CheckboxListTile(
                                    // Firestore modelindeki alanları kullan
                                    title: Text(
                                        '${food.name} (${food.caloriesKcal.toStringAsFixed(0)} kcal / ${food.servingSizeG.toStringAsFixed(0)}g)'),
                                    subtitle: Text(
                                        'P: ${food.proteinG.toStringAsFixed(1)}g, K: ${food.carbsG.toStringAsFixed(1)}g, Y: ${food.fatG.toStringAsFixed(1)}g / ${food.servingSizeG.toStringAsFixed(0)}g'),
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      if (!mounted) return;
                                      setState(() {
                                        if (value == true) {
                                          _selectedFoods[food.id!] = food;
                                          // Controller'ı burada oluşturmak daha güvenli
                                          _gramControllers[food.id!] =
                                              TextEditingController(
                                                  text: '100');
                                        } else {
                                          _selectedFoods.remove(food.id);
                                          _gramControllers[food.id!]?.dispose();
                                          _gramControllers.remove(food.id);
                                        }
                                      });
                                    },
                                    secondary: isSelected
                                        ? Container(width: 70, child: TextField(
                                              controller:
                                                  _gramControllers[food.id!],
                                              keyboardType: TextInputType
                                                  .numberWithOptions(
                                                      decimal: false),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly
                                              ],
                                              decoration: InputDecoration(
                                                labelText: "Gram",
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('İptal'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Seçilenleri Ekle'),
          onPressed: _selectedFoods.isEmpty
              ? null
              : () {
                  if (!mounted) return;

                  double totalCalories = 0;
                  double totalProtein = 0;
                  double totalCarbs = 0;
                  double totalFat = 0;
                  final Map<FoodItem, double> confirmedSelections = {};

                  _selectedFoods.forEach((id, food) {
                    final controller = _gramControllers[id];
                    if (controller != null) {
                      final grams = double.tryParse(
                              controller.text.replaceAll(',', '.')) ??
                          0.0;
                      if (grams > 0 && food.servingSizeG > 0) {
                        // Porsiyon 0 kontrolü
                        // Firestore'daki porsiyona göre oranla
                        final factor = grams / food.servingSizeG;
                        totalCalories += food.caloriesKcal * factor;
                        totalProtein += food.proteinG * factor;
                        totalCarbs += food.carbsG * factor;
                        totalFat += food.fatG * factor;
                        confirmedSelections[food] =
                            grams; // Seçilen gramajı kaydet
                      }
                    }
                  });

                  widget.onSelectionConfirmed(confirmedSelections,
                      totalCalories, totalProtein, totalCarbs, totalFat);
                  Navigator.of(context).pop();
                },
        ),
      ],
    );
  }
}



