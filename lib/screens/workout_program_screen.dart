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

class WorkoutProgramScreen extends StatefulWidget {
  const WorkoutProgramScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutProgramScreen> createState() => _WorkoutProgramScreenState();
}

class _WorkoutProgramScreenState extends State<WorkoutProgramScreen> {
  List<ProgramItem> _workoutPrograms = [];
  Map<String, Exercise> _exerciseDetails =
      {}; // exerciseId -> Exercise (Liste yerine tekil)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print("[WorkoutProgramScreen] initState called.");
    _loadWorkoutPrograms();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadWorkoutPrograms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final programService =
          Provider.of<ProgramService>(context, listen: false);
      final exerciseService =
          Provider.of<ExerciseService>(context, listen: false);

      // ProgramService'den tüm ProgramItem'ları al ve sadece workout olanları filtrele
      // getAllProgramItems ProgramService'e eklendi varsayımıyla devam ediyoruz.
      final allProgramItems = programService.getAllProgramItems();
      _workoutPrograms = allProgramItems
          .where((item) => item.type == ProgramItemType.workout)
          .toList();

      // Workout programlarındaki tüm egzersiz ID'lerini topla (null olmayanları)
      Set<String> exerciseIds = {};
      for (var workout in _workoutPrograms) {
        if (workout.programSets != null) {
          for (var set in workout.programSets!) {
            if (set.exerciseId != null) {
              exerciseIds.add(set.exerciseId!);
            }
          }
        }
      }

      // ExerciseService'ten egzersiz detaylarını çek
      if (exerciseIds.isNotEmpty) {
        // Yeni eklenen getExercisesByIds metodunu kullan
        final List<Exercise>? detailsList =
            await exerciseService.getExercisesByIds(exerciseIds.toList());

        // Dönen Listeyi Map'e çevir
        if (detailsList != null) {
          _exerciseDetails = Map.fromEntries(detailsList
                  .where((ex) => ex.id != null) // Null ID'leri filtrele
                  .map((ex) => MapEntry(ex.id!, ex)) // MapEntry oluştur
              );
        } else {
          _exerciseDetails = {}; // Detaylar null ise boş map ata
        }
      }
    } catch (e) {
      print("Antrenman programları yüklenirken hata: $e");
      // Hata mesajı gösterilebilir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Antrenman programları yüklenemedi.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Programları kategorilere göre grupla (Örn: Göğüs & Arka Kol)
  Map<String, List<ProgramItem>> _groupProgramsByCategory() {
    return groupBy(_workoutPrograms, (ProgramItem item) {
      String titleLower = item.title.toLowerCase();
      if (titleLower.contains('göğüs') || titleLower.contains('arka kol')) {
        return 'Göğüs & Arka Kol';
      } else if (titleLower.contains('sırt') || titleLower.contains('ön kol')) {
        return 'Sırt & Ön Kol';
      } else if (titleLower.contains('omuz') ||
          titleLower.contains('bacak') ||
          titleLower.contains('karın')) {
        return 'Omuz & Bacak & Karın';
      } else if (titleLower.contains('bel sağlığı') ||
          titleLower.contains('pelvic tilt') ||
          titleLower.contains('cat-camel') ||
          titleLower.contains('bird-dog')) {
        // Bel Sağlığı egzersizlerini ayrı grupla
        return 'Bel Sağlığı Egzersizleri';
      } else if (titleLower.contains('kardiyo') ||
          titleLower.contains('yüzme') ||
          titleLower.contains('yürüyüş') ||
          titleLower.contains('esneme')) {
        // Kardiyo ve diğer aktiviteleri ayrı grupla
        return 'Kardiyo & Diğer Aktiviteler';
      }
      return 'Diğer Antrenmanlar'; // Kalanları grupla
    });
  }

  @override
  Widget build(BuildContext context) {
    print("[WorkoutProgramScreen] build called. isLoading: $_isLoading");
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final groupedPrograms = _groupProgramsByCategory();
    final categoryOrder = [
      'Göğüs & Arka Kol',
      'Sırt & Ön Kol',
      'Omuz & Bacak & Karın',
      'Bel Sağlığı Egzersizleri',
      'Kardiyo & Diğer Aktiviteler', // Yeni kategoriyi ekle
      'Diğer Antrenmanlar' // Diğer kategorisini de ekle
    ];
    // Kategorileri filtrele ve sırala
    final availableCategories = groupedPrograms.keys
        .where((key) => key != 'Diğer Antrenmanlar')
        .toList(); // 'Diğer Antrenmanlar' hariç tut
    final sortedCategories = availableCategories
      ..sort((a, b) {
        int indexA = categoryOrder.indexOf(a);
        int indexB = categoryOrder.indexOf(b);
        // Eğer kategori order listesinde yoksa sona ata
        if (indexA == -1) indexA = categoryOrder.length;
        if (indexB == -1) indexB = categoryOrder.length;
        return indexA.compareTo(indexB);
      });

    return Scaffold(
      appBar: KaplanAppBar(
        title: 'Antrenman Programı',
        isDarkMode: isDarkMode,
        isRequiredPage: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _workoutPrograms.isEmpty
              ? Center(child: Text('Yüklenecek antrenman programı bulunamadı.'))
              : ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  itemCount: sortedCategories.length,
                  itemBuilder: (context, index) {
                    final category = sortedCategories[index];
                    final programsInCategory = groupedPrograms[category];

                    if (programsInCategory == null ||
                        programsInCategory.isEmpty) {
                      return SizedBox.shrink();
                    }

                    return Container(
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
                          title: Text(
                            category,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          leading: Icon(
                            _getCategoryIcon(category),
                            color: AppTheme.primaryColor,
                          ),
                          children: programsInCategory.expand((programItem) {
                            if (programItem.programSets == null ||
                                programItem.programSets!.isEmpty) {
                              return <Widget>[];
                            }

                            return programItem.programSets!.map((set) {
                              final exercise = _exerciseDetails[set.exerciseId];
                              if (exercise == null) {
                                print(
                                    "Exercise detail not found for ID: ${set.exerciseId}");
                                return SizedBox.shrink();
                              }
                              return Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.black12
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.white10
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppTheme.primaryColor.withOpacity(0.2),
                                    child: Icon(
                                      Icons.fitness_center,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  title: Text(
                                    exercise.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${set.setsDescription} x ${set.repsDescription}',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                  trailing: exercise.videoUrl != null
                                      ? Icon(
                                          Icons.play_circle_outline,
                                          color: AppTheme.primaryColor,
                                        )
                                      : null,
                                  onTap: () => _showExerciseDetails(exercise),
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

  // Kategoriye göre ikon döndüren yardımcı fonksiyon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Göğüs & Arka Kol':
        return Icons.fitness_center;
      case 'Sırt & Ön Kol':
        return Icons.rowing;
      case 'Omuz & Bacak & Karın':
        return Icons.directions_run;
      case 'Bel Sağlığı Egzersizleri':
        return Icons.self_improvement; // Yeni ikon
      case 'Kardiyo & Diğer Aktiviteler':
        return Icons.directions_walk; // Yeni ikon
      default:
        return Icons.loop;
    }
  }

  // Egzersiz detaylarını gösteren dialog
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

  // Video oynatıcı dialog
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
        // isLive: false, // Canlı yayın değilse
        // forceHD: false,
        // enableCaption: true,
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
          onReady: () {
            // _controller.addListener(listener);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _controller.pause(); // Videoyu durdur
              Navigator.pop(context);
            },
            child: Text('Kapat'),
          ),
        ],
      ),
    ).then((_) {
      // Dialog kapandığında kontrolcüyü temizle
      _controller.dispose();
    });
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