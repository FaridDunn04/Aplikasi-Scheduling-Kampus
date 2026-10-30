class Task {
  final String id;
  final String? courseId;
  final String title;
  final String? description;
  final String deadlineDatetime; // ISO 8601 (YYYY-MM-DDTHH:mm:00)
  final String reminderDatetime; // ISO 8601 (YYYY-MM-DDTHH:mm:00)
  final bool isAlarmEnabled; // 0 = Hanya Notifikasi, 1 = Notifikasi + Alarm
  final String? alarmSoundId;
  final bool isCompleted; // 0 = Belum Selesai, 1 = Selesai
  final String? sharedOriginCode;
  final String taskType; // 'lecture' | 'lab'
  final String createdAt;
  final String updatedAt;

  Task({
    required this.id,
    this.courseId,
    required this.title,
    this.description,
    required this.deadlineDatetime,
    required this.reminderDatetime,
    this.isAlarmEnabled = true,
    this.alarmSoundId,
    this.isCompleted = false,
    this.sharedOriginCode,
    this.taskType = 'lecture',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLab => taskType.toLowerCase().trim() == 'lab';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'description': description,
      'deadline_datetime': deadlineDatetime,
      'reminder_datetime': reminderDatetime,
      'is_alarm_enabled': isAlarmEnabled ? 1 : 0,
      'alarm_sound_id': alarmSoundId,
      'is_completed': isCompleted ? 1 : 0,
      'shared_origin_code': sharedOriginCode,
      'task_type': taskType,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      courseId: map['course_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      deadlineDatetime: map['deadline_datetime'] as String,
      reminderDatetime: map['reminder_datetime'] as String,
      isAlarmEnabled: (map['is_alarm_enabled'] as num?) == 1,
      alarmSoundId: map['alarm_sound_id'] as String?,
      isCompleted: (map['is_completed'] as num?) == 1,
      sharedOriginCode: map['shared_origin_code'] as String?,
      taskType: (map['task_type'] as String?) ?? 'lecture',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Task copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    String? deadlineDatetime,
    String? reminderDatetime,
    bool? isAlarmEnabled,
    String? alarmSoundId,
    bool? isCompleted,
    String? sharedOriginCode,
    String? taskType,
    String? createdAt,
    String? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadlineDatetime: deadlineDatetime ?? this.deadlineDatetime,
      reminderDatetime: reminderDatetime ?? this.reminderDatetime,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      alarmSoundId: alarmSoundId ?? this.alarmSoundId,
      isCompleted: isCompleted ?? this.isCompleted,
      sharedOriginCode: sharedOriginCode ?? this.sharedOriginCode,
      taskType: taskType ?? this.taskType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
