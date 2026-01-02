import 'package:flutter/material.dart';
import '../../core/services/report_service.dart';
import '../../core/services/token_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _reportsFuture;
  String _name = "";
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _reportsFuture = ReportService.getMyReports();
    _loadName();
    _loadPoints();
  }

  Future<void> _loadName() async {
    final name = await TokenService.getUserDisplayName();
    if (!mounted) return;
    setState(() => _name = name.trim());
  }

  Future<void> _loadPoints() async {
    final points = await TokenService.getPoints();
    if (!mounted) return;
    setState(() => _points = points);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final reports = snapshot.data ?? [];
            final total = reports.length;
            final resolved =
                reports.where((r) => r["status"] == "resolved").length;
            final pending = total - resolved;
            final points = _points;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔵 HEADER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 44, 24, 36),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_name.isNotEmpty)
                          Text(
                            _name,
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: scheme.onPrimary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "$points contribution points",
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 📊 OVERVIEW TITLE
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Your Reports Overview",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 📦 STATUS CARDS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _statusTile(
                          label: "Submitted",
                          value: total,
                          color: scheme.primary,
                          icon: Icons.upload_file,
                        ),
                        const SizedBox(width: 12),
                        _statusTile(
                          label: "Resolved",
                          value: resolved,
                          color: scheme.tertiary,
                          icon: Icons.check_circle,
                        ),
                        const SizedBox(width: 12),
                        _statusTile(
                          label: "Pending",
                          value: pending,
                          color: scheme.tertiaryContainer,
                          icon: Icons.hourglass_top,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 🕒 RECENT REPORTS
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Recent Reports",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: reports.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: scheme.surface,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  "You haven’t submitted any reports yet.",
                                  style: TextStyle(color: scheme.onSurface),
                                ),
                              )
                        : Column(
                            children: reports
                                .take(3)
                                .map((r) => _recentReportTile(r))
                                .toList(),
                          ),
                  ),

                  const SizedBox(height: 32),

                  // ℹ️ SYSTEM INFORMATION (REPLACES QUICK ACTIONS)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: scheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Reports submitted through KifTari2 are reviewed by the responsible municipality. "
                              "Once verified, they may be assigned to field operators for resolution.",
                              style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 🔹 STATUS TILE
  Widget _statusTile({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 RECENT REPORT TILE
  Widget _recentReportTile(Map<String, dynamic> report) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            report["status"] == "resolved"
                ? Icons.check_circle
                : Icons.hourglass_top,
            color: report["status"] == "resolved"
                ? scheme.tertiary
                : scheme.tertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              report["title"] ?? "Report",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            report["status"],
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
