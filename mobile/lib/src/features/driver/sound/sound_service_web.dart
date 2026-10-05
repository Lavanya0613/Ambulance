import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class SoundService {
  void playNotificationSound() {
    try {
      final audio = html.AudioElement('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3');
      audio.play().catchError((e) {
        debugPrint('Audio play blocked by browser policy: $e');
      });
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  void vibrate() {
    try {
      (html.window.navigator as dynamic).vibrate?.call(500);
    } catch (e) {
      debugPrint('Vibration not supported: $e');
    }
  }
}
