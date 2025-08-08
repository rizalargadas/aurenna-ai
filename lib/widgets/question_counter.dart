import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';

class QuestionCounter extends StatelessWidget {
  final bool showUpgradeButton;

  const QuestionCounter({super.key, this.showUpgradeButton = false});

  @override
  Widget build(BuildContext context) {
    // Listen to auth service changes
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _getUserStatus(authService),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final hasSubscription = snapshot.data!['hasSubscription'] as bool;
            final questionsRemaining =
                snapshot.data!['questionsRemaining'] as int;

            if (hasSubscription) {
              return _buildPremiumBadge(context);
            }

            return _buildFreeCounter(context, questionsRemaining);
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getUserStatus(AuthService authService) async {
    final hasSubscription = await authService.hasActiveSubscription();
    final questionsRemaining = await authService.getFreeQuestionsRemaining();

    return {
      'hasSubscription': hasSubscription,
      'questionsRemaining': questionsRemaining,
    };
  }

  Widget _buildPremiumBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: AurennaTheme.cosmicGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AurennaTheme.cosmicGlow],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'Unlimited',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeCounter(BuildContext context, int questionsRemaining) {
    final isLow = questionsRemaining <= 1;
    final isEmpty = questionsRemaining == 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isEmpty
                ? AurennaTheme.amberGlow.withValues(alpha: 0.1)
                : isLow
                ? AurennaTheme.stardustPurple.withValues(alpha: 0.1)
                : AurennaTheme.crystalBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEmpty
                  ? AurennaTheme.amberGlow
                  : isLow
                  ? AurennaTheme.stardustPurple
                  : AurennaTheme.crystalBlue,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEmpty ? Icons.lock_outline : Icons.auto_awesome,
                size: 16,
                color: isEmpty
                    ? AurennaTheme.amberGlow
                    : isLow
                    ? AurennaTheme.stardustPurple
                    : AurennaTheme.crystalBlue,
              ),
              const SizedBox(width: 6),
              Text(
                isEmpty
                    ? 'No questions left'
                    : '$questionsRemaining ${questionsRemaining == 1 ? 'question' : 'questions'} left',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isEmpty
                      ? AurennaTheme.amberGlow
                      : isLow
                      ? AurennaTheme.stardustPurple
                      : AurennaTheme.crystalBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (showUpgradeButton && (isEmpty || isLow)) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // TODO: Navigate to payment screen in Week 4
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Payment coming in Week 4! 💳',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: AurennaTheme.stardustPurple,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: Text(
              isEmpty ? 'Go unlimited' : 'Get more questions',
              style: TextStyle(
                color: AurennaTheme.electricViolet,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
