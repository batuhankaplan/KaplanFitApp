import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise_model.dart';
import '../services/exercise_service.dart';
import '../theme.dart';
import '../widgets/kaplan_appbar.dart';

class AddEditExerciseScreen extends StatefulWidget {
  final Exercise? exercise; // Düzenlenecek egzersiz (null ise yeni ekleme modu)

  const AddEditExerciseScreen({Key? key, this.exercise}) : super(key: key);

  @override
  State<AddEditExerciseScreen> createState() => _AddEditExerciseScreenState();
}

class _AddEditExerciseScreenState extends State<AddEditExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _equipmentController;
  late TextEditingController _videoUrlController;

  String? _selectedMuscleGroup;
  final List<String> _muscleGroups = [
    'Göğüs', 'Sırt', 'Bacak', 'Omuz', 'Ön Kol', 'Arka Kol', 'Karın',
    'Bel Sağlığı', 'Kardiyo', 'Diğer' // Genel kategoriler
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _nameController = TextEditingController(text: ex?.name ?? '');
    _descriptionController = TextEditingController(text: ex?.description ?? '');
    _equipmentController = TextEditingController(text: ex?.equipment ?? '');
    _videoUrlController = TextEditingController(text: ex?.videoUrl ?? '');
    _selectedMuscleGroup = ex?.targetMuscleGroup;

    // Eğer düzenleme modundaysak ve seçili kas grubu listede yoksa, listeye ekle
    if (ex != null && !_muscleGroups.contains(ex.targetMuscleGroup)) {
      _muscleGroups.add(ex.targetMuscleGroup);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _equipmentController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form geçerli değilse kaydetme
    }

    setState(() {
      _isLoading = true;
    });

    final exerciseService =
        Provider.of<ExerciseService>(context, listen: false);

    final exerciseData = Exercise(
      id: widget.exercise?.id, // Düzenleme modunda ID'yi koru (String?)
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      targetMuscleGroup: _selectedMuscleGroup!,
      equipment: _equipmentController.text.trim().isEmpty
          ? null
          : _equipmentController.text.trim(),
      videoUrl: _videoUrlController.text.trim().isEmpty
          ? null
          : _videoUrlController.text.trim(),
      createdAt: widget.exercise
          ?.createdAt, // Mevcut Timestamp'ı koru (yoksa null olur, toMap halleder)
    );

    try {
      // Dönüş tipleri String? (add) ve bool (update) olarak güncellendi
      bool success = false;
      String? newId;

      if (widget.exercise == null) {
        // Yeni egzersiz ekle
        newId = await exerciseService.addCustomExercise(exerciseData);
        success = newId != null;
      } else {
        // Mevcut egzersizi güncelle
        success = await exerciseService.updateExercise(exerciseData);
      }

      if (!mounted) return; // İşlem sürerken widget ağaçtan kaldırıldıysa

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Egzersiz başarıyla ${widget.exercise == null ? 'eklendi' : 'güncellendi'}.'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context,
            true); // Başarı durumunda true döndürerek önceki ekranı yenile
      } else {
        throw Exception(
            'Egzersiz kaydedilemedi (belki aynı isimde başka bir egzersiz var?).');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isEditMode = widget.exercise != null;

    return Scaffold(
      appBar: KaplanAppBar(
        title: isEditMode ? 'Egzersizi Düzenle' : 'Yeni Egzersiz Ekle',
        isDarkMode: isDarkMode,
      ),
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Egzersiz Adı'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Egzersiz adı boş bırakılamaz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMuscleGroup,
                decoration: const InputDecoration(labelText: 'Hedef Kas Grubu'),
                items: _muscleGroups.map((String group) {
                  return DropdownMenuItem<String>(
                    value: group,
                    child: Text(group),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMuscleGroup = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Lütfen bir kas grubu seçin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _equipmentController,
                decoration: const InputDecoration(
                    labelText: 'Gerekli Ekipman (Opsiyonel)',
                    hintText: 'Dumbbell, Barbell, Vücut Ağırlığı vb.'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Açıklama (Opsiyonel)',
                    hintText: 'Egzersizin nasıl yapıldığı veya notlar...'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                    labelText: 'Video URL (Opsiyonel)',
                    hintText: 'https://...'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveExercise,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.save, color: Colors.white),
                label: Text(isEditMode ? 'Güncelle' : 'Kaydet',
                    style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor:
                        AppTheme.primaryColor, // Ana rengi kullanalım
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              // Düzenleme modunda silme butonu (isteğe bağlı)
              if (isEditMode)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextButton.icon(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      label: Text('Egzersizi Sil',
                          style: TextStyle(color: Colors.red)),
                      onPressed: _isLoading ? null : _deleteExercise,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.withOpacity(0.1),
                      )),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteExercise() async {
    final exerciseId = widget.exercise?.id; // String? tipinde
    if (exerciseId == null) return;

    // Kullanıcıdan onay al
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Egzersizi Sil'),
        content: Text(
            '"${widget.exercise!.name}" egzersizini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        final exerciseService =
            Provider.of<ExerciseService>(context, listen: false);
        bool deleted = await exerciseService
            .deleteExercise(exerciseId); // String ID gönder

        if (!mounted) return;

        if (deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Egzersiz silindi.'),
                backgroundColor: Colors.orange),
          );
          Navigator.pop(
              context, true); // Başarı ile silindi, önceki ekranı yenile
        } else {
          throw Exception('Egzersiz silinemedi.');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Silme hatası: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
