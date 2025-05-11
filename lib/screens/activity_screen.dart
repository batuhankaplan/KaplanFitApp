import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' hide LocationAccuracy;
import 'package:geolocator/geolocator.dart';
import '../providers/activity_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/user_provider.dart';
import '../models/activity_record.dart';
import '../models/task_type.dart';
import '../theme.dart';
import '../utils/animations.dart';
import '../widgets/kaplan_loading.dart';
import '../models/exercise_model.dart';
import 'exercise_library_screen.dart';
import 'dart:io';

// Servisleri import et
import '../services/program_service.dart';
import '../services/exercise_service.dart';
import '../models/program_model.dart';
import '../models/program_set.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with TickerProviderStateMixin {
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  FitActivityType _selectedActivityType = FitActivityType.walking;

  // Konum izleme değişkenleri
  bool _hasLocationPermission = false;
  late Location _location;

  // Sabit stil tanımları
  static const _titleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const _subtitleStyle = TextStyle(
    color: Colors.grey,
    fontSize: 14,
  );

  static const _emptyStateTextStyle = TextStyle(
    fontSize: 18,
    color: Colors.grey,
  );

  static const _buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  static const _contentPadding = EdgeInsets.all(16.0);

  @override
  void initState() {
    super.initState();

    // Windows platformunda Location plugin'i kullanmayı engelle
    if (!Platform.isWindows) {
      _location = Location();
      _checkLocationPermission();
    } else {
      debugPrint('Windows platformunda konum servisleri devre dışı bırakıldı');
    }

    // Provider'a seçilen tarihi bildir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId != null) {
        Provider.of<ActivityProvider>(context, listen: false)
            .setSelectedDate(_selectedDate, userId);
      }
    });
  }

  // Konum izni kontrolü
  Future<void> _checkLocationPermission() async {
    try {
      if (_location == null) return;

      bool serviceEnabled = await _location!.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location!.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      PermissionStatus permissionStatus = await _location!.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await _location!.requestPermission();
        if (permissionStatus != PermissionStatus.granted) {
          return;
        }
      }

      setState(() {
        _hasLocationPermission = true;
      });
    } catch (e) {
      print('Konum izni hatası: $e');
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activityProvider = Provider.of<ActivityProvider>(context);
    final isLoading = activityProvider.isLoading;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? const KaplanLoading()
          : Consumer<WorkoutProvider>(
              builder: (context, workoutProv, child) {
                if (workoutProv.currentWorkoutLog != null) {
                  return _buildWorkoutInProgressView(context, workoutProv);
                } else {
                  return _buildActivityListView(
                      context, activityProvider, isDarkMode);
                }
              },
            ),
    );
  }

  Widget _buildActivityListView(BuildContext context,
      ActivityProvider activityProvider, bool isDarkMode) {
    return Column(
      children: [
        // Tarih seçici
        KFSlideAnimation(
          offsetBegin: const Offset(0, -0.2),
          duration: const Duration(milliseconds: 500),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDarkMode
                      ? const Color(0xFF2C2C2C)
                      : AppTheme.primaryColor.withOpacity(0.7),
                  isDarkMode ? const Color(0xFF1F1F1F) : AppTheme.primaryColor,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Önceki gün
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: () {
                    _changeDate(-1);
                  },
                ),

                // Seçilen tarih gösterimi
                GestureDetector(
                  onTap: _selectDate,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('d MMMM yyyy', 'tr_TR')
                            .format(_selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sonraki gün
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () {
                    _changeDate(1);
                  },
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        // Aktivite listesi
        Expanded(
          child: activityProvider.activities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      KFSlideAnimation(
                        offsetBegin: const Offset(0, 0.3),
                        child: Column(
                          children: [
                            KFWaveAnimation(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3),
                              height: 100,
                            ),
                            const SizedBox(height: 20),
                            const Icon(
                              Icons.directions_run,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bugün için aktivite yok',
                              style: _emptyStateTextStyle,
                            ),
                            const SizedBox(height: 24),
                            KFPulseAnimation(
                              maxScale: 1.05,
                              child: _buildAddActivityButton(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: activityProvider.activities.length + 1,
                  itemBuilder: (context, index) {
                    if (index == activityProvider.activities.length) {
                      return Center(
                        child: KFPulseAnimation(
                          maxScale: 1.05,
                          child: _buildAddActivityButton(),
                        ),
                      );
                    }

                    final activity = activityProvider.activities[index];
                    return KFAnimatedItem(
                      index: index,
                      child: _buildActivityCard(activity),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(ActivityRecord activity) {
    Color activityColor = _getActivityColor(activity.type);
    String activityTypeName = _getActivityTypeName(activity.type);
    String formattedDate =
        DateFormat('d MMM, HH:mm', 'tr_TR').format(activity.date);

    return Dismissible(
      key: Key('activity_${activity.id}'),
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
        Provider.of<ActivityProvider>(context, listen: false)
            .deleteActivity(activity.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$activityTypeName aktivitesi silindi'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Aktivite Sil'),
              content: Text(
                  'Bu $activityTypeName aktivitesini silmek istediğinize emin misiniz?'),
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
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: _cardShape,
        child: InkWell(
          onTap: () => _showEditActivityDialog(activity),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: _contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: activityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getActivityIcon(activity.type),
                            color: activityColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activityTypeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: _subtitleStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${activity.durationMinutes} dk',
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (activity.notes != null && activity.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Notlar:',
                    style: _subtitleStyle,
                  ),
                  Text(
                    activity.notes!,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    if (userId != null) {
      Provider.of<ActivityProvider>(context, listen: false)
          .setSelectedDate(_selectedDate, userId);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId != null) {
        Provider.of<ActivityProvider>(context, listen: false)
            .setSelectedDate(_selectedDate, userId);
      }
    }
  }

  void _showAddActivityDialog() {
    _durationController.clear();
    _notesController.clear();
    _selectedActivityType = FitActivityType.walking;
    Exercise? _selectedExercise;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Aktivite Ekle'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Aktivite türü seçici
                  _buildActivityTypeDropdown(setDialogState),
                  const SizedBox(height: 16),

                  // Süre girişi
                  _buildDurationTextField(),
                  const SizedBox(height: 16),

                  // Egzersiz Seçim Butonu
                  _buildExerciseSelectionButton(
                    context,
                    setDialogState,
                    (Exercise exercise) {
                      setDialogState(() {
                        _selectedExercise = exercise;
                        _notesController.text = (_notesController.text.isEmpty
                                ? ""
                                : "${_notesController.text}\n") +
                            "Seçilen Egzersiz: ${exercise.name}";
                        // Aktivite tipini egzersize göre ayarla (varsa)
                        if (exercise.targetMuscleGroup
                                .toLowerCase()
                                .contains('kardiyo') ||
                            exercise.name.toLowerCase().contains('kardiyo')) {
                          _selectedActivityType = FitActivityType
                              .other; // Kardiyo için genel 'other' veya özel bir tip
                        } else if (exercise.targetMuscleGroup
                                .toLowerCase()
                                .contains('koşu') ||
                            exercise.name.toLowerCase().contains('koşu')) {
                          _selectedActivityType = FitActivityType.running;
                        } else if (exercise.targetMuscleGroup
                                .toLowerCase()
                                .contains('yürüyüş') ||
                            exercise.name.toLowerCase().contains('yürüyüş')) {
                          _selectedActivityType = FitActivityType.walking;
                        } else if (exercise.targetMuscleGroup
                                .toLowerCase()
                                .contains('bisiklet') ||
                            exercise.name.toLowerCase().contains('bisiklet')) {
                          _selectedActivityType = FitActivityType.cycling;
                        } else {
                          _selectedActivityType = FitActivityType
                              .weightTraining; // Genel antrenman için
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildProgramSelectionButton(
                    context,
                    setDialogState,
                    (List<Exercise> programExercises) {
                      setDialogState(() {
                        _selectedExercise = null;
                        _selectedActivityType = FitActivityType
                            .weightTraining; // Programlar genellikle ağırlık/genel antrenmandır
                        String programNotes = programExercises
                            .map((e) => "- ${e.name}")
                            .join("\n");
                        _notesController.text = (_notesController.text.isEmpty
                                ? ""
                                : "${_notesController.text}\n") +
                            "Seçilen Program Egzersizleri:\n$programNotes";
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Ekle'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final duration = int.tryParse(_durationController.text) ?? 0;
                  if (duration > 0) {
                    final activityProvider =
                        Provider.of<ActivityProvider>(context, listen: false);
                    final userProvider =
                        Provider.of<UserProvider>(context, listen: false);
                    final userId = userProvider.user?.id;

                    if (userId == null) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Aktivite eklemek için kullanıcı girişi yapılmalı.')),
                      );
                      return;
                    }

                    // Programdan mı eklendiğini kontrol et
                    // Basit bir kontrol: _selectedExercise null ve notlar programla ilgiliyse
                    final bool activityIsFromProgram =
                        _selectedExercise == null &&
                            _notesController.text
                                .contains("Seçilen Program Egzersizleri:");

                    // Kalori hesaplama (Örnek)
                    double caloriesBurned = 0;
                    if (_selectedExercise?.fixedCaloriesPerActivity != null &&
                        _selectedExercise!.fixedCaloriesPerActivity! > 0) {
                      caloriesBurned =
                          _selectedExercise!.fixedCaloriesPerActivity!;
                    } else if (_selectedExercise?.metValue != null &&
                        userProvider.user?.weight != null) {
                      caloriesBurned = (_selectedExercise!.metValue! *
                          userProvider.user!.weight! *
                          (duration / 60.0));
                    } else {
                      // FitnessCalculator.calculateCaloriesBurned çağrısı yorum satırı yapıldı.
                      // Geçici olarak 0 veya basit bir tahmin eklenebilir.
                      // print("FitnessCalculator bulunamadı, MET veya sabit kalori de yok. Kalori 0 olarak ayarlandı.");
                      // Örnek: Basit bir aktivite türüne göre tahmin (çok kaba)
                      // switch (_selectedActivityType) {
                      //   case FitActivityType.running:
                      //     caloriesBurned = duration * 8.0; // Dakikada 8 kalori gibi
                      //     break;
                      //   case FitActivityType.walking:
                      //     caloriesBurned = duration * 4.0;
                      //     break;
                      //   default:
                      //     caloriesBurned = duration * 5.0;
                      // }
                    }

                    final newActivity = ActivityRecord(
                      type: _selectedActivityType,
                      durationMinutes: duration,
                      date: _selectedDate,
                      notes:
                          "${_notesController.text}${_selectedExercise != null ? '\nEgzersiz: ${_selectedExercise!.name}' : ''}",
                      caloriesBurned: caloriesBurned.roundToDouble(),
                      userId: userId,
                      isFromProgram:
                          activityIsFromProgram, // isFromProgram alanı set edildi
                    );

                    await activityProvider.addActivity(
                        newActivity, userId, context);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Aktivite eklendi: ${_selectedActivityType.displayName}')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Aktivite ikonu alma
  IconData _getActivityIcon(FitActivityType type) {
    switch (type) {
      case FitActivityType.swimming:
        return Icons.pool;
      case FitActivityType.walking:
        return Icons.directions_walk;
      case FitActivityType.running:
        return Icons.directions_run;
      case FitActivityType.weightTraining:
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }

  String _getActivityTypeName(FitActivityType type) {
    switch (type) {
      case FitActivityType.swimming:
        return 'Yüzme';
      case FitActivityType.walking:
        return 'Yürüyüş';
      case FitActivityType.running:
        return 'Koşu';
      case FitActivityType.weightTraining:
        return 'Ağırlık Antrenmanı';
      default:
        return 'Diğer Aktivite';
    }
  }

  Color _getActivityColor(FitActivityType type) {
    switch (type) {
      case FitActivityType.swimming:
        return Colors.blue;
      case FitActivityType.walking:
        return Colors.green;
      case FitActivityType.running:
        return Colors.orange;
      case FitActivityType.weightTraining:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Aktivite düzenleme dialogu
  void _showEditActivityDialog(ActivityRecord activity) {
    _selectedActivityType = activity.type;
    _durationController.text = activity.durationMinutes.toString();
    _notesController.text = activity.notes ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Aktivite Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Aktivite türü seçici
                _buildActivityTypeDropdown(setState),
                const SizedBox(height: 16),

                // Süre girişi
                _buildDurationTextField(),
                const SizedBox(height: 16),

                // Notlar
                _buildNotesTextField(),
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
                if (activity.id != null) {
                  Provider.of<ActivityProvider>(context, listen: false)
                      .deleteActivity(activity.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${_getActivityTypeName(activity.type)} aktivitesi silindi'),
                      duration: const Duration(seconds: 2),
                    ),
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
                if (_durationController.text.isNotEmpty) {
                  final duration = int.tryParse(_durationController.text);
                  if (duration != null && duration > 0) {
                    final provider =
                        Provider.of<ActivityProvider>(context, listen: false);

                    final updatedActivity = ActivityRecord(
                      id: activity.id,
                      type: _selectedActivityType,
                      durationMinutes: duration,
                      date: activity.date, // Orijinal tarihi koru
                      notes: _notesController.text.isNotEmpty
                          ? _notesController.text
                          : null,
                    );

                    provider.updateActivity(updatedActivity);
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Dialog'ta görünen DropdownButtonFormField widget'ı
  DropdownButtonFormField<FitActivityType> _buildActivityTypeDropdown(
      void Function(void Function()) setDialogState) {
    return DropdownButtonFormField<FitActivityType>(
      value: _selectedActivityType,
      decoration: const InputDecoration(
        labelText: 'Aktivite Türü',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: FitActivityType.walking,
          child: Text('Yürüyüş'),
        ),
        DropdownMenuItem(
          value: FitActivityType.running,
          child: Text('Koşu'),
        ),
        DropdownMenuItem(
          value: FitActivityType.swimming,
          child: Text('Yüzme'),
        ),
        DropdownMenuItem(
          value: FitActivityType.weightTraining,
          child: Text('Ağırlık Antrenmanı'),
        ),
        DropdownMenuItem(
          value: FitActivityType.cycling,
          child: Text('Bisiklet'),
        ),
        DropdownMenuItem(
          value: FitActivityType.yoga,
          child: Text('Yoga'),
        ),
        DropdownMenuItem(
          value: FitActivityType.other,
          child: Text('Diğer'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setDialogState(() {
            _selectedActivityType = value;
          });
        }
      },
    );
  }

  // Süre girişi için TextField
  TextField _buildDurationTextField() {
    return TextField(
      controller: _durationController,
      decoration: const InputDecoration(
        labelText: 'Süre (dakika)',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
    );
  }

  // Notlar için TextField
  TextField _buildNotesTextField({String? selectedExerciseName}) {
    return TextField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: selectedExerciseName != null
            ? 'Notlar (Seçilen: $selectedExerciseName)'
            : 'Notlar (Opsiyonel)',
        border: const OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  // Egzersiz Seçim Butonu Widget'ı
  Widget _buildExerciseSelectionButton(
    BuildContext context,
    void Function(void Function()) setDialogState,
    void Function(Exercise) onExerciseSelected,
  ) {
    return TextButton.icon(
      icon: Icon(Icons.list_alt, color: Theme.of(context).primaryColor),
      label: Text(
        'Kütüphaneden Egzersiz Seç',
        style: TextStyle(color: Theme.of(context).primaryColor),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: Theme.of(context).primaryColor.withOpacity(0.5)),
        ),
        foregroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      onPressed: () async {
        try {
          // Yeni bir route ve stack oluşturmak için pushAndRemoveUntil değil pushReplacement kullanabiliriz
          final selectedExercise = await Navigator.of(context).push<dynamic>(
            MaterialPageRoute(
              builder: (context) =>
                  ExerciseLibraryScreen(isSelectionMode: true),
            ),
          );

          // Sonuç kontrolü
          if (selectedExercise != null) {
            if (selectedExercise is List &&
                selectedExercise.isNotEmpty &&
                selectedExercise.first is Exercise) {
              // Liste olarak geliyorsa ilk elemanı al
              print(
                  "Aktiviteler - Seçilen egzersiz listesi: ${selectedExercise.length} öğe");
              final exercise = selectedExercise.first as Exercise;
              onExerciseSelected(exercise);
            } else if (selectedExercise is Set &&
                selectedExercise.isNotEmpty &&
                selectedExercise.first is Exercise) {
              // Set olarak geliyorsa ilk elemanı al
              print(
                  "Aktiviteler - Seçilen egzersiz seti: ${selectedExercise.length} öğe");
              final exercise = selectedExercise.first as Exercise;
              onExerciseSelected(exercise);
            } else if (selectedExercise is Exercise) {
              // Direkt Exercise objesi olarak geliyorsa
              print("Aktiviteler - Seçilen egzersiz: ${selectedExercise.name}");
              onExerciseSelected(selectedExercise);
            } else {
              print(
                  "Aktiviteler - Dönen sonuç Exercise tipinde değil: ${selectedExercise.runtimeType}");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        "Beklenmeyen egzersiz tipi. Lütfen tekrar deneyin.")),
              );
            }
          } else {
            print("Aktiviteler - Egzersiz seçilmedi (null sonuç)");
          }
        } catch (e) {
          print("Aktiviteler - Egzersiz seçme hatası: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Egzersiz seçme işleminde hata: $e")),
          );
        }
      },
    );
  }

  // YENİ: Program Seçim Butonu Widget'ı (İskelet)
  Widget _buildProgramSelectionButton(
    BuildContext context,
    void Function(void Function()) setDialogState,
    void Function(List<Exercise>)
        onProgramSelected, // Callback programın egzersiz listesini döndürür
  ) {
    return TextButton.icon(
      icon: Icon(Icons.fitness_center,
          color: Theme.of(context).colorScheme.secondary),
      label: Text(
        'Programdan Seç',
        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
        ),
        foregroundColor:
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
      ),
      onPressed: () async {
        final selectedProgramExercises =
            await Navigator.of(context).push<List<Exercise>>(
          MaterialPageRoute(
              builder: (context) => const ProgramSelectionScreen()),
        );
        if (selectedProgramExercises != null &&
            selectedProgramExercises.isNotEmpty) {
          onProgramSelected(selectedProgramExercises);
          // Seçilen egzersizleri logla
          print("Programdan seçilen egzersizler:");
          for (var ex in selectedProgramExercises) {
            print(
                "- ${ex.name}, Sets: ${ex.defaultSets}, Reps: ${ex.defaultReps}");
          }
        } else {
          print("Program seçilmedi veya program boş.");
        }
      },
    );
  }

  // Placeholder for Workout In Progress View (to be added next)
  Widget _buildWorkoutInProgressView(
      BuildContext context, WorkoutProvider provider) {
    // TODO: Copy UI from WorkoutLoggingScreen here
    // return Center(
    //   child: Column(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //      children: [
    //        Text('Antrenman Devam Ediyor...'),
    //        SizedBox(height: 20),
    //         // Add buttons for adding exercise, finishing, cancelling etc.
    //        ElevatedButton(
    //           onPressed: () => provider.cancelWorkout(),
    //           child: Text('İptal Et (Test)'),
    //        ),
    //         ElevatedButton(
    //           onPressed: () => provider.saveWorkout(),
    //           child: Text('Kaydet (Test)'),
    //        ),
    //      ]
    //   ),
    // );

    // --- Copied from WorkoutLoggingScreen ---
    final currentWorkout = provider.currentWorkoutLog;
    if (currentWorkout == null)
      return const SizedBox
          .shrink(); // Should not happen if isWorkoutInProgress is true

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Antrenman Başladı: ${TimeOfDay.fromDateTime(currentWorkout.date).format(context)}',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Placeholder for Exercise List
          Expanded(
            child: currentWorkout.exerciseLogs.isEmpty
                ? Center(
                    child: Text('Henüz egzersiz eklenmedi.',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: currentWorkout.exerciseLogs.length,
                    itemBuilder: (context, index) {
                      final exerciseLog = currentWorkout.exerciseLogs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(exerciseLog.exerciseDetails?.name ??
                              'Bilinmeyen Egzersiz'),
                          subtitle:
                              Text('${exerciseLog.sets?.length ?? 0} set'),
                          // TODO: Add onTap to view/edit sets
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Egzersiz Ekle'),
                onPressed: () {
                  // TODO: Show exercise selection dialog
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Egzersiz ekleme henüz aktif değil.'),
                  ));
                },
              ),
              // TODO: Add Set Button (maybe inside exercise tile?)
            ],
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.check_circle_outline_rounded),
            label: Text('Antrenmanı Bitir ve Kaydet'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              // TODO: Ask for duration, notes, rating, feeling?
              provider.saveWorkout();
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: Icon(Icons.cancel_outlined),
            label: Text('Antrenmanı İptal Et'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              provider.cancelWorkout();
            },
          ),
          const SizedBox(height: 60), // Add padding to avoid FAB overlap
        ],
      ),
    );
    // --- End of Copied Code ---
  }

  // Aktivite ekle butonunu ortalı ve daha güzel göster
  Widget _buildAddActivityButton() {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: _showAddActivityDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.primaryColor
              : AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
        ),
        child: Text(
          'Aktivite Ekle',
          style: _buttonTextStyle,
        ),
      ),
    );
  }
}

// YENİ: Program Seçme Ekranı (StatefulWidget'a dönüştürüldü)
class ProgramSelectionScreen extends StatefulWidget {
  const ProgramSelectionScreen({super.key});

  @override
  State<ProgramSelectionScreen> createState() => _ProgramSelectionScreenState();
}

class _ProgramSelectionScreenState extends State<ProgramSelectionScreen> {
  List<ProgramItem> _workoutPrograms = [];
  Map<String, List<Exercise>> _programExercises =
      {}; // Program ID -> Egzersiz Listesi
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgramsAndExercises();
  }

  Future<void> _loadProgramsAndExercises() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final programService =
          Provider.of<ProgramService>(context, listen: false);
      final exerciseService =
          Provider.of<ExerciseService>(context, listen: false);

      // 1. Tüm antrenman programlarını al
      final allProgramItems =
          programService.getAllProgramItemsIncludingUnassigned();
      _workoutPrograms = allProgramItems
          .where((item) =>
              item.type == ProgramItemType.workout &&
              (item.title?.isNotEmpty ?? false) && // Kategori başlığı olanlar
              (item.programSets?.isNotEmpty ??
                  false)) // İçi boş olmayan programlar
          .toList();

      // 2. Her program için egzersiz detaylarını çek
      for (var program in _workoutPrograms) {
        if (program.id == null) continue;
        List<String> exerciseIds = [];
        program.programSets?.forEach((set) {
          if (set.exerciseId != null) {
            exerciseIds.add(set.exerciseId!);
          }
        });

        if (exerciseIds.isNotEmpty) {
          final List<Exercise>? detailsList =
              await exerciseService.getExercisesByIds(
                  exerciseIds.toSet().toList()); // Benzersiz ID'ler
          if (detailsList != null) {
            // Egzersizleri program setlerindeki sıraya göre (yaklaşık olarak) dizmeye çalışalım
            List<Exercise> orderedExercises = [];
            program.programSets?.forEach((set) {
              final foundExercise = detailsList.firstWhere(
                (ex) => ex.id == set.exerciseId,
                orElse: () => Exercise(
                    id: 'notfound',
                    name: 'Bilinmeyen Egzersiz',
                    targetMuscleGroup: '',
                    defaultSets: set.setsDescription?.toString() ?? '',
                    defaultReps: set.repsDescription?.toString() ??
                        ''), // Egzersiz bulunamazsa placeholder
              );
              // Eğer egzersiz bulunduysa ve placeholder değilse, setteki set/rep bilgilerini egzersize ata (Exercise modeli varsayılanları kullanıyor)
              if (foundExercise.id != 'notfound') {
                orderedExercises.add(foundExercise.copyWith(
                  // copyWith metodu Exercise modelinde olmalı
                  defaultSets: set.setsDescription?.toString() ??
                      foundExercise.defaultSets,
                  defaultReps: set.repsDescription?.toString() ??
                      foundExercise.defaultReps,
                  // Diğer bilgiler (duration, weight vb.) ProgramSet modelinde varsa buraya eklenebilir
                ));
              } else {
                // Eğer ExerciseService egzersizi bulamadıysa, yine de bir placeholder ekle
                orderedExercises.add(foundExercise);
              }
            });
            _programExercises[program.id!] = orderedExercises;
          }
        }
      }
    } catch (e, stackTrace) {
      print("Programlar ve egzersizler yüklenirken hata: $e\\n$stackTrace");
      // Kullanıcıya hata mesajı gösterilebilir
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Seç'),
      ),
      body: _isLoading
          ? const Center(child: KaplanLoading())
          : _workoutPrograms.isEmpty
              ? const Center(
                  child: Text('Kullanılabilir antrenman programı bulunamadı.'),
                )
              : ListView.builder(
                  itemCount: _workoutPrograms.length,
                  itemBuilder: (context, index) {
                    final program = _workoutPrograms[index];
                    final exercisesForProgram =
                        _programExercises[program.id] ?? [];
                    return ListTile(
                      title: Text(program.title ?? 'İsimsiz Program'),
                      subtitle: Text(
                          '${exercisesForProgram.length} egzersiz${program.description != null && program.description!.isNotEmpty ? " - ${program.description}" : ""}'),
                      onTap: () {
                        if (exercisesForProgram.isNotEmpty) {
                          Navigator.of(context).pop(exercisesForProgram);
                        } else {
                          print(
                              "Seçilen programda gösterilecek egzersiz bulunamadı: ${program.title}");
                          // Kullanıcıya bilgi verilebilir
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '"${program.title}" programında tanımlı egzersiz bulunamadı.')),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
}
