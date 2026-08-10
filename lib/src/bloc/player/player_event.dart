part of 'player_bloc.dart';

@immutable
sealed class PlayerEvent {}

class PlayerPlay extends PlayerEvent {}

class PlayerLoadSongs extends PlayerEvent {
  final List<SongModel> playlist;
  final MediaItem mediaItem;

  PlayerLoadSongs(
    this.playlist,
    this.mediaItem,
  );
}

class PlayerPause extends PlayerEvent {}

class PlayerStop extends PlayerEvent {}

class PlayerSeek extends PlayerEvent {
  final Duration position;
  final int? index;

  PlayerSeek(this.position, {this.index});
}

class PlayerNext extends PlayerEvent {}

class PlayerPrevious extends PlayerEvent {}

class PlayerShuffle extends PlayerEvent {}

class PlayerSetVolume extends PlayerEvent {
  final double volume;

  PlayerSetVolume(this.volume);
}

class PlayerSetSpeed extends PlayerEvent {
  final double speed;

  PlayerSetSpeed(this.speed);
}

class PlayerSetLoopMode extends PlayerEvent {
  final LoopMode loopMode;

  PlayerSetLoopMode(this.loopMode);
}

class PlayerSetShuffleModeEnabled extends PlayerEvent {
  final bool shuffleModeEnabled;

  PlayerSetShuffleModeEnabled(this.shuffleModeEnabled);
}

class PlayerAddToQueue extends PlayerEvent {
  final SongModel song;

  PlayerAddToQueue(this.song);
}

class PlayerAddAllToQueue extends PlayerEvent {
  final List<SongModel> songs;

  PlayerAddAllToQueue(this.songs);
}

class PlayerPlayNext extends PlayerEvent {
  final SongModel song;

  PlayerPlayNext(this.song);
}

class PlayerRemoveFromQueue extends PlayerEvent {
  final int index;

  PlayerRemoveFromQueue(this.index);
}

class PlayerMoveInQueue extends PlayerEvent {
  final int oldIndex;
  final int newIndex;

  PlayerMoveInQueue(this.oldIndex, this.newIndex);
}

class PlayerClearQueue extends PlayerEvent {}

class PlayerSetPitch extends PlayerEvent {
  final double pitch;

  PlayerSetPitch(this.pitch);
}

class PlayerSetSleepTimer extends PlayerEvent {
  final Duration? duration;

  PlayerSetSleepTimer(this.duration);
}
