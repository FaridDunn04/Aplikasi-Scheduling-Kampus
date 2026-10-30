class ShareTaskItem {
  final String title;
  final String? description;
  final String? courseCodeRef;
  final String? courseNameRef;
  final String deadlineDatetime;
  final String reminderDatetime;
  final bool isAlarmEnabled;

  ShareTaskItem({
    required this.title,
    this.description,
    this.courseCodeRef,
    this.courseNameRef,
    required this.deadlineDatetime,
    required this.reminderDatetime,
    this.isAlarmEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'course_code_ref': courseCodeRef,
      'course_name_ref': courseNameRef,
      'deadline_datetime': deadlineDatetime,
      'reminder_datetime': reminderDatetime,
      'is_alarm_enabled': isAlarmEnabled,
    };
  }

  factory ShareTaskItem.fromJson(Map<String, dynamic> json) {
    return ShareTaskItem(
      title: json['title'] as String,
      description: json['description'] as String?,
      courseCodeRef: json['course_code_ref'] as String?,
      courseNameRef: json['course_name_ref'] as String?,
      deadlineDatetime: json['deadline_datetime'] as String,
      reminderDatetime: json['reminder_datetime'] as String,
      isAlarmEnabled: json['is_alarm_enabled'] as bool? ?? true,
    );
  }
}

class ShareCourseItem {
  final String courseName;
  final String? courseCode;
  final int sks;
  final String? lecturerName;
  final String? room;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String colorHex;

  ShareCourseItem({
    required this.courseName,
    this.courseCode,
    this.sks = 0,
    this.lecturerName,
    this.room,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.colorHex = '#3B82F6',
  });

  Map<String, dynamic> toJson() {
    return {
      'course_name': courseName,
      'course_code': courseCode,
      'sks': sks,
      'lecturer_name': lecturerName,
      'room': room,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'color_hex': colorHex,
    };
  }

  factory ShareCourseItem.fromJson(Map<String, dynamic> json) {
    return ShareCourseItem(
      courseName: json['course_name'] as String,
      courseCode: json['course_code'] as String?,
      sks: (json['sks'] as num?)?.toInt() ?? 0,
      lecturerName: json['lecturer_name'] as String?,
      room: json['room'] as String?,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      colorHex: (json['color_hex'] as String?) ?? '#3B82F6',
    );
  }
}

class SharePayload {
  final String schemaVersion;
  final String shareType; // 'SINGLE_TASK' | 'COLLECTIVE_SCHEDULE'
  final String generatedAt;
  final List<ShareCourseItem> courses;
  final List<ShareTaskItem> tasks;

  SharePayload({
    this.schemaVersion = '1.0',
    required this.shareType,
    required this.generatedAt,
    this.courses = const [],
    this.tasks = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'share_type': shareType,
      'generated_at': generatedAt,
      'payload': {
        'courses': courses.map((c) => c.toJson()).toList(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
      },
    };
  }

  factory SharePayload.fromJson(Map<String, dynamic> json) {
    final payloadMap = json['payload'] as Map<String, dynamic>? ?? {};
    final coursesList = (payloadMap['courses'] as List<dynamic>? ?? [])
        .map((c) => ShareCourseItem.fromJson(c as Map<String, dynamic>))
        .toList();
    final tasksList = (payloadMap['tasks'] as List<dynamic>? ?? [])
        .map((t) => ShareTaskItem.fromJson(t as Map<String, dynamic>))
        .toList();

    return SharePayload(
      schemaVersion: json['schema_version'] as String? ?? '1.0',
      shareType: json['share_type'] as String? ?? 'SINGLE_TASK',
      generatedAt: json['generated_at'] as String? ?? DateTime.now().toIso8601String(),
      courses: coursesList,
      tasks: tasksList,
    );
  }
}
