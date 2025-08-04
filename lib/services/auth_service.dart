import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase.dart';

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

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // The database trigger will automatically create the user profile
        if (!_disposed) {
          notifyListeners();
        }
      }

      return response;
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with email and password
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
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.aurennaai://reset-password',
      );
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
          .select('subscription_status')
          .eq('id', userId)
          .single();

      final status = response['subscription_status'];
      final isActive =
          status == 'paypal_active' || status == 'google_pay_active';

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
}
