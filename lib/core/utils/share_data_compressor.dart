import 'dart:convert';
import 'dart:io';
import '../../data/models/share_payload_model.dart';

class ShareDataCompressor {
  /// Mengubah objek SharePayload -> JSON -> Kompres GZip -> String Base64Url
  static String compressPayload(SharePayload payload) {
    final jsonStr = jsonEncode(payload.toJson());
    final utf8Bytes = utf8.encode(jsonStr);
    final compressedBytes = gzip.encode(utf8Bytes);
    // Base64Url aman diletakkan di dalam parameter URL web maupun QR Code
    return base64UrlEncode(compressedBytes);
  }

  /// Membaca string (bisa berupa teks terkompresi, URL unisched://, atau JSON mentah)
  static SharePayload? decompressPayload(String input) {
    try {
      String raw = input.trim();

      // 1. Jika input berupa URL (misal: unisched://import?data=XYZ)
      if (raw.startsWith('unisched://')) {
        final uri = Uri.parse(raw);
        final dataParam = uri.queryParameters['data'];
        if (dataParam != null) {
          raw = dataParam;
        }
      }

      // 2. Jika input berupa JSON langsung (jika user paste manual)
      if (raw.startsWith('{') && raw.endsWith('}')) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return SharePayload.fromJson(decoded);
      }

      // 3. Dekompresi dari format Base64Url + GZip
      final normalized = base64Url.normalize(raw);
      final compressedBytes = base64Url.decode(normalized);
      final decompressedBytes = gzip.decode(compressedBytes);
      final jsonStr = utf8.decode(decompressedBytes);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      return SharePayload.fromJson(decoded);
    } catch (e) {
      return null; // Format tidak valid atau korup
    }
  }
}
