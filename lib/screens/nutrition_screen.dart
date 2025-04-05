import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nutrition_provider.dart';
import '../theme.dart';
import '../models/task_type.dart';
import '../models/meal_record.dart';
import 'package:intl/intl.dart';
import '../utils/animations.dart';
import '../utils/show_dialogs.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  DateTime _selectedDate = DateTime.now();
  FitMealType _selectedMealType = FitMealType.breakfast;
  final TextEditingController _foodsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  
  @override
  void dispose() {
    _foodsController.dispose();
    _caloriesController.dispose();
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
          KFAnimatedSlide(
            offsetBegin: const Offset(0, -0.2),
            duration: const Duration(milliseconds: 500),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Theme.of(context).cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Önceki gün
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 18),
                    onPressed: () {
                      _changeDate(-1);
                    },
                  ),
                  
                  // Seçilen tarih gösterimi
                  GestureDetector(
                    onTap: _selectDate,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDate),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Sonraki gün
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 18),
                    onPressed: () {
                      _changeDate(1);
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          
          // Calorie summary
          if (meals.isNotEmpty) 
            KFAnimatedSlide(
              offsetBegin: const Offset(0.2, 0),
              duration: const Duration(milliseconds: 500),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Toplam Kalori',
                        meals.fold<int>(0, (sum, meal) => sum + (meal.calories ?? 0)).toString(),
                        Icons.local_fire_department,
                        AppTheme.lunchColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Toplam Öğün',
                        meals.length.toString(),
                        Icons.restaurant,
                        AppTheme.dinnerColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Meals list
          Expanded(
            child: provider.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : meals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        KFAnimatedSlide(
                          offsetBegin: const Offset(0, 0.3),
                          child: Column(
                            children: [
                              KFWaveAnimation(
                                color: AppTheme.lunchColor.withOpacity(0.3),
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
                                child: _buildAddMealButton(),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: meals.length,
                          itemBuilder: (context, index) {
                            final meal = meals[index];
                            return KFAnimatedItem(
                              index: index,
                              child: _buildMealCard(meal),
                            );
                          },
                        ),
                      ),
                      KFPulseAnimation(
                        maxScale: 1.05,
                        child: _buildAddMealButton(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(
    BuildContext context, 
    String title, 
    String value, 
    IconData icon,
    Color color,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return KFPulseAnimation(
      duration: const Duration(milliseconds: 2000),
      maxScale: 1.03,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.7),
              color.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    Provider.of<NutritionProvider>(context, listen: false).setSelectedDate(_selectedDate);
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      Provider.of<NutritionProvider>(context, listen: false).setSelectedDate(_selectedDate);
    }
  }
  
  Widget _getMealTypeIcon(FitMealType type) {
    switch (type) {
      case FitMealType.breakfast:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.free_breakfast, color: Colors.amber),
        );
      case FitMealType.lunch:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.lunchColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.lunch_dining, color: AppTheme.lunchColor),
        );
      case FitMealType.dinner:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.dinnerColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.dinner_dining, color: AppTheme.dinnerColor),
        );
      case FitMealType.snack:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.lightGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.apple, color: Colors.lightGreen),
        );
      case FitMealType.other:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
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
  
  void _showAddMealDialog(BuildContext context) {
    _foodsController.clear();
    _caloriesController.clear();
    _selectedMealType = FitMealType.breakfast;
    
    showAnimatedDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Öğün Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FitMealType>(
                  value: _selectedMealType,
                  decoration: const InputDecoration(
                    labelText: 'Öğün Türü',
                    border: OutlineInputBorder(),
                  ),
                  items: FitMealType.values.map((type) {
                    return DropdownMenuItem<FitMealType>(
                      value: type,
                      child: Text(_getMealTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMealType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _foodsController,
                  decoration: const InputDecoration(
                    labelText: 'Yiyecekler (virülle ayırın)',
                    hintText: 'Yumurta, ekmek, zeytin',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Kalori',
                    hintText: 'İsteğe bağlı',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Ekle'),
              onPressed: () {
                if (_foodsController.text.isNotEmpty) {
                  final provider = Provider.of<NutritionProvider>(context, listen: false);
                  final foods = _foodsController.text.split(',').map((e) => e.trim()).toList();
                  final calories = int.tryParse(_caloriesController.text);
                  final now = DateTime.now();
                  
                  final meal = MealRecord(
                    type: _selectedMealType,
                    foods: foods,
                    date: _selectedDate.copyWith(
                      hour: now.hour,
                      minute: now.minute,
                    ),
                    calories: calories,
                  );
                  
                  provider.addMeal(meal);
                  Navigator.of(context).pop();
                } else {
                  showAnimatedSnackBar(
                    context: context,
                    message: 'Lütfen en az bir yiyecek girin',
                    backgroundColor: Colors.red,
                    floating: true,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showEditMealDialog(BuildContext context, MealRecord meal) async {
    _foodsController.text = meal.foods.join(', ');
    _caloriesController.text = meal.calories?.toString() ?? '';
    _selectedMealType = meal.type;
    
    showAnimatedDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Öğün Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FitMealType>(
                  value: _selectedMealType,
                  decoration: const InputDecoration(
                    labelText: 'Öğün Türü',
                    border: OutlineInputBorder(),
                  ),
                  items: FitMealType.values.map((type) {
                    return DropdownMenuItem<FitMealType>(
                      value: type,
                      child: Text(_getMealTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMealType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _foodsController,
                  decoration: const InputDecoration(
                    labelText: 'Yiyecekler (virülle ayırın)',
                    hintText: 'Yumurta, ekmek, zeytin',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Kalori',
                    hintText: 'İsteğe bağlı',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 4),
                  Text('Sil'),
                ],
              ),
              onPressed: () {
                if (meal.id != null) {
                  Provider.of<NutritionProvider>(context, listen: false).deleteMeal(meal.id!);
                  showAnimatedSnackBar(
                    context: context,
                    message: '${_getMealTypeName(meal.type)} öğünü silindi',
                    duration: const Duration(seconds: 2),
                    backgroundColor: Theme.of(context).primaryColor,
                  );
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Kaydet'),
              onPressed: () {
                if (_foodsController.text.isNotEmpty) {
                  final provider = Provider.of<NutritionProvider>(context, listen: false);
                  final foods = _foodsController.text.split(',').map((e) => e.trim()).toList();
                  final calories = int.tryParse(_caloriesController.text);
                  
                  final updatedMeal = MealRecord(
                    id: meal.id,
                    type: _selectedMealType,
                    foods: foods,
                    date: meal.date,
                    calories: calories,
                  );
                  
                  provider.updateMeal(updatedMeal);
                  Navigator.of(context).pop();
                } else {
                  showAnimatedSnackBar(
                    context: context,
                    message: 'Lütfen en az bir yiyecek girin',
                    backgroundColor: Colors.red,
                    floating: true,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(MealRecord meal) {
    Color mealColor = _getMealColor(meal.type);
    String mealTypeName = _getMealTypeName(meal.type);
    String foodsList = meal.foods.join(', ');
    String formattedDate = DateFormat('d MMM, HH:mm', 'tr_TR').format(meal.date);
    
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
        Provider.of<NutritionProvider>(context, listen: false).deleteMeal(meal.id!);
        showAnimatedSnackBar(
          context: context,
          message: '$mealTypeName öğünü silindi',
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).primaryColor,
        );
      },
      confirmDismiss: (direction) async {
        return await showAnimatedDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Öğünü Sil'),
              content: Text('Bu $mealTypeName öğününü silmek istediğinize emin misiniz?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Sil'),
                ),
              ],
            );
          },
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showEditMealDialog(context, meal),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  mealColor.withOpacity(0.2),
                  mealColor.withOpacity(0.05),
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
                            color: mealColor.withOpacity(0.2),
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
                                color: Theme.of(context).textTheme.titleLarge?.color,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
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
  Widget _buildAddMealButton() {
    return Container(
      width: 220,
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _showAddMealDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Öğün Ekle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
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
        return Icons.lunch_dining;
      case FitMealType.dinner:
        return Icons.dinner_dining;
      case FitMealType.snack:
        return Icons.apple;
      case FitMealType.other:
        return Icons.restaurant;
    }
  }
} 