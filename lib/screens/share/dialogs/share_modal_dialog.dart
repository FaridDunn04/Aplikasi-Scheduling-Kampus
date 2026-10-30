import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/share_payload_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_data_compressor.dart';

class ShareModalDialog extends StatefulWidget {
  final List<Course>? coursesToShare;
  final Task? singleTaskToShare;
  final Course? relatedCourse;

  const ShareModalDialog({
    super.key,
    this.coursesToShare,
    this.singleTaskToShare,
    this.relatedCourse,
  });

  @override
  State<ShareModalDialog> createState() => _ShareModalDialogState();
}

class _ShareModalDialogState extends State<ShareModalDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _jsonPayloadString;
  late String _uniqueCode;
  late String _deepLink;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generatePayload();
  }

  void _generatePayload() {
    final nowIso = DateTime.now().toIso8601String();
    SharePayload payload;

    if (widget.singleTaskToShare != null) {
      final t = widget.singleTaskToShare!;
      final codeHash = (t.title.hashCode.abs() % 9000 + 1000).toString();
      _uniqueCode = 'TSK-$codeHash';

      payload = SharePayload(
        schemaVersion: '1.0',
        shareType: 'SINGLE_TASK',
        generatedAt: nowIso,
        courses: widget.relatedCourse != null
            ? [
                ShareCourseItem(
                  courseName: widget.relatedCourse!.courseName,
                  courseCode: widget.relatedCourse!.courseCode,
                  sks: widget.relatedCourse!.sks,
                  lecturerName: widget.relatedCourse!.lecturerName,
                  room: widget.relatedCourse!.room,
                  dayOfWeek: widget.relatedCourse!.dayOfWeek,
                  startTime: widget.relatedCourse!.startTime,
                  endTime: widget.relatedCourse!.endTime,
                  colorHex: widget.relatedCourse!.colorHex,
                ),
              ]
            : [],
        tasks: [
          ShareTaskItem(
            title: t.title,
            description: t.description,
            courseCodeRef: widget.relatedCourse?.courseCode,
            courseNameRef: widget.relatedCourse?.courseName,
            deadlineDatetime: t.deadlineDatetime,
            reminderDatetime: t.reminderDatetime,
            isAlarmEnabled: t.isAlarmEnabled,
          ),
        ],
      );
    } else {
      final list = widget.coursesToShare ?? [];
      final codeHash = (list.length.hashCode.abs() % 9000 + 1000).toString();
      _uniqueCode = 'KRS-$codeHash';

      payload = SharePayload(
        schemaVersion: '1.0',
        shareType: 'COLLECTIVE_SCHEDULE',
        generatedAt: nowIso,
        courses: list.map((c) => ShareCourseItem(
          courseName: c.courseName,
          courseCode: c.courseCode,
          sks: c.sks,
          lecturerName: c.lecturerName,
          room: c.room,
          dayOfWeek: c.dayOfWeek,
          startTime: c.startTime,
          endTime: c.endTime,
          colorHex: c.colorHex,
        )).toList(),
        tasks: [],
      );
    }
    final compressedData = ShareDataCompressor.compressPayload(payload);
    _deepLink = 'unisched://import?data=$compressedData';
    _jsonPayloadString = jsonEncode(payload.toJson());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label berhasil disalin ke clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTask = widget.singleTaskToShare != null;
    final title = isTask ? 'Bagikan Tugas' : 'Bagikan Jadwal Kuliah';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(isTask ? Icons.task_alt : Icons.calendar_month, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Tab: QR Code (Offline) vs Link/Kode (Online)
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.qr_code, size: 20), text: 'QR Code (Offline)'),
                  Tab(icon: Icon(Icons.link, size: 20), text: 'Link & Kode Unik'),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: QR Code (100% Offline)
                    SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Teman sebangku dapat langsung scan QR ini secara 100% OFFLINE tanpa internet:',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: _deepLink, // QR Code berisi link yang langsung bisa discan
                            version: QrVersions.auto,
                            size: 220.0,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _copyToClipboard(_jsonPayloadString, 'Data JSON QR Code'),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Salin Data Mentah (JSON)'),
                          ),
                        ],
                      ),
                    ),

                    // Tab 2: Link & Kode Unik (Online Mode)
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gunakan Kode Unik atau tautan untuk dibagikan via grup WhatsApp / Media Sosial:',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          // Kode Unik Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withAlpha(60),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Theme.of(context).primaryColor.withAlpha(80)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('KODE UNIK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _uniqueCode,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.copy),
                                  tooltip: 'Salin Kode',
                                  onPressed: () => _copyToClipboard(_uniqueCode, 'Kode unik'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Deep Link
                          const Text('Deep Link:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _deepLink,
                                    style: const TextStyle(fontSize: 13, color: Colors.blue),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  onPressed: () => _copyToClipboard(_deepLink, 'Deep Link'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // WhatsApp Share Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                              onPressed: () {
                                final pesan = 'Halo! Saya membagikan jadwal kuliah UniSched.\nKlik tautan ini untuk memasukkannya ke aplikasimu:\n$_deepLink';
                                Share.share(pesan, subject: 'Jadwal Kuliah UniSched');
                              },
                              icon: const Icon(Icons.share, color: Colors.white),
                              label: const Text('Bagikan ke WhatsApp'),
                            ),
                          ),
                        ],
                      ),
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
