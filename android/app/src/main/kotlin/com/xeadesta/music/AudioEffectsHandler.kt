package com.xeadesta.music

import android.media.audiofx.BassBoost
import android.media.audiofx.PresetReverb
import android.media.audiofx.Virtualizer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges Android's AudioEffect API to Flutter. just_audio only exposes the
 * equalizer and the loudness enhancer, so bass boost, virtualizer and reverb
 * have to be attached to the player's audio session from here.
 */
class AudioEffectsHandler : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.xeadesta.music/audio_effects"
        private const val PRIORITY = 0
        private const val MAX_STRENGTH = 1000
    }

    private var sessionId = 0
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var presetReverb: PresetReverb? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "attach" -> {
                    attach(call.argument<Int>("sessionId") ?: 0)
                    result.success(true)
                }
                "capabilities" -> result.success(capabilities())
                "setBassBoostEnabled" -> {
                    bassBoost?.enabled = call.argument<Boolean>("enabled") ?: false
                    result.success(true)
                }
                "setBassBoostStrength" -> {
                    bassBoost?.setStrength(strengthOf(call))
                    result.success(true)
                }
                "setVirtualizerEnabled" -> {
                    virtualizer?.enabled = call.argument<Boolean>("enabled") ?: false
                    result.success(true)
                }
                "setVirtualizerStrength" -> {
                    virtualizer?.setStrength(strengthOf(call))
                    result.success(true)
                }
                "setReverbEnabled" -> {
                    presetReverb?.enabled = call.argument<Boolean>("enabled") ?: false
                    result.success(true)
                }
                "setReverbPreset" -> {
                    val preset = (call.argument<Int>("preset") ?: 0)
                        .coerceIn(0, PresetReverb.PRESET_PLATE.toInt())
                    presetReverb?.preset = preset.toShort()
                    result.success(true)
                }
                "release" -> {
                    release()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            // Effects are unavailable on some devices and throw on creation or
            // when the session goes away. Never crash the app for that.
            result.error("audio_effects", error.message, null)
        }
    }

    private fun strengthOf(call: MethodCall): Short {
        val raw = call.argument<Int>("strength") ?: 0
        return raw.coerceIn(0, MAX_STRENGTH).toShort()
    }

    private fun attach(newSessionId: Int) {
        if (newSessionId == 0) {
            return
        }

        if (newSessionId == sessionId && bassBoost != null) {
            return
        }

        release()
        sessionId = newSessionId

        bassBoost = try {
            BassBoost(PRIORITY, newSessionId)
        } catch (error: Exception) {
            null
        }

        virtualizer = try {
            Virtualizer(PRIORITY, newSessionId)
        } catch (error: Exception) {
            null
        }

        presetReverb = try {
            PresetReverb(PRIORITY, newSessionId)
        } catch (error: Exception) {
            null
        }
    }

    private fun capabilities(): Map<String, Boolean> {
        return mapOf(
            "bassBoost" to (bassBoost?.strengthSupported ?: false),
            "virtualizer" to (virtualizer?.strengthSupported ?: false),
            "reverb" to (presetReverb != null)
        )
    }

    fun release() {
        try {
            bassBoost?.release()
            virtualizer?.release()
            presetReverb?.release()
        } catch (error: Exception) {
            // ignore
        }

        bassBoost = null
        virtualizer = null
        presetReverb = null
        sessionId = 0
    }
}
