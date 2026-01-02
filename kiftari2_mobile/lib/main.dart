import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/welcome/welcome_screen.dart';
import 'features/auth/login/login_screen.dart';
import 'features/splash/splash_screen.dart';
import 'layout/main_layout.dart';
import 'theme/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const KifTari2App(),
    ),
  );
}

class KifTari2App extends StatelessWidget {
  const KifTari2App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: "/",
      routes: {
        "/": (context) => const SplashScreen(),
        "/login": (context) => const LoginScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        "/home": (context) => const MainLayout(),
        "/field-home": (context) => const MainLayout(),
        "/employer-home": (context) => const MainLayout(),
      },
    );
  }
}
