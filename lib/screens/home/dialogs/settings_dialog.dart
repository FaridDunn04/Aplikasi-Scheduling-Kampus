import 'package:flutter/material.dart';
import '../../../state/app_state_manager.dart';
import '../../alarm/dialogs/alarm_catalog_dialog.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  void _confirmResetData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This action will permanently delete all courses, schedules, and tasks stored on this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AppStateManager.instance.resetAllData();
              if (context.mounted) {
                Navigator.pop(context); // Close settings dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All local data has been successfully cleared.'),
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
                    'App Settings',
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
                title: const Text('Alarm Sounds Catalog'),
                subtitle: const Text('Manage default tones, custom imports & cloud downloads'),
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
                title: const Text('Architecture Mode'),
                subtitle: const Text('100% Offline-First SQLite Storage'),
              ),
              const Divider(height: 1),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: const Text('Clear & Reset All Data', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Delete all local courses, schedules, and tasks'),
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
                      'College Schedule Management & Task Reminders',
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
