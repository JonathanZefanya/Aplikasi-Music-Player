import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:lottie/lottie.dart';
import 'package:music/src/core/helpers/helpers.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:music/src/bloc/player/player_bloc.dart';
import 'package:music/src/core/constants/assets.dart';
import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/core/router/app_router.dart';
import 'package:music/src/data/repositories/player_repository.dart';
import 'package:music/src/presentation/pages/details/edit_metadata_page.dart';
import 'package:music/src/presentation/widgets/add_to_playlist_sheet.dart';

class SongListTile extends StatefulWidget {
  final SongModel song;
  final List<SongModel> songs;
  final bool showAlbumArt;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelectionToggle;

  const SongListTile({
    super.key,
    required this.song,
    required this.songs,
    this.showAlbumArt = true,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionToggle,
  });

  @override
  State<SongListTile> createState() => _SongListTileState();
}

class _SongListTileState extends State<SongListTile> {
  final player = sl<MusicPlayer>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SequenceState?>(
      key: ValueKey(widget.song.id),
      stream: player.sequenceState,
      builder: (context, snapshot) {
        final MediaItem? currentMediaItem = snapshot.data.currentMediaItem;

        return ListTile(
          selected: widget.selected,
          onLongPress: widget.onSelectionToggle,
          onTap: () async {
            if (widget.selectionMode) {
              widget.onSelectionToggle?.call();
              return;
            }

            MediaItem mediaItem = player.getMediaItemFromSong(widget.song);

            // if this is currently playing, navigate to player
            // else load songs
            if (currentMediaItem?.id == mediaItem.id) {
              if (context.mounted) {
                Navigator.of(context).pushNamed(
                  AppRouter.playerRoute,
                  arguments: mediaItem,
                );
              }
            } else {
              context.read<PlayerBloc>().add(
                    PlayerLoadSongs(widget.songs, mediaItem),
                  );
            }
          },
          leading: widget.selectionMode
              ? Checkbox(
                  value: widget.selected,
                  onChanged: (_) => widget.onSelectionToggle?.call(),
                )
              : _buildLeading(currentMediaItem),
          title: _buildTitle(currentMediaItem, context),
          subtitle: _buildSubtitle(),
          trailing: widget.selectionMode ? null : _buildTrailing(context),
        );
      },
    );
  }

  Widget? _buildLeading(MediaItem? currentMediaItem) {
    // if showAlbumArt is false, don't show leading
    if (!widget.showAlbumArt) {
      return null;
    }

    // if the current media item is the same as the song, show a playing animation
    if (currentMediaItem != null &&
        currentMediaItem.id == widget.song.id.toString()) {
      return Container(
        width: 50,
        height: 50,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.withOpacity(0.1),
        ),
        child: StreamBuilder<bool>(
          stream: player.playing,
          builder: (context, snapshot) {
            return ColorFiltered(
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
              child: Lottie.asset(
                Assets.playingAnimation,
                animate: snapshot.data ?? false,
              ),
            );
          },
        ),
      );
    }

    // otherwise, show the album art
    return QueryArtworkWidget(
      keepOldArtwork: true,
      id: widget.song.albumId ?? 0,
      type: ArtworkType.ALBUM,
      artworkBorder: BorderRadius.circular(10),
      size: 500,
      nullArtworkWidget: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.withOpacity(0.1),
        ),
        child: const Icon(
          Icons.music_note_outlined,
        ),
      ),
    );
  }

  Text _buildTitle(MediaItem? currentMediaItem, BuildContext context) {
    return Text(
      widget.song.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: currentMediaItem != null &&
                currentMediaItem.id == widget.song.id.toString()
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
    );
  }

  Text _buildSubtitle() {
    String subtitle =
        '${widget.song.artist ?? 'Unknown'} | ${widget.song.album ?? 'Unknown'}';
    return Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.8),
      ),
    );
  }

  IconButton _buildTrailing(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      alignment: Alignment.centerRight,
      onPressed: () {
        // add to queue, add to playlist, delete, share
        _buildModalBottomSheet(context);
      },
      icon: Transform.translate(
        offset: const Offset(13, 0),
        child: const Icon(Icons.more_vert_outlined),
      ),
      tooltip: 'More',
    );
  }

  Future<dynamic> _buildModalBottomSheet(BuildContext context) {
    final BuildContext pageContext = context;

    return showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              // border radius same as bottom sheet
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              leading: const Icon(Icons.queue_outlined),
              title: const Text('Add to queue'),
              onTap: () {
                context.read<PlayerBloc>().add(
                      PlayerAddToQueue(widget.song),
                    );
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play_outlined),
              title: const Text('Play next'),
              onTap: () {
                context.read<PlayerBloc>().add(
                      PlayerPlayNext(widget.song),
                    );
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_outlined),
              title: const Text('Add to playlist'),
              onTap: () async {
                Navigator.of(context).pop();
                await showAddToPlaylistSheet(pageContext, [widget.song]);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit metadata'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(pageContext).push(
                  MaterialPageRoute<dynamic>(
                    builder: (_) => EditMetadataPage(song: widget.song),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outlined),
              title: const Text('Delete'),
              onTap: () {
                // Show a confirmation dialog before deleting the song
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Song'),
                      content: const Text(
                          'Are you sure you want to delete this song?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            // Delete the song from the database
                            final file = File(widget.song.data);

                            if (await file.exists()) {
                              debugPrint('Deleting ${widget.song.title}');
                              try {
                                // ask for permission to manage external storage if not granted
                                if (!await Permission
                                    .manageExternalStorage.isGranted) {
                                  final status = await Permission
                                      .manageExternalStorage
                                      .request();

                                  if (status.isGranted) {
                                    debugPrint('Permission granted');
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Permission denied',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                                await file.delete();
                                debugPrint('Deleted ${widget.song.title}');
                              } catch (e) {
                                debugPrint(
                                    'Failed to delete ${widget.song.title}');
                              }
                            } else {
                              debugPrint(
                                  'File does not exist ${widget.song.title}');
                            }

                            // TODO: Remove the song from the list
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () async {
                await shareSong(context, widget.song.data, widget.song.title);
              },
            ),
          ],
        );
      },
    );
  }
}
