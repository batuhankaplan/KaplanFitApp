import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../models/meal_record.dart';
import '../models/task_type.dart'; // FitMealType için
import '../screens/add_edit_food_screen.dart'; // Manuel ekleme ekranı
import '../providers/nutrition_provider.dart';

import '../utils/show_dialogs.dart'; // SnackBar vb. için
import 'food_search_select_dialog.dart'; // Liste dialogu (sonraki adımda oluşturulacak)

// Bu dialog, öğün tipi seçildikten sonra açılır ve kullanıcıya
// manuel besin ekleme veya listeden seçme imkanı sunar.
class AddOrSelectFoodDialog extends StatefulWidget {
  final FitMealType mealType; // Hangi öğün için ekleme yapılıyor
  final MealRecord? existingMeal; // Düzenleme modunda mevcut öğün
  final DateTime selectedDate; // Hangi tarih için ekleme yapılıyor

  const AddOrSelectFoodDialog({
    Key? key,
    required this.mealType,
    this.existingMeal,
    required this.selectedDate,
  });

  @override
  State<AddOrSelectFoodDialog> createState() => _AddOrSelectFoodDialogState();
}

class _AddOrSelectFoodDialogState extends State<AddOrSelectFoodDialog> {
  // Seçilen/eklenen besinleri ve miktarlarını (gram) tutacak map
  // FoodItem nesnesini anahtar olarak kullanmak yerine, FoodItem'ın ID'sini
  // veya manuel eklenmişse geçici bir unique identifier kullanalım.
  // Değer olarak da {food: FoodItem, grams: double} içeren bir Map tutalım.
  Map<String, ({FoodItem food, double grams})> _currentSelections = {};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Düzenleme modundaysa mevcut besinleri yükle (şimdilik desteklenmiyor)
    if (widget.existingMeal != null) {
      // TODO: existingMeal.foods listesindeki string'leri parse edip
      //       ilgili FoodItem'ları Firestore'dan çekip _currentSelections'a ekle.
      //       Bu kısım şimdilik atlanıyor, düzenleme tam desteklenmiyor.
      debugPrint(
          "UYARI: Öğün düzenleme için mevcut besinler henüz yüklenmiyor.");
    }
  }

  // Manuel besin ekleme ekranını açar
  Future<void> _navigateToAddManualFood() async {
    final result = await Navigator.of(context).push<FoodItem?>(
      MaterialPageRoute(
        builder: (_) => AddEditFoodScreen(), // Yeni besin ekleme modu
      ),
    );

    // Eğer kullanıcı yeni bir besin ekleyip kaydettiyse
    if (result != null && mounted) {
      setState(() {
        // Manuel eklenen besini _currentSelections'a ekle (varsayılan 100g)
        // Firestore'dan gelmediği için ID'si null olabilir. Geçici ID olarak name kullanalım.
        final tempId = result.id ?? result.name; // ID yoksa ismi kullan
        _currentSelections[tempId] = (food: result, grams: 100.0);
      });
      showAnimatedSnackBar(
          context: context, message: '${result.name} öğüne eklendi (100g).');
    }
  }

  // Listeden besin seçme dialogunu açar
  Future<void> _showFoodSearchAndSelectDialog() async {
    debugPrint(
        "🔥 LISTEDEN SEÇ butonuna basıldı - FoodSearchAndSelectDialog açılıyor");

    // TODO: food_search_select_dialog.dart oluşturulduktan sonra implement edilecek
    final selectedFoodsFromList =
        await showDialog<Map<String, ({FoodItem food, double grams})>>(
      context: context,
      builder: (_) => FoodSearchAndSelectDialog(
        // Başlangıçta zaten seçili olanları da gönderelim ki üzerine eklensin/güncellensin
        initialSelections: _currentSelections,
      ),
    );

    if (selectedFoodsFromList != null && mounted) {
      setState(() {
        // Listeden gelen seçimleri mevcut seçimlerle birleştir/güncelle
        _currentSelections = selectedFoodsFromList;
      });
      showAnimatedSnackBar(context: context, message: 'Liste güncellendi.');
    }

    // debugPrint("Listeden Besin Seç henüz implemente edilmedi.");
    // showAnimatedSnackBar(context: context, message: 'Bu özellik yakında!', backgroundColor: Colors.blue);
  }

  // Öğünü kaydetme işlemi
  Future<void> _saveMeal() async {
    if (_currentSelections.isEmpty) {
      showAnimatedSnackBar(
          context: context,
          message: 'Lütfen en az bir besin ekleyin.',
          backgroundColor: Colors.orange);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<NutritionProvider>(context, listen: false);
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    List<String> foodDescriptions = [];

    _currentSelections.forEach((_, selection) {
      final food = selection.food;
      final grams = selection.grams;
      if (grams > 0 && food.servingSizeG > 0) {
        final factor = grams / food.servingSizeG;
        totalCalories += food.caloriesKcal * factor;
        totalProtein += food.proteinG * factor;
        totalCarbs += food.carbsG * factor;
        totalFat += food.fatG * factor;
        foodDescriptions.add("${food.name} (${grams.toStringAsFixed(0)}g)");
      }
    });

    try {
      if (widget.existingMeal != null) {
        // Güncelleme
        final updatedMeal = widget.existingMeal!.copyWith(
          foods: foodDescriptions,
          calories: totalCalories.round(),
          proteinGrams: totalProtein,
          carbsGrams: totalCarbs,
          fatGrams: totalFat,
          // type ve date güncellenmiyor (şimdilik)
        );
        await provider.updateMeal(updatedMeal);
        if (!mounted) return;
        showAnimatedSnackBar(context: context, message: 'Öğün güncellendi.');
      } else {
        // Yeni ekleme
        final newMeal = MealRecord(
          type: widget.mealType,
          foods: foodDescriptions,
          date: widget.selectedDate, // Ana ekrandan gelen tarihi kullan
          calories: totalCalories.round(),
          proteinGrams: totalProtein,
          carbsGrams: totalCarbs,
          fatGrams: totalFat,
          // userId Provider'da otomatik atanıyor
        );
        await provider.addMeal(newMeal);
        if (!mounted) return;
        showAnimatedSnackBar(context: context, message: 'Öğün kaydedildi.');
      }
      Navigator.of(context).pop(); // Dialogu kapat
    } catch (e) {
      debugPrint("Öğün kaydedilirken hata: $e");
      if (mounted) {
        showAnimatedSnackBar(
            context: context,
            message: 'Öğün kaydedilemedi.',
            backgroundColor: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Seçili besinleri göstermek için bir liste oluşturalım
    List<Widget> selectionWidgets = _currentSelections.entries.map((entry) {
      final item = entry.value.food;
      final grams = entry.value.grams;
      // Anahtar olarak ID veya name kullanılıyor olabilir
      final keyId = entry.key;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          dense: true,
          leading: Icon(Icons.restaurant_menu, size: 20),
          title: Text(
              "${item.name} (${item.caloriesKcal.toStringAsFixed(0)} kcal/${item.servingSizeG.toStringAsFixed(0)}g)"),
          subtitle: Text(
              'P: ${item.proteinG.toStringAsFixed(1)}g, K: ${item.carbsG.toStringAsFixed(1)}g, Y: ${item.fatG.toStringAsFixed(1)}g / ${item.servingSizeG.toStringAsFixed(0)}g'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gramaj gösterme/düzenleme (şimdilik sadece gösterme)
              GestureDetector(
                onTap: () => _showGramAdjustDialog(keyId, item, grams),
                child: Container(
                  width: 65,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${grams.toStringAsFixed(0)}g',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Icon(Icons.edit,
                          size: 12, color: Theme.of(context).primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Silme butonu
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _currentSelections.remove(keyId);
                  });
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                iconSize: 20,
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width:
            MediaQuery.of(context).size.width * 0.9, // Ekran genişliğinin %90'ı
        constraints: BoxConstraints(
            maxWidth: 500), // Çok geniş ekranlarda maksimum genişlik
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // İçeriğe göre boyut alacak
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingMeal != null ? 'Öğünü Düzenle' : 'Öğün Ekle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Öğün tipi görüntüleme
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getMealTypeIcon(widget.mealType),
                    color: _getMealTypeColor(widget.mealType),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getMealTypeName(widget.mealType),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('d MMM yyyy', 'tr_TR')
                        .format(widget.selectedDate),
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Besin ekleme seçenekleri
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Öğün Ekle'),
                    onPressed: _navigateToAddManualFood,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.list),
                    label: Text('Listeden Seç'),
                    onPressed: _showFoodSearchAndSelectDialog,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Seçili besinlerin listesi
            if (selectionWidgets.isNotEmpty) ...[
              Text(
                'Seçilen Besinler:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: selectionWidgets,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'Lütfen besin ekleyin veya listeden seçin',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            // Toplam değerler ve kaydetme butonu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _isSaving
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _saveMeal,
                        child: Text(
                          widget.existingMeal != null ? 'Güncelle' : 'Kaydet',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                // Toplam değerleri göster
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Toplam: ${_calculateTotalCalories().toStringAsFixed(0)} kcal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'P: ${_calculateTotalProtein().toStringAsFixed(1)}g',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // MealType enum'unu string'e çeviren yardımcı fonksiyon (NutritionScreen'den alınabilir)
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

  // MealType ikonunu alan yardımcı fonksiyon (NutritionScreen'den alınabilir)
  IconData _getMealTypeIcon(FitMealType type) {
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

  // MealType ikonunun renkini alan yardımcı fonksiyon (NutritionScreen'den alınabilir)
  Color _getMealTypeColor(FitMealType type) {
    switch (type) {
      case FitMealType.breakfast:
        return Colors.orange;
      case FitMealType.lunch:
        return Colors.green;
      case FitMealType.dinner:
        return Colors.red;
      case FitMealType.snack:
        return Colors.blue;
      case FitMealType.other:
        return Colors.purple;
    }
  }

  // Toplam kalori hesabı için yardımcı fonksiyon
  double _calculateTotalCalories() {
    double total = 0;
    _currentSelections.forEach((_, selection) {
      final food = selection.food;
      final grams = selection.grams;
      if (grams > 0 && food.servingSizeG > 0) {
        final factor = grams / food.servingSizeG;
        total += food.caloriesKcal * factor;
      }
    });
    return total;
  }

  // Toplam protein hesabı için yardımcı fonksiyon
  double _calculateTotalProtein() {
    double total = 0;
    _currentSelections.forEach((_, selection) {
      final food = selection.food;
      final grams = selection.grams;
      if (grams > 0 && food.servingSizeG > 0) {
        final factor = grams / food.servingSizeG;
        total += food.proteinG * factor;
      }
    });
    return total;
  }

  // Gram miktarını ayarlamak için dialog göster
  Future<void> _showGramAdjustDialog(
      String keyId, FoodItem item, double currentGrams) async {
    // TextEditingController yerine direkt olarak String değeri saklayalım
    String gramInputValue = currentGrams.toStringAsFixed(0);
    // State değişkeni olarak gram miktarını tutalım, böylece TextFormField'dan bağımsız olur
    double parsedGrams = currentGrams;

    // Basitleştirilmiş bir dialog gösterelim
    return showDialog(
      context: context,
      barrierDismissible: false, // Dialog dışına tıklayınca kapanmaması için
      builder: (dialogContext) => StatefulBuilder(
        // StatefulBuilder kullanarak dialog içinde setState kullanabiliriz
        builder: (context, setDialogState) {
          // Besin değerlerini hesaplayan helper fonksiyon
          void calculateNutrients(double grams) {
            return; // Boş fonksiyon - hesaplama direkt olarak build içinde yapılacak
          }

          // String'den double'a güvenli şekilde dönüştürme
          void updateGrams(String value) {
            try {
              final newGrams = double.tryParse(value) ?? currentGrams;
              if (newGrams > 0 && newGrams <= 5000) {
                // Dialog içinde setState kullanarak gram değerini güncelle
                setDialogState(() {
                  parsedGrams = newGrams;
                  gramInputValue = value;
                });
              }
            } catch (e) {
              debugPrint("Gram güncelleme hatası: $e");
            }
          }

          // Besin değerleri ile faktörü güvenli şekilde hesaplama
          double calculateFactor() {
            if (item.servingSizeG <= 0) return 0;
            return parsedGrams / item.servingSizeG;
          }

          return AlertDialog(
            title: Text('Gramaj Ayarla'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.name,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  TextFormField(
                    initialValue: gramInputValue,
                    decoration: InputDecoration(
                      labelText: 'Gram Miktarı',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    onChanged: (value) {
                      // Text değiştiğinde gram değerini güncelle
                      updateGrams(value);
                    },
                  ),
                  SizedBox(height: 8),
                  // Kalori ve besin değerleri hesapla ve göster
                  Builder(builder: (context) {
                    final factor = calculateFactor();

                    return Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Besin Değerleri:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(
                              'Kalori: ${(item.caloriesKcal * factor).toStringAsFixed(0)} kcal'),
                          Text(
                              'Protein: ${(item.proteinG * factor).toStringAsFixed(1)} g'),
                          Text(
                              'Karbonhidrat: ${(item.carbsG * factor).toStringAsFixed(1)} g'),
                          Text(
                              'Yağ: ${(item.fatG * factor).toStringAsFixed(1)} g'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // İptal - dialog'u kapat
                },
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  try {
                    // Dialog kapanmadan önce yeni gram değerini _currentSelections'a ekleyelim
                    if (parsedGrams > 0 && parsedGrams <= 5000) {
                      setState(() {
                        _currentSelections[keyId] =
                            (food: item, grams: parsedGrams);
                      });
                      Navigator.pop(dialogContext); // Başarılı - dialog'u kapat
                    } else {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Lütfen 1-5000g arasında geçerli bir değer girin'),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint("Gramaj kaydetme hatası: $e");
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Hata oluştu: Geçerli bir değer girin'),
                      ),
                    );
                  }
                },
                child: Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }
}
