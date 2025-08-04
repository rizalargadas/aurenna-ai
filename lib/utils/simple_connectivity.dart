import 'package:http/http.dart' as http;

class SimpleConnectivity {
  static Future<bool> checkInternet() async {
    try {
      // Try a simple HTTP HEAD request to a reliable endpoint
      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Timeout'),
          );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<void> ensureInternet() async {
    final hasInternet = await checkInternet();
    if (!hasInternet) {
      throw Exception(
        'No internet connection. Please check your network settings and try again.',
      );
    }
  }
}
