import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/question_counter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AurennaTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '👤 Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Email',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AurennaTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authService.currentUser?.email ?? 'No email',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Free Questions Counter
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AurennaTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🎴 Questions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const QuestionCounter(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<bool>(
                    future: authService.hasActiveSubscription(),
                    builder: (context, snapshot) {
                      final hasSubscription = snapshot.data ?? false;
                      if (hasSubscription) {
                        return Text(
                          'You have unlimited questions! ✨',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AurennaTheme.crystalBlue),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Free tier',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AurennaTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: 0.33, // placeholder value
                            backgroundColor: AurennaTheme.textSecondary
                                .withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AurennaTheme.crystalBlue,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Subscription Status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AurennaTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✨ Subscription',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<bool>(
                    future: authService.hasActiveSubscription(),
                    builder: (context, snapshot) {
                      final hasSubscription = snapshot.data ?? false;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasSubscription ? 'Premium Member' : 'Free Account',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: hasSubscription
                                      ? AurennaTheme.crystalBlue
                                      : AurennaTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (!hasSubscription) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Upgrade for unlimited questions',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AurennaTheme.textSecondary),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Reading History
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AurennaTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📚 Reading History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<bool>(
                    future: authService.hasActiveSubscription(),
                    builder: (context, snapshot) {
                      final hasSubscription = snapshot.data ?? false;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'View Past Readings',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: hasSubscription 
                                ? AurennaTheme.textPrimary 
                                : AurennaTheme.textSecondary,
                          ),
                        ),
                        subtitle: Text(
                          hasSubscription 
                              ? 'Access your complete cosmic journey'
                              : 'Premium feature - Upgrade to unlock',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: hasSubscription 
                                ? AurennaTheme.textSecondary
                                : AurennaTheme.amberGlow,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!hasSubscription)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, 
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AurennaTheme.amberGlow.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'PRO',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AurennaTheme.amberGlow,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: hasSubscription 
                                  ? AurennaTheme.textSecondary 
                                  : AurennaTheme.textSecondary.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (hasSubscription) {
                            Navigator.pushNamed(context, '/reading-history');
                          } else {
                            Navigator.pushNamed(context, '/premium-upgrade');
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Sign Out Button
            ElevatedButton(
              onPressed: () async {
                final shouldSignOut = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out?'),
                    content: const Text(
                      'Are you sure you want to leave the mystical realm?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Stay'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (shouldSignOut == true) {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AurennaTheme.errorColor,
              ),
              child: const Text('Sign Out'),
            ),

            const SizedBox(height: 16),

            // App Version Footer
            Center(
              child: Text(
                'Aurenna.ai v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AurennaTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
