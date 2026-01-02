import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/token_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _loading = false;

  Future<void> _verify() async {
    if (_loading) return;
    final tokenInput = _tokenController.text.trim();
    final url = _extractUrl(tokenInput);
    final token = _extractToken(tokenInput);
    if (url == null && token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Paste the verification link or token from the email"),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await http.get(
        url ?? Uri.parse("${ApiConfig.baseUrl}/auth/verify-email?token=$token"),
        headers: const {"Accept": "application/json"},
      );
      String message = "Verified";
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data["message"] != null) {
          message = data["message"].toString();
        }
      } catch (_) {}
      final verified = response.statusCode == 200;
      if (verified) {
        await TokenService.saveEmailVerified(true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      if (verified) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification failed")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  String _extractToken(String input) {
    if (input.isEmpty) return "";
    final cleaned = input.replaceAll("\n", "").replaceAll(" ", "");
    final decoded = Uri.decodeFull(cleaned);
    // Accept raw token or any text containing token=...
    final tokenMatch =
        RegExp(r"token=([A-Za-z0-9]+)", caseSensitive: false)
            .firstMatch(decoded);
    if (tokenMatch != null) {
      return tokenMatch.group(1) ?? "";
    }
    if (!decoded.contains("http")) {
      return decoded;
    }
    try {
      final uri = Uri.parse(decoded);
      return uri.queryParameters["token"] ?? "";
    } catch (_) {
      return "";
    }
  }

  Uri? _extractUrl(String input) {
    final cleaned = input.trim();
    if (!cleaned.contains("http")) return null;
    try {
      final uri = Uri.parse(cleaned);
      return uri.hasScheme ? uri : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        centerTitle: true,
        title: Text(
          "Verify Email",
          style: TextStyle(color: scheme.onPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Paste the verification link or token from your email.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                hintText: "Verification token",
                filled: true,
                fillColor: scheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: scheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: scheme.primary, width: 1.4),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Text(
                        "Verify Email",
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
