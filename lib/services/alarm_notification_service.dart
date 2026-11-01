import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart';

import '../data/models/task_model.dart';
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

  // Channel ID & Nama untuk Android
  static const String channelIdAlarm = 'unisched_alarm_channel';
  static const String channelNameAlarm = 'Alarm Pengingat Tugas';
  static const String channelDescAlarm = 'Membunyikan nada dering alarm saat waktu pengingat tugas kuliah tiba.';

  static const String channelIdCountdown = 'unisched_countdown_channel';
  static const String channelNameCountdown = 'Peringatan Deadline Tugas';
  static const String channelDescCountdown = 'Notifikasi hitung mundur berkala 5 menit terakhir sebelum batas waktu deadline tugas.';

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
      // Channel 1: Alarm Pengingat (Prioritas Max, Bersuara Keras & Bergetar)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelIdAlarm,
          channelNameAlarm,
          description: channelDescAlarm,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
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
    debugPrint('[AlarmService] Notifikasi diklik, payload: $payload');
    if (payload != null && navigatorKey?.currentContext != null) {
      try {
        final task = AppStateManager.instance.tasks.firstWhere((t) => t.id == payload);
        triggerAlarm(navigatorKey!.currentContext!, task);
      } catch (_) {}
    }
  }

  // ================= PEMUTAR AUDIO NADA DERING ALARM =================
  Future<void> playAlarmSound(String? soundIdOrPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);

      String assetPath = 'sounds/chime.wav';
      if (soundIdOrPath != null) {
        final lower = soundIdOrPath.toLowerCase();
        if (lower.contains('beep')) {
          assetPath = 'sounds/beep.wav';
        } else if (lower.contains('energetic')) {
          assetPath = 'sounds/energetic.wav';
        }
      }

      await _audioPlayer.play(AssetSource(assetPath));
      debugPrint('[AlarmService] Memutar nada dering alarm: $assetPath');
    } catch (e) {
      debugPrint('[AlarmService] Gagal memutar nada dering: $e');
    }
  }

  Future<void> stopAlarmSound() async {
    try {
      await _audioPlayer.stop();
      debugPrint('[AlarmService] Nada dering alarm dihentikan');
    } catch (e) {
      debugPrint('[AlarmService] Gagal menghentikan audio: $e');
    }
  }

  // ================= PENJADWALAN ALARM & HITUNG MUNDUR DEADLINE =================
  Future<void> scheduleAlarmForTask(Task task) async {
    // Jika tugas sudah selesai, batalkan semua alarm & notifikasi terkait
    if (task.isCompleted) {
      cancelAlarmForTask(task.id);
      return;
    }

    // Batalkan jadwal lama terlebih dahulu agar tidak dobel
    cancelAlarmForTask(task.id);

    final int baseId = task.id.hashCode.abs() % 100000;
    final now = DateTime.now();

    // 1. BAGIAN A: ALARM PADA WAKTU PENGINGAT (Hanya ada di waktu pengingat saja)
    if (task.isAlarmEnabled) {
      try {
        final reminderDt = DateTimeUtils.parseIso(task.reminderDatetime);
        if (reminderDt.isAfter(now)) {
          final int reminderNotifId = baseId * 10 + 0;
          await _scheduleZonedNotification(
            id: reminderNotifId,
            title: '⏰ Alarm Pengingat: ${task.title}',
            body: 'Waktu pengingat tugas kuliah tiba! Buka aplikasi untuk melihat rincian.',
            scheduledDate: reminderDt,
            channelId: channelIdAlarm,
            channelName: channelNameAlarm,
            channelDesc: channelDescAlarm,
            importance: Importance.max,
            priority: Priority.high,
            payload: task.id,
            isAlarm: true,
          );
          debugPrint('[AlarmService] Alarm dijadwalkan pada $reminderDt untuk "${task.title}"');
        }
      } catch (e) {
        debugPrint('[AlarmService] Error scheduling reminder alarm: $e');
      }
    }

    // 2. BAGIAN B: PESAN NOTIFIKASI HITUNG MUNDUR DEADLINE (5 Menit Terakhir, 1 Notifikasi Tiap Menit)
    try {
      final deadlineDt = DateTimeUtils.parseIso(task.deadlineDatetime);

      // Loop dari 5 menit sebelum sampai 0 menit (saat deadline habis)
      for (int m = 5; m >= 0; m--) {
        final targetTime = deadlineDt.subtract(Duration(minutes: m));

        // Hanya jadwalkan jika waktu target belum lewat dari saat ini
        if (targetTime.isAfter(now)) {
          String notifTitle;
          String notifBody;

          if (m == 5) {
            notifTitle = '⚠️ Deadline Mendekati (Tinggal 5 Menit!)';
            notifBody = 'Tugas "${task.title}" tersisa 5 menit lagi sebelum batas waktu pengumpulan!';
          } else if (m == 4) {
            notifTitle = '⚠️ Deadline Mendekati (Tinggal 4 Menit!)';
            notifBody = 'Tugas "${task.title}" tersisa 4 menit lagi sebelum batas waktu pengumpulan!';
          } else if (m == 3) {
            notifTitle = '⚠️ Deadline Mendekati (Tinggal 3 Menit!)';
            notifBody = 'Tugas "${task.title}" tersisa 3 menit lagi sebelum batas waktu pengumpulan!';
          } else if (m == 2) {
            notifTitle = '⚠️ Deadline Mendekati (Tinggal 2 Menit!)';
            notifBody = 'Tugas "${task.title}" tersisa 2 menit lagi sebelum batas waktu pengumpulan!';
          } else if (m == 1) {
            notifTitle = '🚨 Deadline Sangat Dekat (Tinggal 1 Menit!)';
            notifBody = 'Tugas "${task.title}" tersisa 1 menit lagi! Segera selesaikan sekarang!';
          } else {
            notifTitle = '⏰ Waktu Deadline Habis!';
            notifBody = 'Batas waktu pengerjaan tugas "${task.title}" telah berakhir.';
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
          debugPrint('[AlarmService] Countdown ($m menit) dijadwalkan pada $targetTime untuk "${task.title}"');
        }
      }
    } catch (e) {
      debugPrint('[AlarmService] Error scheduling deadline countdowns: $e');
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
      enableVibration: true,
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
        payload: payload,
      );
    } catch (e) {
      // Fallback jika exact alarm belum diizinkan oleh sistem Android
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzScheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      } catch (fallbackError) {
        debugPrint('[AlarmService] Fallback zonedSchedule failed: $fallbackError');
      }
    }
  }

  void cancelAlarmForTask(String taskId) {
    final int baseId = taskId.hashCode.abs() % 100000;
    // Batalkan notifikasi pengingat (0) dan notifikasi countdown 5..0 menit (1..6)
    for (int i = 0; i <= 6; i++) {
      _notificationsPlugin.cancel(id: baseId * 10 + i);
    }
    stopAlarmSound();
    debugPrint('[AlarmService] Semua notifikasi & alarm dibatalkan untuk task: $taskId');
  }

  // Tunda Alarm (Snooze 10 Menit)
  Future<void> snoozeAlarm(Task task, {int minutes = 10}) async {
    await stopAlarmSound();
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final int baseId = task.id.hashCode.abs() % 100000;

    await _scheduleZonedNotification(
      id: baseId * 10 + 0,
      title: '⏰ Alarm Pengingat (Snooze): ${task.title}',
      body: 'Pengingat tunda $minutes menit telah tiba! Segera kerjakan tugas ini.',
      scheduledDate: snoozeTime,
      channelId: channelIdAlarm,
      channelName: channelNameAlarm,
      channelDesc: channelDescAlarm,
      importance: Importance.max,
      priority: Priority.high,
      payload: task.id,
      isAlarm: true,
    );
    debugPrint('[AlarmService] Alarm ditunda $minutes menit hingga $snoozeTime');
  }

  // Reschedule semua tugas aktif (dipanggil saat inisialisasi awal)
  Future<void> rescheduleAll(List<Task> tasks) async {
    for (final task in tasks) {
      if (!task.isCompleted) {
        await scheduleAlarmForTask(task);
      }
    }
  }

  // ================= DIALOG IN-APP & FOREGROUND POLLER =================
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

          // Jika waktu sekarang berada di rentang 0 s.d 30 detik setelah reminder
          if (diffInSeconds >= 0 && diffInSeconds <= 30) {
            _triggeredReminderIds.add(task.id);
            triggerAlarm(context, task);
            break; // Tampilkan 1 alarm dialog sekaligus
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
