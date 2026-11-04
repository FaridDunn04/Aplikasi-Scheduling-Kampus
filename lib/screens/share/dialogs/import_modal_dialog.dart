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
          _errorMessage = 'QR Code does not contain valid schedule data.';
        });
      }
    }
  }

  Future<void> _processImport() async {
    final rawText = _inputController.text.trim();
    if (rawText.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid link or JSON data');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final SharePayload? payload = ShareDataCompressor.decompressPayload(rawText);

      setState(() => _isLoading = false);

      if (payload != null && mounted) {
        final imported = await showImportPreview(context, payload);
        if (imported == true && mounted) {
          Navigator.pop(context); // Close input dialog
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid format. Please make sure the unisched:// link or JSON is valid.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid format or corrupted data.';
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
                        'Import Schedule / Tasks',
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

              // Scan QR Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.tonalIcon(
                  onPressed: _openScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text(
                    'Scan QR Code with Camera',
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
                      'OR PASTE SHARE LINK / JSON',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 10),

              const Text(
                'Paste "unisched://" link or raw JSON data:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _inputController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Paste unisched:// link or JSON data here...',
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
                  label: Text(_isLoading ? 'Processing...' : 'Verify & Import Data'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays import preview and confirmation dialog from SharePayload.
/// Returns true if user imported, false if cancelled.
Future<bool?> showImportPreview(BuildContext context, SharePayload payload) {
  final coursesCount = payload.courses.length;
  final tasksCount = payload.tasks.length;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm Data Import'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The following items were found to add to your local database:',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (coursesCount > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month, color: Colors.blue),
              title: Text('$coursesCount Courses'),
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
              title: Text('$tasksCount Tasks'),
              subtitle: Text(
                payload.tasks.map((t) => t.title).join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'The system will automatically match courses (Smart Matching) and prevent duplicates.',
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
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
                    'Successfully imported $addedC course(s), $addedT task(s). ($skipped duplicate(s) skipped)',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: const Text('Add to My Schedule'),
        ),
      ],
    ),
  );
}
