package com.example.tech4girls

import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tech4girls/sms")
            .setMethodCallHandler { call, result ->
                if (call.method != "sendSms") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val phoneNumber = call.argument<String>("phoneNumber")
                val message = call.argument<String>("message")
                if (phoneNumber.isNullOrBlank() || message.isNullOrBlank()) {
                    result.error("INVALID_ARGS", "phoneNumber or message is missing", null)
                    return@setMethodCallHandler
                }

                try {
                    val smsManager = SmsManager.getDefault()
                    smsManager.sendTextMessage(phoneNumber, null, message, null, null)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SMS_SEND_FAILED", e.message, null)
                }
            }
    }
}
