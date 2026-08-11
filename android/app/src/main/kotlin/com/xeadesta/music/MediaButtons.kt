package com.xeadesta.music

import android.content.Context
import android.content.Intent
import android.view.KeyEvent
import com.ryanheise.audioservice.MediaButtonReceiver

/**
 * Sends media button events straight to audio_service's receiver instead of
 * broadcasting them system wide, so the event always lands on this app.
 */
object MediaButtons {

    fun send(context: Context, keyCode: Int) {
        dispatch(context, KeyEvent.ACTION_DOWN, keyCode)
        dispatch(context, KeyEvent.ACTION_UP, keyCode)
    }

    private fun dispatch(context: Context, action: Int, keyCode: Int) {
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            setClass(context, MediaButtonReceiver::class.java)
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(action, keyCode))
        }

        context.sendBroadcast(intent)
    }
}
