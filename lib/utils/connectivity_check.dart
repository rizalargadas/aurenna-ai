import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityCheck {
  static Future<bool> hasInternetConnection() async {
    try {
      // First check if device has any network connection
      final connectivityResult = await Connectivity().checkConnectivity();
      if (kDebugMode) {
        print('Connectivity result: $connectivityResult');
      }

      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Then verify actual internet access (not just network connection)
      try {
        final result = await InternetAddress.lookup('google.com').timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            if (kDebugMode) print('Internet lookup timeout');
            return [];
          },
        );
        final hasInternet =
            result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        if (kDebugMode) print('Internet check result: $hasInternet');
        return hasInternet;
      } catch (e) {
        if (kDebugMode) print('Internet check error: $e');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Connectivity check error: $e');
      return false;
    }
  }

  static Future<void> checkConnectivityWithError() async {
    if (kDebugMode) print('Starting connectivity check...');

    // Add a small delay to allow network state to update
    await Future.delayed(const Duration(milliseconds: 500));

    // First do a quick connectivity check
    final connectivityResult = await Connectivity().checkConnectivity();
    if (kDebugMode) print('Quick check result: $connectivityResult');

    if (connectivityResult == ConnectivityResult.none) {
      throw Exception(
        'No internet connection. Please check your network settings and try again.',
      );
    }

    // Then verify actual internet access
    for (int i = 0; i < 3; i++) {
      if (kDebugMode) print('Internet check attempt ${i + 1}');
      final hasInternet = await hasInternetConnection();
      if (hasInternet) {
        if (kDebugMode) print('Internet connection confirmed!');
        return; // Connection found!
      }
      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // If we get here, no connection after 3 attempts
    throw Exception(
      'No internet connection. Please check your network settings and try again.',
    );
  }
}
