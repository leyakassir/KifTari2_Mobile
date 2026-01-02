import 'package:flutter/material.dart';
import '../../core/services/token_service.dart';
import '../../core/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Small delay so splash is visible
    await Future.delayed(const Duration(seconds: 2));

    final token = await TokenService.getToken();
    final role = await TokenService.getRole();

    if (!mounted) return;

    if (token != null && role != null) {
      // ✅ Logged in → MainLayout decides content by role
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      // ❌ Not logged in
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.traffic,
              size: 72,
              color: scheme.onPrimary,
            ),
            const SizedBox(height: 20),
            Text(
              "KifTari2",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Public Road Safety Platform",
              style: TextStyle(
                fontSize: 14,
                color: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
