import 'package:intl/intl.dart';
import 'task_type.dart';

class DailyTask {
  final int? id;
  final String title;
  final String description;
  final DateTime date;
  final bool isCompleted;
  final TaskType type;

  DailyTask({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.isCompleted = false,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
      'type': type.index,
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      isCompleted: map['isCompleted'] == 1,
      type: TaskType.values[map['type']],
    );
  }

  DailyTask copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? date,
    bool? isCompleted,
    TaskType? type,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
    );
  }

  String get formattedDate => DateFormat('dd/MM/yyyy').format(date);
}

// Define a type alias for easier reference
typedef Task = DailyTask; 