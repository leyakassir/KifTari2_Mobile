import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/report_service.dart';
import '../resolve/resolve_report_screen.dart';
import 'field_operator_map_screen.dart';

class FieldOperatorReportDetailsScreen extends StatefulWidget {
  final String reportId;

  const FieldOperatorReportDetailsScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<FieldOperatorReportDetailsScreen> createState() =>
      _FieldOperatorReportDetailsScreenState();
}

class _FieldOperatorReportDetailsScreenState
    extends State<FieldOperatorReportDetailsScreen> {
  late Future<Map<String, dynamic>> _reportFuture;
  final TextEditingController _notesController = TextEditingController();
  bool _notesLoading = true;

  @override
  void initState() {
    super.initState();
    _reportFuture = ReportService.getReportById(widget.reportId);
    _loadNotes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("report_notes_${widget.reportId}") ?? "";
    if (!mounted) return;
    setState(() {
      _notesController.text = saved;
      _notesLoading = false;
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "report_notes_${widget.reportId}",
      _notesController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notes saved")),
    );
  }

  Future<void> _reload() async {
    setState(() {
      _reportFuture = ReportService.getReportById(widget.reportId);
    });
    await _reportFuture;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Details"),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: textTheme.bodyMedium,
              ),
            );
          }

          final report = snapshot.data!;
          final title = report["title"]?.toString() ?? "Report";
          final description =
              report["description"]?.toString() ?? "No description provided";
          final category = report["aiCategory"]?.toString() ??
              report["category"]?.toString() ??
              "Uncategorized";
          final status = report["status"]?.toString() ?? "pending";
          final assignedAt =
              _formatDate(report["assignedAt"] ?? report["createdAt"]);
          final locationText = _locationText(report);
          final streetImageUrl = report["streetImageUrl"]?.toString();
          final photoUrl = report["photoUrl"]?.toString();
          final coordinates = report["location"]?["coordinates"];
          final latitude = report["latitude"] is num
              ? (report["latitude"] as num).toDouble()
              : (coordinates is List && coordinates.length >= 2)
                  ? (coordinates[1] as num?)?.toDouble()
                  : null;
          final longitude = report["longitude"] is num
              ? (report["longitude"] as num).toDouble()
              : (coordinates is List && coordinates.length >= 2)
                  ? (coordinates[0] as num?)?.toDouble()
                  : null;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      // NEW FEATURE: status indicator
                      _StatusBadge(status: status),
                      const SizedBox(height: 8),
                      Text(description, style: textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.category_outlined,
                        label: "Category",
                        value: category,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: "Location",
                        value: locationText,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: "Assigned",
                        value: assignedAt,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status Timeline", style: textTheme.titleSmall),
                      const SizedBox(height: 12),
                      _TimelineItem(
                        label: "Assigned",
                        active: true,
                      ),
                      _TimelineItem(
                        label: "In Progress",
                        active: status == "in_progress" || status == "resolved",
                      ),
                      _TimelineItem(
                        label: "Resolved",
                        active: status == "resolved",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Photos", style: textTheme.titleSmall),
                      const SizedBox(height: 12),
                      _photoBlock(
                        context,
                        label: "Street Image",
                        url: streetImageUrl,
                      ),
                      const SizedBox(height: 12),
                      _photoBlock(
                        context,
                        label: "Citizen Photo",
                        url: photoUrl,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Actions", style: textTheme.titleSmall),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          onPressed: latitude != null && longitude != null
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FieldOperatorMapScreen(
                                        latitude: latitude,
                                        longitude: longitude,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: scheme.primary),
                          ),
                          child: Text(
                            "Open Map",
                            style: textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Notes", style: textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _notesLoading
                          ? const LinearProgressIndicator()
                          : TextField(
                              controller: _notesController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: "Add internal notes...",
                              ),
                            ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          onPressed: _notesLoading ? null : _saveNotes,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: scheme.primary),
                          ),
                          child: Text(
                            "Save Notes",
                            style: textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (status != "resolved")
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                      ),
                      onPressed: () async {
                        final success = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResolveReportScreen(
                              reportId: widget.reportId,
                              // NEW FEATURE: read-only mode for resolved reports
                              isResolved: status == "resolved",
                            ),
                          ),
                        );
                        if (success == true) {
                          await _reload();
                        }
                      },
                      child: Text(
                        "Resolve Report",
                        style: textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w600,
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
}

Widget _photoBlock(
  BuildContext context, {
  required String label,
  required String? url,
}) {
  final scheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final valid = url != null && url.startsWith("http");

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: textTheme.bodySmall),
      const SizedBox(height: 6),
      Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline),
        ),
        child: valid
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _photoPlaceholder(context),
                ),
              )
            : _photoPlaceholder(context),
      ),
    ],
  );
}

Widget _photoPlaceholder(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_not_supported, size: 32, color: scheme.onSurface),
        const SizedBox(height: 6),
        Text("No photo", style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String label;
  final bool active;

  const _TimelineItem({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = active ? scheme.primary : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// NEW FEATURE: status badge
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = _statusColor(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.replaceAll("_", " ").toUpperCase(),
        style: textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _formatDate(dynamic date) {
  if (date == null) return "-";
  final parsed = DateTime.tryParse(date.toString());
  if (parsed == null) return "-";
  return "${parsed.day}/${parsed.month}/${parsed.year}";
}

String _locationText(Map<String, dynamic> report) {
  final municipality = report["municipality"];
  if (municipality is Map && municipality["name"] != null) {
    return municipality["name"].toString();
  }

  final coordinates = report["location"]?["coordinates"];
  if (coordinates is List && coordinates.length >= 2) {
    return "Lat ${coordinates[1]}, Lng ${coordinates[0]}";
  }

  return report["locationName"]?.toString() ?? "Location not available";
}

// NEW FEATURE: shared status color
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
