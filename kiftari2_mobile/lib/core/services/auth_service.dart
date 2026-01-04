import 'dart:convert';
import 'dart:developer' as developer; // FIX: use logger instead of print
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';
import 'notification_service.dart';

class AuthService {
  // ================= LOGIN =================
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    developer.log("LOGIN API CALL"); // FIX: avoid print in production
    final fcmToken = await NotificationService.getToken();
    final payload = {
      "email": email,
      "password": password,
      if (fcmToken != null) "fcmToken": fcmToken,
    };
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
    developer.log("LOGIN STATUS: ${response.statusCode}"); // FIX: avoid print in production

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Save token + role + name
      await TokenService.clearAll();
      await TokenService.saveToken(data["token"]);
      await TokenService.saveRole(data["user"]["role"]);
      await TokenService.saveUserName(
      "${data["user"]["firstName"]} ${data["user"]["lastName"]}",
    );
      await TokenService.saveEmail(data["user"]["email"]?.toString());
      await TokenService.savePhone(data["user"]["phone"]?.toString());
      await TokenService.saveMunicipalityId(
        data["user"]["municipalityId"]?.toString(),
      );
      final emailVerifiedValue = data["user"]["emailVerified"];
      if (emailVerifiedValue is bool) {
        await TokenService.saveEmailVerified(emailVerifiedValue);
      }
      final pointsValue = data["user"]["points"];
      if (pointsValue is num) {
        await TokenService.savePoints(pointsValue.toInt());
      }
      final municipality = data["user"]["municipality"];
      if (municipality is Map && municipality["name"] != null) {
        await TokenService.saveMunicipality(
          municipality["name"]?.toString(),
        );
      } else {
        await TokenService.saveMunicipality(
          data["user"]["municipalityName"]?.toString(),
        );
      }
      return true;
    }

    String message = "Login failed";
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data["message"] is String) {
        message = data["message"];
      }
    } catch (_) {}

    throw Exception(message);
  }

  // ================= CURRENT USER =================
  static Future<bool> refreshCurrentUser() async {
    final jwt = await TokenService.getToken();
    if (jwt == null) return false;

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/auth/me"),
      headers: {"Authorization": "Bearer $jwt"},
    );

    if (response.statusCode != 200) {
      return false;
    }

    final data = jsonDecode(response.body);
    final user = data is Map ? data["user"] : null;
    if (user is! Map) return false;

    final firstName = user["firstName"]?.toString() ?? "";
    final lastName = user["lastName"]?.toString() ?? "";
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      await TokenService.saveUserName("$firstName $lastName".trim());
    }

    await TokenService.saveEmail(user["email"]?.toString());
    await TokenService.savePhone(user["phone"]?.toString());
    await TokenService.saveRole(user["role"]?.toString() ?? "citizen");
    await TokenService.saveMunicipalityId(
      user["municipalityId"]?.toString(),
    );

    final emailVerifiedValue = user["emailVerified"];
    if (emailVerifiedValue is bool) {
      await TokenService.saveEmailVerified(emailVerifiedValue);
    }

    final pointsValue = user["points"];
    if (pointsValue is num) {
      await TokenService.savePoints(pointsValue.toInt());
    }

    return true;
  }

  // ================= REGISTER (CITIZEN ONLY) =================
  static Future<bool> registerCitizen({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "password": password,
        "phone": phone,
        "role": "citizen",
      }),
    );

    // Optional debug
    // print("REGISTER STATUS: ${response.statusCode}");
    // print("REGISTER BODY: ${response.body}");

    return response.statusCode == 201;
  }

  // ================= FCM TOKEN UPDATE =================
  static Future<void> updateFcmToken(String? fcmToken) async {
    final jwt = await TokenService.getToken();
    if (jwt == null) return;

    await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/auth/fcm-token"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $jwt",
      },
      body: jsonEncode({"fcmToken": fcmToken}),
    );
  }
}
