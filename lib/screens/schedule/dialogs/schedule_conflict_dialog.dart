import 'package:flutter/material.dart';
import '../../../data/models/course_model.dart';

class ScheduleConflictDialog extends StatelessWidget {
  final Course conflictingCourse;
  final String newStartTime;
  final String newEndTime;

  const ScheduleConflictDialog({
    super.key,
    required this.conflictingCourse,
    required this.newStartTime,
    required this.newEndTime,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
      title: const Text(
        'Schedule Conflict Warning',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The selected class time conflicts with an existing course:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withAlpha(80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conflictingCourse.courseName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Existing Time: ${conflictingCourse.startTime} - ${conflictingCourse.endTime}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                Text(
                  'New Time: $newStartTime - $newEndTime',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.deepOrange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Do you still want to save this schedule?',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel & Change Time'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Save Anyway'),
        ),
      ],
    );
  }
}
