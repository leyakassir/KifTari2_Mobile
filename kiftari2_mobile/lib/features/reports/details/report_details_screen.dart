import 'package:flutter/material.dart';
import 'package:kiftari2/features/reports/my_reports/my_reports_screen.dart';

class ReportDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> report;

  const ReportDetailsScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final municipality =
        report["municipality"]?["name"] ?? "Municipality assigned";
    final createdAt = _formatDate(report["createdAt"]);
    final resolvedAt = _formatDate(report["resolvedAt"]);
    final severity = report["aiPriority"] ?? "Unknown";
    final photoUrl = report["photoUrl"];
    final status = report["status"] ?? "unknown";
    final streetImageUrl = report["streetImageUrl"];
    final coordinates = report["location"]?["coordinates"];

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        centerTitle: true,
        title: Text(
          "Report Details",
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
              MaterialPageRoute(builder: (_) => const MyReportsScreen()),
            );
          },
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧾 TITLE + STATUS + POINTS
            _card(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report["title"] ?? "No title",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),
                  _statusBadge(context, status),

                  const SizedBox(height: 14),
                  Text(
                    report["description"] ?? "No description provided",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: scheme.onSurface,
                    ),
                  ),

                  // ⭐ POINTS (MOVED HERE)
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.star, size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        "+20 points earned",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 📍 DETAILS
            _card(
              context: context,
              child: Column(
                children: [
                  _detailRow(
                    context,
                    Icons.location_city,
                    "Municipality",
                    municipality,
                  ),
                  _divider(context),
                  _detailRow(
                    context,
                    Icons.calendar_today,
                    "Submitted on",
                    createdAt,
                  ),
                  if (resolvedAt != "-") ...[
                    _divider(context),
                    _detailRow(
                      context,
                      Icons.check_circle,
                      "Resolved on",
                      resolvedAt,
                    ),
                  ],
                  if (coordinates != null) ...[
                    _divider(context),
                    _detailRow(
                      context,
                      Icons.my_location,
                      "Location",
                      "Lat ${coordinates[1]} , Lng ${coordinates[0]}",
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🖼️ PHOTO
            _sectionTitle(context, "Reported Photo"),
            const SizedBox(height: 12),
            _photoCard(context, photoUrl),

            if (status == "resolved") ...[
              const SizedBox(height: 24),
              _sectionTitle(context, "Resolution Proof"),
              const SizedBox(height: 12),
              _photoCard(context, streetImageUrl),
            ],

            const SizedBox(height: 28),

            // ⚠️ ISSUE SEVERITY (SEPARATE, CLEAN)
            _sectionTitle(context, "Issue Severity"),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: _severityColor(context, severity),
                  size: 22,
                ),
                const SizedBox(width: 12),
                _severityBadge(context, severity),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= SHARED UI =================

  Widget _card({required BuildContext context, required Widget child}) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: child,
    );
  }

  Widget _divider(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: scheme.outline),
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _photoCard(BuildContext context, dynamic url) {
    final scheme = Theme.of(context).colorScheme;
    final valid = url != null && url is String && url.startsWith("http");

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: valid
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _photoPlaceholder(context),
              ),
            )
          : _photoPlaceholder(context),
    );
  }


  Widget _photoPlaceholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 40,
            color: scheme.onSurface,
          ),
          const SizedBox(height: 6),
          Text(
            "No photo available",
            style: TextStyle(color: scheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _severityBadge(BuildContext context, String severity) {
    final scheme = Theme.of(context).colorScheme;
    final color = _severityColor(context, severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    final color = _statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _severityColor(BuildContext context, String severity) {
    final scheme = Theme.of(context).colorScheme;

    switch (severity.toLowerCase()) {
      case "high":
        return scheme.error;
      case "medium":
        return scheme.tertiaryContainer;
      case "low":
        return scheme.tertiary;
      default:
        return scheme.onSurface;
    }
  }

  Color _statusColor(BuildContext context, String status) {
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

  String _formatDate(dynamic date) {
    if (date == null) return "-";
    final parsed = DateTime.tryParse(date.toString());
    if (parsed == null) return "-";
    return "${parsed.day}/${parsed.month}/${parsed.year}";
  }
}
