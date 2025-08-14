import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/error_handler.dart';

class ErrorDialog {
  static void show(
    BuildContext context,
    String error, {
    VoidCallback? onRetry,
  }) {
    // Use the new ErrorHandler for consistent messaging
    final title = ErrorHandler.getErrorTitle(error);
    final message = ErrorHandler.getUserFriendlyMessage(error);
    final showRetry = onRetry != null && !ErrorHandler.isNetworkError(error);

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
        content: SingleChildScrollView(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(
              color: AurennaTheme.silverMist,
              height: 1.4,
            ),
          ),
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
