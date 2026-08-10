import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:marquee/marquee.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/bloc/player/player_bloc.dart';
import 'package:music/src/bloc/song/song_bloc.dart';
import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/data/repositories/player_repository.dart';
import 'package:music/src/data/repositories/song_repository.dart';
import 'package:music/src/data/services/artwork_palette.dart';
import 'package:music/src/presentation/widgets/animated_favorite_button.dart';
import 'package:music/src/presentation/widgets/glass_container.dart';
import 'package:music/src/presentation/widgets/lyrics_sheet.dart';
import 'package:music/src/presentation/widgets/waveform_seek_bar.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final player = sl<MusicPlayer>();
  SequenceState? sequence;

  @override
  void initState() {
    super.initState();

    player.sequenceState.listen((state) {
      setState(() {
        sequence = state;
      });
    });
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          color: Colors.white,
        ),
        actions: [
          // more button
          PopupMenuButton(
            icon: const Icon(
              Icons.more_vert_outlined,
            ),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: () {
                    showSleepTimer(context);
                  },
                  child: const Text('Sleep timer'),
                ),
                PopupMenuItem(
                  onTap: () {
                    showSpeedAndPitch(context);
                  },
                  child: const Text('Speed & pitch'),
                ),
                PopupMenuItem(
                  onTap: () {
                    showLyrics(context);
                  },
                  child: const Text('Lyrics'),
                ),
              ];
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: StreamBuilder<SequenceState?>(
        stream: player.sequenceState,
        builder: (context, snapshot) {
          final MediaItem? mediaItem = snapshot.data.currentMediaItem;
          if (mediaItem == null) {
            return const SizedBox.shrink();
          }
          return Stack(
            children: [
              QueryArtworkWidget(
                keepOldArtwork: true,
                artworkHeight: double.infinity,
                id: int.parse(mediaItem.id),
                type: ArtworkType.AUDIO,
                size: 10000,
                artworkWidth: double.infinity,
                artworkBorder: BorderRadius.circular(0),
                nullArtworkWidget: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: const Icon(
                    Icons.music_note_outlined,
                    size: 100,
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FutureBuilder<Color?>(
                  future: sl<ArtworkPalette>().dominantColor(
                    int.parse(mediaItem.id),
                  ),
                  builder: (context, snapshot) {
                    final Color accent = snapshot.data ?? Colors.black;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent.withOpacity(0.55),
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  32,
                  MediaQuery.of(context).padding.top + 16,
                  32,
                  16,
                ),
                child: LayoutBuilder(builder: (context, constraints) {
                  // large screen
                  if (constraints.maxWidth > 600) {
                    // large screen divided in 2 columns
                    // 1: artwork
                    // 2: info
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // artwork
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 3,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              QueryArtworkWidget(
                                keepOldArtwork: true,
                                id: int.parse(mediaItem.id),
                                type: ArtworkType.AUDIO,
                                size: 10000,
                                artworkWidth: double.infinity,
                                nullArtworkWidget: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Icon(
                                    Icons.music_note_outlined,
                                    size:
                                        MediaQuery.of(context).size.height / 10,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: BlocBuilder<SongBloc, SongState>(
                                  builder: (context, state) {
                                    return AnimatedFavoriteButton(
                                      isFavorite: sl<SongRepository>()
                                          .isFavorite(mediaItem.id),
                                      onTap: () {
                                        context.read<SongBloc>().add(
                                              ToggleFavorite(mediaItem.id),
                                            );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 32),

                        // info
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              // title and artist
                              StreamBuilder<SequenceState?>(
                                stream: player.sequenceState,
                                builder: (context, snapshot) {
                                  final MediaItem? mediaItem =
                                      snapshot.data.currentMediaItem;

                                  if (mediaItem == null) {
                                    return const SizedBox.shrink();
                                  }

                                  return Column(
                                    children: [
                                      SizedBox(
                                        height: 30,
                                        child: mediaItem.title.length > 50
                                            ? Marquee(
                                                text: mediaItem.title,
                                                blankSpace: 100,
                                                startAfter:
                                                    const Duration(seconds: 3),
                                                pauseAfterRound:
                                                    const Duration(seconds: 3),
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                mediaItem.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                      Text(
                                        mediaItem.artist ?? 'Unknown',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const Spacer(),
                              // seek bar
                              WaveformSeekBar(
                                player: player,
                                seed: mediaItem.id,
                              ),
                              const Spacer(),
                              // shuffle, previous, play/pause, next, repeat
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  //  shuffle button
                                  _buildShuffleButton(),
                                  // previous button
                                  _buildPreviousButton(context),
                                  // play/pause button
                                  _buildPlayPauseButton(),
                                  // next button
                                  _buildNextButton(context),
                                  // repeat button
                                  _buildRepeatButton(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // small screen
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // artwork
                      SizedBox(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.width - 64,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            QueryArtworkWidget(
                              keepOldArtwork: true,
                              id: int.parse(mediaItem.id),
                              type: ArtworkType.AUDIO,
                              size: 10000,
                              artworkWidth: double.infinity,
                              nullArtworkWidget: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  Icons.music_note_outlined,
                                  size: MediaQuery.of(context).size.height / 10,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: BlocBuilder<SongBloc, SongState>(
                                builder: (context, state) {
                                  return AnimatedFavoriteButton(
                                    isFavorite: sl<SongRepository>()
                                        .isFavorite(mediaItem.id),
                                    onTap: () {
                                      context.read<SongBloc>().add(
                                            ToggleFavorite(mediaItem.id),
                                          );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // title and artist
                      StreamBuilder<SequenceState?>(
                        stream: player.sequenceState,
                        builder: (context, snapshot) {
                          final MediaItem? mediaItem =
                              snapshot.data.currentMediaItem;

                          if (mediaItem == null) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 30,
                                child: mediaItem.title.length > 30
                                    ? Marquee(
                                        text: mediaItem.title,
                                        blankSpace: 100,
                                        startAfter: const Duration(seconds: 3),
                                        pauseAfterRound:
                                            const Duration(seconds: 3),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        mediaItem.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                              Text(
                                mediaItem.artist ?? 'Unknown',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 64),
                      // seek bar
                      WaveformSeekBar(
                        player: player,
                        seed: mediaItem.id,
                      ),
                      const SizedBox(height: 16),
                      // shuffle, previous, play/pause, next, repeat
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          //  shuffle button
                          _buildShuffleButton(),
                          // previous button
                          _buildPreviousButton(context),
                          // play/pause button
                          _buildPlayPauseButton(),
                          // next button
                          _buildNextButton(context),
                          // repeat button
                          _buildRepeatButton(),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  StreamBuilder<bool> _buildShuffleButton() {
    return StreamBuilder<bool>(
      stream: player.shuffleModeEnabled,
      builder: (context, snapshot) {
        return IconButton(
          onPressed: () async {
            context.read<PlayerBloc>().add(
                  PlayerSetShuffleModeEnabled(
                    !(snapshot.data ?? false),
                  ),
                );
          },
          icon: snapshot.data == false
              ? const Icon(
                  Icons.shuffle_outlined,
                  color: Colors.grey,
                )
              : const Icon(
                  Icons.shuffle_outlined,
                  color: Colors.white,
                ),
          iconSize: 30,
          tooltip: 'Shuffle',
        );
      },
    );
  }

  IconButton _buildPreviousButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.read<PlayerBloc>().add(PlayerPrevious());
      },
      icon: const Icon(
        Icons.skip_previous_outlined,
        color: Colors.white,
      ),
      iconSize: 40,
      tooltip: 'Previous',
    );
  }

  StreamBuilder<bool> _buildPlayPauseButton() {
    return StreamBuilder<bool>(
      stream: player.playing,
      builder: (context, snapshot) {
        final playing = snapshot.data ?? false;
        return IconButton(
          onPressed: () {
            if (playing) {
              context.read<PlayerBloc>().add(PlayerPause());
            } else {
              context.read<PlayerBloc>().add(PlayerPlay());
            }
          },
          icon: playing
              ? const Icon(
                  Icons.pause_outlined,
                  color: Colors.white,
                )
              : const Icon(
                  Icons.play_arrow_outlined,
                  color: Colors.white,
                ),
          iconSize: 40,
          tooltip: 'Play/Pause',
        );
      },
    );
  }

  IconButton _buildNextButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.read<PlayerBloc>().add(PlayerNext());
      },
      icon: const Icon(
        Icons.skip_next_outlined,
        color: Colors.white,
      ),
      iconSize: 40,
      tooltip: 'Next',
    );
  }

  StreamBuilder<LoopMode> _buildRepeatButton() {
    return StreamBuilder<LoopMode>(
      stream: player.loopMode,
      builder: (context, snapshot) {
        return IconButton(
          onPressed: () {
            if (snapshot.data == LoopMode.off) {
              context.read<PlayerBloc>().add(
                    PlayerSetLoopMode(LoopMode.all),
                  );
            } else if (snapshot.data == LoopMode.all) {
              context.read<PlayerBloc>().add(
                    PlayerSetLoopMode(LoopMode.one),
                  );
            } else {
              context.read<PlayerBloc>().add(
                    PlayerSetLoopMode(LoopMode.off),
                  );
            }
          },
          icon: snapshot.data == LoopMode.off
              ? const Icon(
                  Icons.repeat_outlined,
                  color: Colors.grey,
                )
              : snapshot.data == LoopMode.all
                  ? const Icon(
                      Icons.repeat_outlined,
                      color: Colors.white,
                    )
                  : const Icon(
                      Icons.repeat_one_outlined,
                      color: Colors.white,
                    ),
          iconSize: 30,
          tooltip: 'Repeat',
        );
      },
    );
  }

  void showSleepTimer(BuildContext context) {
    const List<Duration?> options = [
      null,
      Duration(minutes: 5),
      Duration(minutes: 10),
      Duration(minutes: 15),
      Duration(minutes: 30),
      Duration(minutes: 45),
      Duration(hours: 1),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassContainer(
          child: SingleChildScrollView(
            child: Column(
              children: [
                StreamBuilder<Duration?>(
                  initialData: player.sleepTimerRemaining,
                  stream: player.sleepTimerStream,
                  builder: (context, snapshot) {
                    final remaining = snapshot.data;

                    return ListTile(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      title: Text(
                        remaining == null
                            ? 'No timer running'
                            : 'Pausing in ${_formatRemaining(remaining)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                for (final Duration? option in options)
                  ListTile(
                    title: Text(
                      option == null ? 'Off' : _formatOption(option),
                    ),
                    onTap: () {
                      context.read<PlayerBloc>().add(
                            PlayerSetSleepTimer(option),
                          );
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatOption(Duration duration) {
    if (duration.inMinutes >= 60) {
      return '${duration.inHours} hour';
    }

    return '${duration.inMinutes} minutes';
  }

  String _formatRemaining(Duration duration) {
    final String minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }

  void showLyrics(BuildContext context) {
    final MediaItem? mediaItem = sequence.currentMediaItem;

    if (mediaItem == null) {
      return;
    }

    final Iterable<SongModel> matches = player.playlist.where(
      (song) => song.id.toString() == mediaItem.id,
    );

    if (matches.isEmpty) {
      Fluttertoast.showToast(msg: 'Song not found in queue');
      return;
    }

    LyricsSheet.show(context, matches.first);
  }

  void showSpeedAndPitch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const GlassContainer(
        child: SpeedAndPitchSheet(),
      ),
    );
  }
}

class SpeedAndPitchSheet extends StatefulWidget {
  const SpeedAndPitchSheet({super.key});

  @override
  State<SpeedAndPitchSheet> createState() => _SpeedAndPitchSheetState();
}

class _SpeedAndPitchSheetState extends State<SpeedAndPitchSheet> {
  final player = sl<MusicPlayer>();

  late double _speed = player.speed;
  late double _pitch = player.pitch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Speed: ${_speed.toStringAsFixed(2)}x',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _speed,
              min: 0.5,
              max: 2.0,
              divisions: 30,
              label: '${_speed.toStringAsFixed(2)}x',
              onChanged: (value) => setState(() => _speed = value),
              onChangeEnd: (value) {
                context.read<PlayerBloc>().add(PlayerSetSpeed(value));
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Pitch: ${_pitch.toStringAsFixed(2)}x',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _pitch,
              min: 0.5,
              max: 2.0,
              divisions: 30,
              label: '${_pitch.toStringAsFixed(2)}x',
              onChanged: (value) => setState(() => _pitch = value),
              onChangeEnd: (value) {
                context.read<PlayerBloc>().add(PlayerSetPitch(value));
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _speed = 1.0;
                    _pitch = 1.0;
                  });
                  context.read<PlayerBloc>().add(PlayerSetSpeed(1.0));
                  context.read<PlayerBloc>().add(PlayerSetPitch(1.0));
                },
                child: const Text('Reset'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
