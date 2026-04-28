package com.codepluscircle.chatbotapp

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val channelName = "orbit/external_actions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    result.success(openUrl(url))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openUrl(url: String): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (url.contains("google.com/maps") || url.startsWith("geo:")) {
            intent.setPackage("com.google.android.apps.maps")
            try {
                startActivity(intent)
                return true
            } catch (_: ActivityNotFoundException) {
                intent.setPackage(null)
            }
        }
        return try {
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }
}
