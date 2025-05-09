import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' hide LocationAccuracy;
import 'package:geolocator/geolocator.dart';
import '../providers/activity_provider.dart';
import '../providers/workout_provider.dart';
import '../models/activity_record.dart';
import '../models/task_type.dart';
import '../theme.dart';
import '../utils/animations.dart';
import '../widgets/kaplan_loading.dart';
import '../models/exercise_model.dart';
import 'exercise_library_screen.dart';
import 'dart:io';

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
      Provider.of<ActivityProvider>(context, listen: false)
          .setSelectedDate(_selectedDate);
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
    Provider.of<ActivityProvider>(context, listen: false)
        .setSelectedDate(_selectedDate);
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
      Provider.of<ActivityProvider>(context, listen: false)
          .setSelectedDate(_selectedDate);
    }
  }

  void _showAddActivityDialog() {
    _durationController.clear();
    _notesController.clear();
    _selectedActivityType = FitActivityType.walking;
    Exercise? _selectedExercise;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Aktivite Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Aktivite türü seçici
                _buildActivityTypeDropdown(setDialogState),
                const SizedBox(height: 16),

                // Süre girişi
                _buildDurationTextField(),
                const SizedBox(height: 16),

                // Egzersiz Seçim Butonu
                _buildExerciseSelectionButton(context, setDialogState,
                    (exercise) {
                  _selectedExercise = exercise;
                  _notesController.text =
                      'Egzersiz: ${exercise.name}\n${_notesController.text}';
                  if (_selectedActivityType != FitActivityType.weightTraining) {
                    _selectedActivityType = FitActivityType.weightTraining;
                  }
                  setDialogState(() {});
                }),
                const SizedBox(height: 16),

                // Notlar
                _buildNotesTextField(
                    selectedExerciseName: _selectedExercise?.name),
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
                if (_durationController.text.isNotEmpty) {
                  final duration = int.tryParse(_durationController.text);
                  if (duration != null && duration > 0) {
                    final provider =
                        Provider.of<ActivityProvider>(context, listen: false);
                    final now = DateTime.now();

                    String notes = _notesController.text.trim();

                    final activity = ActivityRecord(
                      type: _selectedActivityType,
                      durationMinutes: duration,
                      date: _selectedDate.copyWith(
                        hour: now.hour,
                        minute: now.minute,
                      ),
                      notes: notes.isNotEmpty ? notes : null,
                    );

                    provider.addActivity(activity);
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
