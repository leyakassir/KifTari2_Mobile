import 'package:flutter/material.dart';
import '../../../core/services/report_service.dart';

class FieldOperatorOverviewScreen extends StatefulWidget {
  const FieldOperatorOverviewScreen({super.key});

  @override
  State<FieldOperatorOverviewScreen> createState() =>
      _FieldOperatorOverviewScreenState();
}

class _FieldOperatorOverviewScreenState
    extends State<FieldOperatorOverviewScreen> {
  late Future<Map<String, List<dynamic>>> _overviewFuture;

  @override
  void initState() {
    super.initState();
    _overviewFuture = _loadOverview();
  }

  Future<void> _refresh() async {
    setState(() {
      _overviewFuture = _loadOverview();
    });
    await _overviewFuture;
  }

  Future<Map<String, List<dynamic>>> _loadOverview() async {
    final results = await Future.wait([
      ReportService.getMyAssignments(),
      ReportService.getMyResolvedReports(),
    ]);

    return {
      "assignments": results[0],
      "resolved": results[1],
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Field Overview"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _overviewFuture.then((value) => value["assignments"] ?? []),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Card(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              );
            }

            final assignments = snapshot.data ?? [];
            return FutureBuilder<Map<String, List<dynamic>>>(
              future: _overviewFuture,
              builder: (context, overviewSnapshot) {
                if (overviewSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (overviewSnapshot.hasError) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _Card(
                        child: Text(
                          "Error: ${overviewSnapshot.error}",
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  );
                }

                final data = overviewSnapshot.data ?? {};
                final resolvedReports = data["resolved"] ?? [];
                final total = assignments.length + resolvedReports.length;
                final resolved = resolvedReports.length;
                final inProgress = assignments
                    .where((r) => r["status"] == "in_progress")
                    .length;
                final pending = assignments.length - inProgress;
                final avgHours = _averageResolutionHours(resolvedReports);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _HeaderCard(
                      total: total,
                      resolved: resolved,
                      inProgress: inProgress,
                      pending: pending,
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your Summary",
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Track and resolve assigned reports to keep your municipality safe.",
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Status Breakdown",
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _StatusRow(
                            label: "Pending",
                            value: pending.toString(),
                            color: scheme.tertiaryContainer,
                          ),
                          const SizedBox(height: 8),
                          _StatusRow(
                            label: "In Progress",
                            value: inProgress.toString(),
                            color: scheme.secondary,
                          ),
                          const SizedBox(height: 8),
                          _StatusRow(
                            label: "Resolved",
                            value: resolved.toString(),
                            color: scheme.tertiary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Performance",
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _StatusRow(
                            label: "Total Resolved",
                            value: resolved.toString(),
                            color: scheme.tertiary,
                          ),
                          const SizedBox(height: 8),
                          _StatusRow(
                            label: "Avg Resolve Time (hrs)",
                            value: avgHours,
                            color: scheme.secondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Recent Assignments",
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (assignments.isEmpty)
                      _Card(
                        child: Text(
                          "No assignments available yet.",
                          style: textTheme.bodyMedium,
                        ),
                      )
                    else
                      ...assignments.take(3).map((report) {
                        final title = report["title"]?.toString() ?? "Report";
                        final status =
                            report["status"]?.toString() ?? "pending";
                        final dateText = _formatDate(
                          report["assignedAt"] ?? report["createdAt"],
                        );
                        return _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: textTheme.titleSmall),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _StatusPill(status: status),
                                  Text(dateText, style: textTheme.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int total;
  final int resolved;
  final int inProgress;
  final int pending;

  const _HeaderCard({
    required this.total,
    required this.resolved,
    required this.inProgress,
    required this.pending,
  });

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
            "Assigned Reports",
            style: textTheme.titleMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            total.toString(),
            style: textTheme.displaySmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(label: "Pending", value: pending),
              const SizedBox(width: 12),
              _MiniStat(label: "In Progress", value: inProgress),
              const SizedBox(width: 12),
              _MiniStat(label: "Resolved", value: resolved),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: textTheme.titleMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
      margin: const EdgeInsets.only(bottom: 12),
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

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

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

String _averageResolutionHours(List<dynamic> reports) {
  if (reports.isEmpty) return "0";
  num totalHours = 0;
  var count = 0;

  for (final report in reports) {
    if (report is Map) {
      final created = DateTime.tryParse(
        report["createdAt"]?.toString() ?? "",
      );
      final resolved = DateTime.tryParse(
        report["resolvedAt"]?.toString() ?? "",
      );
      if (created != null && resolved != null) {
        final diff = resolved.difference(created);
        totalHours += diff.inMinutes / 60;
        count += 1;
      }
    }
  }

  if (count == 0) return "0";
  final avg = totalHours / count;
  return avg.toStringAsFixed(1);
}
