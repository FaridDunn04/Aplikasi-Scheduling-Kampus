import 'package:flutter/material.dart';

import '../../state/app_state_manager.dart';
import '../../data/models/task_model.dart';
import 'widgets/task_card.dart';
import 'dialogs/task_form_dialog.dart';
import '../share/dialogs/import_modal_dialog.dart';

class TaskScreen extends StatefulWidget {
  static final ValueNotifier<int> _showAllTasksRequest = ValueNotifier<int>(0);

  const TaskScreen({super.key});

  static void requestShowAllTasks() {
    _showAllTasksRequest.value++;
  }

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _filters = ['All', 'Labs', 'Lectures', 'Completed'];

  @override
  void dispose() {
    TaskScreen._showAllTasksRequest.removeListener(_showAllTasks);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    TaskScreen._showAllTasksRequest.addListener(_showAllTasks);
  }

  void _showAllTasks() {
    _searchController.clear();
    setState(() {
      _selectedFilterIndex = 0;
      _searchQuery = '';
    });
  }

  Future<void> _openAddTaskDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => const TaskFormDialog(),
    );
    if (result == true && mounted) {
      if (_selectedFilterIndex == 3) {
        setState(() => _selectedFilterIndex = 0);
      }
    }
  }

  void _openImportDialog() {
    showDialog(context: context, builder: (ctx) => const ImportModalDialog());
  }

  List<Task> _applyFilters(List<Task> allTasks, AppStateManager state) {
    var list = allTasks;

    // Filter by Tab
    switch (_selectedFilterIndex) {
      case 0: // All
        list = list.where((t) => !t.isCompleted).toList();
        break;
      case 1: // Labs
        list = list.where((t) {
          if (t.isCompleted) return false;
          if (t.isLab) return true;
          if (t.taskType.toLowerCase() == 'lecture') return false;
          final course = state.getCourseById(t.courseId);
          return course?.isLab ?? false;
        }).toList();
        break;
      case 2: // Lectures
        list = list.where((t) {
          if (t.isCompleted) return false;
          if (t.taskType.toLowerCase() == 'lecture') return true;
          if (t.isLab) return false;
          final course = state.getCourseById(t.courseId);
          return !(course?.isLab ?? false);
        }).toList();
        break;
      case 3: // Completed
        list = list.where((t) => t.isCompleted).toList();
        break;
    }

    // Filter by Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((t) {
        final titleMatches = t.title.toLowerCase().contains(q);
        final descMatches = t.description?.toLowerCase().contains(q) ?? false;
        final course = state.getCourseById(t.courseId);
        final courseMatches =
            course?.courseName.toLowerCase().contains(q) ?? false;
        return titleMatches || descMatches || courseMatches;
      }).toList();
    }

    // Sort by deadline
    list.sort((a, b) => a.deadlineDatetime.compareTo(b.deadlineDatetime));
    return list;
  }

  void _confirmDeleteTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tugas?'),
        content: Text('Apakah Anda yakin ingin menghapus "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AppStateManager.instance.deleteTask(task.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStateManager.instance,
      builder: (context, _) {
        final state = AppStateManager.instance;
        final tasks = _applyFilters(state.tasks, state);

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FD),
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Title "Assignments" & Subtitle
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assignments',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Manage your tasks and never miss a deadline',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF64748B).withAlpha(16),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search task...',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF4F46E5),
                            size: 20,
                          ),
                          tooltip: 'Import / Opsi',
                          onPressed: _openImportDialog,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Horizontal Filter Chips: All, Labs, Lectures, Completed
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedFilterIndex;
                      return InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF3B82F6).withAlpha(40)
                                    : const Color(0xFF64748B).withAlpha(10),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF475569),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Task List or Empty State
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF64748B)
                                            .withAlpha(15),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.task_alt_rounded,
                                    size: 48,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedFilterIndex == 3
                                      ? 'Belum ada riwayat tugas selesai'
                                      : 'Belum ada tugas di kategori ini',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tambahkan tugas baru untuk mulai memantau deadline Anda.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: _openAddTaskDialog,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Tambah Tugas Baru'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 6, bottom: 80),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            final course = state.getCourseById(task.courseId);

                            return TaskCard(
                              task: task,
                              relatedCourse: course,
                              onToggleComplete: (_) {
                                state.toggleTaskCompleted(task);
                              },
                              onEdit: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) =>
                                      TaskFormDialog(taskToEdit: task),
                                );
                              },
                              onDelete: () => _confirmDeleteTask(context, task),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            tooltip: 'Tambah Tugas',
            onPressed: _openAddTaskDialog,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Tambah Tugas',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
