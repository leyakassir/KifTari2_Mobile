import 'package:flutter/material.dart';
import '../../core/services/token_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late Future<int> _pointsFuture;
  static const int _threshold = 100;

  @override
  void initState() {
    super.initState();
    _pointsFuture = TokenService.getPoints();
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
          "My Rewards",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onPrimary,
          ),
        ),
      ),
      body: FutureBuilder<int>(
        future: _pointsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final points = snapshot.data ?? 0;
          final reached = points >= _threshold;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: reached
                ? [
                    _rewardCard(
                      context,
                      title: "10% Municipality Bill Discount",
                      status: "Eligible",
                      threshold: "$_threshold points reached",
                    ),
                  ]
                : [
                    _emptyState(context, points),
                  ],
          );
        },
      ),
    );
  }

  Widget _rewardCard(
    BuildContext context, {
    required String title,
    required String status,
    required String threshold,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ReflectiveStatusChip(status: status),
          const SizedBox(height: 10),
          Text(
            threshold,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, int points) {
    final scheme = Theme.of(context).colorScheme;
    final remaining = (_threshold - points).clamp(0, _threshold);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "No rewards yet",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            "Earn $remaining more points to unlock your first discount.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class ReflectiveStatusChip extends StatelessWidget {
  final String status;

  const ReflectiveStatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = status == "Sent" ? scheme.tertiary : scheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
