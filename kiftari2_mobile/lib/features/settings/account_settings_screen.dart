import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/token_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    final email = await TokenService.getEmail();
    final phone = await TokenService.getPhone();
    if (!mounted) return;
    setState(() {
      _emailController.text = email;
      _phoneController.text = phone;
    });
  }

  Future<void> _saveAccount() async {
    if (_loading) return;
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty && phone.isEmpty) {
      _toast("Please enter email or phone");
      return;
    }

    setState(() => _loading = true);
    final result = await AuthService.updateProfile(
      email: email,
      phone: phone,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result["success"] == true) {
      final data = result["data"];
      final user = data is Map ? data["user"] : null;
      if (user is Map) {
        await TokenService.saveEmail(user["email"]?.toString());
        await TokenService.savePhone(user["phone"]?.toString());
        final emailVerified = user["emailVerified"];
        if (emailVerified is bool) {
          await TokenService.saveEmailVerified(emailVerified);
        }
      }
      _toast("Profile updated");
    } else {
      _toast(result["message"]?.toString() ?? "Update failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        centerTitle: true,
        title: Text(
          "Account info",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone",
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveAccount,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Save Changes"),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "If you change your email, you'll need to verify it again.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
