package com.callsmsforwarder.call_sms_forwarder

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val SMS_CHANNEL = "com.callsmsforwarder/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setStreamHandler(SmsStreamHandler)
    }
}
