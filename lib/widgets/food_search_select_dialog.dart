import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/food_item.dart';
import '../services/database_service.dart';
import '../utils/show_dialogs.dart'; // SnackBar için
import '../screens/add_edit_food_screen.dart'; // Manuel ekleme için

// Bu dialog, kullanıcının Firestore'dan besin aramasını, seçmesini
// ve gramajlarını girmesini sağlar.
class FoodSearchAndSelectDialog extends StatefulWidget {
  // AddOrSelectFoodDialog'dan gelen mevcut seçimler
  final Map<String, ({FoodItem food, double grams})> initialSelections;

  const FoodSearchAndSelectDialog({
    Key? key,
    required this.initialSelections,
  }) : super(key: key);

  @override
  _FoodSearchAndSelectDialogState createState() =>
      _FoodSearchAndSelectDialogState();
}

class _FoodSearchAndSelectDialogState extends State<FoodSearchAndSelectDialog> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  List<FoodItem> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  // Bu dialog içindeki geçici seçimleri tutar
  // Anahtar: FoodItem ID (veya manuel eklenen için name), Değer: (food, grams)
  Map<String, ({FoodItem food, double grams})> _dialogSelections = {};
  // Seçili öğelerin gramajlarını yönetmek için controller'lar
  Map<String, TextEditingController> _gramControllers = {};

  @override
  void initState() {
    super.initState();
    // Başlangıç seçimlerini bu dialogun state'ine kopyala
    _dialogSelections = Map.from(widget.initialSelections);
    // Mevcut seçimler için gram controller'larını oluştur
    _dialogSelections.forEach((key, value) {
      _gramControllers[key] =
          TextEditingController(text: value.grams.toStringAsFixed(0));
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    // Oluşturulan tüm gram controller'larını dispose et
    _gramControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _searchFoods(_searchController.text);
      }
    });
  }

  Future<void> _searchFoods(String query) async {
    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final results = await _dbService.searchFoodItems(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      print("Besin arama hatası (Search Dialog): $e");
      if (mounted) {
        showAnimatedSnackBar(
          context: context,
          message: 'Besin aranırken hata oluştu.',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Manuel besin ekleme (AddOrSelectFoodDialog'daki gibi)
  Future<void> _navigateToAddManualFood() async {
    final result = await Navigator.of(context).push<FoodItem?>(
      MaterialPageRoute(builder: (_) => AddEditFoodScreen()),
    );
    if (result != null && mounted) {
      final tempId = result.id ?? result.name; // ID yoksa ismi kullan
      setState(() {
        final newSelection = (food: result, grams: 100.0);
        _dialogSelections[tempId] = newSelection;
        // Yeni controller oluştur
        _gramControllers[tempId]?.dispose(); // Varsa eskiyi temizle
        _gramControllers[tempId] =
            TextEditingController(text: newSelection.grams.toStringAsFixed(0));
      });
      showAnimatedSnackBar(
          context: context, message: '${result.name} öğüne eklendi (100g).');
      // Arama sonuçlarını temizleyebiliriz
      _searchController.clear();
      _searchResults = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Besin Seç/Ekle"),
          // Manuel Ekle Butonu
          IconButton(
            icon: Icon(Icons.add_box_outlined,
                color: Theme.of(context).primaryColor),
            tooltip: 'Manuel Besin Ekle',
            onPressed: _navigateToAddManualFood,
          )
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      content: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6, // Yükseklik ayarı
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Arama Çubuğu
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Besin Ara (en az 2 harf)...",
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          if (mounted) setState(() => _searchResults = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
                filled: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
            const SizedBox(height: 10),

            // Arama Sonuçları / Seçilenler Listesi
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _buildResultsAndSelectionList(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('İptal'),
          onPressed: () => Navigator.of(context).pop(null), // Değişiklik yok
        ),
        ElevatedButton(
          child: Text('Seçimi Onayla'),
          // Seçim varsa butonu aktif et
          onPressed: _dialogSelections.isNotEmpty
              ? () {
                  // Dialogu kapatmadan önce gramajları güncelle
                  Map<String, ({FoodItem food, double grams})> finalSelections =
                      {};
                  _dialogSelections.forEach((key, value) {
                    final controller = _gramControllers[key];
                    final grams = double.tryParse(controller?.text ?? '0') ??
                        value
                            .grams; // Controller'dan al, yoksa eski değeri koru
                    finalSelections[key] = (
                      food: value.food,
                      grams: grams > 0 ? grams : 100.0
                    ); // Negatif/sıfır olmasın
                  });
                  Navigator.of(context)
                      .pop(finalSelections); // Seçimleri geri döndür
                }
              : null, // Seçim yoksa disable
        ),
      ],
    );
  }

  // Arama sonuçlarını ve seçili öğeleri gösteren liste
  Widget _buildResultsAndSelectionList() {
    // Önce seçili olanları gösterelim
    List<Widget> selectionWidgets = _dialogSelections.entries.map((entry) {
      final String key = entry.key;
      final FoodItem food = entry.value.food;
      final bool isSearchResult =
          _searchResults.any((f) => (f.id ?? f.name) == key);
      // Eğer arama sonucunda varsa, arama listesinde gösterilecek, burada tekrar gösterme
      if (isSearchResult) return SizedBox.shrink();
      return _buildFoodListItem(food, key, true); // Seçili olduğunu belirt
    }).toList();

    // Sonra arama sonuçlarını (henüz seçilmemiş olanları) ekleyelim
    List<Widget> searchResultWidgets = _searchResults.map((food) {
      final key = food.id ?? food.name;
      final bool isSelected = _dialogSelections.containsKey(key);
      // Sadece seçili olmayanları göster
      if (isSelected) return SizedBox.shrink();
      return _buildFoodListItem(food, key, false); // Seçili olmadığını belirt
    }).toList();

    if (selectionWidgets.isEmpty &&
        searchResultWidgets.isEmpty &&
        _searchController.text.length >= 2) {
      return Center(
          child: Text('"${_searchController.text}" için sonuç bulunamadı.'));
    }
    if (selectionWidgets.isEmpty &&
        searchResultWidgets.isEmpty &&
        _searchController.text.length < 2) {
      return Center(
          child: Text(
              'Arama yapmak için en az 2 harf girin veya manuel ekleyin.'));
    }

    // İki listeyi birleştir ve araya ayırıcı koy
    return ListView.separated(
      itemCount: selectionWidgets.length + searchResultWidgets.length,
      separatorBuilder: (context, index) {
        // Seçilenler ile arama sonuçları arasına daha belirgin bir ayırıcı koy
        if (index == selectionWidgets.length - 1 &&
            searchResultWidgets.isNotEmpty &&
            selectionWidgets.isNotEmpty) {
          return Divider(
              thickness: 1,
              height: 16,
              color: Colors.blueGrey.withOpacity(0.5));
        }
        return Divider(height: 1, thickness: 0.5);
      },
      itemBuilder: (context, index) {
        if (index < selectionWidgets.length) {
          return selectionWidgets[index];
        } else {
          return searchResultWidgets[index - selectionWidgets.length];
        }
      },
    );
  }

  // Tek bir besin öğesini listeleyen widget
  Widget _buildFoodListItem(FoodItem food, String key, bool initiallySelected) {
    // Eğer seçiliyse controller'ı al veya oluştur
    TextEditingController? gramController = _gramControllers[key];
    if (initiallySelected && gramController == null) {
      final initialGrams = _dialogSelections[key]?.grams ?? 100.0;
      gramController =
          TextEditingController(text: initialGrams.toStringAsFixed(0));
      _gramControllers[key] = gramController;
    }

    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 3.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: CheckboxListTile(
        controlAffinity: ListTileControlAffinity.leading, // Checkbox başta
        dense: true,
        title: Text(
            "${food.name} (${food.caloriesKcal.toStringAsFixed(0)} k/${food.servingSizeG.toStringAsFixed(0)}g)"),
        subtitle: Text(
            'P:${food.proteinG.toStringAsFixed(1)} K:${food.carbsG.toStringAsFixed(1)} Y:${food.fatG.toStringAsFixed(1)} /${food.servingSizeG.toStringAsFixed(0)}g',
            style: TextStyle(fontSize: 11)),
        value: initiallySelected, // Seçili mi?
        onChanged: (bool? value) {
          if (!mounted) return;
          setState(() {
            if (value == true) {
              // Seçildi: Listeye ekle ve controller oluştur
              final grams =
                  double.tryParse(gramController?.text ?? '100') ?? 100.0;
              _dialogSelections[key] =
                  (food: food, grams: grams > 0 ? grams : 100.0);
              _gramControllers[key]?.dispose(); // Eski varsa temizle
              _gramControllers[key] = TextEditingController(
                  text: (grams > 0 ? grams : 100.0).toStringAsFixed(0));
            } else {
              // Seçim kaldırıldı: Listeden çıkar ve controller'ı dispose et
              _dialogSelections.remove(key);
              _gramControllers[key]?.dispose();
              _gramControllers.remove(key);
            }
          });
        },
        secondary: initiallySelected && gramController != null
            ? Container(
                width: 75, // Genişliği biraz artır
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: gramController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        // Gramaj değiştiğinde state'i güncellemek için (opsiyonel, onayla'da yapılıyor)
                        // onChanged: (text) {
                        //   final grams = double.tryParse(text) ?? 0.0;
                        //   if (_dialogSelections.containsKey(key)) {
                        //     _dialogSelections[key] = (food: food, grams: grams > 0 ? grams : 100.0);
                        //   }
                        // },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text('g',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
