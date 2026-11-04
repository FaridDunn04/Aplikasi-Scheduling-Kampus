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
      SnackBar(content: Text('$label copied to clipboard!')),
    );
  }

  void _shareViaSocial() {
    final isTask = widget.singleTaskToShare != null;
    String message;
    String subject;

    if (isTask) {
      final t = widget.singleTaskToShare!;
      final courseName = widget.relatedCourse?.courseName;
      subject = 'UniSched Assignment: ${t.title}';
      message = '📌 UniSched Task Reminder\n'
          'Task: "${t.title}"\n'
          '${courseName != null ? 'Course: $courseName\n' : ''}'
          '\nCopy and import this link into your UniSched app:\n$_deepLink';
    } else {
      final count = widget.coursesToShare?.length ?? 0;
      subject = 'UniSched Class Schedule';
      message = '🗓️ UniSched Class Schedule ($count courses)\n'
          'I am sharing my semester class schedule with you.\n'
          '\nCopy and import this link into your UniSched app:\n$_deepLink';
    }

    Share.share(message, subject: subject);
  }

  @override
  Widget build(BuildContext context) {
    final isTask = widget.singleTaskToShare != null;
    final title = isTask ? 'Share Task' : 'Share Class Schedule';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 580),
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

              // Tab: QR Code (Offline) vs Share Link (URL)
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.qr_code, size: 20), text: 'QR Code (Offline)'),
                  Tab(icon: Icon(Icons.link, size: 20), text: 'Share Link (URL)'),
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
                            'Peers can directly scan this QR code 100% OFFLINE without internet:',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: _deepLink,
                            version: QrVersions.auto,
                            size: 220.0,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _copyToClipboard(_jsonPayloadString, 'Raw JSON Data'),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy Raw Data (JSON)'),
                          ),
                        ],
                      ),
                    ),

                    // Tab 2: Share Link (URL)
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Share this direct link via WhatsApp or social media. Peers can copy it and import it into UniSched:',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          // Deep Link Box
                          const Text('Import Link (Deep Link):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withAlpha(40)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _deepLink,
                                    style: const TextStyle(fontSize: 12.5, color: Colors.blue),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  tooltip: 'Copy Link',
                                  onPressed: () => _copyToClipboard(_deepLink, 'Import Link'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // WhatsApp / Direct Share Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                              onPressed: _shareViaSocial,
                              icon: const Icon(Icons.share, color: Colors.white),
                              label: const Text('Share to WhatsApp / Apps'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () => _copyToClipboard(_deepLink, 'Import Link'),
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text('Copy Full Link'),
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
