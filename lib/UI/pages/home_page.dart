import 'package:flutter/material.dart';
import 'package:todo_list/UI/widget/bottom_navigation_controller.dart';
import 'package:todo_list/UI/widget/custom_app_bar.dart';
import 'package:todo_list/core/consants/color_file.dart';
import 'package:todo_list/data/models/task.dart';
import 'package:todo_list/data/services/task_service.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  double offsetY = 0; // Container'ların dikey hareketi

  Future<void> _showAddTaskDialog() async {
    String title = '';
    String description = '';

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (value) {
                  title = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (value) {
                  description = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.trim().isNotEmpty) {
                  final context = dialogContext;
                  Task newTask = Task(title: title.trim(), description: description.trim(), isDone: false);
                  await TaskService().insertTask(newTask);
                  if (!mounted) return;
                  setState(() {});
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleTaskDone(Task task) async {
    task.isDone = !task.isDone;
    await TaskService().updateTask(task);
    setState(() {});
  }

  Future<void> _deleteTask(Task task) async {
    await TaskService().deleteTask(task.id!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: ColorFile.loveColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Tasks',
              style: TextStyle(
                fontSize: 20,
                color: ColorFile.starColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Task>>(
                future: TaskService().fetchTasksForCurrentUser(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No tasks found.'));
                  } else {
                    final tasks = snapshot.data!;
                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(task.title),
                            subtitle: Text(task.description ?? 'No Description'),
                            leading: Icon(Icons.check_circle_outline, color: ColorFile.starColor),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: task.isDone,
                                  onChanged: (value) {
                                    _toggleTaskDone(task);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _deleteTask(task);
                                  },
                                ),
                              ],
                            ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const BottomNavigationController(),
     );
  }
}
