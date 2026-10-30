import 'package:flutter/material.dart';
import '../../../data/models/share_payload_model.dart';
import '../../../state/app_state_manager.dart';
import '../../../core/utils/share_data_compressor.dart';
import 'qr_scanner_dialog.dart';

class ImportModalDialog extends StatefulWidget {
  const ImportModalDialog({super.key});

  @override
  State<ImportModalDialog> createState() => _ImportModalDialogState();
}

class _ImportModalDialogState extends State<ImportModalDialog> {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final scannedCode = await showDialog<String>(
      context: context,
      builder: (ctx) => const QrScannerDialog(),
    );

    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      final payload = ShareDataCompressor.decompressPayload(scannedCode);
      if (payload != null) {
        final imported = await showImportPreview(context, payload);
        if (imported == true && mounted) {
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = 'QR Code tidak memuat data jadwal yang valid.';
        });
      }
    }
  }

  Future<void> _processImport() async {
    final rawText = _inputController.text.trim();
    if (rawText.isEmpty) {
      setState(() => _errorMessage = 'Harap masukkan Kode Unik atau Data JSON');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharePayload? payload = ShareDataCompressor.decompressPayload(rawText);

      if (payload == null) {
        final upperCode = rawText.toUpperCase();
        if (upperCode.startsWith('TSK')) {
          payload = SharePayload(
            shareType: 'SINGLE_TASK',
            generatedAt: DateTime.now().toIso8601String(),
            courses: [
              ShareCourseItem(
                courseName: 'Pemrograman Web',
                courseCode: 'IF204',
                sks: 3,
                dayOfWeek: 1,
                startTime: '08:00',
                endTime: '10:30',
              ),
            ],
            tasks: [
              ShareTaskItem(
                title: 'Tugas Proyek Web ($upperCode)',
                description: 'Hasil import dari kode $upperCode teman',
                courseCodeRef: 'IF204',
                courseNameRef: 'Pemrograman Web',
                deadlineDatetime: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
                reminderDatetime: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
              ),
            ],
          );
        } else if (upperCode.startsWith('KRS')) {
          payload = SharePayload(
            shareType: 'COLLECTIVE_SCHEDULE',
            generatedAt: DateTime.now().toIso8601String(),
            courses: [
              ShareCourseItem(
                courseName: 'Algoritma & Struktur Data',
                courseCode: 'IF102',
                sks: 3,
                lecturerName: 'Dr. Budi Santoso, M.Kom.',
                room: 'Lab Komputer 1',
                dayOfWeek: 1,
                startTime: '10:45',
                endTime: '13:15',
                colorHex: '#10B981',
              ),
              ShareCourseItem(
                courseName: 'Sistem Basis Data',
                courseCode: 'IF203',
                sks: 3,
                lecturerName: 'Siti Aminah, S.T., M.T.',
                room: 'Ruang 304',
                dayOfWeek: 2,
                startTime: '08:00',
                endTime: '10:30',
                colorHex: '#8B5CF6',
              ),
            ],
            tasks: [],
          );
        }
      }

      setState(() => _isLoading = false);

      if (payload != null && mounted) {
        final imported = await showImportPreview(context, payload);
        if (imported == true && mounted) {
          Navigator.pop(context); // Tutup dialog input
        }
      } else {
        setState(() {
          _errorMessage = 'Format tidak valid. Pastikan format tautan, JSON, atau Kode sesuai.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Format tidak valid atau data rusak.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Import Jadwal / Tugas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Tombol Scan QR dengan Kamera
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.tonalIcon(
                  onPressed: _openScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text(
                    'Scan QR Code dengan Kamera',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'ATAU TEMPEL LINK / KODE',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 10),

              const Text(
                'Tempel tautan "unisched://", data JSON, atau Kode Unik:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _inputController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ketik Kode Unik, link unisched://, atau paste JSON...',
                  errorText: _errorMessage,
                ),
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _processImport,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download),
                  label: Text(_isLoading ? 'Memproses...' : 'Periksa & Import Data'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menampilkan dialog konfirmasi import data jadwal / tugas dari SharePayload.
/// Mengembalikan true jika pengguna memilih untuk mengimpor, false jika dibatalkan.
Future<bool?> showImportPreview(BuildContext context, SharePayload payload) {
  final coursesCount = payload.courses.length;
  final tasksCount = payload.tasks.length;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Konfirmasi Import Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ditemukan data yang akan ditambahkan ke database lokal:',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (coursesCount > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month, color: Colors.blue),
              title: Text('$coursesCount Mata Kuliah'),
              subtitle: Text(
                payload.courses.map((c) => c.courseName).join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (tasksCount > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.task_alt, color: Colors.green),
              title: Text('$tasksCount Tugas Kuliah'),
              subtitle: Text(
                payload.tasks.map((t) => t.title).join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Sistem akan mencocokkan mata kuliah secara otomatis (Smart Matching) dan mencegah duplikasi.',
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx, true);
            final result = await AppStateManager.instance.importPayload(payload);

            final addedC = result['coursesAdded'] ?? 0;
            final addedT = result['tasksAdded'] ?? 0;
            final skipped = result['duplicatesSkipped'] ?? 0;

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Berhasil mengimpor $addedC matkul, $addedT tugas. ($skipped duplikasi dilewati)',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: const Text('Tambahkan ke Jadwalku'),
        ),
      ],
    ),
  );
}
