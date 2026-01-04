import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/api_config.dart';
import '../../core/services/report_service.dart';
import '../../core/services/token_service.dart';
import '../field_operator/details/field_operator_report_details_screen.dart';
import '../reports/details/report_details_screen.dart';
import 'notification_permission_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool("notifications") ?? true;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final token = await TokenService.getToken();
    if (token == null) {
      return [];
    }

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/notifications/my"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      return [];
    }

    final decoded = jsonDecode(response.body);
    final list = decoded is Map && decoded["notifications"] is List
        ? List<dynamic>.from(decoded["notifications"])
        : decoded is List
            ? decoded
            : <dynamic>[];

    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _notificationsFuture = _fetchNotifications();
    });
    await _notificationsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        centerTitle: true,
        title: Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onPrimary,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                NotificationPermissionWidget(
                  notificationsEnabled: _notificationsEnabled,
                  onEnablePressed: () {},
                ),
                if (notifications.isEmpty)
                  Center(
                    child: Text(
                      "No notifications yet",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  ...notifications.map(
                    (item) => _notificationCard(
                      context,
                      item,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _notificationCard(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final title = _readString(
      item,
      ["title", "subject"],
      "Notification",
    );
    final message = _readString(
      item,
      ["message", "body", "text"],
      "",
    );
    final createdAt = _readString(
      item,
      ["createdAt", "date"],
      "",
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openNotification(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: scheme.outline,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _iconFor(item),
              color: scheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNotification(Map<String, dynamic> item) async {
    final data = item["data"];
    if (data is! Map) return;

    final reportId = data["reportId"]?.toString();
    if (reportId == null || reportId.isEmpty) return;

    final role = await TokenService.getRole();
    if (!mounted) return;

    if (role == "field_operator") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FieldOperatorReportDetailsScreen(reportId: reportId),
        ),
      );
      return;
    }

    try {
      final report = await ReportService.getReportById(reportId);
      if (!report.containsKey("municipality") &&
          report["municipalityId"] != null) {
        report["municipality"] = report["municipalityId"];
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportDetailsScreen(report: report),
        ),
      );
    } catch (_) {}
  }

  String _readString(
    Map<String, dynamic> item,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  IconData _iconFor(Map<String, dynamic> item) {
    final type = item["type"]?.toString().toLowerCase() ?? "";
    final title = item["title"]?.toString().toLowerCase() ?? "";

    if (type.contains("resolved") || title.contains("resolved")) {
      return Icons.check_circle;
    }
    if (type.contains("assigned") || title.contains("assigned")) {
      return Icons.assignment_turned_in;
    }
    if (type.contains("points") || title.contains("points")) {
      return Icons.star;
    }
    return Icons.notifications;
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return "$day/$month/$year";
  }
}
