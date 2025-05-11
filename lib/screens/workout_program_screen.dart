import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // Youtube player importu
import '../services/program_service.dart';
import '../services/exercise_service.dart';
import '../models/program_model.dart';
import '../models/program_set.dart';
import '../models/exercise_model.dart';
import '../widgets/kaplan_appbar.dart'; // KaplanAppBar kullanacağız
import '../theme.dart';
import 'package:collection/collection.dart'; // groupBy için
import 'package:url_launcher/url_launcher.dart';
import 'edit_program_category_screen.dart'; // Bu satırı ekleyin

class WorkoutProgramScreen extends StatefulWidget {
  const WorkoutProgramScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutProgramScreen> createState() => _WorkoutProgramScreenState();
}

class _WorkoutProgramScreenState extends State<WorkoutProgramScreen> {
  Map<String, Exercise> _exerciseDetails =
      {}; // Build'de kullanmak için state'e taşı
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print("[WorkoutProgramScreen] initState called.");
    _loadInitialExerciseDetails();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadInitialExerciseDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true); // Yükleme başlangıcı
    Map<String, Exercise> loadedDetails = {}; // Geçici map
    try {
      final programService =
          Provider.of<ProgramService>(context, listen: false);
      final exerciseService =
          Provider.of<ExerciseService>(context, listen: false);

      final allProgramItems =
          programService.getAllProgramItemsIncludingUnassigned();
      final workoutPrograms = allProgramItems
          .where((item) =>
              item.type == ProgramItemType.workout &&
              (item.title?.isNotEmpty ?? false))
          .toList();

      Set<String> exerciseIds = {};
      for (var workout in workoutPrograms) {
        workout.programSets?.forEach((set) {
          if (set.exerciseId != null) {
            exerciseIds.add(set.exerciseId!);
          }
        });
      }

      if (exerciseIds.isNotEmpty) {
        print(
            "[WorkoutScreen][_loadInitialExerciseDetails] Fetching details for ${exerciseIds.length} exercise IDs...");
        final List<Exercise>? detailsList =
            await exerciseService.getExercisesByIds(exerciseIds.toList());

        if (detailsList != null) {
          loadedDetails = Map.fromEntries(detailsList // Geçici map'e ata
              .where((ex) => ex.id != null)
              .map((ex) => MapEntry(ex.id!, ex)));
          print(
              "[WorkoutScreen][_loadInitialExerciseDetails] Loaded details for ${loadedDetails.length} exercises.");
        } else {
          print(
              "[WorkoutScreen][_loadInitialExerciseDetails] Exercise details list was null.");
        }
      } else {
        print(
            "[WorkoutScreen][_loadInitialExerciseDetails] No exercise IDs found.");
      }
    } catch (e, stackTrace) {
      print("Initial exercise details load error: $e\nStackTrace: $stackTrace");
    } finally {
      if (mounted) {
        setState(() {
          _exerciseDetails = loadedDetails; // State'i güncelle
          _isLoading = false; // Yükleme bitti
        });
      }
    }
  }

  Map<String, List<ProgramItem>> _groupProgramsByCategory(
      List<ProgramItem> workoutPrograms) {
    print(
        "[WorkoutScreen][_groupProgramsByCategory] Grouping ${workoutPrograms.length} workout items...");
    return groupBy(workoutPrograms, (ProgramItem item) {
      String categoryResult = item.title ?? 'Diğer Antrenmanlar';
      return categoryResult;
    });
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return _AddCategoryDialog(); // Kullanılacak yeni StatefulWidget
      },
    ).then((newCategoryName) {
      if (newCategoryName != null && newCategoryName.isNotEmpty) {
        if (!mounted) return;

        final newId = 'category_${DateTime.now().millisecondsSinceEpoch}';
        final newProgramItem = ProgramItem(
          id: newId,
          title: newCategoryName,
          type: ProgramItemType.workout,
          programSets: [],
          icon: Icons.fitness_center,
          color: Colors.purple,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProgramCategoryScreen(
                  categoryName: newCategoryName,
                  programItems: [newProgramItem],
                ),
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print("[WorkoutProgramScreen] build called. isLoading: $_isLoading");
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final programService = context.watch<ProgramService>();

    final allProgramItems =
        programService.getAllProgramItemsIncludingUnassigned();
    final workoutPrograms = allProgramItems
        .where((item) =>
            item.type == ProgramItemType.workout &&
            (item.title?.isNotEmpty ?? false))
        .toList();

    final groupedPrograms = _groupProgramsByCategory(workoutPrograms);

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

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey[100],
      appBar: KaplanAppBar(
        title: 'Antrenman Programı',
        isDarkMode: isDarkMode,
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit,
                color: isDarkMode ? Colors.white : Colors.black),
            tooltip: 'Kategorileri Düzenle',
            onPressed: () => _showCategoryEditDialog(context, sortedCategories),
          ),
          IconButton(
            icon: Icon(Icons.add,
                color: isDarkMode ? Colors.white : Colors.black),
            tooltip: 'Yeni Kategori Ekle',
            onPressed: () => _showAddCategoryDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : workoutPrograms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Yüklenecek antrenman programı bulunamadı.'),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                          onPressed: () => _showAddCategoryDialog(context),
                          icon: Icon(Icons.add),
                          label: Text('İlk Kategoriyi Ekle'))
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(0, 12, 0, 80),
                  itemCount: sortedCategories.length,
                  itemBuilder: (context, index) {
                    final category = sortedCategories[index];
                    final programsInCategory = groupedPrograms[category] ?? [];

                    return Container(
                      key: ValueKey('container_$category'),
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Color(0xFF1E1E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                background: isDarkMode
                                    ? Color(0xFF1E1E2E)
                                    : Colors.white,
                              ),
                        ),
                        child: ExpansionTile(
                          key: ValueKey(category),
                          initiallyExpanded: false,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          leading: Icon(
                            _getCategoryIcon(category),
                            color: AppTheme.primaryColor,
                          ),
                          children: programsInCategory.isEmpty
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    child: Text(
                                      'Bu kategoride henüz egzersiz yok. Düzenle ikonuna basarak ekleyebilirsiniz.',
                                      style: TextStyle(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                ]
                              : programsInCategory.expand((programItem) {
                                  if (programItem.programSets == null ||
                                      programItem.programSets!.isEmpty) {
                                    return <Widget>[];
                                  }
                                  programItem.programSets!.sort(
                                      (a, b) => (a.order).compareTo(b.order));

                                  return programItem.programSets!.map((set) {
                                    final exercise =
                                        _exerciseDetails[set.exerciseId];

                                    if (exercise == null) {
                                      return ListTile(
                                          title: Text(
                                              "Egzersiz ID: ${set.exerciseId} bulunamadı"));
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 4.0),
                                      child: InkWell(
                                        onTap: () =>
                                            _showExerciseDetails(exercise),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? Colors.white.withOpacity(0.05)
                                                : Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: AppTheme
                                                    .primaryColor
                                                    .withOpacity(0.1),
                                                child: Icon(
                                                  Icons.fitness_center,
                                                  size: 20,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      exercise.name,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${set.setsDescription ?? '-'} x ${set.repsDescription ?? '-'}' +
                                                          (set.restTimeDescription !=
                                                                  null
                                                              ? ' | Dinlenme: ${set.restTimeDescription}'
                                                              : ''),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isDarkMode
                                                            ? Colors.white60
                                                            : Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (exercise.videoUrl != null)
                                                Icon(
                                                  Icons.play_circle_outline,
                                                  color: AppTheme.primaryColor
                                                      .withOpacity(0.7),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList();
                                }).toList(),
                        ),
                      ),
                    );
                  },
                ),
    );
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
        return Icons.loop;
    }
  }

  void _showExerciseDetails(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('Kas Grubu: ${exercise.targetMuscleGroup}'),
              if (exercise.equipment != null)
                Text('Ekipman: ${exercise.equipment}'),
              if (exercise.description?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Açıklama: ${exercise.description}'),
                ),
              if (exercise.videoUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showVideoPlayer(exercise.videoUrl!);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_outline),
                        SizedBox(width: 8),
                        Text('Videoyu İzle'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVideoPlayer(String videoUrl) {
    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);

    if (videoId == null) {
      print("Geçersiz YouTube URL'si: $videoUrl");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Geçersiz YouTube video URL\'si.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    YoutubePlayerController _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppTheme.primaryColor,
          progressColors: ProgressBarColors(
            playedColor: AppTheme.primaryColor,
            handleColor: AppTheme.primaryColor.withOpacity(0.8),
          ),
          onReady: () {},
        ),
        actions: [
          TextButton(
            onPressed: () {
              _controller.pause();
              Navigator.pop(context);
            },
            child: Text('Kapat'),
          ),
        ],
      ),
    ).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.dispose();
      });
    });
  }

  void _showCategoryEditDialog(BuildContext context, List<String> categories) {
    final programService = context.read<ProgramService>();
    final allProgramItems =
        programService.getAllProgramItemsIncludingUnassigned();
    final workoutPrograms = allProgramItems
        .where((item) =>
            item.type == ProgramItemType.workout &&
            (item.title?.isNotEmpty ?? false))
        .toList();
    final groupedPrograms = _groupProgramsByCategory(workoutPrograms);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Düzenlenecek Kategoriyi Seçin'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final programsInCategory = groupedPrograms[category] ?? [];

                int exerciseCount = 0;
                for (var item in programsInCategory) {
                  exerciseCount += item.programSets?.length ?? 0;
                }

                return ListTile(
                  title: Text(category),
                  subtitle: Text('${exerciseCount} egzersiz'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProgramCategoryScreen(
                          categoryName: category,
                          programItems: programsInCategory,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}

// Yeni StatefulWidget dialog içeriği için
class _AddCategoryDialog extends StatefulWidget {
  @override
  _AddCategoryDialogState createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  late TextEditingController _categoryNameController;

  @override
  void initState() {
    super.initState();
    _categoryNameController = TextEditingController();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Yeni Kategori Ekle'),
      content: TextField(
        controller: _categoryNameController,
        decoration: InputDecoration(
          labelText: 'Kategori Adı',
          hintText: 'Örn: Bacak Günü',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: <Widget>[
        TextButton(
          child: Text('İptal'),
          onPressed: () {
            Navigator.of(context).pop(); // Değer döndürmeden kapat
          },
        ),
        TextButton(
          child: Text('Ekle'),
          onPressed: () {
            final newCategoryName = _categoryNameController.text.trim();
            if (newCategoryName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kategori adı boş olamaz')),
              );
            } else {
              Navigator.of(context)
                  .pop(newCategoryName); // Kategori adını döndürerek kapat
            }
          },
        ),
      ],
    );
  }
}

// ProgramService'te olması gereken yardımcı metotlar (varsayılan)
// Bu metotların ProgramService içinde olduğundan emin olun.
/*
extension ProgramServiceExtension on ProgramService {
  List<ProgramItem> getAllProgramItems() {
    List<ProgramItem> allItems = [];
    for (var dailyProgram in _weeklyProgram) {
      allItems.addAll(dailyProgram.items);
    }
    return allItems;
  }
}
*/
