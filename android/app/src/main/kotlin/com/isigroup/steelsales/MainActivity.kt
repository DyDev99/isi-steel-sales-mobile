package com.isigroup.steelsales

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {

    private companion object {
        /** Must match `SapNativeTransport.channelName` on the Dart side. */
        const val CHANNEL = "isi/sap_native_transport"
        const val DEFAULT_TIMEOUT_MS = 20_000
    }

    private val scope = CoroutineScope(Dispatchers.Main)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "send" -> handleSend(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleSend(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
    ) {
        val method = call.argument<String>("method")
        val url = call.argument<String>("url")
        val pin = call.argument<String>("pin")
        val headers = call.argument<Map<String, String>>("headers") ?: emptyMap()
        val body = call.argument<String>("body")
        val timeout = call.argument<Int>("timeoutMs") ?: DEFAULT_TIMEOUT_MS

        if (method.isNullOrBlank() || url.isNullOrBlank() || pin.isNullOrBlank()) {
            result.error("ARGS", "method, url and pin are required", null)
            return
        }

        // Network work must leave the main thread (Android throws
        // NetworkOnMainThreadException otherwise); the MethodChannel reply must
        // then be delivered back on Main.
        scope.launch {
            val response = withContext(Dispatchers.IO) {
                SapNativeHttpClient.send(method, url, headers, body, pin, timeout)
            }
            result.success(
                mapOf(
                    "statusCode" to response.statusCode,
                    "body" to response.body,
                    "headers" to response.headers,
                    "error" to response.error,
                )
            )
        }
    }
}
