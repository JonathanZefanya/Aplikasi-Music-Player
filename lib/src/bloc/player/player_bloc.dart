import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/data/repositories/player_repository.dart';

part 'player_event.dart';
part 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc({required MusicPlayer repository}) : super(PlayerInitial()) {
    on<PlayerLoadSongs>((event, emit) async {
      try {
        emit(PlayerLoading());
        await repository.load(event.mediaItem, event.playlist);
        emit(PlayerSongsLoaded());
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });
    on<PlayerPlay>((event, emit) async {
      try {
        await repository.play();
        emit(PlayerPlaying());
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerPause>((event, emit) async {
      try {
        await repository.pause();
        emit(PlayerPaused());
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerStop>((event, emit) async {
      try {
        await repository.stop();
        emit(PlayerStopped());
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerSeek>((event, emit) async {
      try {
        await repository.seek(event.position, index: event.index);
        emit(PlayerSeeked(event.position));
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerNext>((event, emit) async {
      try {
        await repository.seekToNext();
        emit(PlayerNexted());
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerPrevious>((event, emit) async {
      try {
        await repository.seekToPrevious();
        emit(PlayerPrevioussed());
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerSetVolume>((event, emit) async {
      try {
        await repository.setVolume(event.volume);
        emit(PlayerVolumeSet(event.volume));
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerSetSpeed>((event, emit) async {
      try {
        await repository.setSpeed(event.speed);
        emit(PlayerSpeedSet(event.speed));
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerSetLoopMode>((event, emit) async {
      try {
        await repository.setLoopMode(event.loopMode);
        emit(PlayerLoopModeSet(event.loopMode));
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerSetShuffleModeEnabled>((event, emit) async {
      try {
        await repository.setShuffleModeEnabled(event.shuffleModeEnabled);
        emit(PlayerShuffleModeEnabledSet(event.shuffleModeEnabled));
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerAddToQueue>((event, emit) async {
      try {
        await repository.addToQueue(event.song);
        emit(PlayerQueueUpdated('Added to queue'));
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerAddAllToQueue>((event, emit) async {
      try {
        await repository.addAllToQueue(event.songs);
        emit(
          PlayerQueueUpdated(
            '${event.songs.length} songs added to queue',
          ),
        );
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerPlayNext>((event, emit) async {
      try {
        await repository.playNext(event.song);
        emit(PlayerQueueUpdated('Playing next'));
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerRemoveFromQueue>((event, emit) async {
      try {
        await repository.removeFromQueue(event.index);
        emit(PlayerQueueUpdated('Removed from queue'));
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerMoveInQueue>((event, emit) async {
      try {
        await repository.moveInQueue(event.oldIndex, event.newIndex);
        emit(PlayerQueueUpdated('Queue reordered'));
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerClearQueue>((event, emit) async {
      try {
        await repository.clearQueue();
        emit(PlayerQueueUpdated('Queue cleared'));
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerSetPitch>((event, emit) async {
      try {
        await repository.setPitch(event.pitch);
        emit(PlayerPitchSet(event.pitch));
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });

    on<PlayerSetSleepTimer>((event, emit) async {
      try {
        await repository.setSleepTimer(event.duration);
        emit(PlayerSleepTimerSet(event.duration));
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    });
  }
}
