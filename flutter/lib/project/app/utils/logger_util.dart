import 'package:flutter/foundation.dart';

class LoggerUtil {
  static void log(String tag, String message) {
    if (kDebugMode) {
      final now = DateTime.now();
      final timeString =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
      print('[$timeString] [$tag] $message');
    }
  }
}
