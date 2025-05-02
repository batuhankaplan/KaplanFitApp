import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';
import '../utils/show_dialogs.dart'; // SnackBar için

class AddEditFoodScreen extends StatefulWidget {
  final FoodItem? foodItem; // Düzenleme için (opsiyonel)

  const AddEditFoodScreen({Key? key, this.foodItem}) : super(key: key);

  @override
  _AddEditFoodScreenState createState() => _AddEditFoodScreenState();
}

class _AddEditFoodScreenState extends State<AddEditFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  // Form controller'ları
  late TextEditingController _nameController;
  late TextEditingController _servingSizeController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Düzenleme modundaysak mevcut değerleri yükle
    _nameController = TextEditingController(text: widget.foodItem?.name ?? '');
    _servingSizeController = TextEditingController(
        text: widget.foodItem?.servingSizeG.toString() ??
            '100'); // Modeldeki yeni adı ve tipi kullan (double->String)
    _caloriesController = TextEditingController(
        text: widget.foodItem?.caloriesKcal?.toString() ??
            ''); // Modeldeki yeni adı kullan
    _proteinController = TextEditingController(
        text: widget.foodItem?.proteinG?.toString() ??
            ''); // Modeldeki yeni adı kullan
    _carbsController = TextEditingController(
        text: widget.foodItem?.carbsG?.toString() ??
            ''); // Modeldeki yeni adı kullan
    _fatController = TextEditingController(
        text: widget.foodItem?.fatG?.toString() ??
            ''); // Modeldeki yeni adı kullan
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingSizeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _saveFoodItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final name = _nameController.text;
      final servingSize = _servingSizeController.text;
      final calories = double.tryParse(_caloriesController.text) ?? 0;
      final protein = double.tryParse(_proteinController.text) ?? 0;
      final carbs = double.tryParse(_carbsController.text) ?? 0;
      final fat = double.tryParse(_fatController.text) ?? 0;

      // Firestore'a uygun porsiyon boyutunu (double) al
      final servingSizeG =
          double.tryParse(servingSize.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              100.0; // Sadece sayıyı al, varsayılan 100

      // Yeni FoodItem nesnesi oluştur (Modeldeki güncel alan adları ile)
      final newFood = FoodItem(
        id: widget.foodItem?.id, // Düzenlemedeyse ID'yi koru
        name: name,
        category: widget.foodItem?.category ??
            'Diğer', // Kategori ekle (şimdilik varsayılan)
        servingSizeG: servingSizeG, // Güncellenmiş alan
        caloriesKcal: calories, // Güncellenmiş alan
        proteinG: protein, // Güncellenmiş alan
        carbsG: carbs, // Güncellenmiş alan
        fatG: fat, // Güncellenmiş alan
        // isCustom ve createdAt artık modelde yok, Firestore otomatik halleder.
      );

      try {
        if (widget.foodItem == null) {
          // Yeni ekleme
          await _dbService.insertFoodItem(newFood);
          showAnimatedSnackBar(
              context: context, message: 'Besin eklendi: $name');
          Navigator.of(context).pop(newFood);
        } else {
          // Düzenleme (henüz desteklenmiyor ama altyapı hazır)
          // await _dbService.updateFoodItem(newFood);
          // showAnimatedSnackBar(context: context, message: 'Besin güncellendi: $name');
          print("Düzenleme henüz implemente edilmedi.");
          showAnimatedSnackBar(
              context: context,
              message: 'Düzenleme henüz aktif değil',
              backgroundColor: Colors.orange);
          Navigator.of(context).pop(null);
          return;
        }
      } catch (e) {
        print("Besin kaydederken hata: $e");
        showAnimatedSnackBar(
            context: context,
            message: 'Besin kaydedilemedi.',
            backgroundColor: Colors.red);
        Navigator.of(context).pop(null);
      }

      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.foodItem == null ? 'Yeni Besin Ekle' : 'Besin Düzenle'),
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child:
                  Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveFoodItem,
              tooltip: 'Kaydet',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Besin Adı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_important_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Besin adı gerekli.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _servingSizeController,
                decoration: InputDecoration(
                  labelText: 'Porsiyon Açıklaması',
                  hintText: 'Örn: 100g, 1 adet, 1 kase',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pie_chart_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Porsiyon açıklaması gerekli.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caloriesController,
                decoration: InputDecoration(
                  labelText: 'Kalori (kcal)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_fire_department_outlined),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kalori gerekli.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli bir sayı girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: InputDecoration(
                        labelText: 'Protein (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (double.tryParse(value ?? '0') == null) {
                          return 'Sayı girin.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: InputDecoration(
                        labelText: 'Karb. (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (double.tryParse(value ?? '0') == null) {
                          return 'Sayı girin.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: InputDecoration(
                        labelText: 'Yağ (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (double.tryParse(value ?? '0') == null) {
                          return 'Sayı girin.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text('Kaydet'),
                onPressed: _isSaving ? null : _saveFoodItem,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
