import 'package:flutter/services.dart';

class VibrationService {
  static const _channel = MethodChannel('mpfh/vibration');

  static Future<void> vibrate({int durationMs = 200}) async {
    try {
      await _channel.invokeMethod<void>('vibrate', {
        'duration': durationMs.toDouble(),
      });
    } catch (e) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }
  }
}