import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_service.dart';

class ReportService {
  // ==================================================
  // CREATE REPORT (JSON + optional base64 image)
  // ==================================================
  static Future<Map<String, dynamic>> createReport({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    File? imageFile,
  }) async {
    final token = await TokenService.getToken();

    if (token == null) {
      return {
        "success": false,
        "message": "User not authenticated",
      };
    }

    String? base64Image;
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/reports/create"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "title": title,
        "description": description,
        "latitude": latitude,
        "longitude": longitude,
        if (base64Image != null) "base64Image": base64Image,
      }),
    );

    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE BODY: ${response.body}");

    Map<String, dynamic> decoded = {};
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {}

    return {
      "success": response.statusCode == 200 || response.statusCode == 201,
      "statusCode": response.statusCode,
      "message": decoded["message"] ?? "Unexpected server response",
      "data": decoded,
    };
  }

  // ==================================================
  // GET MY REPORTS (UNCHANGED)
  // ==================================================
  static Future<List<dynamic>> getMyReports() async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/reports/my"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded["reports"] is List) {
        return List<dynamic>.from(decoded["reports"]);
      }

      if (decoded is List) return decoded;

      return [];
    } else {
      throw Exception("Failed to load reports");
    }
  }

  // ==================================================
  // FIELD OPERATOR: MY ASSIGNMENTS
  // ==================================================
  static Future<List<dynamic>> getMyAssignments() async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/reports/my-assignments"),
      headers: {"Authorization": "Bearer $token"},
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception("Request timed out");
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        if (decoded["reports"] is List) {
          return List<dynamic>.from(decoded["reports"]);
        }
        if (decoded["assignments"] is List) {
          return List<dynamic>.from(decoded["assignments"]);
        }
        if (decoded["data"] is List) {
          return List<dynamic>.from(decoded["data"]);
        }
      }

      if (decoded is List) return decoded;

      return [];
    }

    String message = "Failed to load assignments";
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded["message"] != null) {
        message = decoded["message"].toString();
      }
    } catch (_) {}

    throw Exception("$message (HTTP ${response.statusCode})");
  }

  // ==================================================
  // FIELD OPERATOR: GET REPORT DETAILS
  // ==================================================
  static Future<Map<String, dynamic>> getReportById(String reportId) async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/reports/$reportId"),
      headers: {"Authorization": "Bearer $token"},
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception("Request timed out");
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded["report"] is Map) {
        return Map<String, dynamic>.from(decoded["report"]);
      }
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    String message = "Failed to load report details";
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded["message"] != null) {
        message = decoded["message"].toString();
      }
    } catch (_) {}

    throw Exception("$message (HTTP ${response.statusCode})");
  }

  // ==================================================
  // FIELD OPERATOR: RESOLVE REPORT
  // ==================================================
  static Future<Map<String, dynamic>> resolveReport(String reportId) async {
    final token = await TokenService.getToken();
    if (token == null) {
      return {
        "success": false,
        "message": "User not authenticated",
      };
    }

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/reports/resolve"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"reportId": reportId}),
    );

    Map<String, dynamic> decoded = {};
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {}

    return {
      "success": response.statusCode == 200 || response.statusCode == 201,
      "statusCode": response.statusCode,
      "message": decoded["message"] ?? "Unexpected server response",
      "data": decoded,
    };
  }

  // ==================================================
  // FIELD OPERATOR: ATTACH STREET IMAGE
  // ==================================================
  static Future<Map<String, dynamic>> attachStreetImage({
    required String reportId,
    required File imageFile,
  }) async {
    final token = await TokenService.getToken();
    if (token == null) {
      return {
        "success": false,
        "message": "User not authenticated",
      };
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/reports/$reportId/attach-street-image"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"base64Image": base64Image}),
    );

    Map<String, dynamic> decoded = {};
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {}

    return {
      "success": response.statusCode == 200 || response.statusCode == 201,
      "statusCode": response.statusCode,
      "message": decoded["message"] ?? "Unexpected server response",
      "data": decoded,
    };
  }

  // ==================================================
  // MUNICIPALITY: GET BY ID
  // ==================================================
  static Future<String> getMunicipalityName(String municipalityId) async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/municipality/$municipalityId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          decoded["municipality"] is Map &&
          decoded["municipality"]["name"] != null) {
        return decoded["municipality"]["name"].toString();
      }
    }

    throw Exception("Failed to load municipality");
  }

  // ==================================================
  // FIELD OPERATOR: RESOLVED REPORTS
  // ==================================================
  static Future<List<dynamic>> getMyResolvedReports() async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/reports/my-resolved"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded["reports"] is List) {
        return List<dynamic>.from(decoded["reports"]);
      }

      if (decoded is List) return decoded;

      return [];
    }

    String message = "Failed to load resolved reports";
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded["message"] != null) {
        message = decoded["message"].toString();
      }
    } catch (_) {}

    throw Exception("$message (HTTP ${response.statusCode})");
  }
}
