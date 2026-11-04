import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart';

import '../data/models/task_model.dart';
import '../data/models/course_model.dart';
import '../core/utils/date_time_utils.dart';
import '../screens/alarm/dialogs/full_screen_alarm_dialog.dart';
import '../state/app_state_manager.dart';

class AlarmNotificationService {
  static final AlarmNotificationService instance = AlarmNotificationService._init();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _pollingTimer;
  GlobalKey<NavigatorState>? navigatorKey;

  // Track task ID agar alarm tidak berulang-ulang muncul di sesi yang sama
  final Set<String> _triggeredReminderIds = {};

  AlarmNotificationService._init();

  // Channel ID & Names for Android
  static const String channelIdAlarm = 'unisched_alarm_channel_v2';
  static const String channelNameAlarm = 'Assignment Reminder Alarm';
  static const String channelDescAlarm = 'Plays alarm ringtone when course assignment reminder time arrives.';

  static const String channelIdCountdown = 'unisched_countdown_channel';
  static const String channelNameCountdown = 'Assignment Deadline Countdown';
  static const String channelDescCountdown = 'Periodic countdown notifications for the final 5 minutes before deadline.';

  static const String channelIdCourse = 'unisched_course_channel';
  static const String channelNameCourse = 'Class Schedule Reminder';
  static const String channelDescCourse = 'Reminders before class starts (10, 5, and 2 minutes before).';

  Future<void> init(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    // 1. Inisialisasi Timezone
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {
        tz.setLocalLocation(tz.local);
      }
    } catch (e) {
      debugPrint('[AlarmService] Timezone init error: $e');
    }

    // 2. Inisialisasi Pengaturan Notifikasi Android & iOS
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 3. Konfigurasi Channel Notifikasi di Android
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Hapus channel versi lama agar channel baru dengan nada dering kustom aktif
      try {
        await androidPlugin.deleteNotificationChannel(channelId: 'unisched_alarm_channel');
      } catch (_) {}

      // Channel 1: Alarm Pengingat (Prioritas Max, Bersuara Keras dari res/raw, Mengikuti Silent Mode HP)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelIdAlarm,
          channelNameAlarm,
          description: channelDescAlarm,
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alarm_ringtone'),
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.notification,
          bypassDnd: false,
        ),
      );

      // Channel 2: Hitung Mundur Deadline (Pesan berkala 5, 4, 3, 2, 1, 0 menit)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelIdCountdown,
          channelNameCountdown,
          description: channelDescCountdown,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Channel 3: Pengingat Jadwal Kuliah (10, 5, dan 2 menit sebelum kelas dimulai)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelIdCourse,
          channelNameCourse,
          description: channelDescCourse,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Minta izin sistem (Android 13+ & Alarm Presisi)
      try {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('[AlarmService] Permission request error: $e');
      }
    }

    // 4. Jalankan Foreground Periodic Poller (untuk trigger dialog in-app saat app terbuka)
    _startReminderPoller();
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('[AlarmService] Notification tapped, payload: $payload');
    if (payload != null && navigatorKey?.currentContext != null) {
      try {
        final task = AppStateManager.instance.tasks.where((t) => t.id == payload).firstOrNull;
        if (task != null) {
          final sound = AppStateManager.instance.alarmSounds
              .where((s) => s.id == task.alarmSoundId)
              .firstOrNull;
          triggerAlarm(
            navigatorKey!.currentContext!,
            task,
            soundTitle: sound?.title ?? 'Soft Chime',
          );
        }
      } catch (_) {}
    }
  }

  // ================= ALARM AUDIO RINGTONE PLAYER =================
  Future<void> playAlarmSound(String? soundIdOrPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);

      if (soundIdOrPath != null) {
        // Check if soundId matches a local file import in AppStateManager
        try {
          final sound = AppStateManager.instance.alarmSounds
              .where((s) => s.id == soundIdOrPath)
              .firstOrNull;

          if (sound != null && sound.localFilePath.isNotEmpty) {
            final file = File(sound.localFilePath);
            if (await file.exists()) {
              await _audioPlayer.play(DeviceFileSource(sound.localFilePath));
              debugPrint('[AlarmService] Playing local file: ${sound.localFilePath}');
              return;
            }
          }
        } catch (_) {}

        // Check if soundIdOrPath itself is an existing file path
        try {
          final directFile = File(soundIdOrPath);
          if (await directFile.exists()) {
            await _audioPlayer.play(DeviceFileSource(soundIdOrPath));
            debugPrint('[AlarmService] Playing direct file: $soundIdOrPath');
            return;
          }
        } catch (_) {}

        final lower = soundIdOrPath.toLowerCase();
        if (lower.contains('beep') || soundIdOrPath == 'sound_default_2') {
          await _audioPlayer.play(AssetSource('sounds/beep.wav'));
          debugPrint('[AlarmService] Playing asset: sounds/beep.wav');
          return;
        } else if (lower.contains('energetic') || soundIdOrPath == 'sound_default_3') {
          await _audioPlayer.play(AssetSource('sounds/energetic.wav'));
          debugPrint('[AlarmService] Playing asset: sounds/energetic.wav');
          return;
        }
      }

      await _audioPlayer.play(AssetSource('sounds/chime.wav'));
      debugPrint('[AlarmService] Playing default chime: sounds/chime.wav');
    } catch (e) {
      debugPrint('[AlarmService] Failed to play sound: $e');
    }
  }

  Future<void> stopAlarmSound() async {
    try {
      await _audioPlayer.stop();
      debugPrint('[AlarmService] Alarm audio stopped');
    } catch (e) {
      debugPrint('[AlarmService] Failed to stop audio: $e');
    }
  }

  // ================= TASK ALARM SCHEDULING & DEADLINE COUNTDOWN =================
  Future<void> scheduleAlarmForTask(Task task) async {
    // If task is completed, cancel all notifications & alarms
    if (task.isCompleted) {
      cancelAlarmForTask(task.id);
      return;
    }

    cancelAlarmForTask(task.id);

    final int baseId = task.id.hashCode.abs() % 100000;
    final now = DateTime.now();

    // 1. REMINDER NOTIFICATION (At reminder datetime)
    try {
      final reminderDt = DateTimeUtils.parseIso(task.reminderDatetime);
      if (reminderDt.isAfter(now)) {
        final int reminderNotifId = baseId * 10 + 0;
        await _scheduleZonedNotification(
          id: reminderNotifId,
          title: task.isAlarmEnabled
              ? '⏰ Reminder Alarm: ${task.title}'
              : '📌 Task Reminder: ${task.title}',
          body: task.isAlarmEnabled
              ? 'Assignment reminder time has arrived! Open app to view details.'
              : 'Reminder for task "${task.title}". Tap to check details.',
          scheduledDate: reminderDt,
          channelId: task.isAlarmEnabled ? channelIdAlarm : channelIdCountdown,
          channelName: task.isAlarmEnabled ? channelNameAlarm : channelNameCountdown,
          channelDesc: task.isAlarmEnabled ? channelDescAlarm : channelDescCountdown,
          importance: task.isAlarmEnabled ? Importance.max : Importance.high,
          priority: Priority.high,
          payload: task.id,
          isAlarm: task.isAlarmEnabled,
        );
        debugPrint('[AlarmService] Reminder notification scheduled at $reminderDt for "${task.title}" (isAlarm: ${task.isAlarmEnabled})');
      }
    } catch (e) {
      debugPrint('[AlarmService] Error scheduling reminder notification: $e');
    }

    // 2. DEADLINE COUNTDOWN NOTIFICATIONS (Last 5 Minutes, 1 per minute)
    try {
      final deadlineDt = DateTimeUtils.parseIso(task.deadlineDatetime);

      // Loop from 5 minutes down to 0 (at deadline)
      for (int m = 5; m >= 0; m--) {
        final targetTime = deadlineDt.subtract(Duration(minutes: m));

        // Only schedule if target time is in the future
        if (targetTime.isAfter(now)) {
          String notifTitle;
          String notifBody;

          if (m == 5) {
            notifTitle = '⚠️ Deadline Approaching (5 Minutes Left!)';
            notifBody = 'Task "${task.title}" has 5 minutes left until submission deadline!';
          } else if (m == 4) {
            notifTitle = '⚠️ Deadline Approaching (4 Minutes Left!)';
            notifBody = 'Task "${task.title}" has 4 minutes left until submission deadline!';
          } else if (m == 3) {
            notifTitle = '⚠️ Deadline Approaching (3 Minutes Left!)';
            notifBody = 'Task "${task.title}" has 3 minutes left until submission deadline!';
          } else if (m == 2) {
            notifTitle = '⚠️ Deadline Approaching (2 Minutes Left!)';
            notifBody = 'Task "${task.title}" has 2 minutes left until submission deadline!';
          } else if (m == 1) {
            notifTitle = '🚨 Deadline Critical (1 Minute Left!)';
            notifBody = 'Task "${task.title}" has only 1 minute left! Submit now!';
          } else {
            notifTitle = '⏰ Deadline Passed!';
            notifBody = 'Submission deadline for "${task.title}" has ended.';
          }

          final int countdownNotifId = baseId * 10 + (6 - m);
          await _scheduleZonedNotification(
            id: countdownNotifId,
            title: notifTitle,
            body: notifBody,
            scheduledDate: targetTime,
            channelId: channelIdCountdown,
            channelName: channelNameCountdown,
            channelDesc: channelDescCountdown,
            importance: Importance.high,
            priority: Priority.high,
            payload: task.id,
            isAlarm: false,
          );
          debugPrint('[AlarmService] Countdown ($m min) scheduled at $targetTime for "${task.title}"');
        }
      }
    } catch (e) {
      debugPrint('[AlarmService] Error scheduling deadline countdowns: $e');
    }
  }

  // ================= COURSE CLASS REMINDER NOTIFICATIONS =================
  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute, int minusMinutes) {
    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).subtract(Duration(minutes: minusMinutes));

    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  /// Schedules 3 reminders before class starts: 10 minutes, 5 minutes, and 2 minutes before
  Future<void> scheduleNotificationsForCourse(Course course) async {
    cancelNotificationsForCourse(course.id);

    try {
      final parts = course.startTime.split(':');
      if (parts.length < 2) return;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final int courseBaseId = (course.id.hashCode.abs() % 100000) + 500000;
      final roomStr = (course.room != null && course.room!.trim().isNotEmpty)
          ? ' di ${course.room!.trim()}'
          : '';

      final reminders = [
        {
          'offset': 10,
          'suffix': 1,
          'title': '🔔 Kelas dalam 10 Menit: ${course.courseName}',
          'body': 'Kuliah dimulai pukul ${course.startTime}$roomStr. Segera persiapkan materi kuliah!',
        },
        {
          'offset': 5,
          'suffix': 2,
          'title': '⚠️ Kelas dalam 5 Menit: ${course.courseName}',
          'body': 'Kuliah dimulai pukul ${course.startTime}$roomStr. Segera masuk ke ruang kelas!',
        },
        {
          'offset': 2,
          'suffix': 3,
          'title': '🚨 Kelas dalam 2 Menit: ${course.courseName}',
          'body': 'Kuliah ${course.courseName} dimulai pukul ${course.startTime}$roomStr! Harap segera hadir.',
        },
      ];

      for (final r in reminders) {
        final offset = r['offset'] as int;
        final suffix = r['suffix'] as int;
        final title = r['title'] as String;
        final body = r['body'] as String;

        final scheduledDate = _nextInstanceOfDayAndTime(course.dayOfWeek, hour, minute, offset);
        final notifId = courseBaseId * 10 + suffix;

        await _scheduleZonedNotification(
          id: notifId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          channelId: channelIdCourse,
          channelName: channelNameCourse,
          channelDesc: channelDescCourse,
          importance: Importance.high,
          priority: Priority.high,
          payload: course.id,
          isAlarm: false,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        debugPrint('[AlarmService] Scheduled weekly course reminder ($offset min before) at $scheduledDate for "${course.courseName}"');
      }
    } catch (e) {
      debugPrint('[AlarmService] Error scheduling course reminders: $e');
    }
  }

  void cancelNotificationsForCourse(String courseId) {
    final int courseBaseId = (courseId.hashCode.abs() % 100000) + 500000;
    for (int i = 1; i <= 3; i++) {
      _notificationsPlugin.cancel(id: courseBaseId * 10 + i);
    }
    debugPrint('[AlarmService] Cancelled class reminders for course: $courseId');
  }

  Future<void> rescheduleAllCourses(List<Course> courses) async {
    for (final course in courses) {
      await scheduleNotificationsForCourse(course);
    }
  }

  Future<void> _scheduleZonedNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    required String channelName,
    required String channelDesc,
    required Importance importance,
    required Priority priority,
    required String payload,
    required bool isAlarm,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: importance,
      priority: priority,
      playSound: true,
      sound: isAlarm ? const RawResourceAndroidNotificationSound('alarm_ringtone') : null,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.notification,
      category: isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
      fullScreenIntent: isAlarm,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } catch (e) {
      // Fallback if exact alarm not yet granted
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzScheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: matchDateTimeComponents,
          payload: payload,
        );
      } catch (fallbackError) {
        debugPrint('[AlarmService] Fallback zonedSchedule failed: $fallbackError');
      }
    }
  }

  void cancelAlarmForTask(String taskId) {
    final int baseId = taskId.hashCode.abs() % 100000;
    for (int i = 0; i <= 6; i++) {
      _notificationsPlugin.cancel(id: baseId * 10 + i);
    }
    stopAlarmSound();
    debugPrint('[AlarmService] All notifications & alarms cancelled for task: $taskId');
  }

  // Snooze Alarm (10 Minutes)
  Future<void> snoozeAlarm(Task task, {int minutes = 10}) async {
    await stopAlarmSound();
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final int baseId = task.id.hashCode.abs() % 100000;

    await _scheduleZonedNotification(
      id: baseId * 10 + 0,
      title: '⏰ Reminder Alarm (Snooze): ${task.title}',
      body: 'Snooze reminder ($minutes minutes) has arrived! Complete this task now.',
      scheduledDate: snoozeTime,
      channelId: channelIdAlarm,
      channelName: channelNameAlarm,
      channelDesc: channelDescAlarm,
      importance: Importance.max,
      priority: Priority.high,
      payload: task.id,
      isAlarm: true,
    );
    debugPrint('[AlarmService] Alarm snoozed for $minutes minutes until $snoozeTime');
  }

  // Reschedule all active tasks
  Future<void> rescheduleAll(List<Task> tasks) async {
    for (final task in tasks) {
      if (!task.isCompleted) {
        await scheduleAlarmForTask(task);
      }
    }
  }

  // ================= IN-APP DIALOG & FOREGROUND POLLER =================
  void triggerAlarm(BuildContext context, Task task, {String soundTitle = 'Soft Chime'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FullScreenAlarmDialog(
        task: task,
        soundTitle: soundTitle,
      ),
    );
  }

  void _startReminderPoller() {
    _pollingTimer?.cancel();
    // Periksa reminder setiap 10 detik secara live saat aplikasi terbuka
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkDueReminders();
    });
  }

  Future<void> _checkDueReminders() async {
    final context = navigatorKey?.currentContext;
    if (context == null || !context.mounted) return;

    final now = DateTime.now();
    final tasks = AppStateManager.instance.tasks;

    for (final task in tasks) {
      if (task.isCompleted) continue;

      // Pengecekan Waktu Pengingat Alarm (Hanya terjadi di waktu pengingat)
      if (task.isAlarmEnabled && !_triggeredReminderIds.contains(task.id)) {
        try {
          final reminderDt = DateTimeUtils.parseIso(task.reminderDatetime);
          final diffInSeconds = now.difference(reminderDt).inSeconds;

          // If current time is within 0 to 30 seconds after reminder
          if (diffInSeconds >= 0 && diffInSeconds <= 30) {
            _triggeredReminderIds.add(task.id);
            final sound = AppStateManager.instance.alarmSounds
                .where((s) => s.id == task.alarmSoundId)
                .firstOrNull;
            triggerAlarm(
              context,
              task,
              soundTitle: sound?.title ?? 'Soft Chime',
            );
            break; // Show 1 alarm dialog at a time
          }
        } catch (_) {}
      }
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _audioPlayer.dispose();
  }
}
