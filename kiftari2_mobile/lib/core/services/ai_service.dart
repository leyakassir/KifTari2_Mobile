import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AiService {
  static Future<String> sendMessage({
    required String message,
    required String context,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/ai/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "message": message,
        "context": context,
      }),
    );

    Map<String, dynamic> decoded = {};
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {}

    if (response.statusCode == 200 && decoded["reply"] is String) {
      return decoded["reply"] as String;
    }

    throw Exception(
      decoded["message"]?.toString() ?? "AI service is unavailable",
    );
  }
}
