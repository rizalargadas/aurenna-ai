import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class PremiumCheck {
  /// Checks if user has premium access and redirects to upgrade screen if not
  /// Returns true if user has access, false if redirected
  static Future<bool> requirePremiumAccess(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final hasSubscription = await authService.hasActiveSubscription();
      
      if (!hasSubscription) {
        // User doesn't have premium access, redirect to upgrade
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/premium-upgrade');
        }
        return false;
      }
      
      return true;
    } catch (e) {
      // If check fails, redirect to upgrade for safety
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/premium-upgrade');
      }
      return false;
    }
  }
}