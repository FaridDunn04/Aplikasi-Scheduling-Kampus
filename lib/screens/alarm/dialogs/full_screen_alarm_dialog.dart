import 'package:flutter/material.dart';
import '../../../data/models/task_model.dart';
import '../../../core/utils/date_time_utils.dart';

class FullScreenAlarmDialog extends StatefulWidget {
  final Task task;
  final String soundTitle;

  const FullScreenAlarmDialog({
    super.key,
    required this.task,
    this.soundTitle = 'Chime Lembut',
  });

  @override
  State<FullScreenAlarmDialog> createState() => _FullScreenAlarmDialogState();
}

class _FullScreenAlarmDialogState extends State<FullScreenAlarmDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadlineDt = DateTimeUtils.parseIso(widget.task.deadlineDatetime);
    final deadlineFormatted = DateTimeUtils.formatDateTimeDisplay(deadlineDt);

    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF1E293B),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Column(
                children: [
                  const Text(
                    'PENGINGAT TUGAS KULIAH',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_note, color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Memutar: ${widget.soundTitle}',
                        style: const TextStyle(color: Colors.amber, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),

              // Animated Pulsing Alarm Icon & Task Details
              Column(
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent, width: 3),
                      ),
                      child: const Icon(
                        Icons.alarm_on_rounded,
                        color: Colors.redAccent,
                        size: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    widget.task.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.task.description != null && widget.task.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        widget.task.description!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, color: Colors.orangeAccent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Deadline: $deadlineFormatted',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Action Buttons: Snooze & Dismiss
              Column(
                children: [
                  // Tombol Tunda 10 Menit (Snooze)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.amber, width: 1.5),
                        foregroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alarm ditunda 10 menit (Snooze)'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      icon: const Icon(Icons.snooze),
                      label: const Text(
                        'Tunda 10 Menit (Snooze)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tombol Matikan Alarm (Dismiss)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alarm dimatikan'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text(
                        'Matikan Alarm (Dismiss)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
