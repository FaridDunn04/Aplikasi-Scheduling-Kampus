import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/course_model.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../state/app_state_manager.dart';
import 'schedule_conflict_dialog.dart';

class CourseFormDialog extends StatefulWidget {
  final Course? courseToEdit;
  final int? initialDayOfWeek;

  const CourseFormDialog({
    super.key,
    this.courseToEdit,
    this.initialDayOfWeek,
  });

  @override
  State<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _sksController;
  late TextEditingController _lecturerController;
  late TextEditingController _roomController;

  late int _selectedDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _selectedColorHex;
  late String _courseType; // 'lecture' | 'lab'

  final List<String> _colorOptions = [
    '#3B82F6', // Blue
    '#10B981', // Green
    '#8B5CF6', // Purple
    '#F59E0B', // Amber
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#F43F5E', // Rose
    '#6366F1', // Indigo
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.courseToEdit;
    _nameController = TextEditingController(text: edit?.courseName ?? '');
    _codeController = TextEditingController(text: edit?.courseCode ?? '');
    _sksController = TextEditingController(text: edit != null ? edit.sks.toString() : '3');
    _lecturerController = TextEditingController(text: edit?.lecturerName ?? '');
    _roomController = TextEditingController(text: edit?.room ?? '');

    _courseType = edit != null ? (edit.courseType.isNotEmpty ? edit.courseType : (edit.isLab ? 'lab' : 'lecture')) : 'lecture';
    _selectedDay = edit?.dayOfWeek ?? widget.initialDayOfWeek ?? DateTime.now().weekday;

    if (edit != null) {
      final startParts = edit.startTime.split(':');
      _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));

      final endParts = edit.endTime.split(':');
      _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));

      _selectedColorHex = edit.colorHex;
    } else {
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 30);
      _selectedColorHex = '#3B82F6';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _sksController.dispose();
    _lecturerController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be later than start time!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final startStr = _formatTimeOfDay(_startTime);
    final endStr = _formatTimeOfDay(_endTime);

    // Check Schedule Conflict (PRD Bab 7.1)
    final conflict = await AppStateManager.instance.checkConflict(
      _selectedDay,
      startStr,
      endStr,
      excludeId: widget.courseToEdit?.id,
    );

    if (conflict != null && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => ScheduleConflictDialog(
          conflictingCourse: conflict,
          newStartTime: startStr,
          newEndTime: endStr,
        ),
      );

      if (proceed != true) return; // User cancelled
    }

    final nowIso = DateTime.now().toIso8601String();
    final course = Course(
      id: widget.courseToEdit?.id ?? const Uuid().v4(),
      courseName: _nameController.text.trim(),
      courseCode: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
      sks: int.tryParse(_sksController.text.trim()) ?? 0,
      lecturerName: _lecturerController.text.trim().isEmpty ? null : _lecturerController.text.trim(),
      room: _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
      dayOfWeek: _selectedDay,
      startTime: startStr,
      endTime: endStr,
      colorHex: _selectedColorHex,
      courseType: _courseType,
      createdAt: widget.courseToEdit?.createdAt ?? nowIso,
      updatedAt: nowIso,
    );

    await AppStateManager.instance.saveCourse(course, isEdit: widget.courseToEdit != null);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.courseToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Class Schedule' : 'Add Class Schedule',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),

                Expanded(
                  child: ListView(
                    children: [
                      // Schedule Type: Lecture vs Lab
                      const Text(
                        'Schedule Type',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() {
                                  _courseType = 'lecture';
                                  if (_selectedColorHex == '#6366F1') _selectedColorHex = '#3B82F6';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: _courseType == 'lecture' ? const Color(0xFFEFF6FF) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _courseType == 'lecture' ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                                    width: _courseType == 'lecture' ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.menu_book_rounded,
                                      size: 19,
                                      color: _courseType == 'lecture' ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lecture',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _courseType == 'lecture' ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() {
                                  _courseType = 'lab';
                                  if (_selectedColorHex == '#3B82F6') _selectedColorHex = '#6366F1';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: _courseType == 'lab' ? const Color(0xFFEEF2FF) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _courseType == 'lab' ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
                                    width: _courseType == 'lab' ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.science_rounded,
                                      size: 19,
                                      color: _courseType == 'lab' ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Labs',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _courseType == 'lab' ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Course Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: _courseType == 'lab' ? 'Lab Course Name *' : 'Course Name *',
                          hintText: _courseType == 'lab' ? 'e.g., Algorithms Lab' : 'e.g., Web Programming',
                          prefixIcon: Icon(_courseType == 'lab' ? Icons.science_outlined : Icons.book_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Course name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Code & Credits
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _codeController,
                              decoration: const InputDecoration(
                                labelText: 'Course Code / ID',
                                hintText: 'IF204',
                                prefixIcon: Icon(Icons.tag),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _sksController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Credits (SKS)',
                                prefixIcon: Icon(Icons.confirmation_number_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Lecturer & Room
                      TextFormField(
                        controller: _lecturerController,
                        decoration: const InputDecoration(
                          labelText: 'Lecturer Name',
                          hintText: 'e.g., Dr. John Doe, M.Sc.',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _roomController,
                        decoration: const InputDecoration(
                          labelText: 'Classroom / Room',
                          hintText: 'e.g., Room 402 / Central Lab',
                          prefixIcon: Icon(Icons.meeting_room_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Day of Week
                      const Text(
                        'Day of Week',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedDay,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        items: List.generate(7, (index) {
                          final day = index + 1;
                          return DropdownMenuItem(
                            value: day,
                            child: Text(DateTimeUtils.getDayName(day)),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDay = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Class Time: Start - End
                      const Text(
                        'Class Time',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _pickTime(true),
                              icon: const Icon(Icons.access_time),
                              label: Text('Start: ${_formatTimeOfDay(_startTime)}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('to'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _pickTime(false),
                              icon: const Icon(Icons.access_time_filled),
                              label: Text('End: ${_formatTimeOfDay(_endTime)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Color Label Tag
                      const Text(
                        'Card Color Tag',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: _colorOptions.map((hex) {
                          final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                          final isSelected = _selectedColorHex == hex;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColorHex = hex),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.black87, width: 2.5)
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _submitForm,
                    child: Text(isEdit ? 'Save Changes' : 'Add Course'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
