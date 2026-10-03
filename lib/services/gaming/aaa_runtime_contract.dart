import 'dart:async';
import 'package:flutter/services.dart';

/// Production contract for the native/embedded AUREN 3D runtime.
///
/// The Flutter layer owns account, social, store and meta-game systems.
/// The runtime owns frame rendering, physics, animation, gameplay and VFX.
class AaaRuntimeContract {
  static const method = MethodChannel('com.auren.games/3d_runtime');
  static const events = EventChannel('com.auren.games/3d_runtime/events');

  static Future<bool> available() async {
    try {
      return await method.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> launch({
    required String gameId,
    String quality = 'adaptive',
    String? saveId,
  }) async {
    await method.invokeMethod('launch', {
      'gameId': gameId,
      'quality': quality,
      if (saveId != null) 'saveId': saveId,
    });
  }

  static Future<void> command(String gameId, String command, [Map<String, dynamic>? data]) async {
    await method.invokeMethod('command', {
      'gameId': gameId,
      'command': command,
      if (data != null) 'data': data,
    });
  }

  static Stream<Map<String, dynamic>> eventStream() {
    return events.receiveBroadcastStream().map((raw) {
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return <String, dynamic>{'type': 'unknown', 'value': raw};
    });
  }
}
