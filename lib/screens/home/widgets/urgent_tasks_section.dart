import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/task_model.dart';
import '../../../state/app_state_manager.dart';
import '../../task/dialogs/task_form_dialog.dart';
import '../../main_navigation_screen.dart';

class UrgentTasksSection extends StatelessWidget {
  final List<Task> urgentTasks;

  const UrgentTasksSection({
    super.key,
    required this.urgentTasks,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppStateManager.instance;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Urgent Tasks',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: MainNavigationScreen.showAllTasks,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF4F46E5),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (urgentTasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Column(
              children: [
                Icon(Icons.done_all_rounded, size: 36, color: Colors.green),
                SizedBox(height: 10),
                Text(
                  'Semua tugas telah selesai atau belum ada tugas aktif. 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 145,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: urgentTasks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final task = urgentTasks[index];
                final course = state.getCourseById(task.courseId);

                DateTime deadline;
                try {
                  deadline = DateTime.parse(task.deadlineDatetime);
                } catch (_) {
                  deadline = now;
                }

                final isToday = deadline.year == now.year &&
                    deadline.month == now.month &&
                    deadline.day == now.day;
                final tomorrow = now.add(const Duration(days: 1));
                final isTomorrow = deadline.year == tomorrow.year &&
                    deadline.month == tomorrow.month &&
                    deadline.day == tomorrow.day;

                // Color Themes from Screenshot 1
                final isRoseCard = index % 2 == 0;
                final cardBg = isRoseCard
                    ? const Color(0xFFFFF1F2)
                    : const Color(0xFFFFFBEB);
                final badgeColor = isRoseCard
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFF59E0B);
                final badgeLabel = isToday
                    ? 'Due Today'
                    : (isTomorrow ? 'Due Tomorrow' : 'Due Soon');
                final chevronColor = isRoseCard
                    ? const Color(0xFFF43F5E)
                    : const Color(0xFFD97706);

                final timeString = isToday
                    ? DateFormat('HH:mm').format(deadline)
                    : DateFormat('MMM d, HH:mm').format(deadline);

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => TaskFormDialog(taskToEdit: task),
                    );
                  },
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: badgeColor.withAlpha(40),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withAlpha(15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Pill Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_filled_rounded,
                                  color: badgeColor,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  badgeLabel,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: chevronColor,
                              size: 18,
                            ),
                          ],
                        ),

                        // Title & Course
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              course?.courseName ?? 'Tugas Umum',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),

                        // Time / Due Row
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: badgeColor,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeString,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
