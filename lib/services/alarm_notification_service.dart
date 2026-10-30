import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/task_model.dart';
import '../screens/alarm/dialogs/full_screen_alarm_dialog.dart';

class AlarmNotificationService {
  static final AlarmNotificationService instance = AlarmNotificationService._init();
  Timer? _pollingTimer;
  GlobalKey<NavigatorState>? navigatorKey;

  AlarmNotificationService._init();

  void init(GlobalKey<NavigatorState> navKey) {
    navigatorKey = navKey;
    _startReminderPoller();
  }

  void _startReminderPoller() {
    _pollingTimer?.cancel();
    // Periksa reminder setiap 15 detik secara background di aplikasi
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkDueReminders();
    });
  }

  Future<void> _checkDueReminders() async {
    // Dipanggil secara berkala atau manual
  }

  void triggerAlarm(BuildContext context, Task task, {String soundTitle = 'Chime Lembut'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FullScreenAlarmDialog(
        task: task,
        soundTitle: soundTitle,
      ),
    );
  }

  void cancelAlarmForTask(String taskId) {
    debugPrint('[AlarmService] Alarm dibatalkan untuk task ID: $taskId');
  }

  void scheduleAlarmForTask(Task task) {
    debugPrint('[AlarmService] Alarm dijadwalkan untuk "${task.title}" pada ${task.reminderDatetime}');
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}
