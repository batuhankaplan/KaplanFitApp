import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../models/meal_record.dart';
import '../models/task_type.dart'; // FitMealType için
import '../screens/add_edit_food_screen.dart'; // Manuel ekleme ekranı
import '../providers/nutrition_provider.dart';
import '../services/database_service.dart';
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
  }) : super(key: key);

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
      print("UYARI: Öğün düzenleme için mevcut besinler henüz yüklenmiyor.");
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

    // print("Listeden Besin Seç henüz implemente edilmedi.");
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
      print("Öğün kaydedilirken hata: $e");
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text("${grams.toStringAsFixed(0)} g",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),

              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 20),
                onPressed: () {
                  setState(() {
                    _currentSelections.remove(keyId); // Seçimlerden kaldır
                  });
                },
              ),
            ],
          ),
          // TODO: Gramajı düzenlemek için onTap eklenebilir
        ),
      );
    }).toList();

    return AlertDialog(
      title: Text(widget.existingMeal == null
          ? '${_getMealTypeName(widget.mealType)} Öğünü Ekle'
          : '${_getMealTypeName(widget.existingMeal!.type)} Öğünü Düzenle'),
      content: Container(
        width: double.maxFinite, // Genişliği doldur
        // Yüksekliği içeriğe göre ayarla ama maksimum sınır koy
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min, // İçeriğe göre boyutlan
          children: [
            // Butonlar: Manuel Ekle / Listeden Seç
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.add_box_outlined),
                  label: Text("Manuel Ekle"),
                  onPressed: _navigateToAddManualFood,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.list_alt),
                  label: Text("Listeden Seç"),
                  onPressed: _showFoodSearchAndSelectDialog,
                ),
              ],
            ),
            const Divider(height: 20),

            // Seçili Besinler Başlığı
            if (selectionWidgets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "Seçilen Besinler (${_currentSelections.length})",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

            // Seçili Besinler Listesi (Kaydırılabilir)
            // Eğer liste boşsa placeholder göster
            selectionWidgets.isEmpty
                ? Expanded(
                    child: Center(
                      child: Text(
                        "Henüz besin eklenmedi.\nManuel ekleyin veya listeden seçin.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: selectionWidgets,
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
          // Yükleniyor durumunda butonu disable et
          onPressed: _isSaving || _currentSelections.isEmpty ? null : _saveMeal,
          child: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(widget.existingMeal == null
                  ? 'Öğünü Kaydet'
                  : 'Değişiklikleri Kaydet'),
        ),
      ],
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
}
