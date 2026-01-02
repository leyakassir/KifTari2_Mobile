import 'package:flutter/material.dart';
import '../../../core/services/report_service.dart';
import '../../../core/services/token_service.dart';
import '../details/field_operator_report_details_screen.dart';

class FieldOperatorHomeScreen extends StatefulWidget {
  const FieldOperatorHomeScreen({super.key});

  @override
  State<FieldOperatorHomeScreen> createState() =>
      _FieldOperatorHomeScreenState();
}

class _FieldOperatorHomeScreenState extends State<FieldOperatorHomeScreen> {
  late Future<List<dynamic>> _assignmentsFuture;
  String _query = "";
  String _statusFilter = "all";
  String _operatorName = "";

  @override
  void initState() {
    super.initState();
    _assignmentsFuture = ReportService.getMyAssignments();
    _loadOperatorName();
  }

  // NEW FEATURE: load operator name for header
  Future<void> _loadOperatorName() async {
    final name = await TokenService.getUserDisplayName();
    if (!mounted) return;
    setState(() => _operatorName = name.trim());
  }

  Future<void> _refresh() async {
    setState(() {
      _assignmentsFuture = ReportService.getMyAssignments();
    });
    await _assignmentsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Reports"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<dynamic>>(
          future: _assignmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: textTheme.bodyMedium,
                ),
              );
            }

            final assignments = snapshot.data ?? [];

            if (assignments.isEmpty) {
              return _EmptyState(textTheme: textTheme);
            }

            final filtered = _filterAssignments(assignments);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: [
                  // NEW FEATURE: field operator header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _operatorName.isEmpty ? "Welcome" : _operatorName,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Field Operator",
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Reports waiting for your action",
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: "Search reports...",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => _query = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: "Status",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "all",
                        child: Text("All"),
                      ),
                      DropdownMenuItem(
                        value: "assigned",
                        child: Text("Assigned"),
                      ),
                      DropdownMenuItem(
                        value: "pending",
                        child: Text("Pending"),
                      ),
                      DropdownMenuItem(
                        value: "in_progress",
                        child: Text("In Progress"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _statusFilter = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    _EmptyState(textTheme: textTheme)
                  else
                    ...filtered.map((report) {
                      final reportId = report["_id"]?.toString() ?? "";
                      return _AssignmentCard(
                        report: report,
                        onTap: reportId.isEmpty
                            ? null
                            : () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FieldOperatorReportDetailsScreen(
                                          reportId: reportId,
                                        ),
                                  ),
                                );
                                await _refresh();
                              },
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterAssignments(
    List<dynamic> assignments,
  ) {
    final query = _query.trim().toLowerCase();

    return assignments
        .whereType<Map<String, dynamic>>()
        .where((report) {
          final status = report["status"]?.toString() ?? "";
          if (_statusFilter != "all" && status != _statusFilter) {
            return false;
          }

          if (query.isEmpty) return true;

          final title = report["title"]?.toString().toLowerCase() ?? "";
          final category =
              report["aiCategory"]?.toString().toLowerCase() ?? "";
          final location = _locationText(report).toLowerCase();

          return title.contains(query) ||
              category.contains(query) ||
              location.contains(query);
        })
        .toList();
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback? onTap;

  const _AssignmentCard({
    required this.report,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final title = report["title"]?.toString() ?? "Report";
    final category = report["aiCategory"]?.toString() ??
        report["category"]?.toString() ??
        "Uncategorized";
    final status = report["status"]?.toString() ?? "pending";
    final dateText = _formatDate(report["assignedAt"] ?? report["createdAt"]);
    final locationText = _locationText(report);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.category_outlined, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(category, style: textTheme.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: scheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(locationText, style: textTheme.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusChip(status: status),
                Text(
                  dateText,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

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

class _EmptyState extends StatelessWidget {
  final TextTheme textTheme;

  const _EmptyState({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: scheme.primary,
          ),
          const SizedBox(height: 16),
          // NEW FEATURE: empty state security feedback
          Text(
            "No reports assigned to you at the moment.",
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "You will be notified when a report is assigned to you.",
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
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
