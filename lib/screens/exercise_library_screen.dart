import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/exercise_service.dart';
import '../models/exercise_model.dart';
import '../theme.dart';
import '../widgets/kaplan_appbar.dart'; // KaplanAppBar'ı kullanacağız
import 'add_edit_exercise_screen.dart'; // Oluşturduğumuz ekranı import et
// import 'add_edit_exercise_screen.dart'; // Henüz oluşturulmadı

class ExerciseLibraryScreen extends StatefulWidget {
  /// Eğer bu ekran egzersiz seçmek için açıldıysa true olur.
  final bool isSelectionMode;

  const ExerciseLibraryScreen({Key? key, this.isSelectionMode = false})
      : super(key: key);

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  // _exercisesFuture değişkenini late tanımlamak yerine doğrudan tanımlıyorum
  Future<List<Exercise>> _exercisesFuture = Future.value([]);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // Seçilen egzersizleri tutmak için Set (benzersizlik sağlar)
  final Set<Exercise> _selectedExercises = {};

  @override
  void initState() {
    super.initState();
    print("ExerciseLibraryScreen: initState çağrıldı");
    // Asenkron olarak egzersizleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExercises();
    });
  }

  void _loadExercises() {
    print("ExerciseLibraryScreen: egzersizler yükleniyor...");
    try {
      final exerciseService =
          Provider.of<ExerciseService>(context, listen: false);
      // Seçim modunda tüm egzersizleri yüklemek daha mantıklı olabilir
      // veya filtrelemeye devam edilebilir.
      _exercisesFuture = exerciseService.getExercises(query: _searchQuery);
      if (mounted) {
        setState(() {
          print(
              "ExerciseLibraryScreen: egzersizler yüklendi, UI güncelleniyor");
        });
      }
    } catch (e) {
      print("ExerciseLibraryScreen: egzersizler yüklenirken hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Egzersizler yüklenirken hata oluştu: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Egzersiz seçme/seçimi kaldırma
  void _toggleSelection(Exercise exercise) {
    setState(() {
      if (_selectedExercises.contains(exercise)) {
        _selectedExercises.remove(exercise);
      } else {
        _selectedExercises.add(exercise);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: KaplanAppBar(
        // Seçim moduna göre başlık ve action'ları ayarla
        title: widget.isSelectionMode ? 'Egzersiz Seç' : 'Egzersiz Kütüphanesi',
        isDarkMode: isDarkMode,
        showBackButton: true, // Geri dönüş butonunu göster
        isRequiredPage: true, // AppBar'ın her zaman görünmesini sağla
        actions: widget.isSelectionMode
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton(
                    onPressed: () {
                      if (_selectedExercises.isNotEmpty) {
                        Navigator.of(context).pop(_selectedExercises);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Lütfen en az bir egzersiz seçin.')),
                        );
                      }
                    },
                    child: Text(
                      'Ekle (${_selectedExercises.length})',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ]
            : null,
      ),
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Egzersiz ara...',
                prefixIcon: Icon(Icons.search,
                    color: isDarkMode ? Colors.white70 : Colors.black54),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color:
                                isDarkMode ? Colors.white70 : Colors.black54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _loadExercises();
                        },
                      )
                    : null,
                filled: true,
                fillColor:
                    isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
              onChanged: (value) {
                // Her harfte değil, belirli bir süre sonra arama yapmak daha performanslı olabilir
                // Debounce eklenebilir.
                setState(() {
                  _searchQuery = value;
                });
                _loadExercises();
              },
            ),
          ),
          // TODO: Kas grubu filtreleme widget'ları buraya eklenebilir (örn: Chips)
          Expanded(
            child: FutureBuilder<List<Exercise>>(
              future: _exercisesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child:
                          Text('Egzersizler yüklenemedi: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Egzersiz bulunamadı.',
                          style: TextStyle(fontSize: 16)));
                } else {
                  final exercises = snapshot.data!;
                  return ListView.separated(
                    itemCount: exercises.length,
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      final bool isSelected =
                          _selectedExercises.contains(exercise);

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: widget.isSelectionMode && isSelected
                                ? BorderSide(
                                    color: AppTheme.primaryColor, width: 1.5)
                                : BorderSide.none),
                        color: isDarkMode
                            ? (isSelected
                                ? AppTheme.darkSurfaceColor
                                : AppTheme.darkCardBackgroundColor)
                            : (isSelected
                                ? AppTheme.primaryColor.withOpacity(0.05)
                                : Colors.white),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor
                                .withOpacity(isSelected ? 0.25 : 0.1),
                            child: Icon(
                              _getMuscleGroupIcon(exercise.targetMuscleGroup),
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(exercise.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87)),
                          subtitle: Text(
                              '${exercise.targetMuscleGroup}${exercise.equipment != null ? ' - ${exercise.equipment}' : ''}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey.shade600)),
                          trailing: widget.isSelectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    _toggleSelection(exercise);
                                  },
                                  activeColor: AppTheme.primaryColor,
                                )
                              : IconButton(
                                  icon: Icon(Icons.edit_note,
                                      color: isDarkMode
                                          ? Colors.white54
                                          : Colors.black45),
                                  onPressed: () {
                                    _navigateToEditExercise(exercise);
                                  },
                                  tooltip: 'Egzersizi Düzenle',
                                ),
                          onTap: () {
                            if (widget.isSelectionMode) {
                              // Seçim modunda tıklayınca seçimi değiştir
                              _toggleSelection(exercise);
                            } else {
                              // Normal modda detayları göster
                              _showExerciseDetails(exercise);
                            }
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      // Seçim modunda FAB'ı gösterme
      floatingActionButton: widget.isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                _navigateToAddNewExercise();
              },
              child: const Icon(Icons.add, color: Colors.white),
              backgroundColor: AppTheme.accentColor,
              tooltip: 'Yeni Egzersiz Ekle',
            ),
    );
  }

  IconData _getMuscleGroupIcon(String muscleGroup) {
    // Basit bir ikon eşleştirmesi, daha detaylı yapılabilir
    switch (muscleGroup.toLowerCase()) {
      case 'göğüs':
        return Icons.fitness_center; // Örnek ikon
      case 'sırt':
        return Icons.airline_seat_recline_normal; // Örnek ikon
      case 'bacak':
        return Icons.directions_run; // Örnek ikon
      case 'omuz':
        return Icons.accessibility_new; // Örnek ikon
      case 'arka kol':
      case 'ön kol':
        return Icons.fitness_center; // Örnek ikon
      case 'karın':
        return Icons.self_improvement; // Örnek ikon
      case 'bel sağlığı':
        return Icons.healing; // Örnek ikon
      default:
        return Icons.sports_gymnastics; // Varsayılan ikon
    }
  }

  Future<void> _navigateToAddNewExercise() async {
    final result = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => const AddEditExerciseScreen()));
    if (result == true) {
      _loadExercises();
    }
  }

  Future<void> _navigateToEditExercise(Exercise exercise) async {
    final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => AddEditExerciseScreen(exercise: exercise)));
    if (result == true) {
      _loadExercises();
    }
  }

  void _showExerciseDetails(Exercise exercise) {
    // Egzersiz detaylarını gösteren bir dialog veya alt sayfa açılabilir.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exercise.name),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Kas Grubu: ${exercise.targetMuscleGroup}'),
              if (exercise.equipment != null)
                Text('Ekipman: ${exercise.equipment}'),
              if (exercise.description.isNotEmpty)
                Text('Açıklama: ${exercise.description}'),
              // TODO: Video oynatıcı veya link eklenebilir
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Kapat'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
