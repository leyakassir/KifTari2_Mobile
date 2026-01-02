import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PendingUpload {
  final String reportId;
  final String filePath;

  PendingUpload({
    required this.reportId,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
        "reportId": reportId,
        "filePath": filePath,
      };

  static PendingUpload fromJson(Map<String, dynamic> json) {
    return PendingUpload(
      reportId: json["reportId"]?.toString() ?? "",
      filePath: json["filePath"]?.toString() ?? "",
    );
  }
}

class OfflineUploadService {
  static const String _storageKey = "pending_uploads";

  static Future<List<PendingUpload>> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => PendingUpload.fromJson(
                Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  static Future<void> saveQueue(List<PendingUpload> uploads) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(uploads.map((u) => u.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static Future<void> enqueue(String reportId, String filePath) async {
    final uploads = await loadQueue();
    final exists = uploads.any(
      (u) => u.reportId == reportId && u.filePath == filePath,
    );
    if (!exists) {
      uploads.add(PendingUpload(reportId: reportId, filePath: filePath));
      await saveQueue(uploads);
    }
  }

  static Future<void> removeAt(int index) async {
    final uploads = await loadQueue();
    if (index < 0 || index >= uploads.length) return;
    uploads.removeAt(index);
    await saveQueue(uploads);
  }

  static Future<int> pendingCount() async {
    final uploads = await loadQueue();
    return uploads.length;
  }
}
