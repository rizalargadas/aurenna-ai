import 'package:flutter/material.dart';
import '../config/theme.dart';

class ErrorDialog {
  static void show(
    BuildContext context,
    String error, {
    VoidCallback? onRetry,
  }) {
    String title = 'Oops!';
    String message = error;
    String solution = '';
    bool showRetry = true;

    // Brand-voiced error parsing
    if (error.contains('OpenAI') || error.contains('API')) {
      title = 'Cosmic Connection Lost';
      message = 'The universe is being a bit shy right now.';
      solution = 'Let\'s try that again in a sec.';
    } else if (error.contains('Authentication failed')) {
      title = 'Configuration Hiccup';
      message = 'The cosmic keys got a bit tangled.';
      solution = 'This one\'s on us. Hit up support and we\'ll sort it out.';
      showRetry = false;
    } else if (error.contains('Too many requests')) {
      title = 'Cosmic Traffic Jam';
      message = 'Everyone wants their tea spilled at once!';
      solution = 'Give it a moment and try again.';
    } else if (error.contains('temporarily unavailable')) {
      title = 'Quick Cosmic Nap';
      message = 'The cards are recharging their mystical batteries.';
      solution = 'They\'ll be back in a few.';
    } else if (error.contains('network') || error.contains('connection')) {
      title = 'Connection Wonky';
      message = 'Your WiFi and the cosmos aren\'t vibing.';
      solution = 'Check your connection and let\'s try again.';
    } else if (error.contains('questions') || error.contains('limit')) {
      title = 'Out of Free Reads';
      message = 'You\'ve used up your cosmic freebies.';
      solution = 'Ready to go unlimited? The universe has so much more to say!';
      showRetry = false;
    } else if (error.contains('auth') || error.contains('session')) {
      title = 'Session Timeout';
      message = 'Your cosmic connection expired.';
      solution = 'Just log back in and we\'re good to go.';
      showRetry = false;
    } else if (error.contains('timeout')) {
      title = 'Taking Too Long';
      message = 'The cosmic connection is being extra slow today.';
      solution = 'Let\'s give it another shot.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AurennaTheme.mysticBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AurennaTheme.electricViolet),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AurennaTheme.silverMist),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AurennaTheme.silverMist),
            ),
            if (solution.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AurennaTheme.crystalBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: AurennaTheme.crystalBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        solution,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AurennaTheme.crystalBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (onRetry != null && showRetry)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Retry'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AurennaTheme.electricViolet,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError
            ? AurennaTheme.electricViolet
            : AurennaTheme.crystalBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
