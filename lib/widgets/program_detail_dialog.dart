import 'package:flutter/material.dart';
import '../models/program_model.dart';

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

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.programItem.description);

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
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_dialogIcon, color: _dialogColor),
          const SizedBox(width: 10),
          Text(_dialogTitle),
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
            const SizedBox(height: 20),
            Text(
              'Bu içeriği düzenlemek, anasayfadaki günlük programınızı da günceller.',
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
              type: widget.programItem.type,
              title: widget.programItem.title,
              description: _descriptionController.text,
              programSets: widget.programItem.programSets,
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
}
