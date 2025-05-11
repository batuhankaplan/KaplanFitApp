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
  bool _isLoading = true;

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

    if (!Platform.isWindows) {
      _location = Location();
      _checkLocationPermission();
    } else {
      debugPrint('Windows platformunda konum servisleri devre dışı bırakıldı');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ActivityProvider>(context, listen: false)
          .setSelectedDate(_selectedDate);
      _loadInitialData();
    });
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
        if (permissionStatus != PermissionStatus.granted) {
          return;
        }
      }
      if (mounted) {
        setState(() {
          _hasLocationPermission = true;
        });
      }
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const KaplanLoading()
          : Consumer<WorkoutProvider>(
              builder: (context, workoutProv, child) {
                if (workoutProv.currentWorkoutLog != null) {
                  return _buildWorkoutInProgressView(context, workoutProv);
                } else {
                  return _buildActivityListView(
                      context, activityProvider.activities, isDarkMode);
                }
              },
            ),
    );
  }

  Widget _buildActivityListView(
      BuildContext context, List<ActivityRecord> activities, bool isDarkMode) {
    return Column(
      children: [
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
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: () {
                    _changeDate(-1);
                  },
                ),
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
        Expanded(
          child: activities.isEmpty && !_isLoading
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
                  itemCount: activities.length + 1,
                  itemBuilder: (context, index) {
                    if (index == activities.length) {
                      return Center(
                        child: KFPulseAnimation(
                          maxScale: 1.05,
                          child: _buildAddActivityButton(),
                        ),
                      );
                    }
                    final activity = activities[index];
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
                              style: _titleStyle,
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

  void _changeDate(int days) {
    if (mounted) {
      setState(() {
        _selectedDate = _selectedDate.add(Duration(days: days));
        _isLoading = true;
      });
    }
    Provider.of<ActivityProvider>(context, listen: false)
        .setSelectedDate(_selectedDate);
    _loadInitialData();
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
      if (mounted) {
        setState(() {
          _selectedDate = picked;
          _isLoading = true;
        });
      }
      Provider.of<ActivityProvider>(context, listen: false)
          .setSelectedDate(_selectedDate);
      _loadInitialData();
    }
  }

  void _showAddActivityDialog({ActivityRecord? existingActivity}) {
    _durationController.clear();
    _notesController.clear();
    _selectedActivityType = FitActivityType.walking;
    if (existingActivity != null) {
      _selectedActivityType = existingActivity.type;
      _durationController.text = existingActivity.durationMinutes.toString();
      _notesController.text = existingActivity.notes ?? '';
    }

    Exercise? _selectedExercise;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              existingActivity == null ? 'Aktivite Ekle' : 'Aktivite Düzenle'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildActivityTypeDropdown(setDialogState),
                  const SizedBox(height: 16),
                  _buildDurationTextField(),
                  const SizedBox(height: 16),
                  if (existingActivity == null) ...[
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
                          if (exercise.targetMuscleGroup
                                  .toLowerCase()
                                  .contains('kardiyo') ||
                              exercise.name.toLowerCase().contains('kardiyo')) {
                            _selectedActivityType = FitActivityType.other;
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
                              exercise.name
                                  .toLowerCase()
                                  .contains('bisiklet')) {
                            _selectedActivityType = FitActivityType.cycling;
                          } else {
                            _selectedActivityType =
                                FitActivityType.weightTraining;
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
                          _selectedActivityType =
                              FitActivityType.weightTraining;
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
                  const SizedBox(height: 16),
                  _buildNotesTextField(
                      selectedExerciseName: _selectedExercise?.name),
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
              child: Text(existingActivity == null ? 'Ekle' : 'Kaydet'),
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

                    final bool activityIsFromProgram =
                        existingActivity?.isFromProgram ??
                            (_selectedExercise == null &&
                                _notesController.text
                                    .contains("Seçilen Program Egzersizleri:"));

                    double caloriesBurned =
                        existingActivity?.caloriesBurned ?? 0;
                    if (existingActivity == null) {
                      if (_selectedExercise?.fixedCaloriesPerActivity != null &&
                          _selectedExercise!.fixedCaloriesPerActivity! > 0) {
                        caloriesBurned =
                            _selectedExercise!.fixedCaloriesPerActivity!;
                      } else if (_selectedExercise?.metValue != null &&
                          userProvider.user?.weight != null) {
                        caloriesBurned = (_selectedExercise!.metValue! *
                            userProvider.user!.weight! *
                            (duration / 60.0));
                      }
                    }

                    final activityToSave = ActivityRecord(
                      id: existingActivity?.id,
                      type: _selectedActivityType,
                      durationMinutes: duration,
                      date: existingActivity?.date ?? _selectedDate,
                      notes: _notesController.text,
                      caloriesBurned: caloriesBurned.roundToDouble(),
                      userId: userId,
                      isFromProgram: activityIsFromProgram,
                    );

                    if (existingActivity == null) {
                      await activityProvider.addActivity(
                          activityToSave, context);
                    } else {
                      await activityProvider.updateActivity(activityToSave);
                    }
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Aktivite ${existingActivity == null ? "eklendi" : "güncellendi"}: ${_selectedActivityType.displayName}')),
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

  void _showEditActivityDialog(ActivityRecord activity) {
    _showAddActivityDialog(existingActivity: activity);
  }

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
          final selectedExercise = await Navigator.of(context).push<dynamic>(
            MaterialPageRoute(
              builder: (context) =>
                  ExerciseLibraryScreen(isSelectionMode: true),
            ),
          );

          if (selectedExercise != null) {
            if (selectedExercise is List &&
                selectedExercise.isNotEmpty &&
                selectedExercise.first is Exercise) {
              final exercise = selectedExercise.first as Exercise;
              onExerciseSelected(exercise);
            } else if (selectedExercise is Set &&
                selectedExercise.isNotEmpty &&
                selectedExercise.first is Exercise) {
              final exercise = selectedExercise.first as Exercise;
              onExerciseSelected(exercise);
            } else if (selectedExercise is Exercise) {
              onExerciseSelected(selectedExercise);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        "Beklenmeyen egzersiz tipi. Lütfen tekrar deneyin.")),
              );
            }
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Egzersiz seçme işleminde hata: $e")),
          );
        }
      },
    );
  }

  Widget _buildProgramSelectionButton(
    BuildContext context,
    void Function(void Function()) setDialogState,
    void Function(List<Exercise>) onProgramSelected,
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
        }
      },
    );
  }

  Widget _buildWorkoutInProgressView(
      BuildContext context, WorkoutProvider provider) {
    final currentWorkout = provider.currentWorkoutLog;
    if (currentWorkout == null) return const SizedBox.shrink();

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
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Egzersiz Ekle'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Egzersiz ekleme henüz aktif değil.'),
                  ));
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.check_circle_outline_rounded),
            label: Text('Antrenmanı Bitir ve Kaydet'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
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
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final activityProvider =
        Provider.of<ActivityProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await userProvider.loadUser();
      if (userProvider.user == null) {
        debugPrint(
            "[ActivityScreen] Kullanıcı bulunamadı, veri yükleme durduruldu.");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      await activityProvider.refreshActivities();
      activityProvider.setSelectedDate(_selectedDate);

      _filterActivities();
    } catch (e) {
      debugPrint('Veri yüklenirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler yüklenirken bir hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterActivities() {
    if (mounted) {
      setState(() {});
    }
  }
}

class ProgramSelectionScreen extends StatefulWidget {
  const ProgramSelectionScreen({super.key});

  @override
  State<ProgramSelectionScreen> createState() => _ProgramSelectionScreenState();
}

class _ProgramSelectionScreenState extends State<ProgramSelectionScreen> {
  List<ProgramItem> _workoutPrograms = [];
  Map<String, List<Exercise>> _programExercises = {};
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

      final allProgramItems =
          programService.getAllProgramItemsIncludingUnassigned();
      _workoutPrograms = allProgramItems
          .where((item) =>
              item.type == ProgramItemType.workout &&
              (item.title?.isNotEmpty ?? false) &&
              (item.programSets?.isNotEmpty ?? false))
          .toList();

      for (var program in _workoutPrograms) {
        if (program.id == null) continue;
        List<String> exerciseIds = [];
        program.programSets?.forEach((set) {
          if (set.exerciseId != null) {
            exerciseIds.add(set.exerciseId!);
          }
        });

        if (exerciseIds.isNotEmpty) {
          final List<Exercise>? detailsList = await exerciseService
              .getExercisesByIds(exerciseIds.toSet().toList());
          if (detailsList != null) {
            List<Exercise> orderedExercises = [];
            program.programSets?.forEach((set) {
              final foundExercise = detailsList.firstWhere(
                (ex) => ex.id == set.exerciseId,
                orElse: () => Exercise(
                    id: 'notfound',
                    name: 'Bilinmeyen Egzersiz',
                    targetMuscleGroup: '',
                    defaultSets: set.setsDescription?.toString() ?? '',
                    defaultReps: set.repsDescription?.toString() ?? ''),
              );
              if (foundExercise.id != 'notfound') {
                orderedExercises.add(foundExercise.copyWith(
                  defaultSets: set.setsDescription?.toString() ??
                      foundExercise.defaultSets,
                  defaultReps: set.repsDescription?.toString() ??
                      foundExercise.defaultReps,
                ));
              } else {
                orderedExercises.add(foundExercise);
              }
            });
            _programExercises[program.id!] = orderedExercises;
          }
        }
      }
    } catch (e, stackTrace) {
      print("Programlar ve egzersizler yüklenirken hata: $e\n$stackTrace");
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
