import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  late int _selectedDayIndex;
  late DateTime _startOfWeek;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Monday of current week
    _startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    _selectedDayIndex = now.weekday - 1; // 0 = Mon, 6 = Sun
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
          content: Text('No schedule available to share. Please add classes first!'),
          behavior: SnackBarBehavior.floating,
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

        final selectedDate = _startOfWeek.add(Duration(days: _selectedDayIndex));
        final fullDateHeader = DateFormat('EEEE, MMM d').format(selectedDate);

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FD),
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Title & Action Icons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Schedule',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Your class schedule for this week',
                            style: TextStyle(
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
                            tooltip: 'Import Schedule',
                            onTap: _openImportDialog,
                          ),
                          const SizedBox(width: 8),
                          _buildActionCircle(
                            icon: Icons.share_rounded,
                            tooltip: 'Share Schedule',
                            onTap: hasAnyCourse ? _openShareDialog : null,
                          ),
                          const SizedBox(width: 8),
                          _buildActionCircle(
                            icon: Icons.list_alt_rounded,
                            tooltip: 'Manage Courses',
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

                // Horizontal Day Selector Cards (Mon Oct 6, Tue Oct 7, etc.)
                SizedBox(
                  height: 68,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: 7,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedDayIndex;
                      final dayDate = _startOfWeek.add(Duration(days: index));
                      final dayAbbr = DateFormat('EEE').format(dayDate);
                      final dateStr = DateFormat('MMM d').format(dayDate);

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          setState(() {
                            _selectedDayIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 66,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF2563EB).withAlpha(80)
                                    : const Color(0xFF64748B).withAlpha(12),
                                blurRadius: isSelected ? 12 : 6,
                                offset: Offset(0, isSelected ? 4 : 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayAbbr,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white.withAlpha(230)
                                      : const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Selected Day Header (e.g. Thursday, Oct 9)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fullDateHeader,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: dayCourses.isEmpty ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          dayCourses.isEmpty
                              ? 'No classes'
                              : '${dayCourses.length} ${dayCourses.length == 1 ? 'class' : 'classes'}',
                          style: TextStyle(
                            color: dayCourses.isEmpty ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
                                  'No classes scheduled for ${DateFormat('EEEE').format(selectedDate)}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Time to relax, recharge, or catch up on your assignments.',
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
                                  label: const Text('Add Class Schedule'),
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
            tooltip: 'Add Schedule',
            onPressed: _openAddCourseDialog,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Add Schedule',
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
