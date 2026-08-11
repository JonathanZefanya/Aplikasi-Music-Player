package com.xeadesta.music

import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.view.KeyEvent
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class PlaybackTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            label = getString(R.string.tile_play_pause)
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        MediaButtons.send(this, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
    }
}
