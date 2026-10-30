import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/course_model.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../share/dialogs/share_modal_dialog.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Course? relatedCourse;
  final ValueChanged<bool?> onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.relatedCourse,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final deadlineDt = DateTimeUtils.parseIso(task.deadlineDatetime);
    final reminderDt = DateTimeUtils.parseIso(task.reminderDatetime);

    final dueString = DateFormat('MMM d, HH:mm').format(deadlineDt);
    final alarmString = DateFormat('MMM d, HH:mm').format(reminderDt);

    Color courseColor = const Color(0xFF3B82F6);
    if (relatedCourse != null) {
      try {
        courseColor = Color(int.parse('FF${relatedCourse!.colorHex.replaceAll('#', '')}', radix: 16));
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withAlpha(14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Circular Checkbox / Radio
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onToggleComplete(!task.isCompleted),
                    child: task.isCompleted
                        ? Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          )
                        : Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF94A3B8),
                                width: 1.8,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // 2. Middle Task Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Title
                      Text(
                        task.title,
                        style: TextStyle(
                          color: task.isCompleted
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Course Row (Color dot + Course Name)
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: courseColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              relatedCourse?.courseName ?? 'Tugas Umum',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),

                      // Badges Row: Due Date & Alarm
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          // Category Pill (Lecture / Lab)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: task.isLab
                                  ? const Color(0xFF818CF8).withAlpha(35)
                                  : const Color(0xFF3B82F6).withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  task.isLab ? Icons.science_rounded : Icons.menu_book_rounded,
                                  color: task.isLab ? const Color(0xFF6366F1) : const Color(0xFF2563EB),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.isLab ? 'Lab' : 'Lecture',
                                  style: TextStyle(
                                    color: task.isLab ? const Color(0xFF6366F1) : const Color(0xFF2563EB),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Due Status Pill
                          if (task.isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 13),
                                  SizedBox(width: 4),
                                  Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: Color(0xFF059669),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_filled_rounded, color: Color(0xFFEF4444), size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Due $dueString',
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Alarm Badge
                          if (task.isAlarmEnabled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.notifications_active_rounded, color: Color(0xFF4F46E5), size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Alarm: $alarmString',
                                    style: const TextStyle(
                                      color: Color(0xFF4F46E5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Trailing Chevron & More Actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                    if (val == 'share') {
                      showDialog(
                        context: context,
                        builder: (ctx) => ShareModalDialog(
                          singleTaskToShare: task,
                          relatedCourse: relatedCourse,
                        ),
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Tugas'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_2_outlined, size: 18, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('Bagikan (QR Code)'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus Tugas', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
