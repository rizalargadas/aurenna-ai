import 'package:pay/pay.dart';
import 'dart:developer' as developer;

class GooglePayService {
  static final Future<PaymentConfiguration> _googlePayConfigFuture = 
      PaymentConfiguration.fromAsset('google_pay.json');

  static final Future<PaymentConfiguration> _applePayConfigFuture = 
      PaymentConfiguration.fromAsset('apple_pay.json');

  static Future<PaymentConfiguration> get googlePayConfig => _googlePayConfigFuture;

  static Future<PaymentConfiguration> get applePayConfig => _applePayConfigFuture;

  static List<PaymentItem> getPaymentItems(String serviceName, double amount) {
    return [
      PaymentItem(
        label: serviceName,
        amount: amount.toStringAsFixed(2),
        status: PaymentItemStatus.final_price,
      ),
    ];
  }

  static void onGooglePayResult(Map<String, dynamic> result) {
    // Process the payment result
    developer.log('Google Pay Result: $result', name: 'GooglePayService');
    // Here you would typically:
    // 1. Send the payment token to your backend
    // 2. Process the payment on your server
    // 3. Return the result to the user
  }

  static void onApplePayResult(Map<String, dynamic> result) {
    // Process the payment result
    developer.log('Apple Pay Result: $result', name: 'GooglePayService');
    // Here you would typically:
    // 1. Send the payment token to your backend
    // 2. Process the payment on your server
    // 3. Return the result to the user
  }
}