class AlarmSound {
  final String id;
  final String title;
  final String sourceType; // 'DEFAULT' | 'LOCAL_IMPORT' | 'CLOUD_DOWNLOAD'
  final String localFilePath;
  final String? remoteUrl;
  final String createdAt;

  AlarmSound({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.localFilePath,
    this.remoteUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'source_type': sourceType,
      'local_file_path': localFilePath,
      'remote_url': remoteUrl,
      'created_at': createdAt,
    };
  }

  factory AlarmSound.fromMap(Map<String, dynamic> map) {
    return AlarmSound(
      id: map['id'] as String,
      title: map['title'] as String,
      sourceType: map['source_type'] as String,
      localFilePath: map['local_file_path'] as String,
      remoteUrl: map['remote_url'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  AlarmSound copyWith({
    String? id,
    String? title,
    String? sourceType,
    String? localFilePath,
    String? remoteUrl,
    String? createdAt,
  }) {
    return AlarmSound(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceType: sourceType ?? this.sourceType,
      localFilePath: localFilePath ?? this.localFilePath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
