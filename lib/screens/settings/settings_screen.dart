import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/question_counter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _resetSubscription(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Reset subscription status in database
      await Supabase.instance.client.from('users').update({
        'subscription_status': 'free',
        'subscription_start_date': null,
        'subscription_end_date': null,
        'subscription_plan': null,
        'payment_method': null,
        'paypal_payment_id': null,
        'paypal_payer_id': null,
        'free_questions_remaining': 3, // Reset free questions too
      }).eq('id', userId);

      // Refresh auth service
      await authService.hasActiveSubscription();
      await authService.refreshQuestionCount();

      // Check if context is still mounted before showing snackbar
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Subscription reset! You\'re back to free tier.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      // Check if context is still mounted before showing error snackbar
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting subscription: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

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
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/premium-upgrade');
                                },
                                icon: const Icon(Icons.upgrade, size: 18),
                                label: const Text('Upgrade to Premium'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              'Enjoy unlimited premium readings!',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AurennaTheme.crystalBlue),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: Add subscription management
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Subscription management coming soon!'),
                                      backgroundColor: AurennaTheme.cosmicPurple,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.manage_accounts, size: 18),
                                label: const Text('Manage Subscription'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
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

            // Developer Testing - Reset Subscription Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🧪 Developer Testing',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final shouldReset = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reset Subscription?'),
                            content: const Text(
                              'This will reset your account to free tier for testing purposes. Continue?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );

                        if (shouldReset == true && context.mounted) {
                          await _resetSubscription(context);
                        }
                      },
                      icon: const Icon(Icons.refresh, color: Colors.orange, size: 18),
                      label: const Text('Reset to Free Account'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

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
