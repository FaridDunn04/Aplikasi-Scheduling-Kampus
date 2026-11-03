import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/task_model.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../state/app_state_manager.dart';

class TaskFormDialog extends StatefulWidget {
  final Task? taskToEdit;
  final String? initialCourseId;

  const TaskFormDialog({super.key, this.taskToEdit, this.initialCourseId});

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;

  String? _selectedCourseId;
  late DateTime _deadlineDate;
  late TimeOfDay _deadlineTime;

  late DateTime _reminderDate;
  late TimeOfDay _reminderTime;

  bool _isAlarmEnabled = true;
  String? _selectedAlarmSoundId;
  late String _taskType; // 'lecture' | 'lab'
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.taskToEdit;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _descController = TextEditingController(text: edit?.description ?? '');

    _selectedCourseId = edit?.courseId ?? widget.initialCourseId;

    if (edit != null) {
      _taskType = edit.taskType.isNotEmpty
          ? edit.taskType
          : (edit.isLab ? 'lab' : 'lecture');
    } else {
      _taskType = 'lecture';
      if (_selectedCourseId != null) {
        final c = AppStateManager.instance.getCourseById(_selectedCourseId);
        if (c != null && c.isLab) {
          _taskType = 'lab';
        }
      }
    }

    final now = DateTime.now();
    if (edit != null) {
      final deadlineDt = DateTimeUtils.parseIso(edit.deadlineDatetime);
      _deadlineDate = deadlineDt;
      _deadlineTime = TimeOfDay(
        hour: deadlineDt.hour,
        minute: deadlineDt.minute,
      );

      final reminderDt = DateTimeUtils.parseIso(edit.reminderDatetime);
      _reminderDate = reminderDt;
      _reminderTime = TimeOfDay(
        hour: reminderDt.hour,
        minute: reminderDt.minute,
      );

      _isAlarmEnabled = edit.isAlarmEnabled;
      _selectedAlarmSoundId = edit.alarmSoundId;
    } else {
      // Default: Deadline besok jam 23:59
      _deadlineDate = now.add(const Duration(days: 1));
      _deadlineTime = const TimeOfDay(hour: 23, minute: 59);

      // Default: Reminder besok jam 19:00
      _reminderDate = now.add(const Duration(days: 1));
      _reminderTime = const TimeOfDay(hour: 19, minute: 0);

      _isAlarmEnabled = true;
      _selectedAlarmSoundId = 'sound_default_1';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadlineDate.isBefore(DateTime.now())
          ? DateTime.now()
          : _deadlineDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _deadlineTime,
      );
      if (pickedTime != null) {
        setState(() {
          _deadlineDate = pickedDate;
          _deadlineTime = pickedTime;

          // Jika pengingat berada setelah deadline baru atau sudah kadaluwarsa,
          // sesuaikan pengingat agar otomatis relevan
          final newDeadline = _combineDateAndTime(pickedDate, pickedTime);
          final currentReminder = _combineDateAndTime(_reminderDate, _reminderTime);
          if (currentReminder.isAfter(newDeadline) || currentReminder.isBefore(DateTime.now())) {
            final candidateReminder = newDeadline.subtract(const Duration(hours: 1));
            final adjusted = candidateReminder.isAfter(DateTime.now())
                ? candidateReminder
                : newDeadline;
            _reminderDate = DateTime(adjusted.year, adjusted.month, adjusted.day);
            _reminderTime = TimeOfDay(hour: adjusted.hour, minute: adjusted.minute);
          }
        });
      }
    }
  }

  Future<void> _pickReminder() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderDate.isBefore(DateTime.now())
          ? DateTime.now()
          : _reminderDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _reminderTime,
      );
      if (pickedTime != null) {
        setState(() {
          _reminderDate = pickedDate;
          _reminderTime = pickedTime;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final deadline = _combineDateAndTime(_deadlineDate, _deadlineTime);
    final reminder = _combineDateAndTime(_reminderDate, _reminderTime);

    // Reminder Time Validation: reminder_datetime <= deadline_datetime
    if (reminder.isAfter(deadline)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reminder time cannot be later than deadline!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final nowIso = now.toIso8601String();

      final bool isDeadlineInFuture = deadline.isAfter(now);
      final bool newIsCompleted = !isDeadlineInFuture;

      final task = Task(
        id: widget.taskToEdit?.id ?? const Uuid().v4(),
        courseId: _selectedCourseId,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        deadlineDatetime: DateTimeUtils.toIso8601String(deadline),
        reminderDatetime: DateTimeUtils.toIso8601String(reminder),
        isAlarmEnabled: _isAlarmEnabled,
        alarmSoundId: _isAlarmEnabled ? _selectedAlarmSoundId : null,
        isCompleted: newIsCompleted,
        sharedOriginCode: widget.taskToEdit?.sharedOriginCode,
        taskType: _taskType,
        createdAt: widget.taskToEdit?.createdAt ?? nowIso,
        updatedAt: nowIso,
      );

      await AppStateManager.instance.saveTask(
        task,
        isEdit: widget.taskToEdit != null,
      );

      if (mounted) {
        Navigator.pop(context, true);

        String successMessage = widget.taskToEdit != null
            ? 'Task updated successfully!'
            : 'Task added successfully!';
        if (widget.taskToEdit?.isCompleted == true && !newIsCompleted) {
          successMessage =
              'Deadline updated! Task has been reactivated to the active task list.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save task: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.taskToEdit != null;
    final courses = AppStateManager.instance.courses;
    final alarmSounds = AppStateManager.instance.alarmSounds;

    final deadlineCombined = _combineDateAndTime(_deadlineDate, _deadlineTime);
    final reminderCombined = _combineDateAndTime(_reminderDate, _reminderTime);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
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
                      isEdit ? 'Edit Assignment' : 'Add New Assignment',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    clipBehavior: Clip.none,
                    children: [
                      // Status Info Banner when editing a completed task
                      if (isEdit && widget.taskToEdit!.isCompleted) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: deadlineCombined.isAfter(DateTime.now())
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: deadlineCombined.isAfter(DateTime.now())
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFFFCD34D),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                deadlineCombined.isAfter(DateTime.now())
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.info_outline_rounded,
                                color: deadlineCombined.isAfter(DateTime.now())
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFD97706),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  deadlineCombined.isAfter(DateTime.now())
                                      ? 'Deadline is set to a future date. This task will be automatically reactivated and appear in the task list.'
                                      : 'This task is marked as completed because the deadline has passed. Set the deadline to a future date to reactivate it in your task list.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: deadlineCombined.isAfter(DateTime.now())
                                        ? const Color(0xFF1E40AF)
                                        : const Color(0xFF92400E),
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Course Dropdown
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedCourseId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          prefixIcon: Icon(Icons.book_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'General Task (No Course)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...courses.map(
                            (c) => DropdownMenuItem<String?>(
                              value: c.id,
                              child: Text(
                                c.courseName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedCourseId = val;
                            if (val != null) {
                              final c = AppStateManager.instance.getCourseById(
                                val,
                              );
                              if (c != null) {
                                _taskType = c.isLab ? 'lab' : 'lecture';
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      // Task Category Selection: Lecture vs Lab
                      const Text(
                        'Task Category',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () =>
                                  setState(() => _taskType = 'lecture'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                   vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: _taskType == 'lecture'
                                      ? const Color(0xFFEFF6FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _taskType == 'lecture'
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFFCBD5E1),
                                    width: _taskType == 'lecture' ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.menu_book_rounded,
                                      size: 19,
                                      color: _taskType == 'lecture'
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lectures',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _taskType == 'lecture'
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFF64748B),
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
                              onTap: () => setState(() => _taskType = 'lab'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: _taskType == 'lab'
                                      ? const Color(0xFFEEF2FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _taskType == 'lab'
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFFCBD5E1),
                                    width: _taskType == 'lab' ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.science_rounded,
                                      size: 19,
                                      color: _taskType == 'lab'
                                          ? const Color(0xFF6366F1)
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Labs',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _taskType == 'lab'
                                            ? const Color(0xFF6366F1)
                                            : const Color(0xFF64748B),
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

                      // Task Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: _taskType == 'lab'
                              ? 'Lab Assignment Name *'
                              : 'Course Assignment Name *',
                          hintText: _taskType == 'lab'
                              ? 'e.g., Module 2 Lab Report'
                              : 'e.g., Chapter 3 Paper / API Presentation',
                          prefixIcon: Icon(
                            _taskType == 'lab'
                                ? Icons.biotech_outlined
                                : Icons.task_alt,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Task name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Task Description
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Detailed Instructions (Optional)',
                          hintText: 'e.g., Submit via campus LMS portal in PDF format',
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Deadline Date & Time
                      const Text(
                        'Submission Deadline',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.event,
                          color: Colors.redAccent,
                        ),
                        title: Text(
                          DateTimeUtils.formatDateTimeDisplay(deadlineCombined),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Tap button to change deadline date & time',
                        ),
                        trailing: OutlinedButton(
                          onPressed: _pickDeadline,
                          child: const Text('Change'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Reminder Date & Time
                      const Text(
                        'Alarm Reminder Time',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.alarm, color: Colors.orange),
                        title: Text(
                          DateTimeUtils.formatDateTimeDisplay(reminderCombined),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Must be earlier than or equal to deadline',
                        ),
                        trailing: OutlinedButton(
                          onPressed: _pickReminder,
                          child: const Text('Change'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Toggle Alarm
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sound Audio Alarm'),
                        subtitle: Text(
                          _isAlarmEnabled
                              ? 'Push Notification + Audio Alarm'
                              : 'Standard Push Notification Only',
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: _isAlarmEnabled,
                        onChanged: (val) =>
                            setState(() => _isAlarmEnabled = val),
                      ),

                      if (_isAlarmEnabled) ...[
                        const SizedBox(height: 8),
                        // Dropdown Suara Alarm
                        DropdownButtonFormField<String>(
                          initialValue:
                              _selectedAlarmSoundId ??
                              (alarmSounds.isNotEmpty
                                  ? alarmSounds.first.id
                                  : null),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Alarm Sound',
                            prefixIcon: Icon(Icons.music_note_outlined),
                          ),
                          items: alarmSounds.map((sound) {
                            return DropdownMenuItem<String>(
                              value: sound.id,
                              child: Text(
                                sound.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedAlarmSoundId = val),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isEdit ? 'Save Changes' : 'Add Task'),
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
