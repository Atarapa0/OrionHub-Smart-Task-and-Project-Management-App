import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_list/data/models/project.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final List<String> _projectMembers = [];
  final List<Map<String, dynamic>> _projectTasks = [];

  @override
  void initState() {
    super.initState();
    _loadProjectMembers();
    _loadProjectTasks();
  }

  Future<void> _loadProjectMembers() async {
    try {
      final response = await Supabase.instance.client
          .from('project_members')
          .select('user_id')
          .eq('project_id', widget.project.id as Object);
      
      setState(() {
        _projectMembers.clear();
        _projectMembers.addAll(
          (response as List).map((member) => member['user_id'] as String)
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Üye listesi yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _loadProjectTasks() async {
    try {
      final response = await Supabase.instance.client
          .from('tasks')
          .select('*, assigned_to')
          .eq('project_id', widget.project.id as Object);
      
      setState(() {
        _projectTasks.clear();
        _projectTasks.addAll(List<Map<String, dynamic>>.from(response as List));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görevler yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _showAddMemberDialog() async {
    final emailController = TextEditingController();

    if (!mounted) return;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Üye Ekle'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'E-posta',
            hintText: 'Kullanıcının e-posta adresini girin',
          ),
          keyboardType: TextInputType.emailAddress,
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

    if (result != true || !mounted) return;

    try {
      // Önce kullanıcıyı e-posta ile bulalım
      final userResponse = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('email', emailController.text)
          .single();

      final userId = userResponse['id'];

      // Kullanıcıyı projeye ekleyelim
      await Supabase.instance.client.from('project_members').insert({
        'project_id': widget.project.id,
        'user_id': userId,
        'added_at': DateTime.now().toIso8601String(),
      });

      _loadProjectMembers();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Üye başarıyla eklendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Üye eklenirken hata: $e')),
      );
    }
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedMemberId;

    if (!mounted) return;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görev Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Görev Başlığı',
                hintText: 'Görevi kısaca tanımlayın',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Görev Açıklaması',
                hintText: 'Görevi detaylı açıklayın',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Görev Atanacak Üye',
              ),
              value: selectedMemberId,
              items: _projectMembers.map((memberId) {
                return DropdownMenuItem(
                  value: memberId,
                  child: FutureBuilder<String>(
                    future: _getUserName(memberId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(snapshot.data!);
                      }
                      return const Text('Yükleniyor...');
                    },
                  ),
                );
              }).toList(),
              onChanged: (value) {
                selectedMemberId = value;
              },
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

    if (result != true || !mounted) return;

    try {
      await Supabase.instance.client.from('tasks').insert({
        'project_id': widget.project.id,
        'title': titleController.text,
        'description': descriptionController.text,
        'assigned_to': selectedMemberId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      _loadProjectTasks();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görev başarıyla eklendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görev eklenirken hata: $e')),
      );
    }
  }

  Future<String> _getUserName(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();
      return response['full_name'] as String;
    } catch (e) {
      return 'Bilinmeyen Kullanıcı';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.project.title),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Görevler'),
              Tab(text: 'Üyeler'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Görevler Tab'ı
            ListView.builder(
              itemCount: _projectTasks.length,
              itemBuilder: (context, index) {
                final task = _projectTasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(task['title']),
                    subtitle: Text(task['description'] ?? ''),
                    trailing: FutureBuilder<String>(
                      future: _getUserName(task['assigned_to']),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(snapshot.data!);
                        }
                        return const Text('Yükleniyor...');
                      },
                    ),
                  ),
                );
              },
            ),
            // Üyeler Tab'ı
            ListView.builder(
              itemCount: _projectMembers.length,
              itemBuilder: (context, index) {
                final memberId = _projectMembers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: FutureBuilder<String>(
                      future: _getUserName(memberId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(snapshot.data!);
                        }
                        return const Text('Yükleniyor...');
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('Üye Ekle'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddMemberDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_task),
                    title: const Text('Görev Ekle'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddTaskDialog();
                    },
                  ),
                ],
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
