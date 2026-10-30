import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/alarm_sound_model.dart';
import '../../../state/app_state_manager.dart';

class AlarmCatalogDialog extends StatefulWidget {
  const AlarmCatalogDialog({super.key});

  @override
  State<AlarmCatalogDialog> createState() => _AlarmCatalogDialogState();
}

class _AlarmCatalogDialogState extends State<AlarmCatalogDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock katalog online (PRD Bab 6.1.3: Unduh Nada Alarm Online)
  final List<Map<String, String>> _cloudCatalog = [
    {
      'title': 'Bell Universitas Modern',
      'url': 'https://unisched.app/sounds/campus_bell.mp3',
      'duration': '0:12',
    },
    {
      'title': 'Radar Sonar High Alert',
      'url': 'https://unisched.app/sounds/radar.mp3',
      'duration': '0:08',
    },
    {
      'title': 'Harmonic Acoustic Wakeup',
      'url': 'https://unisched.app/sounds/harmonic.mp3',
      'duration': '0:15',
    },
    {
      'title': 'Digital Future Synth',
      'url': 'https://unisched.app/sounds/synth.mp3',
      'duration': '0:10',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _downloadCloudSound(Map<String, String> item) async {
    final nowIso = DateTime.now().toIso8601String();
    final newSound = AlarmSound(
      id: const Uuid().v4(),
      title: item['title']!,
      sourceType: 'CLOUD_DOWNLOAD',
      localFilePath: 'local_storage/sounds/${item['title']!.toLowerCase().replaceAll(' ', '_')}.mp3',
      remoteUrl: item['url'],
      createdAt: nowIso,
    );

    await AppStateManager.instance.addAlarmSound(newSound);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil mengunduh "${item['title']}" ke penyimpanan lokal!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _importLocalSoundManual() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Audio Lokal HP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih file .mp3 / .wav dari memori internal HP:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Nama Tampilan Audio',
                hintText: 'contoh: Lagu Semangat Pagi',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(ctx);
                final nowIso = DateTime.now().toIso8601String();
                final imported = AlarmSound(
                  id: const Uuid().v4(),
                  title: title,
                  sourceType: 'LOCAL_IMPORT',
                  localFilePath: 'app_documents/custom_sounds/${DateTime.now().millisecondsSinceEpoch}.mp3',
                  remoteUrl: null,
                  createdAt: nowIso,
                );
                await AppStateManager.instance.addAlarmSound(imported);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Audio "$title" berhasil diimpor!')),
                  );
                }
              }
            },
            child: const Text('Simpan Audio'),
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
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.library_music_outlined, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Koleksi Suara Alarm',
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
              const SizedBox(height: 8),

              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Tersimpan (Lokal)'),
                  Tab(text: 'Katalog Cloud (Online)'),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Tersimpan di HP
                    ListenableBuilder(
                      listenable: AppStateManager.instance,
                      builder: (context, _) {
                        final sounds = AppStateManager.instance.alarmSounds;

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                itemCount: sounds.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final s = sounds[index];
                                  final isDefault = s.sourceType == 'DEFAULT';

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: isDefault ? Colors.blue.withAlpha(30) : Colors.purple.withAlpha(30),
                                      child: Icon(
                                        isDefault ? Icons.music_note : Icons.audio_file,
                                        color: isDefault ? Colors.blue : Colors.purple,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      s.sourceType,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    trailing: isDefault
                                        ? const Chip(label: Text('Bawaan', style: TextStyle(fontSize: 10)))
                                        : IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                            onPressed: () {
                                              AppStateManager.instance.deleteAlarmSound(s.id);
                                            },
                                          ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _importLocalSoundManual,
                                icon: const Icon(Icons.file_upload_outlined),
                                label: const Text('Import File Audio dari HP (.mp3 / .wav)'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // Tab 2: Katalog Cloud Online
                    ListView.separated(
                      itemCount: _cloudCatalog.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _cloudCatalog[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orangeAccent,
                            child: Icon(Icons.cloud_download_outlined, color: Colors.white, size: 20),
                          ),
                          title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Durasi: ${item['duration']} • Katalog Cloud'),
                          trailing: FilledButton.tonal(
                            onPressed: () => _downloadCloudSound(item),
                            child: const Text('Unduh'),
                          ),
                        );
                      },
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
