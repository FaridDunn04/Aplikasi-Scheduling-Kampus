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
        'Peringatan Jadwal Bentrok',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Waktu kuliah yang Anda pilih bertabrakan dengan mata kuliah yang sudah ada:',
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
                  'Waktu yang sudah ada: ${conflictingCourse.startTime} - ${conflictingCourse.endTime}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                Text(
                  'Waktu baru: $newStartTime - $newEndTime',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.deepOrange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Apakah Anda tetap ingin menyimpan jadwal ini?',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false), // Batal
          child: const Text('Batal & Ubah Jam'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
          onPressed: () => Navigator.pop(context, true), // Tetap Simpan
          child: const Text('Tetap Simpan'),
        ),
      ],
    );
  }
}
