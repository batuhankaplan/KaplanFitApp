import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/program_model.dart';
import '../models/program_set.dart';
import '../models/exercise_model.dart';
import '../services/exercise_service.dart';
import '../screens/exercise_library_screen.dart';
import '../theme.dart';

class ProgramDetailDialog extends StatefulWidget {
  final ProgramItem programItem;
  final String type;

  const ProgramDetailDialog({
    Key? key,
    required this.programItem,
    required this.type,
  }) : super(key: key);

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

    // Dialog başlığını ve ikonunu program tipine göre ayarla
    switch (widget.type) {
      case 'morning':
        _dialogTitle = 'Sabah Egzersizi';
        _dialogIcon = Icons.wb_sunny;
        _dialogColor = Colors.orange;
        break;
      case 'lunch':
        _dialogTitle = 'Öğle Yemeği';
        _dialogIcon = Icons.restaurant;
        _dialogColor = Colors.green;
        break;
      case 'evening':
        _dialogTitle = 'Akşam Egzersizi';
        _dialogIcon = Icons.fitness_center;
        _dialogColor = Colors.purple;
        break;
      case 'dinner':
        _dialogTitle = 'Akşam Yemeği';
        _dialogIcon = Icons.dinner_dining;
        _dialogColor = Colors.blue;
        break;
      default:
        _dialogTitle = 'Program Detayı';
        _dialogIcon = Icons.event_note;
        _dialogColor = Colors.grey;
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
            print(
                "Egzersiz detayları yüklendi: ${_exerciseDetails.length} adet");
          });
        } else {
          setState(() => _detailsLoading = false);
        }
      } else {
        setState(() => _detailsLoading = false);
      }
    } catch (e) {
      print("Egzersiz detayları yüklenirken hata: $e");
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
          if (isWorkout)
            IconButton(
              icon: Icon(Icons.add_circle_outline,
                  color: Theme.of(context).iconTheme.color),
              tooltip: 'Egzersiz Ekle',
              onPressed: _navigateToAddExercise,
            ),
        ],
      ),
      content: SingleChildScrollView(
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
            if (isWorkout) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              Text('Egzersizler',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              _buildExerciseList(isDarkMode),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),
            Text(
              widget.programItem.type == ProgramItemType.workout
                  ? 'Egzersiz listesini veya açıklamayı değiştirmek haftalık programınızı günceller.'
                  : 'Bu açıklamayı düzenlemek, anasayfadaki günlük programınızı da günceller.',
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
              programSets: isWorkout
                  ? _currentProgramSets
                  : widget.programItem.programSets,
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
          'Henüz egzersiz eklenmemiş.\nYukarıdaki ' +
              ' butonu ile ekleyebilirsiniz.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
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
      print(
          "Seçilen egzersizler eklendi: ${selectedExercises.map((e) => e.name)}");
    } else {
      print("Egzersiz seçilmedi veya iptal edildi.");
    }
  }
}
