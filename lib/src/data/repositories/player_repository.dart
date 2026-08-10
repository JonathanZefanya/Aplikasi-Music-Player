import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:audio_session/audio_session.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/data/repositories/song_repository.dart';
import 'package:music/src/data/repositories/stats_repository.dart';
import 'package:music/src/data/services/hive_box.dart';
import 'package:on_audio_query/on_audio_query.dart';

extension SequenceStateExtension on SequenceState? {
  MediaItem? get currentMediaItem {
    final SequenceState? state = this;

    if (state == null) {
      return null;
    }

    final int index = state.currentIndex;

    if (index < 0 || index >= state.sequence.length) {
      return null;
    }

    return state.sequence[index].tag as MediaItem?;
  }
}

abstract class MusicPlayer {
  Future<void> init();
  Future<void> load(
    MediaItem mediaItem,
    List<SongModel> playlist,
  );
  MediaItem getMediaItemFromSong(SongModel song);
  Future<void> savePlaylist();
  Future<List<SongModel>> loadPlaylist();
  Future<void> setSequenceFromPlaylist(
    List<SongModel> playlist,
    SongModel lastPlayedSong,
  );
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position, {int? index});
  Future<void> seekToNext();
  Future<void> seekToPrevious();
  Stream<Duration> get position;
  Stream<Duration?> get duration;
  Stream<bool> get shuffleModeEnabled;
  Stream<LoopMode> get loopMode;
  Stream<bool> get playing;
  Stream<int?> get currentIndex;
  Stream<SequenceState?> get sequenceState;
  List<SongModel> get playlist;
  Stream<ProcessingState> get processingStateStream;
  Future<void> dispose();
  Future<void> setVolume(double volume);
  Future<void> setSpeed(double speed);
  Future<void> setShuffleModeEnabled(bool enabled);
  Future<void> setLoopMode(LoopMode loopMode);
  Future<void> addToQueue(SongModel song);
  Future<void> addAllToQueue(List<SongModel> songs);
  Future<void> playNext(SongModel song);
  Future<void> removeFromQueue(int index);
  Future<void> moveInQueue(int oldIndex, int newIndex);
  Future<void> clearQueue();
  Stream<List<SongModel>> get queueStream;
  Future<void> setPitch(double pitch);
  Future<void> setSleepTimer(Duration? duration);
  Stream<Duration?> get sleepTimerStream;
  Duration? get sleepTimerRemaining;
  double get speed;
  double get pitch;
}

class JustAudioPlayer implements MusicPlayer {
  final AudioPlayer _player = AudioPlayer();
  List<SongModel> currentPlaylist = [];
  ConcatenatingAudioSource _queue = ConcatenatingAudioSource(children: []);

  final StreamController<List<SongModel>> _queueController =
      StreamController<List<SongModel>>.broadcast();

  final StreamController<Duration?> _sleepTimerController =
      StreamController<Duration?>.broadcast();

  Timer? _sleepTimer;
  DateTime? _sleepTimerEndsAt;

  double _volume = 1.0;
  bool _pausedByDisconnect = false;
  Duration _lastSavedPosition = Duration.zero;

  final StatsRepository _stats = StatsRepository();
  String? _statsSongId;
  DateTime? _statsSince;

  var box = Hive.box(HiveBox.boxName);

  Duration get _fadeDuration => Duration(
        milliseconds: box.get(HiveBox.fadeDurationKey, defaultValue: 0) as int,
      );

  @override
  double get speed =>
      (box.get(HiveBox.speedKey, defaultValue: 1.0) as num).toDouble();

  @override
  double get pitch =>
      (box.get(HiveBox.pitchKey, defaultValue: 1.0) as num).toDouble();

  @override
  Future<void> init() async {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.xeadesta.music.channel.audio',
      androidNotificationChannelName: 'music',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      // background tidak boleh transparan
      notificationColor: _getNotificationColor(),
    );

    // subscribe to changes in playback state to add to the recently played
    _player.playbackEventStream.listen((event) {
      if (event.currentIndex != null && currentPlaylist.isNotEmpty) {
        String songId = currentPlaylist[event.currentIndex!].id.toString();
        SongRepository().addToRecentlyPlayed(songId);
      }
    });

    _player.positionStream.listen(_rememberPosition);

    _player.currentIndexStream.distinct().listen(_trackSongChange);

    _player.playingStream.listen((playing) {
      if (playing) {
        _statsSince ??= DateTime.now();
      } else {
        _flushListeningTime();
      }
    });

    await _player.setSpeed(speed);

    if (Platform.isAndroid) {
      await _player.setPitch(pitch);
    }

    await _listenToAudioDevices();

    // set loop mode
    if (box.get(HiveBox.loopModeKey) != null) {
      _player.setLoopMode(LoopMode.values[box.get(HiveBox.loopModeKey)]);
    }

    // set shuffle mode
    if (box.get(HiveBox.shuffleModeKey) != null) {
      _player.setShuffleModeEnabled(
        box.get(HiveBox.shuffleModeKey),
      );
    }
  }

  // JustAudioBackground.init hanya menerima notificationColor sekali saat startup,
  // jadi warna notifikasi mengikuti tema aplikasi, bukan album yang sedang diputar.
  Color _getNotificationColor() {
    return Themes.getTheme().primaryColor;
  }

  AudioSource _buildAudioSource(SongModel song) {
    var artUri = 'content://media/external/audio/albumart/';

    if (song.albumId != null) {
      artUri += song.albumId.toString();
    }

    return AudioSource.uri(
      Uri.parse(song.uri!),
      tag: MediaItem(
        id: song.id.toString(),
        title: song.title,
        album: song.album,
        artUri: Platform.isAndroid ? Uri.parse(artUri) : null,
        artist: song.artist,
        duration: Duration(milliseconds: song.duration!),
        genre: song.genre,
      ),
    );
  }

  void _notifyQueue() {
    _queueController.add(List<SongModel>.unmodifiable(currentPlaylist));
  }

  @override
  Stream<List<SongModel>> get queueStream => _queueController.stream;

  @override
  Future<void> addToQueue(SongModel song) async {
    if (currentPlaylist.isEmpty) {
      await load(getMediaItemFromSong(song), [song], play: false);
      return;
    }

    await _queue.add(_buildAudioSource(song));
    currentPlaylist.add(song);
    await savePlaylist();
    _notifyQueue();
  }

  @override
  Future<void> addAllToQueue(List<SongModel> songs) async {
    if (songs.isEmpty) {
      return;
    }

    if (currentPlaylist.isEmpty) {
      await load(
        getMediaItemFromSong(songs.first),
        List<SongModel>.of(songs),
        play: false,
      );
      return;
    }

    await _queue.addAll(songs.map(_buildAudioSource).toList());
    currentPlaylist.addAll(songs);
    await savePlaylist();
    _notifyQueue();
  }

  @override
  Future<void> playNext(SongModel song) async {
    if (currentPlaylist.isEmpty) {
      await load(getMediaItemFromSong(song), [song], play: false);
      return;
    }

    final int target =
        ((_player.currentIndex ?? -1) + 1).clamp(0, currentPlaylist.length);

    await _queue.insert(target, _buildAudioSource(song));
    currentPlaylist.insert(target, song);
    await savePlaylist();
    _notifyQueue();
  }

  @override
  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= currentPlaylist.length) {
      return;
    }

    await _queue.removeAt(index);
    currentPlaylist.removeAt(index);
    await savePlaylist();
    _notifyQueue();
  }

  @override
  Future<void> moveInQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= currentPlaylist.length) {
      return;
    }

    final int target = newIndex.clamp(0, currentPlaylist.length - 1);
    if (oldIndex == target) {
      return;
    }

    await _queue.move(oldIndex, target);
    currentPlaylist.insert(target, currentPlaylist.removeAt(oldIndex));
    await savePlaylist();
    _notifyQueue();
  }

  @override
  Future<void> clearQueue() async {
    await _player.stop();
    await _queue.clear();
    currentPlaylist.clear();
    await savePlaylist();
    _notifyQueue();
  }

  Future<void> _listenToAudioDevices() async {
    final AudioSession session = await AudioSession.instance;

    session.becomingNoisyEventStream.listen((_) async {
      final bool enabled =
          box.get(HiveBox.pauseOnDisconnectKey, defaultValue: true) as bool;

      if (!enabled || !_player.playing) {
        return;
      }

      _pausedByDisconnect = true;
      await pause();
    });

    session.devicesChangedEventStream.listen((event) async {
      final bool enabled =
          box.get(HiveBox.resumeOnReconnectKey, defaultValue: true) as bool;

      if (!enabled || !_pausedByDisconnect || _player.playing) {
        return;
      }

      final bool reconnected = event.devicesAdded.any(
        (device) =>
            device.type == AudioDeviceType.bluetoothA2dp ||
            device.type == AudioDeviceType.bluetoothLe ||
            device.type == AudioDeviceType.wiredHeadset ||
            device.type == AudioDeviceType.wiredHeadphones,
      );

      if (reconnected) {
        _pausedByDisconnect = false;
        await play();
      }
    });
  }

  Future<void> _trackSongChange(int? index) async {
    await _flushListeningTime();

    if (index == null ||
        currentPlaylist.isEmpty ||
        index >= currentPlaylist.length) {
      _statsSongId = null;
      return;
    }

    _statsSongId = currentPlaylist[index].id.toString();
    _statsSince = _player.playing ? DateTime.now() : null;

    await _stats.incrementPlayCount(_statsSongId!);
  }

  Future<void> _flushListeningTime() async {
    final String? songId = _statsSongId;
    final DateTime? since = _statsSince;

    _statsSince = null;

    if (songId == null || since == null) {
      return;
    }

    final Duration listened = DateTime.now().difference(since);

    if (listened < const Duration(seconds: 1)) {
      return;
    }

    await _stats.addListeningTime(songId, listened);
  }

  void _rememberPosition(Duration position) {
    if (currentPlaylist.isEmpty || _player.currentIndex == null) {
      return;
    }

    if ((position - _lastSavedPosition).abs() < const Duration(seconds: 5)) {
      return;
    }

    _lastSavedPosition = position;

    final Map<dynamic, dynamic> positions = Map<dynamic, dynamic>.from(
      box.get(HiveBox.playbackPositionsKey, defaultValue: {}) as Map,
    );

    positions[currentPlaylist[_player.currentIndex!].id.toString()] =
        position.inMilliseconds;

    box.put(HiveBox.playbackPositionsKey, positions);
  }

  Duration _savedPositionOf(SongModel song) {
    final Map<dynamic, dynamic> positions = Map<dynamic, dynamic>.from(
      box.get(HiveBox.playbackPositionsKey, defaultValue: {}) as Map,
    );

    final int? saved = positions[song.id.toString()] as int?;

    return saved == null ? Duration.zero : Duration(milliseconds: saved);
  }

  Future<void> _fade(double from, double to) async {
    const int steps = 16;
    final int stepMs = (_fadeDuration.inMilliseconds / steps).round();

    for (int step = 1; step <= steps; step++) {
      await Future<void>.delayed(Duration(milliseconds: stepMs));
      await _player.setVolume(from + (to - from) * (step / steps));
    }
  }

  @override
  Future<void> setPitch(double pitch) async {
    await box.put(HiveBox.pitchKey, pitch);

    if (Platform.isAndroid) {
      await _player.setPitch(pitch);
    }
  }

  @override
  Stream<Duration?> get sleepTimerStream => _sleepTimerController.stream;

  @override
  Duration? get sleepTimerRemaining {
    if (_sleepTimerEndsAt == null) {
      return null;
    }

    final Duration remaining = _sleepTimerEndsAt!.difference(DateTime.now());

    return remaining.isNegative ? null : remaining;
  }

  @override
  Future<void> setSleepTimer(Duration? duration) async {
    _sleepTimer?.cancel();

    if (duration == null) {
      _sleepTimerEndsAt = null;
      _sleepTimerController.add(null);
      return;
    }

    _sleepTimerEndsAt = DateTime.now().add(duration);
    _sleepTimerController.add(duration);

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final Duration? remaining = sleepTimerRemaining;

      if (remaining == null) {
        timer.cancel();
        _sleepTimerEndsAt = null;
        _sleepTimerController.add(null);
        await pause();
        return;
      }

      _sleepTimerController.add(remaining);
    });
  }

  @override
  Future<void> load(
    MediaItem mediaItem,
    List<SongModel> playlist, {
    bool play = true,
  }) async {
    List<AudioSource> sources = playlist.map(_buildAudioSource).toList();

    int initialIndex = 0;

    for (int i = 0; i < playlist.length; i++) {
      if (playlist[i].id.toString() == mediaItem.id) {
        initialIndex = i;
        break;
      }
    }

    // set queue
    _queue = ConcatenatingAudioSource(
      children: sources,
    );

    // set initial index
    await _player.setAudioSource(initialIndex: initialIndex, _queue);

    // set current playlist
    currentPlaylist = List<SongModel>.of(playlist);

    // save current playlist
    await savePlaylist();
    _notifyQueue();

    if (play) {
      // play the song
      await _player.play();
    }
  }

  /// save current playlist to hive
  @override
  Future savePlaylist() async {
    await box.put(
      HiveBox.lastPlayedPlaylistKey,
      currentPlaylist.map((song) => song.getMap).toList(),
    );
  }

  /// load current playlist from hive
  @override
  Future<List<SongModel>> loadPlaylist() async {
    List<dynamic> playlist = box.get(
      HiveBox.lastPlayedPlaylistKey,
      defaultValue: List.empty(),
    );
    return playlist.map((song) => SongModel(song)).toList();
  }

  @override
  Future<void> setSequenceFromPlaylist(
    List<SongModel> playlist,
    SongModel lastPlayedSong,
  ) async {
    await load(
      getMediaItemFromSong(lastPlayedSong),
      playlist,
      play: false,
    );

    final Duration saved = _savedPositionOf(lastPlayedSong);

    if (saved > Duration.zero) {
      await _player.seek(saved);
    }
  }

  @override
  MediaItem getMediaItemFromSong(SongModel song) {
    return MediaItem(
      id: song.id.toString(),
      album: song.album,
      title: song.title,
      artist: song.artist,
      duration: Duration(milliseconds: song.duration!),
    );
  }

  @override
  Future<void> play() async {
    if (_fadeDuration == Duration.zero) {
      return _player.play();
    }

    await _player.setVolume(0);
    final Future<void> playing = _player.play();
    await _fade(0, _volume);

    return playing;
  }

  @override
  Future<void> pause() async {
    if (_fadeDuration == Duration.zero) {
      return _player.pause();
    }

    await _fade(_player.volume, 0);
    await _player.pause();
    await _player.setVolume(_volume);
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position, {int? index}) async {
    if (index != null) {
      await _player.seek(
        position,
        index: index,
      );
    } else {
      await _player.seek(position);
    }
  }

  @override
  Future<void> seekToNext() => _player.seekToNext();

  @override
  Future<void> seekToPrevious() => _player.seekToPrevious();

  @override
  Stream<Duration> get position => _player.positionStream;

  @override
  Stream<Duration?> get duration => _player.durationStream;

  @override
  Stream<bool> get shuffleModeEnabled => _player.shuffleModeEnabledStream;

  @override
  Stream<LoopMode> get loopMode => _player.loopModeStream;

  @override
  Future<void> dispose() async {
    _sleepTimer?.cancel();
    await _sleepTimerController.close();
    await _queueController.close();
    await _player.dispose();
  }

  @override
  Stream<bool> get playing => _player.playingStream;

  @override
  Stream<int?> get currentIndex => _player.currentIndexStream;

  @override
  Stream<SequenceState?> get sequenceState => _player.sequenceStateStream;

  @override
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _player.setVolume(volume);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await box.put(HiveBox.speedKey, speed);
    await _player.setSpeed(speed);
  }

  @override
  Future<void> setLoopMode(LoopMode loopMode) async {
    await box.put(HiveBox.loopModeKey, loopMode.index);
    await _player.setLoopMode(loopMode);
  }

  @override
  Future<void> setShuffleModeEnabled(bool enabled) async {
    await box.put(HiveBox.shuffleModeKey, enabled);
    await _player.setShuffleModeEnabled(enabled);
  }

  @override
  List<SongModel> get playlist => currentPlaylist;
}
