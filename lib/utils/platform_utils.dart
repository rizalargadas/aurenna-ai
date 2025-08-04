import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  static bool get isWeb => kIsWeb;

  // Shorter timeouts for mobile devices
  static Duration get networkTimeout {
    if (isMobile) {
      return const Duration(seconds: 15); // Shorter for mobile
    }
    return const Duration(seconds: 30); // Original for desktop/web
  }

  static Duration get connectivityCheckTimeout {
    if (isMobile) {
      return const Duration(seconds: 3);
    }
    return const Duration(seconds: 5);
  }
}
