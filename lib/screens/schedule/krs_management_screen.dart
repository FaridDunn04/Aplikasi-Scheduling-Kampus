import 'package:flutter/material.dart';
import '../../data/models/course_model.dart';
import '../../core/utils/date_time_utils.dart';
import '../../state/app_state_manager.dart';
import 'dialogs/course_form_dialog.dart';

class KrsManagementScreen extends StatelessWidget {
  const KrsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStateManager.instance,
      builder: (context, _) {
        final state = AppStateManager.instance;
        final courses = state.courses;
        final totalSks = state.totalSks;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Kelola KRS Semester'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Tambah Mata Kuliah',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const CourseFormDialog(),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Summary Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha(90),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(40),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Total Mata Kuliah', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${courses.length} Matkul',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(height: 32, width: 1, color: Colors.grey.withAlpha(60)),
                    Column(
                      children: [
                        const Text('Beban Studi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '$totalSks SKS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // List of all courses
              Expanded(
                child: courses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada mata kuliah di KRS',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Gunakan tombol + di atas untuk menambah mata kuliah.',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: courses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final c = courses[index];
                          final dayName = DateTimeUtils.getDayName(c.dayOfWeek);

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(int.parse('FF${c.colorHex.replaceAll('#', '')}', radix: 16)),
                                radius: 18,
                                child: Text(
                                  '${c.sks}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                c.courseName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '$dayName • ${c.startTime} - ${c.endTime} ${c.room != null ? "• ${c.room}" : ""}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => CourseFormDialog(courseToEdit: c),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    onPressed: () => _confirmDelete(context, c),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Mata Kuliah?'),
        content: Text('Apakah Anda yakin ingin menghapus "${course.courseName}" dari daftar KRS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AppStateManager.instance.deleteCourse(course.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
