import 'package:flutter/material.dart';
import '../../../data/models/course_model.dart';
import '../../../state/app_state_manager.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../schedule/dialogs/course_form_dialog.dart';
import '../../main_navigation_screen.dart';

class NextClassCard extends StatelessWidget {
  final Course? nextCourse;

  const NextClassCard({
    super.key,
    required this.nextCourse,
  });

  double _calculateProgress(Course course, bool isOngoing) {
    final now = DateTime.now();
    final currentMin = now.hour * 60 + now.minute;
    final startMin = DateTimeUtils.timeStringToMinutes(course.startTime);
    final endMin = DateTimeUtils.timeStringToMinutes(course.endTime);

    if (isOngoing) {
      if (endMin <= startMin) return 0.5;
      final total = endMin - startMin;
      final elapsed = currentMin - startMin;
      return (elapsed / total).clamp(0.08, 1.0);
    } else {
      final diff = startMin - currentMin;
      if (diff <= 0) return 1.0;
      if (diff > 120) return 0.2;
      return ((120 - diff) / 120).clamp(0.15, 0.95);
    }
  }

  String _formatCountdownBadge(Course course, bool isOngoing) {
    if (isOngoing) return 'Ongoing Now';

    final now = DateTime.now();
    final currentMin = now.hour * 60 + now.minute;
    final startMin = DateTimeUtils.timeStringToMinutes(course.startTime);
    final diff = startMin - currentMin;

    if (diff <= 0) return 'Starts Now';
    if (diff < 60) return 'Starts in ${diff}m';
    final hours = diff ~/ 60;
    final mins = diff % 60;
    return mins > 0 ? 'Starts in ${hours}h ${mins}m' : 'Starts in ${hours}h';
  }

  @override
  Widget build(BuildContext context) {
    if (nextCourse == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withAlpha(18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Caught Up',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tidak Ada Kelas Lagi Hari Ini',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Semua perkuliahan hari ini telah selesai atau sedang libur. Waktunya istirahat atau cicil tugas!',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => MainNavigationScreen.switchTab(1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Jadwal Lengkap',
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, color: Color(0xFF4F46E5), size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isOngoing = AppStateManager.instance.isClassOngoing(nextCourse!);
    final progress = _calculateProgress(nextCourse!, isOngoing);
    final badgeText = _formatCountdownBadge(nextCourse!, isOngoing);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => CourseFormDialog(courseToEdit: nextCourse),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withAlpha(85),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon + "Upcoming Next" + Badge "Starts in 35m"
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isOngoing ? 'Ongoing Now' : 'Upcoming Next',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Course Name
            Text(
              nextCourse!.courseName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Bottom Meta Row: Time | Room | Lecturer
            Row(
              children: [
                const Icon(Icons.access_time_filled_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${nextCourse!.startTime} – ${nextCourse!.endTime}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('|', style: TextStyle(color: Colors.white38, fontSize: 13)),
                const SizedBox(width: 10),
                const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  (nextCourse!.room != null && nextCourse!.room!.trim().isNotEmpty)
                      ? nextCourse!.room!
                      : 'Ruang Kelas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (nextCourse!.lecturerName != null && nextCourse!.lecturerName!.trim().isNotEmpty) ...[
                  const SizedBox(width: 10),
                  const Text('|', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  const SizedBox(width: 10),
                  const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      nextCourse!.lecturerName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Progress Bar
            Container(
              height: 5,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(45),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
