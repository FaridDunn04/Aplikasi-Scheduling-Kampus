import 'package:flutter/material.dart';
import '../../../state/app_state_manager.dart';
import '../../alarm/dialogs/alarm_catalog_dialog.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  void _confirmResetData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Seluruh Data?'),
        content: const Text(
          'Tindakan ini akan menghapus semua mata kuliah, jadwal, dan tugas yang tersimpan di perangkat ini. Data tidak dapat dipulihkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AppStateManager.instance.resetAllData();
              if (context.mounted) {
                Navigator.pop(context); // Tutup settings dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Seluruh data lokal berhasil dibersihkan.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reset Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pengaturan Aplikasi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.music_note_outlined, color: Colors.blue),
                title: const Text('Katalog Nada & Suara Alarm'),
                subtitle: const Text('Kelola nada dering bawaan, import & download cloud'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const AlarmCatalogDialog(),
                  );
                },
              ),
              const Divider(height: 1),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.wifi_off_outlined, color: Colors.green),
                title: const Text('Mode Arsitektur'),
                subtitle: const Text('100% Offline-First SQLite Storage'),
              ),
              const Divider(height: 1),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: const Text('Bersihkan & Reset Data', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Hapus seluruh jadwal dan tugas lokal'),
                onTap: () => _confirmResetData(context),
              ),
              const SizedBox(height: 16),

              Center(
                child: Column(
                  children: [
                    Text(
                      'UniSched v1.0.0',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Aplikasi Manajemen Jadwal Kuliah & Pengingat Tugas',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
