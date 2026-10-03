import 'dart:async';
import 'package:flutter/services.dart';

/// Boundary between the AUREN Flutter shell and a production 3D game runtime.
class Auren3dRuntimeBridge {
  static const _channel = MethodChannel('com.auren.games/3d_runtime');
  static Future<bool> isAvailable() async {
    try { return await _channel.invokeMethod<bool>('isAvailable') ?? false; }
    on MissingPluginException { return false; } on PlatformException { return false; }
  }
  static Future<void> launch({required String gameId, String? saveId, String quality='adaptive'}) async {
    await _channel.invokeMethod<void>('launch', {'gameId':gameId,'saveId':saveId,'quality':quality});
  }
  static Future<void> pause(String gameId) async => _channel.invokeMethod<void>('pause', {'gameId':gameId});
  static Future<void> resume(String gameId) async => _channel.invokeMethod<void>('resume', {'gameId':gameId});
  static Future<void> close(String gameId) async => _channel.invokeMethod<void>('close', {'gameId':gameId});
  static Stream<Map<String,dynamic>> events() {
    const channel=EventChannel('com.auren.games/3d_runtime/events');
    return channel.receiveBroadcastStream().map((event)=>event is Map ? Map<String,dynamic>.from(event) : {'type':'unknown','value':event});
  }
}