import 'package:flutter/material.dart';
import '../../auth/login/login_screen.dart';
import '../../auth/register/register_screen.dart';
import '../ai/guest_ai_screen.dart';

class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Guest Home"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.traffic, size: 34, color: scheme.onPrimary),
                const SizedBox(height: 10),
                Text(
                  "Make your roads safer",
                  style: textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Join KifTari2 to report issues and track progress.",
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.onPrimary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Create Account",
                          style: textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: scheme.onPrimary),
                        ),
                        child: Text(
                          "Login",
                          style: textTheme.labelLarge?.copyWith(
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GuestAiScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.smart_toy_outlined),
            label: Text(
              "Ask AI About KifTari2",
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          _InfoCard(
            icon: Icons.verified_outlined,
            title: "Welcome to KifTari2",
            description:
                "KifTari2 helps citizens report road issues quickly and safely. "
                "Municipalities receive reports and coordinate resolution.",
          ),
          const SizedBox(height: 16),
          _StepsCard(
            title: "How reporting works",
            steps: const [
              "Report the issue",
              "Municipality reviews",
              "Field operator resolves",
              "Status updates are shared",
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.shield_outlined,
            title: "Why it matters",
            description:
                "Your reports improve safety, transparency, and faster action.",
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.lock_outline,
            title: "Ready to report?",
            description:
                "Create an account to submit reports and track progress.",
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(description, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  final String title;
  final List<String> steps;

  const _StepsCard({
    required this.title,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepBadge(number: index + 1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[index],
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int number;

  const _StepBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
