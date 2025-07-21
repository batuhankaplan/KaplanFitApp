import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../models/task_model.dart';
import '../models/task_type.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key}) ;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ActivityProvider>(context);
    final tasks = provider.tasks;

    return Scaffold(
      appBar: AppBar(
        title: Text('Günlük Görevler'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddTaskDialog(context),
          ),
        ],
      ),
      body: provider.isLoading
          ? Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? _buildEmptyState(context)
              : _buildTaskList(context, tasks),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Görev Listeniz Boş',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Günlük görevlerinizi ekleyin ve sağlıklı alışkanlıklar geliştirin.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          // ElevatedButton(
          //   onPressed: () {
          //     final provider = Provider.of<ActivityProvider>(context, listen: false);
          //     // provider.createDefaultTasks(); // Bu metod kaldırıldı
          //   },
          //   child: Text('Öntanımlı Görevleri Ekle'),
          // ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<DailyTask> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Icon(
              _getTaskIcon(task.type),
              color: task.isCompleted
                  ? Colors.grey
                  : Theme.of(context).primaryColor,
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null && task.description!.isNotEmpty)
                  Text(
                    task.description!,
                    style: TextStyle(
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? Colors.grey : null,
                    ),
                  ),
                SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy', 'tr_TR').format(task.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Yeni Görev Ekle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Görev Başlığı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Başlık gerekli';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Açıklama gerekli';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final task = DailyTask(
                  title: titleController.text,
                  description: descriptionController.text,
                  date: DateTime.now(),
                  type: TaskType.other,
                );

                final provider =
                    Provider.of<ActivityProvider>(context, listen: false);
                provider.addTask(task);

                Navigator.of(context).pop();
              }
            },
            child: Text('Ekle'),
          ),
        ],
      ),
    );
  }

  IconData _getTaskIcon(TaskType type) {
    switch (type) {
      case TaskType.morningExercise:
        return Icons.directions_run;
      case TaskType.lunch:
        return Icons.restaurant;
      case TaskType.eveningExercise:
        return Icons.fitness_center;
      case TaskType.dinner:
        return Icons.dinner_dining;
      case TaskType.other:
        return Icons.task_alt;
    }
  }
}

