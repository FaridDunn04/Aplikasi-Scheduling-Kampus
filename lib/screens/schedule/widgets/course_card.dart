import 'package:flutter/material.dart';
import '../../../data/models/course_model.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CourseCard({
    super.key,
    required this.course,
    required this.onEdit,
    required this.onDelete,
  });

  bool _isLabCourse(Course course) {
    return course.isLab;
  }

  @override
  Widget build(BuildContext context) {
    final isLab = _isLabCourse(course);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Icon Container
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isLab ? const Color(0xFF818CF8).withAlpha(35) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isLab ? Icons.science_rounded : Icons.menu_book_rounded,
                    color: isLab ? const Color(0xFF6366F1) : const Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Center Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges: Time, Lab/Lecture, SKS
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isLab ? const Color(0xFF6366F1) : const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isLab ? 'Lab' : 'Lecture',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${course.sks} SKS',
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${course.startTime} – ${course.endTime}',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Course Name
                      Text(
                        course.courseName,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Lecturer and Room
                      Row(
                        children: [
                          if (course.room != null && course.room!.trim().isNotEmpty) ...[
                            const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              course.room!,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                            const SizedBox(width: 10),
                          ],
                          const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              (course.lecturerName != null && course.lecturerName!.trim().isNotEmpty)
                                  ? course.lecturerName!
                                  : 'Dosen Pengampu',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trailing Popup Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Jadwal'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
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
