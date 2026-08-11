package com.xeadesta.music

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.KeyEvent
import android.widget.RemoteViews

class MusicWidgetProvider : AppWidgetProvider() {

    companion object {
        const val PREFS = "music_widget"
        const val KEY_TITLE = "title"
        const val KEY_ARTIST = "artist"
        const val KEY_PLAYING = "playing"

        private const val ACTION_PREVIOUS = "com.xeadesta.music.WIDGET_PREVIOUS"
        private const val ACTION_PLAY_PAUSE = "com.xeadesta.music.WIDGET_PLAY_PAUSE"
        private const val ACTION_NEXT = "com.xeadesta.music.WIDGET_NEXT"

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, MusicWidgetProvider::class.java)
            )

            for (id in ids) {
                render(context, manager, id)
            }
        }

        private fun render(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val title = prefs.getString(KEY_TITLE, null)
            val artist = prefs.getString(KEY_ARTIST, null)
            val playing = prefs.getBoolean(KEY_PLAYING, false)

            val views = RemoteViews(context.packageName, R.layout.music_widget)

            views.setTextViewText(
                R.id.widget_title,
                title ?: context.getString(R.string.widget_nothing_playing)
            )
            views.setTextViewText(R.id.widget_artist, artist ?: "")
            views.setImageViewResource(
                R.id.widget_play_pause,
                if (playing) R.drawable.ic_widget_pause else R.drawable.ic_widget_play
            )

            views.setOnClickPendingIntent(
                R.id.widget_previous,
                broadcast(context, ACTION_PREVIOUS, 1)
            )
            views.setOnClickPendingIntent(
                R.id.widget_play_pause,
                broadcast(context, ACTION_PLAY_PAUSE, 2)
            )
            views.setOnClickPendingIntent(
                R.id.widget_next,
                broadcast(context, ACTION_NEXT, 3)
            )

            val open = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }

            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getActivity(
                    context,
                    0,
                    open,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )

            manager.updateAppWidget(widgetId, views)
        }

        private fun broadcast(
            context: Context,
            action: String,
            requestCode: Int
        ): PendingIntent {
            val intent = Intent(context, MusicWidgetProvider::class.java).apply {
                this.action = action
            }

            return PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            render(context, appWidgetManager, widgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_PREVIOUS ->
                MediaButtons.send(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS)
            ACTION_PLAY_PAUSE ->
                MediaButtons.send(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
            ACTION_NEXT ->
                MediaButtons.send(context, KeyEvent.KEYCODE_MEDIA_NEXT)
        }
    }
}
