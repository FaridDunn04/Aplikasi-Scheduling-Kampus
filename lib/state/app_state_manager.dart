import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/database/database_helper.dart';
import '../data/models/course_model.dart';
import '../data/models/task_model.dart';
import '../data/models/alarm_sound_model.dart';
import '../data/models/share_payload_model.dart';
import '../core/utils/date_time_utils.dart';
import '../services/alarm_notification_service.dart';
import 'dart:async';

class AppStateManager extends ChangeNotifier {
  static final AppStateManager instance = AppStateManager._init();
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  List<Course> _courses = [];
  List<Task> _tasks = [];
  List<AlarmSound> _alarmSounds = [];
  bool _isLoading = true;

  AppStateManager._init();

  List<Course> get courses => _courses;
  List<Task> get tasks => _tasks;
  List<AlarmSound> get alarmSounds => _alarmSounds;
  bool get isLoading => _isLoading;

  int get totalSks => _courses.fold(0, (sum, c) => sum + c.sks);

  Timer? _autoCompleteTimer;
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await _db.ensureDefaultData();
    await refresh();
    await AlarmNotificationService.instance.rescheduleAll(_tasks);
    // 2. Tambahkan timer pengecekan otomatis tiap 1 menit:

    _autoCompleteTimer?.cancel();
    _autoCompleteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _autoCompleteExpiredTasks();
    });
    _isLoading = false;
    notifyListeners();
  }


  Future<void> refresh() async {
    _courses = await _db.getAllCourses();
    _tasks = await _db.getAllTasks();
    _alarmSounds = await _db.getAllAlarmSounds();

    await _autoCompleteExpiredTasks();

    notifyListeners();
  }

  Future<void> _autoCompleteExpiredTasks() async {
    final now = DateTime.now();
    bool anyUpdate = false;

    for (final task in _tasks) {
      if (!task.isCompleted) {
        final deadline = DateTimeUtils.parseIso(task.deadlineDatetime);

        if (now.isAfter(deadline)) {
          final updated = task.copyWith(
            isCompleted: true,
            updatedAt: now.toIso8601String(),
          );

          await _db.updateTask(updated);
          AlarmNotificationService.instance.cancelAlarmForTask(task.id);
          anyUpdate = true;
        }
      }
    }

    if(anyUpdate){
      _tasks = await _db.getAllTasks();
      
    }
  }

  // ================= COURSES =================
  List<Course> getCoursesForDay(int dayOfWeek) {
    return _courses.where((c) => c.dayOfWeek == dayOfWeek).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Course? getCourseById(String? id) {
    if (id == null) return null;
    try {
      return _courses.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Course?> checkConflict(
    int day,
    String start,
    String end, {
    String? excludeId,
  }) async {
    return await _db.checkCourseConflict(
      day,
      start,
      end,
      excludeCourseId: excludeId,
    );
  }

  Future<void> saveCourse(Course course, {bool isEdit = false}) async {
    if (isEdit) {
      await _db.updateCourse(course);
    } else {
      await _db.insertCourse(course);
    }
    await refresh();
  }

  Future<void> deleteCourse(String id) async {
    await _db.deleteCourse(id);
    await refresh();
  }

  // ================= NEXT CLASS LOGIC (PRD 5.1 A) =================
  Course? getNextClass() {
    final now = DateTime.now();
    final todayCourses = getCoursesForDay(now.weekday);
    if (todayCourses.isEmpty) return null;

    final currentMinutes = now.hour * 60 + now.minute;

    // 1. Cek jika ada kelas yang sedang berlangsung
    for (final c in todayCourses) {
      final startMin = DateTimeUtils.timeStringToMinutes(c.startTime);
      final endMin = DateTimeUtils.timeStringToMinutes(c.endTime);
      if (currentMinutes >= startMin && currentMinutes <= endMin) {
        return c;
      }
    }

    // 2. Ambil kelas terdekat yang akan datang
    for (final c in todayCourses) {
      final startMin = DateTimeUtils.timeStringToMinutes(c.startTime);
      if (startMin > currentMinutes) {
        return c;
      }
    }

    return null;
  }

  bool isClassOngoing(Course course) {
    final now = DateTime.now();
    if (course.dayOfWeek != now.weekday) return false;
    final currentMinutes = now.hour * 60 + now.minute;
    final startMin = DateTimeUtils.timeStringToMinutes(course.startTime);
    final endMin = DateTimeUtils.timeStringToMinutes(course.endTime);
    return currentMinutes >= startMin && currentMinutes <= endMin;
  }

  String getNextClassCountdown(Course course) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMin = DateTimeUtils.timeStringToMinutes(course.startTime);
    final endMin = DateTimeUtils.timeStringToMinutes(course.endTime);

    if (currentMinutes >= startMin && currentMinutes <= endMin) {
      return 'Sedang Berlangsung';
    }

    final diff = startMin - currentMinutes;
    if (diff <= 0) return 'Selesai';
    if (diff < 60) {
      return 'Mulai dalam $diff menit';
    } else {
      final hours = diff ~/ 60;
      final mins = diff % 60;
      return mins > 0
          ? 'Mulai dalam $hours jam $mins mnt'
          : 'Mulai dalam $hours jam';
    }
  }

  // ================= TASKS =================
  List<Task> getUrgentTasks({int limit = 5}) {
    return _tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => a.deadlineDatetime.compareTo(b.deadlineDatetime));
  }

  List<Task> getFilteredTasks(int filterIndex, {DateTime? specificDate}) {
    final now = DateTime.now();
    switch (filterIndex) {
      case 0: // Segera (< 2 Hari)
        final cutoff = now.add(const Duration(hours: 48));
        return _tasks.where((t) {
            if (t.isCompleted) return false;
            final dt = DateTimeUtils.parseIso(t.deadlineDatetime);
            // Termasuk overdue (dt < now) dan yang deadline <= 48 jam ke depan
            return dt.isBefore(cutoff);
          }).toList()
          ..sort((a, b) => a.deadlineDatetime.compareTo(b.deadlineDatetime));

      case 1: // Per Hari / Kalender
        final targetDate = specificDate ?? now;
        final targetYMD =
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
        return _tasks.where((t) {
            return t.deadlineDatetime.startsWith(targetYMD);
          }).toList()
          ..sort((a, b) => a.deadlineDatetime.compareTo(b.deadlineDatetime));

      case 2: // Semua Aktif
        return _tasks.where((t) => !t.isCompleted).toList()
          ..sort((a, b) => a.deadlineDatetime.compareTo(b.deadlineDatetime));

      case 3: // Selesai
        return _tasks.where((t) => t.isCompleted).toList()
          ..sort((a, b) => b.deadlineDatetime.compareTo(a.deadlineDatetime));

      default:
        return _tasks;
    }
  }

  Future<void> saveTask(Task task, {bool isEdit = false}) async {
    if (isEdit) {
      await _db.updateTask(task);
    } else {
      await _db.insertTask(task);
    }
    AlarmNotificationService.instance.scheduleAlarmForTask(task);
    await refresh();
  }

  Future<void> toggleTaskCompleted(Task task) async {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _db.updateTask(updated);

    if (updated.isCompleted) {
      AlarmNotificationService.instance.cancelAlarmForTask(task.id);
    } else {
      AlarmNotificationService.instance.scheduleAlarmForTask(updated);
    }

    await refresh();
  }

  Future<void> deleteTask(String id) async {
    AlarmNotificationService.instance.cancelAlarmForTask(id);
    await _db.deleteTask(id);
    await refresh();
  }

  // ================= ALARM SOUNDS =================
  Future<void> addAlarmSound(AlarmSound sound) async {
    await _db.insertAlarmSound(sound);
    await refresh();
  }

  Future<void> deleteAlarmSound(String id) async {
    await _db.deleteAlarmSound(id);
    await refresh();
  }

  // ================= SHARE & IMPORT (PRD 6.2 & 7.3) =================
  Future<Map<String, dynamic>> importPayload(
    SharePayload payload, {
    bool autoCreateCourses = true,
  }) async {
    int coursesAdded = 0;
    int tasksAdded = 0;
    int duplicatesSkipped = 0;

    // 1. Simpan courses jika ada di payload
    final Map<String, String> courseCodeToIdMap = {};

    for (final c in payload.courses) {
      final existing = await _db.findCourseByCodeOrName(
        c.courseCode,
        c.courseName,
      );
      if (existing != null) {
        if (c.courseCode != null) {
          courseCodeToIdMap[c.courseCode!.toUpperCase()] = existing.id;
        }
      } else if (autoCreateCourses) {
        final newId = _uuid.v4();
        final nowIso = DateTime.now().toIso8601String();
        final newCourse = Course(
          id: newId,
          courseName: c.courseName,
          courseCode: c.courseCode,
          sks: c.sks,
          lecturerName: c.lecturerName,
          room: c.room,
          dayOfWeek: c.dayOfWeek,
          startTime: c.startTime,
          endTime: c.endTime,
          colorHex: c.colorHex,
          courseType:
              (c.courseName.toLowerCase().contains('lab') ||
                  c.courseName.toLowerCase().contains('praktikum') ||
                  (c.room?.toLowerCase().contains('lab') ?? false))
              ? 'lab'
              : 'lecture',
          createdAt: nowIso,
          updatedAt: nowIso,
        );
        await _db.insertCourse(newCourse);
        coursesAdded++;
        if (c.courseCode != null) {
          courseCodeToIdMap[c.courseCode!.toUpperCase()] = newId;
        }
      }
    }

    // 2. Import tasks
    for (final t in payload.tasks) {
      // Cek duplikasi (PRD 7.3)
      final existingTask = await _db.findExistingTaskForImport(
        null,
        t.title,
        t.deadlineDatetime,
      );
      if (existingTask != null) {
        duplicatesSkipped++;
        continue;
      }

      // Smart Matching Course (PRD 6.2 B.3)
      String? matchedCourseId;
      if (t.courseCodeRef != null &&
          courseCodeToIdMap.containsKey(t.courseCodeRef!.toUpperCase())) {
        matchedCourseId = courseCodeToIdMap[t.courseCodeRef!.toUpperCase()];
      } else {
        final match = await _db.findCourseByCodeOrName(
          t.courseCodeRef,
          t.courseNameRef ?? '',
        );
        matchedCourseId = match?.id;
      }

      final matchedCourse = matchedCourseId != null
          ? getCourseById(matchedCourseId)
          : null;
      final nowIso = DateTime.now().toIso8601String();
      final newTask = Task(
        id: _uuid.v4(),
        courseId: matchedCourseId,
        title: t.title,
        description: t.description,
        deadlineDatetime: t.deadlineDatetime,
        reminderDatetime: t.reminderDatetime,
        isAlarmEnabled: t.isAlarmEnabled,
        alarmSoundId: 'sound_default_1',
        isCompleted: false,
        sharedOriginCode: 'IMP-${DateTime.now().millisecondsSinceEpoch}',
        taskType: (matchedCourse?.isLab ?? false) ? 'lab' : 'lecture',
        createdAt: nowIso,
        updatedAt: nowIso,
      );

      await _db.insertTask(newTask);
      AlarmNotificationService.instance.scheduleAlarmForTask(newTask);
      tasksAdded++;
    }

    await refresh();

    return {
      'coursesAdded': coursesAdded,
      'tasksAdded': tasksAdded,
      'duplicatesSkipped': duplicatesSkipped,
    };
  }

  Future<void> resetAllData() async {
    await _db.clearAllData();
    await refresh();
  }

  @override
  void dispose() {
    _autoCompleteTimer?.cancel();
    super.dispose();
  }
}
