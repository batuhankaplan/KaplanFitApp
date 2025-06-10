import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart'; // Provider ekleyelim
import 'package:collection/collection.dart'; // DeepCollectionEquality için
import '../models/program_model.dart';
import '../models/program_set.dart'; // ProgramSet ekleyelim
import '../models/exercise_model.dart'; // Exercise ekleyelim
import '../services/exercise_service.dart'; // ExerciseService ekleyelim
import '../services/program_service.dart'; // ProgramService ekleyelim (Kaydetmek için)
import '../widgets/kaplan_appbar.dart';
import 'exercise_library_screen.dart'; // Egzersiz seçme ekranı importu

class EditProgramCategoryScreen extends StatefulWidget {
  final String categoryName;
  final List<ProgramItem> programItems;

  const EditProgramCategoryScreen({
    Key? key,
    required this.categoryName,
    required this.programItems,
  });

  @override
  _EditProgramCategoryScreenState createState() =>
      _EditProgramCategoryScreenState();
}

class _EditProgramCategoryScreenState extends State<EditProgramCategoryScreen> {
  late TextEditingController _categoryNameController;
  late List<ProgramItem> _currentProgramItems; // Değişiklikleri tutacak kopya
  Map<String, Exercise> _exerciseDetails = {}; // Egzersiz detayları için Map
  bool _isLoading = false; // Yükleme durumu
  bool _isSaving = false; // Kaydetme durumu için ayrı flag

  @override
  void initState() {
    super.initState();
    _categoryNameController = TextEditingController(text: widget.categoryName);
    // Gelen listeyi kopyalayarak başlayalım (Deep copy - ProgramSet modeline uygun)
    _currentProgramItems = widget.programItems
        .map((item) => ProgramItem(
              id: item.id,
              type: item.type,
              title: item.title,
              icon: item.icon, // Kopyalamada eksik kalan alanları ekleyelim
              color: item.color,
              time: item.time,
              description: item.description,
              programSets: item.programSets
                  ?.map((set) => ProgramSet(
                        // Modeldeki doğru alan adlarını kullanalım
                        exerciseId: set.exerciseId,
                        order: set.order,
                        setsDescription: set.setsDescription,
                        repsDescription: set.repsDescription,
                        restTimeDescription: set.restTimeDescription,
                        notes: set.notes,
                        // exerciseDetails kopyalanmaz, _loadExerciseDetails ile yüklenir
                      ))
                  .toList(),
            ))
        .toList();
    _loadExerciseDetails();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  Future<void> _loadExerciseDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final exerciseService =
          Provider.of<ExerciseService>(context, listen: false);
      Set<String> exerciseIds = {};
      for (var item in _currentProgramItems) {
        item.programSets?.forEach((set) {
          if (set.exerciseId != null) {
            exerciseIds.add(set.exerciseId!);
          }
        });
      }

      if (exerciseIds.isNotEmpty) {
        final detailsList =
            await exerciseService.getExercisesByIds(exerciseIds.toList());
        if (detailsList != null && mounted) {
          setState(() {
            _exerciseDetails = Map.fromEntries(detailsList
                .where((ex) => ex.id != null)
                .map((ex) => MapEntry(ex.id!, ex)));

            // Egzersiz detayları yüklendikten sonra programSet'lere atama yapalım
            for (int i = 0; i < _currentProgramItems.length; i++) {
              var item = _currentProgramItems[i];
              if (item.programSets != null) {
                List<ProgramSet> updatedProgramSets = [];
                for (var set in item.programSets!) {
                  if (set.exerciseId != null &&
                      _exerciseDetails.containsKey(set.exerciseId)) {
                    updatedProgramSets.add(set.copyWith(
                        exerciseDetails: () =>
                            _exerciseDetails[set.exerciseId]));
                  } else {
                    updatedProgramSets.add(set);
                  }
                }
                _currentProgramItems[i] =
                    item.copyWith(programSets: updatedProgramSets);
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Egzersiz detayları yüklenirken hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Egzersiz detayları yüklenemedi.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteExercise(String programItemId, String exerciseId) {
    if (!mounted) return;
    setState(() {
      final programItemIndex =
          _currentProgramItems.indexWhere((item) => item.id == programItemId);
      if (programItemIndex != -1) {
        _currentProgramItems[programItemIndex]
            .programSets
            ?.removeWhere((set) => set.exerciseId == exerciseId);
        // İsteğe bağlı: Eğer setler boşaldıysa item'ı sil
        // if (_currentProgramItems[programItemIndex].programSets?.isEmpty ?? true) {
        //    _currentProgramItems.removeAt(programItemIndex);
        // }
        debugPrint(
            "[EditScreen][_deleteExercise] UI Updated. Item ID: $programItemId, Exercise ID: $exerciseId. Current sets count: ${_currentProgramItems[programItemIndex].programSets?.length}");
      }
    });
    debugPrint(
        "Deleted exercise $exerciseId from item $programItemId (UI only)");
  }

  void _addExercise() async {
    if (!mounted) return;

    try {
      final result = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
            builder: (context) => ExerciseLibraryScreen(isSelectionMode: true)),
      );

      if (result != null && mounted) {
        setState(() {
          // Eğer _currentProgramItems boşsa (ilk egzersiz ekleniyorsa)
          // ve henüz bir kategori item'ı yoksa, bir tane oluşturalım.
          // Bu genellikle yeni kategori oluşturma senaryosunda olur.
          if (_currentProgramItems.isEmpty) {
            final newItem = ProgramItem(
              id: 'category_${DateTime.now().millisecondsSinceEpoch}', // Yeni kategori ID
              title: _categoryNameController.text,
              type: ProgramItemType.workout,
              programSets: [],
              icon: Icons.fitness_center,
              color: Colors.purple,
            );
            _currentProgramItems.add(newItem);
          }

          // Gelen sonucun türüne göre işlem yap (Tek veya Liste)
          List<Exercise> exercisesToAdd = [];
          if (result is Exercise) {
            exercisesToAdd.add(result);
          } else if (result is List<Exercise>) {
            exercisesToAdd = result;
          } else if (result is Set<Exercise>) {
            exercisesToAdd = result.toList();
          }

          if (exercisesToAdd.isNotEmpty) {
            // Eklenecek item'ı bul (genellikle ilki)
            final targetItemIndex =
                _currentProgramItems.indexWhere((item) => item.id != null);
            if (targetItemIndex == -1) return; // Hedef item yoksa çık
            ProgramItem targetItem = _currentProgramItems[targetItemIndex];
            List<ProgramSet> currentSets =
                List<ProgramSet>.from(targetItem.programSets ?? []);
            int currentMaxOrder =
                currentSets.map((s) => s.order ?? 0).fold(0, max);

            for (var exercise in exercisesToAdd) {
              if (exercise.id == null) continue; // ID yoksa atla

              // Egzersiz detaylarını map'e ekle
              _exerciseDetails[exercise.id!] = exercise;

              // Yeni ProgramSet oluştur
              currentMaxOrder++;
              final programSet = ProgramSet(
                exerciseId: exercise.id,
                order: currentMaxOrder, // Sırayı artır
                setsDescription: exercise.defaultSets ?? '3',
                repsDescription: exercise.defaultReps ?? '10',
                restTimeDescription: exercise.defaultRestTime ?? '60 sn',
                exerciseDetails: exercise, // Detayı hemen ekle
              );
              currentSets.add(programSet);
            } // for döngüsü sonu

            // Hedef ProgramItem'ı güncellenmiş setlerle güncelle
            _currentProgramItems[targetItemIndex] = targetItem.copyWith(
              programSets: currentSets,
            );
          }
        });
      }
    } catch (e) {
      debugPrint("[EditProgramCategoryScreen][_addExercise] Hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Egzersiz eklenirken bir hata oluştu.')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_isSaving || !mounted) return;
    setState(() => _isSaving = true);
    try {
      final programService =
          Provider.of<ProgramService>(context, listen: false);
      final newCategoryName = _categoryNameController.text.trim();

      if (newCategoryName.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kategori adı boş olamaz!')),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      // Başlangıç ve bitiş item setleri (ID'ye göre map)
      // Bu kısım kategori item'ları için kafa karıştırıcı olabilir,
      // şimdilik sadece kategori adı değişikliğini ve setleri odaklanalım.
      /*
      final initialItemsMap = {
        for (var item in widget.programItems)
          if (item.id != null) item.id!: item
      };
      final currentItemsMap = {
        for (var item in _currentProgramItems)
          if (item.id != null) item.id!: item
      };
      */

      List<ProgramItem> itemsToUpdate = [];
      List<String> idsToDelete = [];
      Map<String, String> categoryTitleChange = {}; // Eski -> Yeni

      // Kategori adı değişti mi?
      final initialCategoryName = widget.categoryName;
      if (initialCategoryName != newCategoryName) {
        debugPrint(
            "Kategori adı değişti: '$initialCategoryName' -> '$newCategoryName'");
        categoryTitleChange[initialCategoryName] = newCategoryName;
      }

      // Güncellenmiş öğeleri hazırla
      // Sadece kategoriye ait Temsilci ProgramItem'ı güncelleyelim (içindeki setlerle birlikte)
      if (_currentProgramItems.isNotEmpty) {
        // Genellikle _currentProgramItems bir eleman içerir (kategoriyi temsil eden)
        // veya aynı kategoriye ait birden fazla item içerebilir (nadiren).
        // Şimdilik ilk item'ı baz alalım.
        ProgramItem representativeItem = _currentProgramItems.first;

        // Temsilci item'ın başlığını yeni kategori adına güncelle
        // ve setleri de al.
        // ID'si 'category_' ile başlıyorsa bu bir kategori item'ıdır.
        if (representativeItem.id != null &&
            representativeItem.id!.startsWith('category_')) {
          // Tüm setleri içeren güncel item'ı oluştur
          ProgramItem categoryUpdateItem = ProgramItem(
            id: representativeItem.id,
            title: newCategoryName, // Yeni başlık
            type: ProgramItemType.workout,
            programSets: _currentProgramItems
                .expand<ProgramSet>((item) => item.programSets ?? [])
                .toList(),
            icon: representativeItem.icon, // İkonu koru
            color: representativeItem.color, // Rengi koru
          );
          itemsToUpdate.add(categoryUpdateItem);
        } else {
          // Eğer ID 'category_' ile başlamıyorsa, bu normal bir program item düzenlemesidir.
          // Bu senaryo şu anki akışta beklenmiyor ama yine de ele alalım.
          for (var item in _currentProgramItems) {
            itemsToUpdate.add(item.copyWith(title: newCategoryName));
          }
        }

        // Silinecek setleri (item değil) bulmak daha karmaşık, şimdilik atlıyoruz.
        // Sadece eklenen/güncellenen setleri gönderiyoruz.
      } else if (initialCategoryName != newCategoryName) {
        // Kategori boştu ama adı değişti (yeni kategori oluşturma sonrası isim değiştirme gibi)
        // Yeni, boş bir kategori item'ı gönderelim.
        final newItemId =
            'category_${DateTime.now().millisecondsSinceEpoch}'; // Yeni ID
        ProgramItem emptyCategoryItem = ProgramItem(
          id: newItemId,
          title: newCategoryName,
          type: ProgramItemType.workout,
          programSets: [],
          icon: Icons.fitness_center,
          color: Colors.purple,
        );
        itemsToUpdate.add(emptyCategoryItem);
      }

      // Silinecek ana ProgramItem ID'lerini bul
      // idsToDelete = initialItemsMap.keys
      //     .where((id) => !currentItemsMap.containsKey(id))
      //     .toList();
      // Şimdilik kategori silme dışında ana item silmeyi desteklemiyoruz.

      debugPrint("--- Değişiklikler Kaydedilecek ---");
      debugPrint("Kategori Adı Değişikliği: $categoryTitleChange");
      debugPrint(
          "Güncellenecek/Eklenecek Kategori Item (${itemsToUpdate.length}): ${itemsToUpdate.map((i) => i.id).toList()}");
      for (var item in itemsToUpdate) {
        debugPrint(
            "[SaveChanges] Item to update: ID=${item.id}, Title='${item.title}', SetsCount=${item.programSets?.length}");
        // Her set için detaylı bilgi yazdır
        if (item.programSets != null) {
          for (int i = 0; i < item.programSets!.length; i++) {
            final set = item.programSets![i];
            debugPrint(
                "  Set $i: ExerciseID=${set.exerciseId}, Setsler=${set.setsDescription}, Tekrarlar=${set.repsDescription}");
          }
        }
      }
      //debugPrint("Silinecek (${idsToDelete.length}): $idsToDelete");

      if (itemsToUpdate.isEmpty &&
          idsToDelete.isEmpty &&
          categoryTitleChange.isEmpty) {
        debugPrint("[SaveChanges] Kaydedilecek bir değişiklik bulunamadı.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kaydedilecek değişiklik yok.')),
          );
          setState(() => _isSaving = false);
          if (Navigator.canPop(context)) {
            Navigator.pop(context, false); // Değişiklik yok olarak dön
          }
        }
        return; // Değişiklik yoksa servisi çağırma
      }

      // ProgramService üzerinden toplu güncelleme yap
      debugPrint(
          "[SaveChanges] ProgramService.updateProgramItems çağrılıyor...");
      await programService.updateProgramItems(
          itemsToUpdate, idsToDelete, categoryTitleChange // Yeni parametre
          );
      debugPrint("[SaveChanges] ProgramService.updateProgramItems tamamlandı.");

      debugPrint("--- Değişiklikler Servise Gönderildi ---");

      if (mounted) {
        // Kaydetme başarılı oldu, UI'yı refresh et
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Program başarıyla güncellendi!')),
        );

        // Ana program sayfasına geri dön ve refresh tetikle
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true); // Başarı ile dön

          // Main program screen'i refresh etmek için ek signal gönder
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint(
                "📢 Edit tamamlandı, ana program screen refresh edilecek");
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Program kaydedilirken hata: $e\nStackTrace: $stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Program kaydedilirken bir hata oluştu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Kategoriyi silme fonksiyonu
  Future<void> _deleteCategory() async {
    if (_isSaving || !mounted) return;

    // Silme onayı iste
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kategoriyi Sil'),
        content: Text(
            '${_categoryNameController.text} kategorisini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final programService =
          Provider.of<ProgramService>(context, listen: false);

      // Tüm program item ID'lerini topla
      List<String> idsToDelete = _currentProgramItems
          .where((item) => item.id != null)
          .map((item) => item.id!)
          .toList();

      if (idsToDelete.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silinecek bir program bulunamadı')),
        );
        setState(() => _isSaving = false);
        return;
      }

      // Programları sil
      await programService.updateProgramItems([], idsToDelete, {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kategori başarıyla silindi')),
        );
        Navigator.pop(context, true); // Başarılı olarak dön
      }
    } catch (e) {
      debugPrint("Kategori silinirken hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Kategori silinirken hata oluştu: ${e.toString()}')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  /// Belirli bir ProgramSet'in detaylarını düzenlemek için dialog gösterir.
  void _showEditSetDialog(ProgramItem programItem, ProgramSet set) {
    if (!mounted) return;

    // Önce önceki değerleri al
    Map<String, String> editSetData = {
      'sets': set.setsDescription ?? '',
      'reps': set.repsDescription ?? '',
      'rest': set.restTimeDescription ?? '',
      'notes': set.notes ?? '',
    };

    // TextEditingController'ları oluştur ve önceki değerlerle doldur
    TextEditingController setsController =
        TextEditingController(text: editSetData['sets']);
    TextEditingController repsController =
        TextEditingController(text: editSetData['reps']);
    TextEditingController restController =
        TextEditingController(text: editSetData['rest']);
    TextEditingController notesController =
        TextEditingController(text: editSetData['notes']);

    // Egzersiz detayını bul
    final exercise = _exerciseDetails[set.exerciseId];
    if (exercise == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Egzersiz detayları yüklenemedi. Lütfen sayfayı yeniden yükleyin.')));
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(exercise.name),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: setsController,
                    decoration: InputDecoration(
                      labelText: 'Set Sayısı',
                      hintText: 'Örn: 3',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: repsController,
                    decoration: InputDecoration(
                      labelText: 'Tekrar Açıklaması',
                      hintText: 'Örn: 12 veya 12-10-8',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: restController,
                    decoration: InputDecoration(
                      labelText: 'Dinlenme Süresi',
                      hintText: 'Örn: 60 sn',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notlar',
                      hintText: 'Opsiyonel',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('İptal'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Kaydet'),
                onPressed: () {
                  // Dialog'dan yeni değerleri al
                  final Map<String, String> updatedSetData = {
                    'sets': setsController.text.trim(),
                    'reps': repsController.text.trim(),
                    'rest': restController.text.trim(),
                    'notes': notesController.text.trim(),
                  };

                  // Dialog'u kapat
                  Navigator.of(context).pop();

                  // Güncellenmiş değerleri state'e uygula
                  setState(() {
                    // ProgramItem'ı bul ve içindeki doğru ProgramSet'i güncelle
                    if (programItem.programSets != null) {
                      final int setIndex = programItem.programSets!
                          .indexWhere((s) => s.order == set.order);

                      if (setIndex != -1) {
                        final updatedSet = set.copyWith(
                          setsDescription: updatedSetData['sets'],
                          repsDescription: updatedSetData['reps'],
                          // ValueGetter kullanarak nullable yapalım
                          restTimeDescription: () =>
                              updatedSetData['rest']?.isNotEmpty ?? false
                                  ? updatedSetData['rest']
                                  : null,
                          notes: () =>
                              updatedSetData['notes']?.isNotEmpty ?? false
                                  ? updatedSetData['notes']
                                  : null,
                        );

                        // Mevcut liste üzerinde güncelleme yap
                        List<ProgramSet> updatedSets =
                            List<ProgramSet>.from(programItem.programSets!);
                        updatedSets[setIndex] = updatedSet;

                        // ProgramItem'ı güncelle
                        final itemIndex =
                            _currentProgramItems.indexOf(programItem);
                        if (itemIndex != -1) {
                          _currentProgramItems[itemIndex] =
                              programItem.copyWith(
                            programSets: updatedSets,
                          );
                        }

                        debugPrint(
                            "Updated set details for ${exercise.name} in UI.");
                        debugPrint(
                            "[EditScreen][_showEditSetDialog] UI Updated. Item ID: ${programItem.id}, Set Order: ${set.order}. New Reps: ${updatedSetData['reps']}");
                      }
                    }
                  });
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Subtitle bilgisi oluşturma fonksiyonu
  String _buildSubtitleText(ProgramSet set) {
    final List<String> parts = [];

    if (set.setsDescription != null && set.setsDescription!.isNotEmpty) {
      parts.add('${set.setsDescription} set');
    }

    if (set.repsDescription != null && set.repsDescription!.isNotEmpty) {
      parts.add('${set.repsDescription} tekrar');
    }

    // Dinlenme süresi bilgisini sadece değer varsa ve "0" veya "0 sn" değilse göster
    if (set.restTimeDescription != null &&
        set.restTimeDescription!.isNotEmpty &&
        !set.restTimeDescription!.trim().startsWith('0')) {
      // Sadece dinlenme süresini göster, "dinlenme" kelimesini eklemeden
      parts.add('${set.restTimeDescription}');
    }

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: KaplanAppBar(
        title: '${_categoryNameController.text} - Programı Düzenle',
        isDarkMode: isDarkMode,
        showBackButton: true,
        actions: [
          // Egzersiz Ekle Butonu
          IconButton(
            icon: Icon(Icons.add,
                color: isDarkMode ? Colors.white : Colors.black),
            tooltip: 'Egzersiz Ekle',
            onPressed: _addExercise,
          ),
          IconButton(
            icon: Icon(Icons.save,
                color: isDarkMode ? Colors.white : Colors.black),
            tooltip: 'Değişiklikleri Kaydet',
            onPressed: _isSaving ? null : _saveChanges,
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            tooltip: 'Kategoriyi Sil',
            onPressed: _deleteCategory,
          ),
        ],
      ),
      body: _isLoading // Detaylar yüklenirken farklı bir yükleme göstergesi
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Egzersiz detayları yükleniyor...")
                ]))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _categoryNameController,
                    decoration: InputDecoration(
                      labelText: 'Kategori Adı',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    ),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Egzersizler:',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: (_currentProgramItems.isEmpty ||
                            _currentProgramItems.every(
                                (item) => item.programSets?.isEmpty ?? true))
                        ? Center(
                            child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Bu kategoride henüz egzersiz yok.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _addExercise,
                                child: Text('Egzersiz Ekle'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 12),
                                ),
                              ),
                            ],
                          ))
                        : ListView.builder(
                            // ReorderableListView da kullanılabilir
                            itemCount: _currentProgramItems.length,
                            itemBuilder: (context, itemIndex) {
                              final programItem =
                                  _currentProgramItems[itemIndex];
                              if (programItem.programSets == null ||
                                  programItem.programSets!.isEmpty) {
                                return SizedBox
                                    .shrink(); // İçi boş item gösterme
                              }

                              // Setleri sırala (varsa)
                              programItem.programSets!.sort((a, b) =>
                                  (a.order ?? 0).compareTo(b.order ?? 0));

                              // return Column(
                              //    crossAxisAlignment: CrossAxisAlignment.start,
                              //    children: programItem.programSets!.map((set) {
                              //       // ... ListTile kodu ...
                              //    }).toList(),
                              // );
                              // Yukarıdaki Column yerine doğrudan ListView.separated kullanalım
                              return ListView.separated(
                                shrinkWrap: true, // İç içe ListView için önemli
                                physics:
                                    NeverScrollableScrollPhysics(), // İç içe ListView için önemli
                                itemCount: programItem.programSets!.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: 8),
                                itemBuilder: (context, setIndex) {
                                  final set =
                                      programItem.programSets![setIndex];
                                  final exercise =
                                      _exerciseDetails[set.exerciseId];
                                  if (exercise == null)
                                    return ListTile(
                                        title: Text(
                                            "Egzersiz ID: ${set.exerciseId} yüklenemedi"));

                                  return Card(
                                    elevation: 2,
                                    // margin: EdgeInsets.symmetric(vertical: 5), // separatorBuilder ile ayarlandı
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: ListTile(
                                      leading: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: exercise.imageUrl != null &&
                                                Uri.tryParse(exercise.imageUrl!)
                                                        ?.hasAbsolutePath ==
                                                    true
                                            ? Image.network(
                                                exercise.imageUrl!,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Icon(Icons.broken_image,
                                                        size: 40),
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                      child: SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2)));
                                                },
                                              )
                                            : Icon(Icons.fitness_center,
                                                size: 40),
                                      ),
                                      title: Text(exercise.name,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500)),
                                      subtitle: Text(_buildSubtitleText(set)),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            color: Colors.redAccent),
                                        onPressed: () => _deleteExercise(
                                            programItem.id!, set.exerciseId!),
                                        tooltip: 'Egzersizi Sil',
                                      ),
                                      onTap: () {
                                        // Egzersiz detaylarını düzenleme dialogunu aç
                                        _showEditSetDialog(programItem, set);
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Helper extension for max function on empty list (requires collection package)
// extension MaxValue<T extends num> on Iterable<T> {
//   T? maxOrNull() => isEmpty ? null : reduce(max);
// }
// Note: `reduce(max)` already handles non-empty lists. Need check for empty.
// The logic inside _addExercise already handles the empty case correctly.
