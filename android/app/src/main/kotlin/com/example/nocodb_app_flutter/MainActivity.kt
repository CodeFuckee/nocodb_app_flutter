package com.example.nocodb_app_flutter

import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.mobile_portainer_flutter/channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "showToast") {
                val message = call.arguments as? String
                Toast.makeText(applicationContext, message, Toast.LENGTH_SHORT).show()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}