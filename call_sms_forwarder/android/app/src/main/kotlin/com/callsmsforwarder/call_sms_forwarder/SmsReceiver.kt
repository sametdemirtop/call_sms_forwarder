package com.callsmsforwarder.call_sms_forwarder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.telephony.SmsMessage
import io.flutter.plugin.common.EventChannel

class SmsReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == "android.provider.Telephony.SMS_RECEIVED") {
            val bundle: Bundle? = intent.extras
            if (bundle != null) {
                try {
                    val pdus = bundle["pdus"] as Array<*>
                    val messages = arrayOfNulls<SmsMessage>(pdus.size)
                    
                    for (i in messages.indices) {
                        messages[i] = SmsMessage.createFromPdu(pdus[i] as ByteArray)
                    }
                    
                    if (messages.isNotEmpty()) {
                        val sender = messages[0]?.originatingAddress ?: "Unknown"
                        val messageBody = StringBuilder()
                        
                        for (message in messages) {
                            messageBody.append(message?.messageBody)
                        }
                        
                        // Flutter'a SMS bilgisini gönder
                        SmsStreamHandler.sendSmsToFlutter(
                            mapOf(
                                "address" to sender,
                                "body" to messageBody.toString(),
                                "timestamp" to System.currentTimeMillis()
                            )
                        )
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }
}

object SmsStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun sendSmsToFlutter(smsData: Map<String, Any>) {
        eventSink?.success(smsData)
    }
}

