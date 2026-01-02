import 'package:flutter/material.dart';

class NotificationPermissionWidget extends StatelessWidget {
  final bool notificationsEnabled;
  final VoidCallback onEnablePressed;

  const NotificationPermissionWidget({
    super.key,
    required this.notificationsEnabled,
    required this.onEnablePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (notificationsEnabled) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Stay updated",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  "Enable notifications to receive report updates and rewards.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onEnablePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Enable Notifications",
                      style: TextStyle(color: scheme.onPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
