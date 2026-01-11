import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';

class AiService {
  static Future<String> sendMessage({
    required String message,
    required String context,
  }) async {
    final headers = <String, String>{"Content-Type": "application/json"};

    if (context != "guest_help") {
      final token = await TokenService.getToken();
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/ai/chat"),
      headers: headers,
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
