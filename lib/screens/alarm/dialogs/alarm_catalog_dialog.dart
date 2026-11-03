import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../data/models/alarm_sound_model.dart';
import '../../../state/app_state_manager.dart';

class AlarmCatalogDialog extends StatefulWidget {
  const AlarmCatalogDialog({super.key});

  @override
  State<AlarmCatalogDialog> createState() => _AlarmCatalogDialogState();
}

class _AlarmCatalogDialogState extends State<AlarmCatalogDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;

  // Mock online catalog
  final List<Map<String, String>> _cloudCatalog = [
    {
      'title': 'Modern Campus Bell',
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
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _currentlyPlayingId = null);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePreviewSound(AlarmSound sound) async {
    if (_currentlyPlayingId == sound.id) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _currentlyPlayingId = null);
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);

      if (sound.sourceType == 'LOCAL_IMPORT' || sound.sourceType == 'CLOUD_DOWNLOAD') {
        final file = File(sound.localFilePath);
        if (await file.exists()) {
          await _audioPlayer.play(DeviceFileSource(sound.localFilePath));
        } else {
          // Fallback to chime if file was removed
          await _audioPlayer.play(AssetSource('sounds/chime.wav'));
        }
      } else {
        // Default sounds
        final t = sound.title.toLowerCase();
        if (t.contains('beep') || sound.id == 'sound_default_2') {
          await _audioPlayer.play(AssetSource('sounds/beep.wav'));
        } else if (t.contains('energetic') || sound.id == 'sound_default_3') {
          await _audioPlayer.play(AssetSource('sounds/energetic.wav'));
        } else {
          await _audioPlayer.play(AssetSource('sounds/chime.wav'));
        }
      }

      if (mounted) {
        setState(() => _currentlyPlayingId = sound.id);
      }
    } catch (e) {
      debugPrint('[AlarmCatalog] Error previewing sound: $e');
    }
  }

  Future<void> _downloadCloudSound(Map<String, String> item) async {
    final nowIso = DateTime.now().toIso8601String();
    final appDir = await getApplicationDocumentsDirectory();
    final cloudSoundsDir = Directory('${appDir.path}/cloud_sounds');
    if (!await cloudSoundsDir.exists()) {
      await cloudSoundsDir.create(recursive: true);
    }

    final targetPath = '${cloudSoundsDir.path}/${item['title']!.toLowerCase().replaceAll(' ', '_')}.mp3';
    final targetFile = File(targetPath);
    if (!await targetFile.exists()) {
      await targetFile.create(recursive: true);
    }

    final newSound = AlarmSound(
      id: const Uuid().v4(),
      title: item['title']!,
      sourceType: 'CLOUD_DOWNLOAD',
      localFilePath: targetPath,
      remoteUrl: item['url'],
      createdAt: nowIso,
    );

    await AppStateManager.instance.addAlarmSound(newSound);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully downloaded "${item['title']}" to local storage!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _importLocalSoundManual() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      final filePath = pickedFile.path;
      if (filePath == null) return;

      final fileName = pickedFile.name;
      final defaultTitle = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;

      if (!mounted) return;

      final titleController = TextEditingController(text: defaultTitle);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Local Audio File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected File: $fileName',
                style: const TextStyle(fontSize: 12.5, color: Colors.blue, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Audio Display Name',
                  hintText: 'e.g., Morning Motivation Sound',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Audio'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        final title = titleController.text.trim().isEmpty ? defaultTitle : titleController.text.trim();

        // Copy file to app's documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final customSoundsDir = Directory('${appDir.path}/custom_sounds');
        if (!await customSoundsDir.exists()) {
          await customSoundsDir.create(recursive: true);
        }

        final ext = pickedFile.extension ?? 'mp3';
        final targetPath = '${customSoundsDir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await File(filePath).copy(targetPath);

        final nowIso = DateTime.now().toIso8601String();
        final imported = AlarmSound(
          id: const Uuid().v4(),
          title: title,
          sourceType: 'LOCAL_IMPORT',
          localFilePath: targetPath,
          remoteUrl: null,
          createdAt: nowIso,
        );

        await AppStateManager.instance.addAlarmSound(imported);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio "$title" imported successfully from storage!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick audio file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                        'Alarm Sounds Catalog',
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
                  Tab(text: 'Saved (Local)'),
                  Tab(text: 'Cloud Catalog (Online)'),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Saved on Device
                    ListenableBuilder(
                      listenable: AppStateManager.instance,
                      builder: (context, _) {
                        final sounds = AppStateManager.instance.alarmSounds;

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                itemCount: sounds.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final s = sounds[index];
                                  final isDefault = s.sourceType == 'DEFAULT';
                                  final isPlaying = _currentlyPlayingId == s.id;

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    leading: CircleAvatar(
                                      backgroundColor: isPlaying
                                          ? Colors.green.withAlpha(40)
                                          : (isDefault ? Colors.blue.withAlpha(30) : Colors.purple.withAlpha(30)),
                                      child: Icon(
                                        isPlaying
                                            ? Icons.volume_up_rounded
                                            : (isDefault ? Icons.music_note : Icons.audio_file),
                                        color: isPlaying
                                            ? Colors.green
                                            : (isDefault ? Colors.blue : Colors.purple),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      isPlaying
                                          ? 'Playing preview...'
                                          : (isDefault ? 'Default Tone' : 'Local Storage Audio'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isPlaying ? Colors.green : Colors.grey,
                                        fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                                            color: isPlaying ? Colors.redAccent : const Color(0xFF2563EB),
                                            size: 28,
                                          ),
                                          tooltip: isPlaying ? 'Stop' : 'Play Preview',
                                          onPressed: () => _togglePreviewSound(s),
                                        ),
                                        if (isDefault)
                                          const Chip(label: Text('Default', style: TextStyle(fontSize: 10)))
                                        else
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                            tooltip: 'Delete Sound',
                                            onPressed: () async {
                                              if (_currentlyPlayingId == s.id) {
                                                await _audioPlayer.stop();
                                                setState(() => _currentlyPlayingId = null);
                                              }
                                              try {
                                                final f = File(s.localFilePath);
                                                if (await f.exists()) await f.delete();
                                              } catch (_) {}
                                              await AppStateManager.instance.deleteAlarmSound(s.id);
                                            },
                                          ),
                                      ],
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
                                label: const Text('Import Audio File from Device (.mp3 / .wav)'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // Tab 2: Cloud Catalog
                    ListView.separated(
                      itemCount: _cloudCatalog.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _cloudCatalog[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orangeAccent,
                            child: Icon(Icons.cloud_download_outlined, color: Colors.white, size: 20),
                          ),
                          title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Duration: ${item['duration']} • Cloud Catalog'),
                          trailing: FilledButton.tonal(
                            onPressed: () => _downloadCloudSound(item),
                            child: const Text('Download'),
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
