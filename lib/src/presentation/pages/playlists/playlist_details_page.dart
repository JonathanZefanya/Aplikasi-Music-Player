import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/src/bloc/player/player_bloc.dart';
import 'package:music/src/bloc/playlists/playlists_cubit.dart';
import 'package:music/src/bloc/home/home_bloc.dart';
import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/core/router/app_router.dart';
import 'package:music/src/data/repositories/player_repository.dart';
import 'package:music/src/presentation/widgets/player_bottom_app_bar.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music/src/core/theme/themes.dart';

class PlaylistDetailsPage extends StatefulWidget {
  final PlaylistModel playlist;
  const PlaylistDetailsPage({super.key, required this.playlist});

  @override
  State<PlaylistDetailsPage> createState() => _PlaylistDetailsPageState();
}

class _PlaylistDetailsPageState extends State<PlaylistDetailsPage> {
  List<SongModel> _songs = [];

  @override
  void initState() {
    super.initState();
    context.read<PlaylistsCubit>().queryPlaylistSongs(widget.playlist.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // current song, play/pause button, song progress bar, song queue button
      bottomNavigationBar: const PlayerBottomAppBar(),
      extendBody: true,
      appBar: AppBar(
        title: Text(widget.playlist.playlist),
        backgroundColor: Themes.getTheme().primaryColor,
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: BlocListener<PlaylistsCubit, PlaylistsState>(
          listener: (context, state) {
            if (state is PlaylistsSongsLoaded) {
              setState(() {
                _songs = state.songs;
              });
            }
          },
          child: _songs.isEmpty
              ? const Center(
                  child: Text('No songs added to this playlist'),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _songs.length,
                  onReorder: (oldIndex, newIndex) {
                    final int target =
                        newIndex > oldIndex ? newIndex - 1 : newIndex;

                    setState(() {
                      _songs.insert(target, _songs.removeAt(oldIndex));
                    });

                    context.read<PlaylistsCubit>().moveInPlaylist(
                          widget.playlist.id,
                          oldIndex,
                          target,
                        );
                  },
                  itemBuilder: (context, index) {
                    final song = _songs[index];

                    return _buildTile(
                      key: ValueKey('${index}_${song.id}'),
                      song: song,
                      index: index,
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(
            AppRouter.addSongToPlaylistRoute,
            arguments: {
              'playlist': widget.playlist,
              'songs': _songs,
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTile({
    required Key key,
    required SongModel song,
    required int index,
  }) {
    return ListTile(
      key: key,
      onTap: () {
        context.read<PlayerBloc>().add(
              PlayerLoadSongs(
                _songs,
                sl<MusicPlayer>().getMediaItemFromSong(song),
              ),
            );
      },
      leading: QueryArtworkWidget(
        keepOldArtwork: true,
        id: song.albumId ?? 0,
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
          child: const Icon(Icons.music_note_outlined),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${song.artist ?? 'Unknown'} | ${song.album ?? 'Unknown'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.8),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              context.read<PlaylistsCubit>().removeFromPlaylist(
                    widget.playlist.id,
                    song,
                  );
            },
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Remove from playlist',
          ),
          const SizedBox(width: 8),
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle_outlined),
          ),
        ],
      ),
    );
  }
}

class AddSongToPlaylist extends StatefulWidget {
  const AddSongToPlaylist({
    super.key,
    required this.playlist,
    required this.songs,
  });

  final PlaylistModel playlist;
  final List<SongModel> songs;

  @override
  State<AddSongToPlaylist> createState() => _AddSongToPlaylistState();
}

class _AddSongToPlaylistState extends State<AddSongToPlaylist> {
  final List<SongModel> _songs = [];

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(GetSongsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add songs to playlist'),
        backgroundColor: Themes.getTheme().primaryColor,
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: BlocListener<HomeBloc, HomeState>(
          listener: (context, state) {
            if (state is SongsLoaded) {
              setState(() {
                _songs.addAll(state.songs);
              });
            }
          },
          child: ListView.builder(
            itemCount: _songs.length,
            itemBuilder: (context, index) {
              final song = _songs[index];
              return CheckboxListTile(
                title: Text(song.title),
                subtitle: Text(song.artist ?? 'Unknown'),
                value: widget.songs.map((e) => e.data).contains(song.data),
                onChanged: (value) {
                  if (value!) {
                    widget.songs.add(song);
                    context.read<PlaylistsCubit>().addToPlaylist(
                          widget.playlist.id,
                          song,
                        );
                  } else {
                    widget.songs.removeWhere((e) => e.data == song.data);
                    context.read<PlaylistsCubit>().removeFromPlaylist(
                          widget.playlist.id,
                          song,
                        );
                  }
                  setState(() {});
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
