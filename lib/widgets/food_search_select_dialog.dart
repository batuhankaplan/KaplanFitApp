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
    // YENİ: Başlangıçta tüm besinleri (veya varsayılan bir listeyi) yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFoods(''); // Boş sorgu ile ilk listeyi getir
    });
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
    // YENİ: Artık query boş olsa bile arama yapılıyor (DatabaseService'de handle ediliyor)
    // if (query.length < 2 && query.isNotEmpty) {
    //   if (mounted) {
    //     setState(() {
    //       _searchResults = [];
    //       _isLoading = false;
    //     });
    //   }
    //   return;
    // }

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

  // Manuel besin ekleme fonksiyonu artık buradan çağrılmayacak
  // Future<void> _navigateToAddManualFood() async { ... }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Besin Seç"), // YENİ: Başlık güncellendi, buton kaldırıldı
      contentPadding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      content: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Besin Ara...", // YENİ: Hint text güncellendi
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          // _searchFoods(''); // Arama temizlenince varsayılan listeyi tekrar yükle
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
          onPressed: () => Navigator.of(context).pop(null),
        ),
        ElevatedButton(
          child: Text('Seçimi Onayla'),
          onPressed: _dialogSelections.isNotEmpty
              ? () {
                  Map<String, ({FoodItem food, double grams})> finalSelections =
                      {};
                  _dialogSelections.forEach((key, value) {
                    final controller = _gramControllers[key];
                    final grams =
                        double.tryParse(controller?.text ?? '0') ?? value.grams;
                    finalSelections[key] =
                        (food: value.food, grams: grams > 0 ? grams : 100.0);
                  });
                  Navigator.of(context).pop(finalSelections);
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildResultsAndSelectionList() {
    List<Widget> selectionWidgets = _dialogSelections.entries.map((entry) {
      final String key = entry.key;
      final FoodItem food = entry.value.food;
      final bool isSearchResult =
          _searchResults.any((f) => (f.id ?? f.name) == key);
      if (isSearchResult && _searchController.text.isNotEmpty)
        return SizedBox.shrink(); // Arama varsa ve sonuçtaysa gösterme
      return _buildFoodListItem(food, key, true);
    }).toList();

    List<Widget> searchResultWidgets = _searchResults.map((food) {
      final key = food.id ?? food.name;
      final bool isSelected = _dialogSelections.containsKey(key);
      if (isSelected) return SizedBox.shrink();
      return _buildFoodListItem(food, key, false);
    }).toList();

    // YENİ: Arama sonucu yoksa veya başlangıçta gösterilecek mesajlar
    if (_searchResults.isEmpty &&
        _searchController.text.isNotEmpty &&
        !_isLoading) {
      return Center(
          child: Text('"${_searchController.text}" için sonuç bulunamadı.'));
    }
    // if (_searchResults.isEmpty && _searchController.text.isEmpty && !_isLoading) {
    //   return Center(child: Text('Lütfen arama yapın veya yukarıdan manuel ekleyin.')); // Bu artık geçerli değil
    // }

    List<Widget> combinedList = [];
    if (_searchController.text.isEmpty) {
      // Arama yoksa, önce seçilenler, sonra arama sonuçları (yani tüm liste)
      combinedList.addAll(selectionWidgets
          .where((w) => w is! SizedBox)); // SizedBox olmayanları ekle
      List<String> selectedKeys = _dialogSelections.keys.toList();
      combinedList.addAll(searchResultWidgets.where((w) =>
          w is! SizedBox &&
          !selectedKeys.contains((w as Card)
              .key
              .toString()))); //SizedBox olmayan ve seçili olmayanları ekle
    } else {
      // Arama varsa, önce seçilenler (arama sonucu olmayanlar), sonra arama sonuçları (seçilmemiş olanlar)
      combinedList.addAll(selectionWidgets.where((w) => w is! SizedBox));
      combinedList.addAll(searchResultWidgets.where((w) => w is! SizedBox));
    }

    // Tekrarları engellemek için Set kullanılabilir, ama key bazlı olduğu için sorun olmamalı.
    // Şimdilik basit birleştirme.
    // Eğer _searchController.text boş ise _searchResults tüm listeyi içerecek.
    // Seçili olanlar hem _dialogSelections'da hem de _searchResults'da olabilir.
    // Bu yüzden _buildFoodListItem içinde `initiallySelected` doğru yönetilmeli.
    // Ve _buildResultsAndSelectionList içinde mükerrer göstermemeye dikkat edilmeli.

    // Basitleştirilmiş birleştirme:
    // 1. Seçili olanlar (ama arama sonuçlarında da varsa orada gösterilecekler)
    // 2. Arama sonuçları (ama zaten seçiliyse seçili olarak işaretlenecekler)
    // Bu mantık _buildFoodListItem'ın `initiallySelected` ve CheckboxListTile'ın `value` parametresi ile sağlanıyor.

    final displayedItems = <String>{}; // Zaten listelenenleri takip et
    List<Widget> finalWidgetList = [];

    // Önce seçilenleri ekle (eğer arama sonucu değillerse veya arama boşsa)
    for (var entry in _dialogSelections.entries) {
      final key = entry.key;
      final food = entry.value.food;
      // Eğer arama metni varsa ve bu öğe arama sonuçlarında değilse, seçili olarak ekle
      // Ya da arama metni yoksa (tüm liste gösteriliyor), seçili olarak ekle
      if ((_searchController.text.isNotEmpty &&
              !_searchResults.any((f) => (f.id ?? f.name) == key)) ||
          _searchController.text.isEmpty) {
        if (displayedItems.add(key)) {
          finalWidgetList.add(_buildFoodListItem(food, key, true));
        }
      }
    }

    // Sonra arama sonuçlarını ekle (eğer zaten seçili olarak eklenmediyse)
    for (var food in _searchResults) {
      final key = food.id ?? food.name;
      if (displayedItems.add(key)) {
        finalWidgetList.add(
            _buildFoodListItem(food, key, _dialogSelections.containsKey(key)));
      }
    }

    if (finalWidgetList.isEmpty && !_isLoading) {
      if (_searchController.text.isNotEmpty) {
        return Center(
            child: Text('"${_searchController.text}" için sonuç bulunamadı.'));
      } else {
        // Arama boş ve sonuç yoksa (ve yüklenmiyorsa), bu genellikle başlangıç durumudur veya DB boştur.
        return Center(child: Text('Besin bulunamadı veya yükleniyor...'));
      }
    }

    return ListView.separated(
      itemCount: finalWidgetList.length,
      separatorBuilder: (context, index) => Divider(height: 1, thickness: 0.5),
      itemBuilder: (context, index) {
        return finalWidgetList[index];
      },
    );
  }

  Widget _buildFoodListItem(FoodItem food, String key, bool initiallySelected) {
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
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        title: Text(
            "${food.name} (${food.caloriesKcal.toStringAsFixed(0)} k/${food.servingSizeG.toStringAsFixed(0)}g)"),
        subtitle: Text(
            'P:${food.proteinG.toStringAsFixed(1)} K:${food.carbsG.toStringAsFixed(1)} Y:${food.fatG.toStringAsFixed(1)} /${food.servingSizeG.toStringAsFixed(0)}g',
            style: TextStyle(fontSize: 11)),
        value: _dialogSelections
            .containsKey(key), // Dinamik olarak _dialogSelections'dan al
        onChanged: (bool? value) {
          if (!mounted) return;
          setState(() {
            if (value == true) {
              final grams =
                  double.tryParse(gramController?.text ?? '100') ?? 100.0;
              _dialogSelections[key] =
                  (food: food, grams: grams > 0 ? grams : 100.0);
              if (_gramControllers[key] == null) {
                // Sadece controller yoksa oluştur
                _gramControllers[key] = TextEditingController(
                    text: (grams > 0 ? grams : 100.0).toStringAsFixed(0));
              }
            } else {
              _dialogSelections.remove(key);
              _gramControllers[key]?.dispose();
              _gramControllers.remove(key);
            }
          });
        },
        secondary: _dialogSelections.containsKey(key)
            ? Container(
                width: 75,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gramControllers[
                            key], // Doğrudan _gramControllers'dan al
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
                        onChanged: (text) {
                          // Gramaj değiştikçe _dialogSelections'ı güncelle
                          final grams = double.tryParse(text) ?? 0.0;
                          if (_dialogSelections.containsKey(key)) {
                            setState(() {
                              _dialogSelections[key] = (
                                food: food,
                                grams: grams > 0 ? grams : 100.0
                              );
                            });
                          }
                        },
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
