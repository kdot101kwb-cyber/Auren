package com.auren.auren

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nova/wifi")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openWifiSettings" -> try {
                        startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("WIFI_SETTINGS_FAILED", error.message, null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
