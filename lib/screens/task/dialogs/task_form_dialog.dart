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
      initialDate: _deadlineDate,
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
        });
      }
    }
  }

  Future<void> _pickReminder() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderDate,
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

    final deadline = _combineDateAndTime(_deadlineDate, _deadlineTime);
    final reminder = _combineDateAndTime(_reminderDate, _reminderTime);

    // Validasi Waktu Pengingat (PRD Bab 7.2): reminder_datetime <= deadline_datetime
    if (reminder.isAfter(deadline)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Waktu pengingat tidak boleh melebihi batas waktu deadline!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final nowIso = DateTime.now().toIso8601String();
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
        isCompleted: widget.taskToEdit?.isCompleted ?? false,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.taskToEdit != null
                  ? 'Tugas berhasil diperbarui!'
                  : 'Tugas berhasil ditambahkan!',
            ),
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
            content: Text('Gagal menyimpan tugas: $e'),
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
                      isEdit ? 'Edit Tugas Kuliah' : 'Tambah Tugas Baru',
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
                      // Pilih Mata Kuliah (Dropdown KRS)
                      DropdownButtonFormField<String?>(
                        value: _selectedCourseId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Mata Kuliah',
                          prefixIcon: Icon(Icons.book_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Tugas Umum (Tanpa Mata Kuliah)',
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

                      // Pilihan Jenis / Kategori Tugas: Lecture vs Lab
                      const Text(
                        'Kategori Tugas',
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

                      // Judul Tugas
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: _taskType == 'lab'
                              ? 'Nama Tugas Praktikum *'
                              : 'Nama Tugas Kuliah *',
                          hintText: _taskType == 'lab'
                              ? 'contoh: Laporan Praktikum Modul 2'
                              : 'contoh: Makalah Bab 3 / Presentasi API',
                          prefixIcon: Icon(
                            _taskType == 'lab'
                                ? Icons.biotech_outlined
                                : Icons.task_alt,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama tugas wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Deskripsi Tugas
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Catatan / Detail Instruksi (Opsional)',
                          hintText: 'Kumpulkan via portal e-learning kampus format PDF',
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tanggal & Jam Deadline
                      const Text(
                        'Batas Waktu Pengumpulan (Deadline)',
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
                          'Klik tombol untuk ubah tanggal & jam deadline',
                        ),
                        trailing: OutlinedButton(
                          onPressed: _pickDeadline,
                          child: const Text('Ubah'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tanggal & Jam Pengingat
                      const Text(
                        'Waktu Pengingat Alarm (Reminder)',
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
                          'Maksimal sama dengan waktu deadline',
                        ),
                        trailing: OutlinedButton(
                          onPressed: _pickReminder,
                          child: const Text('Ubah'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Toggle Alarm
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bunyikan Alarm Audio'),
                        subtitle: Text(
                          _isAlarmEnabled
                              ? 'Notifikasi + Pemutaran Audio Alarm'
                              : 'Hanya Standard Push Notification',
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
                          value:
                              _selectedAlarmSoundId ??
                              (alarmSounds.isNotEmpty
                                  ? alarmSounds.first.id
                                  : null),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Pilih Suara Alarm',
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
                        : Text(isEdit ? 'Simpan Perubahan' : 'Tambahkan Tugas'),
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
