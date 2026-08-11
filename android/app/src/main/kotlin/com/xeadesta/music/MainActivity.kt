package com.xeadesta.music

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Must extend AudioServiceActivity so just_audio_background keeps working.
class MainActivity : AudioServiceActivity() {

    companion object {
        private const val WIDGET_CHANNEL = "com.xeadesta.music/widget"
    }

    private var audioEffects: AudioEffectsHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val handler = AudioEffectsHandler()
        audioEffects = handler

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AudioEffectsHandler.CHANNEL
        ).setMethodCallHandler(handler)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "update") {
                getSharedPreferences(MusicWidgetProvider.PREFS, MODE_PRIVATE)
                    .edit()
                    .putString(
                        MusicWidgetProvider.KEY_TITLE,
                        call.argument<String>("title")
                    )
                    .putString(
                        MusicWidgetProvider.KEY_ARTIST,
                        call.argument<String>("artist")
                    )
                    .putBoolean(
                        MusicWidgetProvider.KEY_PLAYING,
                        call.argument<Boolean>("playing") ?: false
                    )
                    .apply()

                MusicWidgetProvider.refresh(this)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        audioEffects?.release()
        audioEffects = null
        super.onDestroy()
    }
}
