import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/program_model.dart';
import '../models/program_set.dart';
import '../models/exercise_model.dart';
import '../services/exercise_service.dart';
import '../screens/exercise_library_screen.dart';
import '../services/program_service.dart';

class ProgramDetailDialog extends StatefulWidget {
  final ProgramItem programItem;
  final String type;

  const ProgramDetailDialog({
    Key? key,
    required this.programItem,
    required this.type,
  });

  @override
  State<ProgramDetailDialog> createState() => _ProgramDetailDialogState();
}

class _ProgramDetailDialogState extends State<ProgramDetailDialog> {
  late TextEditingController _descriptionController;
  late String _dialogTitle;
  late IconData _dialogIcon;
  late Color _dialogColor;
  late List<ProgramSet> _currentProgramSets;
  Map<String, Exercise> _exerciseDetails = {};
  bool _detailsLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.programItem.description);
    _currentProgramSets =
        List<ProgramSet>.from(widget.programItem.programSets ?? []);

    // Program türüne ve verilerine göre dialog başlığını ve simgesini ayarla
    switch (widget.type) {
      case 'morning':
        _dialogTitle = 'Sabah Aktivitesi';
        _dialogIcon = Icons.wb_sunny;
        _dialogColor = Colors.orange;
        break;
      case 'lunch':
        _dialogTitle = 'Öğle Yemeği';
        _dialogIcon = Icons.restaurant;
        _dialogColor = Colors.brown;
        break;
      case 'evening':
        _dialogTitle = 'Akşam Aktivitesi';
        _dialogIcon = Icons.nightlight_round;
        _dialogColor = Colors.deepPurple;
        break;
      case 'dinner':
        _dialogTitle = 'Akşam Yemeği';
        _dialogIcon = Icons.dinner_dining;
        _dialogColor = Colors.teal;
        break;
      default:
        _dialogTitle = 'Program Detayı';
        _dialogIcon = Icons.calendar_today;
        _dialogColor = Colors.blue;
    }

    // Eğer workout ise egzersiz detaylarını yükle
    if (widget.programItem.type == ProgramItemType.workout &&
        _currentProgramSets.isNotEmpty) {
      _loadExerciseDetails();
    }
  }

  Future<void> _loadExerciseDetails() async {
    if (!mounted) return;
    setState(() {
      _detailsLoading = true;
    });
    try {
      final exerciseService =
          Provider.of<ExerciseService>(context, listen: false);
      final exerciseIds = _currentProgramSets
          .map((ps) => ps.exerciseId)
          .where((id) => id != null)
          .cast<String>() // non-null ID'leri al
          .toSet(); // Benzersiz ID'ler

      if (exerciseIds.isNotEmpty) {
        final detailsList =
            await exerciseService.getExercisesByIds(exerciseIds.toList());
        if (detailsList != null && mounted) {
          setState(() {
            _exerciseDetails = Map.fromEntries(detailsList
                .where((ex) => ex.id != null)
                .map((ex) => MapEntry(ex.id!, ex)));
            _detailsLoading = false;
            debugPrint(
                "Egzersiz detayları yüklendi: ${_exerciseDetails.length} adet");
          });
        } else {
          setState(() => _detailsLoading = false);
        }
      } else {
        setState(() => _detailsLoading = false);
      }
    } catch (e) {
      debugPrint("Egzersiz detayları yüklenirken hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Egzersiz detayları yüklenemedi.')),
        );
        setState(() => _detailsLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWorkout = widget.programItem.type == ProgramItemType.workout;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Icon(_dialogIcon, color: _dialogColor),
          const SizedBox(width: 10),
          Expanded(child: Text(_dialogTitle)),
          // İki farklı ekleme seçeneği sunuyoruz
          PopupMenuButton<String>(
            tooltip: 'Ekle',
            icon: Icon(Icons.add_circle_outline,
                color: Theme.of(context).iconTheme.color),
            onSelected: (String value) {
              if (value == 'single_exercise') {
                _navigateToAddExercise();
              } else if (value == 'category') {
                _navigateToSelectCategory();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'single_exercise',
                child: ListTile(
                  leading: Icon(Icons.fitness_center),
                  title: Text('Tek Egzersiz Ekle'),
                  dense: true,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'category',
                child: ListTile(
                  leading: Icon(Icons.category),
                  title: Text('Kategori Seç'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        height:
            350, // Sabit bir yükseklik ekleyerek ScrollView sorununu çözüyoruz
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              minLines: 3,
            ),
            // Tüm öğe türleri için egzersiz listesini görüntüleme seçeneği ekle
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Text('Egzersizler', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Expanded(
              child: _buildExerciseList(isDarkMode),
            ),
            const SizedBox(height: 10),
            Text(
              'Açıklama ve egzersiz listesi beraber kaydedilir. İstediğiniz kombinasyonu kullanabilirsiniz.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            // Programı güncelle ve yeni nesne oluştur
            final updatedItem = ProgramItem(
              id: widget.programItem.id,
              type: widget.programItem.type,
              title: widget.programItem.title,
              description: _descriptionController.text,
              programSets: _currentProgramSets,
              icon: widget.programItem.icon,
              color: widget.programItem.color,
              time: widget.programItem.time,
            );

            Navigator.of(context).pop(updatedItem);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _dialogColor,
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  Widget _buildExerciseList(bool isDarkMode) {
    if (_detailsLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_currentProgramSets.isEmpty) {
      return Center(
        child: Text(
          'Henüz egzersiz eklenmemiş.\nYukarıdaki + butonu ile ekleyebilirsiniz.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _currentProgramSets.length,
      itemBuilder: (context, index) {
        final programSet = _currentProgramSets[index];
        final exerciseDetail = _exerciseDetails[programSet.exerciseId];
        final exerciseName =
            exerciseDetail?.name ?? 'Egzersiz ID: ${programSet.exerciseId}';

        String details = '';
        if (programSet.setsDescription != null &&
            programSet.repsDescription != null) {
          details +=
              '${programSet.setsDescription} set x ${programSet.repsDescription} tekrar';
        } else if (programSet.repsDescription != null) {
          details += '${programSet.repsDescription}';
        }

        return ListTile(
          dense: true,
          leading: Icon(Icons.fitness_center,
              size: 18, color: isDarkMode ? Colors.white70 : Colors.black54),
          title: Text(exerciseName, style: TextStyle(fontSize: 14)),
          subtitle: details.isNotEmpty
              ? Text(details, style: TextStyle(fontSize: 12))
              : null,
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            tooltip: 'Egzersizi Sil',
            onPressed: () {
              setState(() {
                _currentProgramSets.removeAt(index);
              });
            },
          ),
        );
      },
    );
  }

  void _navigateToAddExercise() async {
    if (!mounted) return;

    final selectedExercises = await Navigator.push<List<Exercise>>(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseLibraryScreen(isSelectionMode: true),
      ),
    );

    if (selectedExercises != null && selectedExercises.isNotEmpty) {
      if (!mounted) return;
      final newSets = selectedExercises.map((ex) {
        if (!_exerciseDetails.containsKey(ex.id)) {
          _exerciseDetails[ex.id!] = ex;
        }
        return ProgramSet(
            exerciseId: ex.id!,
            order:
                _currentProgramSets.length + selectedExercises.indexOf(ex) + 1,
            setsDescription: '?',
            repsDescription: '?',
            exerciseDetails: ex);
      }).toList();

      setState(() {
        _currentProgramSets.addAll(newSets);
      });
      debugPrint(
          "Seçilen egzersizler eklendi: ${selectedExercises.map((e) => e.name)}");
    } else {
      debugPrint("Egzersiz seçilmedi veya iptal edildi.");
    }
  }

  void _navigateToSelectCategory() async {
    final programService = Provider.of<ProgramService>(context, listen: false);
    final allProgramItems =
        programService.getAllProgramItemsIncludingUnassigned();

    // Antrenman türündeki programları filtrele
    final workoutPrograms = allProgramItems
        .where((item) =>
            item.type == ProgramItemType.workout &&
            (item.title?.isNotEmpty ?? false) &&
            (item.programSets?.isNotEmpty ?? false))
        .toList();

    // Kategorilere göre grupla
    final groupedPrograms = Map<String, List<ProgramItem>>();
    for (var item in workoutPrograms) {
      if (item.title != null) {
        if (!groupedPrograms.containsKey(item.title)) {
          groupedPrograms[item.title!] = [];
        }
        groupedPrograms[item.title!]!.add(item);
      }
    }

    // Kategori sıralama
    final categoryOrder = [
      'Göğüs & Arka Kol',
      'Sırt & Ön Kol',
      'Omuz & Bacak & Karın',
      'Bel Sağlığı Egzersizleri',
      'Kardiyo & Diğer Aktiviteler',
    ];

    List<String> sortedCategories = groupedPrograms.keys.toList();
    sortedCategories.sort((a, b) {
      int indexA = categoryOrder.indexOf(a);
      int indexB = categoryOrder.indexOf(b);
      if (indexA == -1 && a != 'Diğer Antrenmanlar')
        indexA = categoryOrder.length;
      if (indexB == -1 && b != 'Diğer Antrenmanlar')
        indexB = categoryOrder.length;
      if (a == 'Diğer Antrenmanlar') indexA = categoryOrder.length + 1;
      if (b == 'Diğer Antrenmanlar') indexB = categoryOrder.length + 1;
      return indexA.compareTo(indexB);
    });

    // Kategori seçme dialogu göster
    showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Antrenman Kategorisi Seç'),
          content: Container(
            width: double.maxFinite, height: 300, // Sabit yükseklik
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                final category = sortedCategories[index];
                final items = groupedPrograms[category]!;
                int exerciseCount = 0;
                for (var item in items) {
                  exerciseCount += item.programSets?.length ?? 0;
                }

                return ListTile(
                  leading: Icon(_getCategoryIcon(category),
                      color: Theme.of(context).primaryColor),
                  title: Text(category),
                  subtitle: Text('$exerciseCount egzersiz'),
                  onTap: () {
                    Navigator.pop(dialogContext, category);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('İptal'),
            ),
          ],
        );
      },
    ).then((selectedCategory) {
      if (selectedCategory != null && selectedCategory.isNotEmpty) {
        // Seçilen kategorideki ilk program öğesini al
        final selectedItems = groupedPrograms[selectedCategory]!;
        if (selectedItems.isNotEmpty &&
            selectedItems.first.programSets != null) {
          final selectedSets = selectedItems.first.programSets!;

          // Egzersiz detaylarını yükle
          _loadExerciseDetailsForSets(selectedSets).then((_) {
            setState(() {
              // Mevcut programdaki egzersizleri seçilen kategoridekilerle değiştir
              // Boş veya geçersiz ID'ler için ek kontrol
              List<ProgramSet> validSets = selectedSets.where((set) {
                return set.exerciseId != null && set.exerciseId!.isNotEmpty;
              }).toList();

              // Set içeriği ataması
              _currentProgramSets = validSets;

              // Başlığı da güncelle - "Akşam Antremanı: Kategori Adı" veya sabah için "Sabah Antremanı: Kategori Adı" şeklinde
              String timePrefix = "";
              if (widget.type == 'morning') {
                timePrefix = "Sabah Antremanı: ";
              } else if (widget.type == 'evening') {
                timePrefix = "Akşam Antremanı: ";
              }

              // Program başlığı ve dialog başlığı güncelleme
              widget.programItem.title = timePrefix + selectedCategory;
              _dialogTitle = timePrefix + selectedCategory;

              // Program türünü workout olarak ayarla
              widget.programItem.type = ProgramItemType.workout;
            });
          });
        }
      }
    });
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Göğüs & Arka Kol':
        return Icons.fitness_center;
      case 'Sırt & Ön Kol':
        return Icons.rowing;
      case 'Omuz & Bacak & Karın':
        return Icons.directions_run;
      case 'Bel Sağlığı Egzersizleri':
        return Icons.self_improvement;
      case 'Kardiyo & Diğer Aktiviteler':
        return Icons.directions_walk;
      default:
        return Icons.category;
    }
  }

  Future<void> _loadExerciseDetailsForSets(List<ProgramSet> sets) async {
    if (!mounted) return;

    setState(() => _detailsLoading = true);
    try {
      final exerciseService =
          Provider.of<ExerciseService>(context, listen: false);

      // Egzersiz ID'lerini topla
      Set<String> exerciseIds = {};
      for (var set in sets) {
        if (set.exerciseId != null) {
          exerciseIds.add(set.exerciseId!);
        }
      }

      if (exerciseIds.isNotEmpty) {
        final exerciseDetails =
            await exerciseService.getExercisesByIds(exerciseIds.toList());
        if (exerciseDetails != null && mounted) {
          setState(() {
            for (var exercise in exerciseDetails) {
              _exerciseDetails[exercise.id!] = exercise;
            }
            _detailsLoading = false;
          });
        } else {
          setState(() => _detailsLoading = false);
        }
      } else {
        setState(() => _detailsLoading = false);
      }
    } catch (e) {
      debugPrint("Egzersiz detayları yüklenirken hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Egzersiz detayları yüklenemedi.')),
        );
        setState(() => _detailsLoading = false);
      }
    }
  }
}
