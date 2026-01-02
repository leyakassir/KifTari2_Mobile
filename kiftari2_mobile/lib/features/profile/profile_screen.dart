import 'package:flutter/material.dart';
import '../../core/services/report_service.dart';
import '../../core/services/token_service.dart';
import '../notifications/notifications_screen.dart';
import '../rewards/rewards_screen.dart';
import '../auth/change_password/change_password_screen.dart';
import '../auth/verify_email/verify_email_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<List<dynamic>> _reportsFuture = Future.value([]);
  String _name = "";
  String? _role;
  String _email = "";
  String _phone = "";
  String _municipality = "";
  String _municipalityId = "";
  bool _emailVerified = false;
  bool _municipalityLoading = false;
  bool _profileLoading = true;
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
}

  Future<void> _loadUser() async {
    final name = await TokenService.getUserDisplayName();
    final role = await TokenService.getRole();
    final email = await TokenService.getEmail();
    final phone = await TokenService.getPhone();
    final municipality = await TokenService.getMunicipality();
    final municipalityId = await TokenService.getMunicipalityId();
    final emailVerified = await TokenService.getEmailVerified();
    final points = await TokenService.getPoints();
    if (!mounted) return;
    setState(() {
      _name = name.trim();
      _role = role ?? "citizen";
      _email = email.trim();
      _phone = phone.trim();
      _municipality = municipality.trim();
      _municipalityId = municipalityId.trim();
      _emailVerified = emailVerified;
      _points = points;
      _profileLoading = false;
      if (_role != "field_operator") {
        _reportsFuture = ReportService.getMyReports();
      }
    });

    if (_role == "field_operator" && _municipality.isEmpty) {
      if (_municipalityId.isNotEmpty) {
        await _loadMunicipalityFromId();
      } else {
        await _loadMunicipalityFromAssignments();
      }
    }
  }

  Future<void> _loadMunicipalityFromId() async {
    setState(() => _municipalityLoading = true);
    try {
      final name = await ReportService.getMunicipalityName(_municipalityId);
      if (!mounted) return;
      setState(() {
        _municipality = name;
        _municipalityLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _municipalityLoading = false);
    }
  }

  Future<void> _loadMunicipalityFromAssignments() async {
    setState(() => _municipalityLoading = true);
    try {
      final assignments = await ReportService.getMyAssignments();
      if (!mounted) return;
      final name = _extractMunicipality(assignments);
      setState(() {
        _municipality = name;
        _municipalityLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _municipalityLoading = false);
    }
  }

  String _extractMunicipality(List<dynamic> assignments) {
    for (final item in assignments) {
      if (item is Map) {
        final municipality = item["municipality"];
        if (municipality is Map && municipality["name"] != null) {
          return municipality["name"].toString();
        }
        if (item["municipalityName"] != null) {
          return item["municipalityName"].toString();
        }
      }
    }
    return "";
  }

  String _calculateLevel(int points) {
    if (points >= 200) return "Community Guardian";
    if (points >= 120) return "Trusted Reporter";
    if (points >= 60) return "Active Citizen";
    return "New Reporter";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_profileLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_role == "field_operator") {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          backgroundColor: scheme.primary,
          centerTitle: true,
          title: Text(
            "Profile",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: scheme.onPrimary,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 42,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_name.isNotEmpty)
                    Text(
                      _name,
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    "Field Operator",
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Details",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: "Email",
                    value: _email.isEmpty ? "-" : _email,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: "Email Status",
                    value: _emailVerified ? "Verified" : "Not Verified",
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: "Phone",
                    value: _phone.isEmpty ? "-" : _phone,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: "Municipality",
                    value: _municipalityLoading
                        ? "Loading..."
                        : (_municipality.isEmpty ? "-" : _municipality),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  await TokenService.clearAll();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    "/login",
                    (_) => false,
                  );
                },
                child: Text(
                  "Logout",
                  style: TextStyle(
                    color: scheme.onError,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // NEW FEATURE: security actions (field operator)
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  // NEW FEATURE: notifications shortcut (field operator)
                  ListTile(
                    leading: Icon(Icons.notifications, color: scheme.primary),
                    title: const Text("Notifications"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.lock, color: scheme.primary),
                    title: const Text("Change Password"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.verified, color: scheme.primary),
                    title: const Text("Verify Email"),
                    subtitle: Text(
                      _emailVerified ? "Verified" : "Not Verified",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VerifyEmailScreen(),
                        ),
                      ).then((value) async {
                        if (value == true) {
                          await _loadUser();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        centerTitle: true,
        title: Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onPrimary,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final reports = snapshot.data ?? [];
          final totalReports = reports.length;
          final acceptedReports =
              reports.where((r) => r["status"] == "resolved").length;

          final points = _points;
          final level = _calculateLevel(points);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👤 HEADER CARD (REFINED)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 42,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_name.isNotEmpty)
                        Text(
                          _name,
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      const SizedBox(height: 6),
                      Text(
                        level,
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 📊 STATS
                Row(
                  children: [
                    _statCard(context, "Points", points.toString(), Icons.star),
                    const SizedBox(width: 16),
                    _statCard(
                      context,
                      "Reports",
                      totalReports.toString(),
                      Icons.description,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    _statCard(
                      context,
                      "Accepted",
                      acceptedReports.toString(),
                      Icons.check_circle,
                    ),
                    const SizedBox(width: 16),
                    _statCard(context, "Level", level, Icons.trending_up),
                  ],
                ),

                const SizedBox(height: 20),

                // NAVIGATION
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.card_giftcard, color: scheme.primary),
                        title: const Text("My Rewards"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RewardsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading:
                            Icon(Icons.notifications, color: scheme.primary),
                        title: const Text("Notifications"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.lock, color: scheme.primary),
                        title: const Text("Change Password"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.verified, color: scheme.primary),
                        title: const Text("Verify Email"),
                        subtitle: Text(
                          _emailVerified ? "Verified" : "Not Verified",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VerifyEmailScreen(),
                            ),
                          ).then((value) async {
                            if (value == true) {
                              await _loadUser();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 📈 POINTS HISTORY
                const Text(
                  "Points History",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                _pointsTile("+20 Points", "Report accepted"),
                _pointsTile("+10 Points", "Report submitted"),
                _pointsTile("+15 Points", "Clear photo uploaded"),

                const SizedBox(height: 36),

                // 🚪 LOGOUT (CALMER RED)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await TokenService.clearAll();
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        "/login",
                        (_) => false,
                      );
                    },
                    child: Text(
                      "Logout",
                      style: TextStyle(
                        color: scheme.onError,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: scheme.primary, size: 26),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pointsTile(String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: scheme.primary),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: scheme.onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodySmall),
        Flexible(
          child: Text(
            value,
            style: textTheme.bodyMedium,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
