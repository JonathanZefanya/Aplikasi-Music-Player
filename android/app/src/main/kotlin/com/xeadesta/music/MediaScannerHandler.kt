package com.xeadesta.music

import android.content.Context
import android.media.MediaScannerConnection
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicInteger

/**
 * Asks Android to re-index files after the app rewrites their tags. Without
 * this the library keeps showing the metadata MediaStore cached earlier.
 */
class MediaScannerHandler(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.xeadesta.music/media_scanner"
        private const val TIMEOUT_MS = 8000L
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "scan") {
            result.notImplemented()
            return
        }

        val paths = call.argument<List<String>>("paths").orEmpty()

        if (paths.isEmpty()) {
            result.success(false)
            return
        }

        // Everything below touches `replied` on the main thread only.
        var replied = false
        val remaining = AtomicInteger(paths.size)

        val timeout = Runnable {
            if (!replied) {
                replied = true
                result.success(false)
            }
        }

        mainHandler.postDelayed(timeout, TIMEOUT_MS)

        try {
            MediaScannerConnection.scanFile(
                context,
                paths.toTypedArray(),
                null
            ) { _, _ ->
                if (remaining.decrementAndGet() == 0) {
                    mainHandler.post {
                        if (!replied) {
                            replied = true
                            mainHandler.removeCallbacks(timeout)
                            result.success(true)
                        }
                    }
                }
            }
        } catch (error: Exception) {
            mainHandler.removeCallbacks(timeout)

            if (!replied) {
                replied = true
                result.error("media_scanner", error.message, null)
            }
        }
    }
}
