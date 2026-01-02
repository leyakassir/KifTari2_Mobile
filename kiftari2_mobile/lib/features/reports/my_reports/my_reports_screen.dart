import 'package:flutter/material.dart';
import 'package:kiftari2/core/services/report_service.dart';
import '../../../layout/main_layout.dart';
import '../details/report_details_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late Future<List<dynamic>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = ReportService.getMyReports();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,

      // 🔵 APP BAR
      appBar: AppBar(
        backgroundColor: scheme.primary,
        centerTitle: true,
        title: Text(
          "My Reports",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: scheme.onPrimary),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainLayout()),
            );
          },
        ),
      ),

      // ⚪ BODY
      body: FutureBuilder<List<dynamic>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: scheme.error),
              ),
            );
          }

          final reports = snapshot.data!;

          // 🟡 EMPTY STATE
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: scheme.onSurface,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No reports submitted yet",
                    style: TextStyle(
                      fontSize: 16,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.outline,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReportDetailsScreen(report: report),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      // 🟢 STATUS ICON
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _statusIcon(report["status"]),
                          color: _statusColor(context, report["status"]),
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // 📝 TITLE + STATUS
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report["title"] ?? "No title",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _statusBadge(context, report["status"]),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ================= STATUS UI HELPERS =================

  Widget _statusBadge(BuildContext context, String? status) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatStatus(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _statusColor(context, status),
        ),
      ),
    );
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case "assigned":
        return Icons.assignment_ind;
      case "pending":
        return Icons.hourglass_empty;
      case "in_progress":
        return Icons.build_circle;
      case "resolved":
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _formatStatus(String? status) {
    switch (status) {
      case "assigned":
        return "Assigned";
      case "pending":
        return "Pending";
      case "in_progress":
        return "In Progress";
      case "resolved":
        return "Resolved";
      default:
        return "Unknown";
    }
  }

  Color _statusColor(BuildContext context, String? status) {
    final scheme = Theme.of(context).colorScheme;

    switch (status) {
      case "assigned":
        return scheme.tertiaryContainer;
      case "pending":
        return scheme.onSurface;
      case "in_progress":
        return scheme.secondary;
      case "resolved":
        return scheme.tertiary;
      default:
        return scheme.onSurface;
    }
  }
}
