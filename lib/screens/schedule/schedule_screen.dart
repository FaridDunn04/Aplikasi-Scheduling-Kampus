import 'package:flutter/material.dart';
import '../../core/utils/date_time_utils.dart';
import '../../state/app_state_manager.dart';
import 'widgets/course_card.dart';
import 'dialogs/course_form_dialog.dart';
import 'krs_management_screen.dart';
import '../share/dialogs/share_modal_dialog.dart';
import '../share/dialogs/import_modal_dialog.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<String> _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = DateTime.now().weekday - 1;
  }

  void _openAddCourseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CourseFormDialog(initialDayOfWeek: _selectedDayIndex + 1),
    );
  }

  void _openImportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const ImportModalDialog(),
    );
  }

  void _openShareDialog() {
    final state = AppStateManager.instance;
    if (state.courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada jadwal untuk dibagikan. Tambahkan jadwal terlebih dahulu!'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => ShareModalDialog(
        coursesToShare: state.courses,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStateManager.instance,
      builder: (context, _) {
        final state = AppStateManager.instance;
        final selectedDayOfWeek = _selectedDayIndex + 1;
        final dayCourses = state.getCoursesForDay(selectedDayOfWeek);
        final hasAnyCourse = state.courses.isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FD),
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Title & Action Icons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Schedule',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${DateTimeUtils.getDayName(selectedDayOfWeek)}, ${dayCourses.length} Kelas Terjadwal',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Action Buttons
                      Row(
                        children: [
                          _buildActionCircle(
                            icon: Icons.qr_code_scanner_rounded,
                            tooltip: 'Import Jadwal',
                            onTap: _openImportDialog,
                          ),
                          const SizedBox(width: 8),
                          _buildActionCircle(
                            icon: Icons.share_rounded,
                            tooltip: 'Bagikan Jadwal',
                            onTap: hasAnyCourse ? _openShareDialog : null,
                          ),
                          const SizedBox(width: 8),
                          _buildActionCircle(
                            icon: Icons.list_alt_rounded,
                            tooltip: 'Kelola KRS',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const KrsManagementScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Horizontal Day Selector Chips
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: _days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedDayIndex;
                      final dayOfWeek = index + 1;
                      final courseCount = state.getCoursesForDay(dayOfWeek).length;

                      return InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          setState(() {
                            _selectedDayIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF2563EB).withAlpha(45)
                                    : const Color(0xFF64748B).withAlpha(10),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _days[index],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (courseCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$courseCount',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF4F46E5),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Course List or Empty State
                Expanded(
                  child: dayCourses.isEmpty
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
                                        color: const Color(0xFF64748B).withAlpha(15),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.wb_sunny_outlined,
                                    size: 46,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Libur! Tidak ada kuliah hari ${_days[_selectedDayIndex]}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Waktunya bersantai, istirahat, atau menyicil tugas.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  onPressed: _openAddCourseDialog,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Tambah Jadwal Kuliah'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 80),
                          itemCount: dayCourses.length,
                          itemBuilder: (context, index) {
                            final course = dayCourses[index];
                            return CourseCard(
                              course: course,
                              onEdit: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => CourseFormDialog(courseToEdit: course),
                                );
                              },
                              onDelete: () {
                                state.deleteCourse(course.id);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            tooltip: 'Tambah Jadwal',
            onPressed: _openAddCourseDialog,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Tambah Jadwal',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withAlpha(16),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 19,
          color: onTap != null ? const Color(0xFF475569) : Colors.grey.shade300,
        ),
      ),
    );
  }
}
