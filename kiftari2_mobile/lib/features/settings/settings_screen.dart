import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/token_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/auth_service.dart';
import '../welcome/welcome_screen.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ================= LOAD / SAVE =================

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool("notifications") ?? true;
    });
  }
  
  Future<void> _saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notifications", value);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: scheme.primary,
        centerTitle: true,
        title: Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onPrimary,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _sectionTitle("Appearance"),
          _card(
            child: SwitchListTile(
              value: themeProvider.isDarkMode,
              activeColor: scheme.primary,
              title: const Text(
                "Dark Mode",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text("Save preference locally"),
              onChanged: (value) {
                context.read<ThemeProvider>().toggleTheme(value);
},

            ),
          ),

          const SizedBox(height: 20),

          _sectionTitle("Notifications"),
          _card(
            child: SwitchListTile(
              value: notificationsEnabled,
              activeColor: scheme.primary,
              title: const Text(
                "Push Notifications",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text("Receive report updates"),
              onChanged: (value) async {
                setState(() => notificationsEnabled = value);
                await _saveNotifications(value);
                final token =
                    await NotificationService.setNotificationsEnabled(value);
                await AuthService.updateFcmToken(token);
              },
            ),
          ),

          const SizedBox(height: 20),

          _sectionTitle("Privacy & Legal"),
          _card(
            child: Column(
              children: [
                _listItem(
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy Policy",
                  onTap: () => _showInfoDialog(
                    "Privacy Policy",
                    "Your data is used only for road safety reporting and is never shared with third parties.",
                  ),
                ),
                const Divider(height: 1),
                _listItem(
                  icon: Icons.description_outlined,
                  title: "Terms & Conditions",
                  onTap: () => _showInfoDialog(
                    "Terms & Conditions",
                    "Users must submit accurate reports. Abuse or spam may result in account suspension.",
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _sectionTitle("About"),
          _card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: scheme.primary),
                  title: const Text(
                    "App Version",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Text("v1.0.0"),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.public, color: scheme.primary),
                  title: const Text(
                    "Platform",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Text("Lebanon Road Safety System"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          _card(
            child: ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text(
                "Logout",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.error,
                ),
              ),
              subtitle: const Text("Sign out from your account"),
              onTap: () async {
                await TokenService.clearAll();
                if (!context.mounted) return; // FIX: guard context after async
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (_) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _listItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
