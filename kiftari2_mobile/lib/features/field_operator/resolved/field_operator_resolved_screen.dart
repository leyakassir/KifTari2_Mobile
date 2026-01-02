import 'package:flutter/material.dart';
import '../../../core/services/report_service.dart';
import '../details/field_operator_report_details_screen.dart';

class FieldOperatorResolvedScreen extends StatefulWidget {
  const FieldOperatorResolvedScreen({super.key});

  @override
  State<FieldOperatorResolvedScreen> createState() =>
      _FieldOperatorResolvedScreenState();
}

class _FieldOperatorResolvedScreenState
    extends State<FieldOperatorResolvedScreen> {
  late Future<List<dynamic>> _resolvedFuture;
  String _query = "";
  String _categoryFilter = "all";

  @override
  void initState() {
    super.initState();
    _resolvedFuture = ReportService.getMyResolvedReports();
  }

  Future<void> _refresh() async {
    setState(() {
      _resolvedFuture = ReportService.getMyResolvedReports();
    });
    await _resolvedFuture;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resolved Reports"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<dynamic>>(
          future: _resolvedFuture,
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

            final reports = snapshot.data ?? [];
            if (reports.isEmpty) {
              return _EmptyState(textTheme: textTheme);
            }

            final categories = _categoriesFromReports(reports);
            final filtered = _filterReports(reports);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: [
                  _HeaderCard(
                    totalResolved: reports.length,
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Find Reports",
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: "Search resolved reports...",
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() => _query = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _categoryFilter,
                          decoration: const InputDecoration(
                            labelText: "Category",
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: "all",
                              child: Text("All"),
                            ),
                            ...categories.map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _categoryFilter = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    _EmptyState(textTheme: textTheme)
                  else
                    ...filtered.map((report) {
                      final reportId = report["_id"]?.toString() ?? "";
                      return _ResolvedCard(
                        report: report,
                        highlight: scheme.tertiary,
                        onTap: reportId.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FieldOperatorReportDetailsScreen(
                                      reportId: reportId,
                                    ),
                                  ),
                                );
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

  List<Map<String, dynamic>> _filterReports(List<dynamic> reports) {
    final query = _query.trim().toLowerCase();

    return reports
        .whereType<Map<String, dynamic>>()
        .where((report) {
          final category =
              report["aiCategory"]?.toString().toLowerCase() ?? "";
          if (_categoryFilter != "all" &&
              category != _categoryFilter.toLowerCase()) {
            return false;
          }

          if (query.isEmpty) return true;

          final title = report["title"]?.toString().toLowerCase() ?? "";
          final location = _locationText(report).toLowerCase();
          return title.contains(query) ||
              category.contains(query) ||
              location.contains(query);
        })
        .toList();
  }

  List<String> _categoriesFromReports(List<dynamic> reports) {
    final set = <String>{};
    for (final report in reports) {
      if (report is Map && report["aiCategory"] != null) {
        final value = report["aiCategory"].toString();
        if (value.isNotEmpty) set.add(value);
      }
    }
    final list = set.toList();
    list.sort();
    return list;
  }
}

class _ResolvedCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback? onTap;
  final Color highlight;

  const _ResolvedCard({
    required this.report,
    required this.highlight,
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
    final resolvedAt = _formatDate(report["resolvedAt"] ?? report["updatedAt"]);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium,
                  ),
                ),
                _StatusChip(label: "RESOLVED", color: highlight),
              ],
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event_available, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text("Resolved: $resolvedAt", style: textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
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
            Icons.check_circle_outline,
            size: 64,
            color: scheme.primary,
          ),
          const SizedBox(height: 16),
          Text("No resolved reports yet", style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            "Resolved reports will appear here.",
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int totalResolved;

  const _HeaderCard({required this.totalResolved});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Resolved Reports",
            style: textTheme.titleMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalResolved.toString(),
            style: textTheme.displaySmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
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

String _formatDate(dynamic date) {
  if (date == null) return "-";
  final parsed = DateTime.tryParse(date.toString());
  if (parsed == null) return "-";
  return "${parsed.day}/${parsed.month}/${parsed.year}";
}

String _locationText(Map<String, dynamic> report) {
  final municipality = report["municipalityId"];
  if (municipality is Map && municipality["name"] != null) {
    return municipality["name"].toString();
  }

  final coordinates = report["location"]?["coordinates"];
  if (coordinates is List && coordinates.length >= 2) {
    return "Lat ${coordinates[1]}, Lng ${coordinates[0]}";
  }

  return report["locationName"]?.toString() ?? "Location not available";
}
