import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _roleKey = 'user_role';
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _phoneKey = 'user_phone';
  static const _municipalityKey = 'user_municipality';
  static const _municipalityIdKey = 'user_municipality_id';
  static const _pointsKey = 'user_points';
  static const _emailVerifiedKey = 'user_email_verified';

  // TOKEN
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // ROLE
  static Future<void> saveRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  // NAME ✅
  static Future<void> saveUserName(String name) async {
    await _storage.write(key: _nameKey, value: name);
  }

  static Future<String> getUserDisplayName() async {
    return await _storage.read(key: _nameKey) ?? "";
  }

  static Future<void> saveEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    await _storage.write(key: _emailKey, value: email);
  }

  static Future<String> getEmail() async {
    return await _storage.read(key: _emailKey) ?? "";
  }

  static Future<void> savePhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    await _storage.write(key: _phoneKey, value: phone);
  }

  static Future<String> getPhone() async {
    return await _storage.read(key: _phoneKey) ?? "";
  }

  static Future<void> saveMunicipality(String? municipality) async {
    if (municipality == null || municipality.isEmpty) return;
    await _storage.write(key: _municipalityKey, value: municipality);
  }

  static Future<String> getMunicipality() async {
    return await _storage.read(key: _municipalityKey) ?? "";
  }

  static Future<void> saveMunicipalityId(String? municipalityId) async {
    if (municipalityId == null || municipalityId.isEmpty) return;
    await _storage.write(key: _municipalityIdKey, value: municipalityId);
  }

  static Future<String> getMunicipalityId() async {
    return await _storage.read(key: _municipalityIdKey) ?? "";
  }

  // POINTS
  static Future<void> savePoints(int points) async {
    await _storage.write(key: _pointsKey, value: points.toString());
  }

  static Future<int> getPoints() async {
    final value = await _storage.read(key: _pointsKey);
    return int.tryParse(value ?? "") ?? 0;
  }

  // EMAIL VERIFIED
  static Future<void> saveEmailVerified(bool verified) async {
    await _storage.write(
      key: _emailVerifiedKey,
      value: verified ? "true" : "false",
    );
  }

  static Future<bool> getEmailVerified() async {
    final value = await _storage.read(key: _emailVerifiedKey);
    return value == "true";
  }

  // LOGOUT
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
