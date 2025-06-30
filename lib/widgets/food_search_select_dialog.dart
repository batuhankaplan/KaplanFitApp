import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/food_item.dart';
import '../services/database_service.dart';
import '../utils/show_dialogs.dart'; // SnackBar için
// import '../screens/add_edit_food_screen.dart'; // Manuel ekleme için artık kullanılmayacak

// Bu dialog, kullanıcının Firestore'dan besin aramasını, seçmesini
// ve gramajlarını girmesini sağlar.
class FoodSearchAndSelectDialog extends StatefulWidget {
  // AddOrSelectFoodDialog'dan gelen mevcut seçimler
  final Map<String, ({FoodItem food, double grams})> initialSelections;

  const FoodSearchAndSelectDialog({
    Key? key,
    this.initialSelections = const {},
  }) : super(key: key);

  @override
  State<FoodSearchAndSelectDialog> createState() =>
      _FoodSearchAndSelectDialogState();
}

class _FoodSearchAndSelectDialogState extends State<FoodSearchAndSelectDialog> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  List<FoodItem> _allFoods = [];
  List<FoodItem> _filteredFoods = [];
  Map<String, double> _selectedGrams = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
        "🎯 FoodSearchAndSelectDialog YENİ VERSİYON - initState başladı");

    // Başlangıç seçimlerini kopyala
    widget.initialSelections.forEach((key, value) {
      _selectedGrams[key] = value.grams;
    });

    _loadAllFoods();
  }

  Future<void> _loadAllFoods() async {
    setState(() {
      _isLoading = true;
    });

    debugPrint("📥 Tüm besinler yükleniyor...");

    try {
      final foods = await _databaseService.searchFoodItems('');
      debugPrint(
          "✅ ${foods.length} besin yüklendi: ${foods.map((f) => f.name).take(5).join(', ')}...");

      setState(() {
        _allFoods = foods;
        _filteredFoods = foods;
        _isLoading = false;
      });

      debugPrint(
          "🔄 UI güncellendi - _allFoods: ${_allFoods.length}, _filteredFoods: ${_filteredFoods.length}");
    } catch (e) {
      debugPrint("❌ Besinler yüklenirken hata: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterFoods(String query) {
    debugPrint("🔍 Besinler filtreleniyor: '$query'");

    setState(() {
      if (query.isEmpty) {
        _filteredFoods = _allFoods;
      } else {
        _filteredFoods = _allFoods
            .where(
                (food) => food.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });

    debugPrint("📋 Filtreleme sonucu: ${_filteredFoods.length} besin");
  }

  void _toggleSelection(FoodItem food) {
    final foodKey = food.id ?? food.name;
    setState(() {
      if (_selectedGrams.containsKey(foodKey)) {
        _selectedGrams.remove(foodKey);
        debugPrint("➖ ${food.name} seçimden çıkarıldı");
      } else {
        _selectedGrams[foodKey] = 100.0; // Varsayılan gram
        debugPrint("➕ ${food.name} seçildi (100g)");
      }
    });
  }

  void _updateGrams(String foodId, double grams) {
    setState(() {
      _selectedGrams[foodId] = grams;
    });
  }

  Map<String, ({FoodItem food, double grams})> _buildResult() {
    Map<String, ({FoodItem food, double grams})> result = {};

    _selectedGrams.forEach((foodId, grams) {
      final food = _allFoods.firstWhere((f) => (f.id ?? f.name) == foodId);
      result[foodId] = (food: food, grams: grams);
    });

    debugPrint("📤 Dialog sonucu: ${result.length} besin seçildi");
    return result;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "🎨 FoodSearchAndSelectDialog build - _isLoading: $_isLoading, _filteredFoods: ${_filteredFoods.length}");

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Besin Seç',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Besin ara...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterFoods,
                  ),
                ],
              ),
            ),

            Divider(height: 1),

            // Body
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Besinler yükleniyor...'),
                        ],
                      ),
                    )
                  : _filteredFoods.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Hiç besin bulunamadı'
                                : '"${_searchController.text}" için sonuç bulunamadı',
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredFoods.length,
                          itemBuilder: (context, index) {
                            final food = _filteredFoods[index];
                            final foodKey = food.id ?? food.name;
                            final isSelected =
                                _selectedGrams.containsKey(foodKey);
                            final grams = _selectedGrams[foodKey] ?? 100.0;

                            return Card(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _toggleSelection(food),
                                ),
                                title: Text(
                                  food.name,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${food.caloriesKcal.toStringAsFixed(0)} kcal / 100g'),
                                    Text(
                                        'Protein: ${food.proteinG.toStringAsFixed(1)}g'),
                                    if (isSelected) ...[
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text('Gram: '),
                                          SizedBox(
                                            width: 80,
                                            child: TextFormField(
                                              initialValue:
                                                  grams.toStringAsFixed(0),
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                              ),
                                              onChanged: (value) {
                                                final newGrams =
                                                    double.tryParse(value) ??
                                                        100.0;
                                                _updateGrams(foodKey, newGrams);
                                              },
                                            ),
                                          ),
                                          Text(' g'),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () => _toggleSelection(food),
                              ),
                            );
                          },
                        ),
            ),

            Divider(height: 1),

            // Footer
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_selectedGrams.length} besin seçildi'),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('İptal'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final result = _buildResult();
                          Navigator.of(context).pop(result);
                        },
                        child: Text('Tamam'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
