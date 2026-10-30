class Course {
  final String id;
  final String courseName;
  final String? courseCode;
  final int sks;
  final String? lecturerName;
  final String? room;
  final int dayOfWeek; // 1 (Senin) s/d 7 (Minggu)
  final String startTime; // Format HH:mm
  final String endTime; // Format HH:mm
  final String colorHex;
  final String courseType; // 'lecture' | 'lab'
  final String createdAt;
  final String updatedAt;

  Course({
    required this.id,
    required this.courseName,
    this.courseCode,
    this.sks = 0,
    this.lecturerName,
    this.room,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.colorHex = '#3B82F6',
    this.courseType = 'lecture',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLab {
    final type = courseType.toLowerCase().trim();
    if (type == 'lab') return true;
    if (type == 'lecture') return false;
    final lowerName = courseName.toLowerCase();
    final lowerRoom = room?.toLowerCase() ?? '';
    return lowerName.contains('lab') ||
        lowerName.contains('praktikum') ||
        lowerRoom.contains('lab');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_name': courseName,
      'course_code': courseCode,
      'sks': sks,
      'lecturer_name': lecturerName,
      'room': room,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'color_hex': colorHex,
      'course_type': courseType,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      courseName: map['course_name'] as String,
      courseCode: map['course_code'] as String?,
      sks: (map['sks'] as num?)?.toInt() ?? 0,
      lecturerName: map['lecturer_name'] as String?,
      room: map['room'] as String?,
      dayOfWeek: (map['day_of_week'] as num).toInt(),
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      colorHex: (map['color_hex'] as String?) ?? '#3B82F6',
      courseType: (map['course_type'] as String?) ?? 'lecture',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Course copyWith({
    String? id,
    String? courseName,
    String? courseCode,
    int? sks,
    String? lecturerName,
    String? room,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? colorHex,
    String? courseType,
    String? createdAt,
    String? updatedAt,
  }) {
    return Course(
      id: id ?? this.id,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      sks: sks ?? this.sks,
      lecturerName: lecturerName ?? this.lecturerName,
      room: room ?? this.room,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorHex: colorHex ?? this.colorHex,
      courseType: courseType ?? this.courseType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
