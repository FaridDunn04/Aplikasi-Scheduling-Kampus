import 'package:flutter/material.dart';
import '../../../data/models/course_model.dart';
import '../../../state/app_state_manager.dart';
import '../../schedule/dialogs/course_form_dialog.dart';
import '../../main_navigation_screen.dart';

class TodayCoursesSection extends StatelessWidget {
  final List<Course> todayCourses;

  const TodayCoursesSection({
    super.key,
    required this.todayCourses,
  });

  bool _isLabCourse(Course course) {
    return course.isLab;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Flow",
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => MainNavigationScreen.switchTab(1),
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

        if (todayCourses.isEmpty)
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
            child: Column(
              children: [
                Icon(Icons.bedtime_outlined, size: 36, color: Colors.blue.shade300),
                const SizedBox(height: 10),
                const Text(
                  'Tidak ada jadwal kuliah hari ini. Waktunya istirahat atau cicil tugas! ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todayCourses.length,
            itemBuilder: (context, index) {
              final course = todayCourses[index];
              final isLast = index == todayCourses.length - 1;
              final isOngoing = AppStateManager.instance.isClassOngoing(course);
              final isLab = _isLabCourse(course);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Timeline Column with Time & Connected Node
                    SizedBox(
                      width: 58,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 14),
                          // Times
                          Text(
                            course.startTime,
                            style: TextStyle(
                              color: isOngoing ? const Color(0xFF2563EB) : const Color(0xFF334155),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            course.endTime,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Timeline Node Dot
                          Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: isOngoing ? const Color(0xFF2563EB) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isOngoing ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                width: 2,
                              ),
                              boxShadow: isOngoing
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB).withAlpha(150),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                            ),
                          ),
                          // Connecting Vertical Line
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Course Card
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => CourseFormDialog(courseToEdit: course),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isOngoing ? const Color(0xFFEFF6FF) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isOngoing
                                    ? const Color(0xFF2563EB).withAlpha(80)
                                    : const Color(0xFFF1F5F9),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF64748B).withAlpha(15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            child: Row(
                              children: [
                                // Left Rounded Icon Circle (Blue when ongoing, like previous design)
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isOngoing
                                        ? const Color(0xFFDBEAFE)
                                        : (isLab ? const Color(0xFF818CF8).withAlpha(35) : const Color(0xFFF1F5F9)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isLab ? Icons.science_rounded : Icons.menu_book_rounded,
                                    color: isOngoing
                                        ? const Color(0xFF2563EB)
                                        : (isLab ? const Color(0xFF6366F1) : const Color(0xFF475569)),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Center Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Category Pill (Blue when ongoing, like previous design)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOngoing
                                              ? const Color(0xFFDBEAFE)
                                              : (isLab
                                                  ? const Color(0xFF6366F1)
                                                  : const Color(0xFFE2E8F0)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          isLab ? 'Lab' : 'Lecture',
                                          style: TextStyle(
                                            color: isOngoing
                                                ? const Color(0xFF2563EB)
                                                : (isLab ? Colors.white : const Color(0xFF475569)),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Course Name
                                      Text(
                                        course.courseName,
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),

                                      // Lecturer • Room
                                      Text(
                                        [
                                          if (course.lecturerName != null && course.lecturerName!.trim().isNotEmpty)
                                            course.lecturerName!,
                                          if (course.room != null && course.room!.trim().isNotEmpty)
                                            course.room!
                                          else
                                            'Room 201',
                                        ].join('  •  '),
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Chevron Right
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
