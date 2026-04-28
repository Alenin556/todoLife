package com.example.todolife

import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
  private val channel = "todolife/privacy"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
      when (call.method) {
        "setSecure" -> {
          val args = call.arguments as? Map<*, *>
          val enabled = (args?.get("enabled") as? Boolean) ?: true
          if (enabled) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
          } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
          }
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }
  }
}
