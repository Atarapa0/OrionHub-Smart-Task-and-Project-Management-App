import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_list/data/models/project.dart';
import 'package:todo_list/UI/widget/bottom_navigation_controller.dart';
import 'package:todo_list/UI/widget/custom_app_bar.dart';
import 'package:todo_list/data/services/project_services.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key});

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  late Future<List<Project>> _projectsFuture;
  final _projectService = ProjectService();

  @override
  void initState() {
    super.initState();
    _projectsFuture = _loadProjects();
  }

  Future<List<Project>> _loadProjects() async {
    try {
      return await _projectService.fetchProjects();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Projeler yüklenirken hata oluştu: $e')),
        );
      }
      return [];
    }
  }

  Future<void> _refreshProjects() async {
    if (!mounted) return;
    setState(() {
      _projectsFuture = _loadProjects();
    });
  }

  Future<void> _showAddProjectDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    if (!mounted) return;

    final dialogContext = context;
    final result = await showDialog(
      context: dialogContext,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Yeni Proje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Proje Adı',
                hintText: 'Projenizin adını girin',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'Proje açıklamasını girin',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (!mounted || result != true) return;

    if (titleController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen proje adını girin')));
      return;
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Oturum açmanız gerekiyor')));
      return;
    }

    try {
      await _projectService.addProject(
        Project(
          title: titleController.text,
          description: descriptionController.text,
          createdBy: currentUser.id,
          createdAt: DateTime.now().toUtc(),
        ),
      );

      if (!mounted) return;
      _refreshProjects();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proje başarıyla oluşturuldu')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Proje oluşturulurken hata: $e')));
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: FutureBuilder<List<Project>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bir hata oluştu'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refreshProjects,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Henüz proje yok.'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showAddProjectDialog,
                    child: const Text('Proje Ekle'),
                  ),
                ],
              ),
            );
          }

          final projects = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshProjects,
            child: ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(project.title),
                    subtitle: Text(project.description ?? ''),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/project-detail',
                        arguments: project,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectDialog,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const BottomNavigationController(initialIndex: 1),
    );
  }
}
