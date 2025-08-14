import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase.dart';
import '../models/subscription_plan.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;
  int? _cachedQuestionCount;
  bool? _cachedSubscriptionStatus;
  bool _disposed = false;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;

  @override
  void notifyListeners() {
    if (!_disposed) {
      try {
        super.notifyListeners();
      } catch (e) {
        // Silently handle disposal errors
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Sign up with email (OTP)
  Future<void> signUpWithOtp({
    required String email,
  }) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
      );
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Verify OTP
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: token,
      );

      if (response.user != null) {
        // The database trigger will automatically create the user profile
        if (!_disposed) {
          notifyListeners();
        }
      }

      return response;
    } catch (e) {
      throw Exception('Verification failed: ${e.toString()}');
    }
  }

  // Resend OTP
  Future<void> resendOtp(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
      );
    } catch (e) {
      throw Exception('Failed to resend code: ${e.toString()}');
    }
  }

  // Sign up with email and password - requires OTP verification
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null, // We'll handle verification via OTP
      );

      // Note: User won't be automatically signed in until email is verified
      return response;
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Verify OTP for email confirmation
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
    required String type,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: type == 'signup' ? OtpType.signup : OtpType.email,
        email: email,
        token: token,
      );

      if (response.user != null) {
        // The database trigger will automatically create the user profile
        if (!_disposed) {
          notifyListeners();
        }
      }

      return response;
    } catch (e) {
      throw Exception('Verification failed: ${e.toString()}');
    }
  }

  // Resend signup OTP
  Future<void> resendSignupOTP(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      throw Exception('Failed to resend code: ${e.toString()}');
    }
  }

  // Sign in with email OTP
  Future<void> signInWithOtp({
    required String email,
  }) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
      );
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign in with email and password (kept for compatibility)
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        if (!_disposed) {
          notifyListeners();
        }
      }

      return response;
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      // Clear cached values
      _cachedQuestionCount = null;
      _cachedSubscriptionStatus = null;
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Send password reset OTP
  Future<void> sendPasswordResetOTP(String email) async {
    try {
      // Use recovery flow instead of signin
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: null, // No redirect, we'll handle OTP verification
      );
    } catch (e) {
      throw Exception('Failed to send reset code: ${e.toString()}');
    }
  }

  // Reset password with OTP verification
  Future<void> resetPasswordWithOTP({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      // Verify the recovery OTP and get session
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.recovery,
        email: email,
        token: token,
      );

      if (response.user != null) {
        // Now update the password
        await _supabase.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        
        // Sign out the user so they need to login with new password
        await _supabase.auth.signOut();
        
        if (!_disposed) {
          notifyListeners();
        }
      }
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Get user's free questions remaining
  Future<int> getFreeQuestionsRemaining() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('users')
          .select('free_questions_remaining')
          .eq('id', userId)
          .single();

      final count = response['free_questions_remaining'] ?? 0;

      // Update cache and notify if changed
      if (_cachedQuestionCount != count) {
        _cachedQuestionCount = count;
        if (!_disposed) {
          notifyListeners();
        }
      }

      return count;
    } catch (e) {
      return _cachedQuestionCount ?? 0;
    }
  }

  // Force refresh the question count
  Future<void> refreshQuestionCount() async {
    _cachedQuestionCount = null;
    await getFreeQuestionsRemaining();
  }

  // Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('users')
          .select('subscription_status, subscription_end_date')
          .eq('id', userId)
          .single();

      final status = response['subscription_status'];
      final endDateStr = response['subscription_end_date'] as String?;
      
      // Check if subscription is active and not expired
      bool isActive = false;
      if (status == 'paypal_active') {
        if (endDateStr != null) {
          final endDate = DateTime.parse(endDateStr);
          final now = DateTime.now();
          
          if (now.isBefore(endDate)) {
            isActive = true;
          } else {
            // Subscription expired, update status to free
            await _supabase.from('users').update({
              'subscription_status': 'free',
            }).eq('id', userId);
            isActive = false;
          }
        } else {
          // No end date set (legacy), keep active
          isActive = true;
        }
      }

      // Update cache and notify if changed
      if (_cachedSubscriptionStatus != isActive) {
        _cachedSubscriptionStatus = isActive;
        if (!_disposed) {
          notifyListeners();
        }
      }

      return isActive;
    } catch (e) {
      return _cachedSubscriptionStatus ?? false;
    }
  }

  // Public getter for cached subscription status
  bool? get cachedSubscriptionStatus => _cachedSubscriptionStatus;

  // Get remaining premium days
  Future<int> getRemainingPremiumDays() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('users')
          .select('subscription_status, subscription_end_date, subscription_start_date')
          .eq('id', userId)
          .single();

      final status = response['subscription_status'];
      final endDateStr = response['subscription_end_date'] as String?;
      final startDateStr = response['subscription_start_date'] as String?;

      debugPrint('Debug getRemainingPremiumDays:');
      debugPrint('  Status: $status');
      debugPrint('  End date: $endDateStr');
      debugPrint('  Start date: $startDateStr');

      if (status == 'paypal_active') {
        if (endDateStr != null) {
          final endDate = DateTime.parse(endDateStr);
          final now = DateTime.now();
          
          // Calculate days remaining, accounting for time zones and ensuring we include today
          final endDateMidnight = DateTime(endDate.year, endDate.month, endDate.day);
          final nowMidnight = DateTime(now.year, now.month, now.day);
          final difference = endDateMidnight.difference(nowMidnight);
          
          final remainingDays = difference.inDays + 1; // +1 to include today
          
          debugPrint('  End date midnight: $endDateMidnight');
          debugPrint('  Now midnight: $nowMidnight');
          debugPrint('  Difference: ${difference.inDays}');
          debugPrint('  Remaining days (with +1): $remainingDays');
          
          return remainingDays > 0 ? remainingDays : 0;
        } else if (startDateStr != null) {
          // Fallback: calculate based on start date + 30 days
          final startDate = DateTime.parse(startDateStr);
          final calculatedEndDate = startDate.add(const Duration(days: 30));
          final now = DateTime.now();
          
          final calculatedEndMidnight = DateTime(calculatedEndDate.year, calculatedEndDate.month, calculatedEndDate.day);
          final nowMidnight = DateTime(now.year, now.month, now.day);
          final difference = calculatedEndMidnight.difference(nowMidnight);
          
          final remainingDays = difference.inDays + 1;
          
          debugPrint('  Calculated end from start: $calculatedEndDate');
          debugPrint('  Remaining days (fallback): $remainingDays');
          
          return remainingDays > 0 ? remainingDays : 0;
        }
      }

      return 0;
    } catch (e) {
      debugPrint('Error in getRemainingPremiumDays: $e');
      return 0;
    }
  }

  // Get current subscription plan
  Future<SubscriptionPlan?> getCurrentSubscriptionPlan() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('users')
          .select('subscription_status, subscription_plan')
          .eq('id', userId)
          .single();

      final status = response['subscription_status'];
      final planId = response['subscription_plan'] as String?;

      if (status == 'paypal_active' && planId != null) {
        switch (planId) {
          case 'premium_monthly':
            return SubscriptionPlan.monthly;
          case 'premium_quarterly':
            return SubscriptionPlan.quarterly;
          case 'premium_yearly':
            return SubscriptionPlan.yearly;
          default:
            return SubscriptionPlan.monthly; // fallback
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting current subscription plan: $e');
      return null;
    }
  }
}
