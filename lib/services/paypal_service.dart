import 'package:flutter/material.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription_plan.dart';
import 'auth_service.dart';

class CouponDetails {
  final String code;
  final double discountPercentage;
  final double discountAmount;
  final bool isValid;
  final String? message;

  CouponDetails({
    required this.code,
    required this.discountPercentage,
    required this.discountAmount,
    required this.isValid,
    this.message,
  });
}

class PayPalService {
  static final PayPalService _instance = PayPalService._internal();
  factory PayPalService() => _instance;
  PayPalService._internal();

  final _supabase = Supabase.instance.client;
  final _authService = AuthService();

  // PayPal configuration
  String get clientId => dotenv.env['PAYPAL_CLIENT_ID'] ?? '';
  String get secretKey => dotenv.env['PAYPAL_SECRET_KEY'] ?? '';
  bool get sandboxMode => dotenv.env['PAYPAL_ENVIRONMENT'] == 'sandbox';

  // Subscription details
  static const String subscriptionPlanId = 'aurenna_premium_monthly';
  static const double basePrice = 6.99;
  static const String currency = 'USD';

  // Predefined coupon codes
  static final Map<String, Map<String, dynamic>> _coupons = {
    'WELCOME50': {
      'discount_percentage': 50.0,
      'description': '50% off your subscription',
      'max_uses': 1,
      'expires': DateTime(2025, 12, 31),
    },
    'AURENNA20': {
      'discount_percentage': 20.0,
      'description': '20% off any subscription plan',
      'max_uses': null,
      'expires': DateTime(2025, 12, 31),
    },
    'AURENNA90': {
      'discount_percentage': 90.0,
      'description': '90% off any subscription plan',
      'max_uses': null,
      'expires': DateTime(2026, 12, 31),
    },
    'AURENNA99': {
      'discount_percentage': 99.0,
      'description': '99% off any subscription plan',
      'max_uses': null,
      'expires': DateTime(2026, 12, 31),
    },
    'FRIEND30': {
      'discount_percentage': 30.0,
      'description': '30% friend referral discount',
      'max_uses': 1,
      'expires': DateTime(2025, 12, 31),
    },
    'BETA100': {
      'discount_percentage': 100.0,
      'description': 'Beta tester - 100% FREE',
      'max_uses': 1,
      'expires': DateTime(2025, 12, 31),
    },
  };

  // Validate coupon code
  Future<CouponDetails> validateCoupon(String code, {required double planPrice}) async {
    try {
      final upperCode = code.toUpperCase().trim();

      // Check if coupon exists
      if (!_coupons.containsKey(upperCode)) {
        return CouponDetails(
          code: code,
          discountPercentage: 0,
          discountAmount: 0,
          isValid: false,
          message: 'Invalid coupon code',
        );
      }

      final coupon = _coupons[upperCode]!;
      final expires = coupon['expires'] as DateTime;

      // Check if coupon is expired
      if (DateTime.now().isAfter(expires)) {
        return CouponDetails(
          code: code,
          discountPercentage: 0,
          discountAmount: 0,
          isValid: false,
          message: 'This coupon has expired',
        );
      }

      // Check if user has already used this coupon
      final userId = _authService.currentUser?.id;
      if (userId != null && coupon['max_uses'] == 1) {
        try {
          final response = await _supabase
              .from('coupon_usage')
              .select('id')
              .eq('user_id', userId)
              .eq('coupon_code', upperCode)
              .maybeSingle();

          if (response != null) {
            return CouponDetails(
              code: code,
              discountPercentage: 0,
              discountAmount: 0,
              isValid: false,
              message: 'You have already used this coupon',
            );
          }
        } catch (e) {
          // Table might not exist, continue with validation
          debugPrint('Coupon usage check error: $e');
        }
      }

      final discountPercentage = coupon['discount_percentage'] as double;
      final discountAmount = planPrice * (discountPercentage / 100);

      return CouponDetails(
        code: upperCode,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        isValid: true,
        message: coupon['description'] as String,
      );
    } catch (e) {
      debugPrint('Coupon validation error: $e');
      return CouponDetails(
        code: code,
        discountPercentage: 0,
        discountAmount: 0,
        isValid: false,
        message: 'Error validating coupon',
      );
    }
  }

  Future<bool> startSubscription(
    BuildContext context, {
    String? couponCode,
    SubscriptionPlan selectedPlan = SubscriptionPlan.monthly,
  }) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Check if PayPal credentials are configured
      if (clientId.isEmpty || secretKey.isEmpty) {
        throw Exception(
          'PayPal credentials not configured. Please add your PayPal Client ID and Secret Key to the .env file.',
        );
      }

      double finalPrice = selectedPlan.price;
      CouponDetails? couponDetails;

      // Validate and apply coupon if provided
      if (couponCode != null && couponCode.isNotEmpty) {
        couponDetails = await validateCoupon(couponCode, planPrice: selectedPlan.price);
        if (couponDetails.isValid) {
          finalPrice = selectedPlan.price - couponDetails.discountAmount;
        } else {
          throw Exception('Invalid coupon: ${couponDetails.message}');
        }
      }

      // Debug logging
      debugPrint('PayPal Service Debug:');
      debugPrint('- Client ID configured: ${clientId.isNotEmpty}');
      debugPrint('- Secret Key configured: ${secretKey.isNotEmpty}');
      debugPrint('- Environment: ${sandboxMode ? 'sandbox' : 'live'}');
      debugPrint('- Coupon applied: ${couponDetails?.code ?? 'none'}');
      debugPrint('- Final price: ₱${finalPrice.toStringAsFixed(2)}');

      // If price is 0 (100% discount), handle differently
      if (finalPrice <= 0) {
        debugPrint('- Free subscription path taken');
        // Directly update subscription without payment
        await _handleFreeSubscription(userId, couponDetails!, selectedPlan);
        return true;
      }

      // Navigate to PayPal checkout
      if (!context.mounted) return false;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => PaypalCheckoutView(
            sandboxMode: sandboxMode,
            clientId: clientId,
            secretKey: secretKey,
            transactions: [
              {
                "amount": {
                  "total": finalPrice.toStringAsFixed(2),
                  "currency": currency,
                },
                "description":
                    "Aurenna Premium ${selectedPlan.name} Subscription${couponDetails?.isValid == true ? ' (${couponDetails!.code} applied)' : ''}",
                "item_list": {
                  "items": [
                    {
                      "name": couponDetails?.isValid == true
                          ? "Aurenna Premium ${selectedPlan.name} - ${couponDetails!.code} (${couponDetails.discountPercentage.toStringAsFixed(0)}% OFF)"
                          : "Aurenna Premium - ${selectedPlan.name}",
                      "quantity": 1,
                      "price": finalPrice.toStringAsFixed(2),
                      "currency": currency,
                      "description": couponDetails?.isValid == true
                          ? "Premium subscription with ${couponDetails!.discountPercentage.toStringAsFixed(0)}% discount"
                          : "Unlimited premium tarot readings for ${selectedPlan.description}",
                    },
                  ],
                },
              },
            ],
            note: "Subscribe to Aurenna Premium for unlimited readings",
            onSuccess: (Map params) async {
              await _handlePaymentSuccess(
                params,
                userId,
                couponDetails,
                finalPrice,
                selectedPlan,
              );
              if (context.mounted) Navigator.pop(context, true);
            },
            onError: (error) {
              _handlePaymentError(error);
              if (context.mounted) Navigator.pop(context, false);
            },
            onCancel: () {
              debugPrint('Payment cancelled by user');
              if (context.mounted) Navigator.pop(context, false);
            },
          ),
        ),
      );

      return result == true;
    } catch (e) {
      debugPrint('PayPal subscription error: $e');
      return false;
    }
  }

  Future<void> _handleFreeSubscription(
    String userId,
    CouponDetails couponDetails,
    SubscriptionPlan selectedPlan,
  ) async {
    try {
      // Update user subscription status in Supabase with expiration
      final subscriptionEndDate = DateTime.now().add(
        Duration(days: selectedPlan.durationInDays),
      );
      await _supabase
          .from('users')
          .update({
            'subscription_status': 'paypal_active',
            'subscription_start_date': DateTime.now().toIso8601String(),
            'subscription_end_date': subscriptionEndDate.toIso8601String(),
            'subscription_plan': selectedPlan.planId,
            'payment_method': 'coupon',
            'paypal_payment_id':
                'COUPON_${couponDetails.code}_${DateTime.now().millisecondsSinceEpoch}',
            'paypal_payer_id': userId,
          })
          .eq('id', userId);

      // Store payment record
      await _supabase.from('payments').insert({
        'user_id': userId,
        'amount': 0,
        'original_amount': selectedPlan.price,
        'discount_amount': couponDetails.discountAmount,
        'coupon_code': couponDetails.code,
        'currency': currency,
        'payment_method': 'coupon',
        'payment_id':
            'COUPON_${couponDetails.code}_${DateTime.now().millisecondsSinceEpoch}',
        'payer_id': userId,
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Record coupon usage
      try {
        await _supabase.from('coupon_usage').insert({
          'user_id': userId,
          'coupon_code': couponDetails.code,
          'discount_amount': couponDetails.discountAmount,
          'used_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error recording coupon usage: $e');
      }

      // Refresh auth service subscription status
      await _authService.hasActiveSubscription();

      debugPrint(
        'Free subscription activated with coupon: ${couponDetails.code}',
      );
    } catch (e) {
      debugPrint('Error activating free subscription: $e');
      rethrow;
    }
  }

  Future<void> _handlePaymentSuccess(
    Map params,
    String userId,
    CouponDetails? couponDetails,
    double finalPrice,
    SubscriptionPlan selectedPlan,
  ) async {
    try {
      // Extract payment details
      final paymentId = params['paymentId'] ?? params['data']?['id'] ?? '';
      final payerId =
          params['PayerID'] ?? params['data']?['payer']?['payer_id'] ?? '';
      final status = params['status'] ?? 'completed';

      // Update user subscription status in Supabase with expiration
      final subscriptionEndDate = DateTime.now().add(
        Duration(days: selectedPlan.durationInDays),
      );
      await _supabase
          .from('users')
          .update({
            'subscription_status': 'paypal_active',
            'subscription_start_date': DateTime.now().toIso8601String(),
            'subscription_end_date': subscriptionEndDate.toIso8601String(),
            'subscription_plan': selectedPlan.planId,
            'payment_method': 'paypal',
            'paypal_payment_id': paymentId,
            'paypal_payer_id': payerId,
          })
          .eq('id', userId);

      // Store payment record
      await _supabase.from('payments').insert({
        'user_id': userId,
        'amount': finalPrice,
        'original_amount': selectedPlan.price,
        'discount_amount': couponDetails?.discountAmount ?? 0,
        'coupon_code': couponDetails?.code,
        'currency': currency,
        'payment_method': 'paypal',
        'payment_id': paymentId,
        'payer_id': payerId,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Record coupon usage if applicable
      if (couponDetails?.isValid == true) {
        try {
          await _supabase.from('coupon_usage').insert({
            'user_id': userId,
            'coupon_code': couponDetails!.code,
            'discount_amount': couponDetails.discountAmount,
            'used_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // Table might not exist, log and continue
          debugPrint('Error recording coupon usage: $e');
        }
      }

      // Refresh auth service subscription status
      await _authService.hasActiveSubscription();

      debugPrint('Payment successful! Payment ID: $paymentId');
    } catch (e) {
      debugPrint('Error updating subscription status: $e');
      rethrow;
    }
  }

  void _handlePaymentError(dynamic error) {
    debugPrint('PayPal payment error: $error');
  }

  // Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return false;

      // Update user subscription status
      await _supabase
          .from('users')
          .update({
            'subscription_status': 'free',
            'subscription_end_date': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Refresh auth service subscription status
      await _authService.hasActiveSubscription();

      return true;
    } catch (e) {
      debugPrint('Error canceling subscription: $e');
      return false;
    }
  }

  // Verify subscription status with PayPal
  Future<bool> verifySubscription() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return false;

      // Get user's PayPal subscription details from database
      final response = await _supabase
          .from('users')
          .select('paypal_payment_id, subscription_status')
          .eq('id', userId)
          .single();

      if (response['subscription_status'] == 'paypal_active') {
        // In production, you would verify with PayPal API
        // For now, trust the database status
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error verifying subscription: $e');
      return false;
    }
  }
}
