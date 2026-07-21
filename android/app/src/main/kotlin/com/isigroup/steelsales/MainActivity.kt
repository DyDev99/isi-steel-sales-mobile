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
    }

    private val scope = CoroutineScope(Dispatchers.Main)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "post" -> handlePost(call.argument("url"),
                        call.argument("body"),
                        call.argument("pin"),
                        result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handlePost(
        url: String?,
        body: String?,
        pin: String?,
        result: MethodChannel.Result,
    ) {
        if (url.isNullOrBlank() || pin.isNullOrBlank()) {
            result.error("ARGS", "url and pin are required", null)
            return
        }

        // Network work must not run on the main thread — Android throws
        // NetworkOnMainThreadException — so it is dispatched to IO and the
        // result is posted back on Main, which is where the MethodChannel
        // reply must be delivered from.
        scope.launch {
            val response = withContext(Dispatchers.IO) {
                SapTlsProbe.post(url, body ?: "{}", pin)
            }
            result.success(
                mapOf(
                    "statusCode" to response.statusCode,
                    "body" to response.body,
                    "error" to response.error,
                )
            )
        }
    }
}
