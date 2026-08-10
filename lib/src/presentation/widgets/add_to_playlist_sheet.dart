import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/bloc/playlists/playlists_cubit.dart';

Future<void> showAddToPlaylistSheet(
  BuildContext context,
  List<SongModel> songs,
) {
  return showModalBottomSheet(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(25),
      ),
    ),
    context: context,
    builder: (sheetContext) => AddToPlaylistSheet(songs: songs),
  );
}

class AddToPlaylistSheet extends StatefulWidget {
  final List<SongModel> songs;

  const AddToPlaylistSheet({super.key, required this.songs});

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  @override
  void initState() {
    super.initState();
    context.read<PlaylistsCubit>().queryPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<PlaylistsCubit, PlaylistsState>(
        builder: (context, state) {
          final playlists = context.read<PlaylistsCubit>().playlists;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                ),
                leading: const Icon(Icons.playlist_add_outlined),
                title: const Text('New playlist'),
                onTap: _createAndAdd,
              ),
              const Divider(height: 1),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No playlists yet'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];

                      return ListTile(
                        leading: const Icon(Icons.queue_music_outlined),
                        title: Text(playlist.playlist),
                        subtitle: Text('${playlist.numOfSongs} songs'),
                        onTap: () => _addTo(playlist.id),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addTo(int playlistId) async {
    final int added = await context.read<PlaylistsCubit>().addSongsToPlaylist(
          playlistId,
          widget.songs,
        );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
    Fluttertoast.showToast(
      msg: added > 0 ? '$added songs added' : 'Failed to add songs',
    );
  }

  Future<void> _createAndAdd() async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (context) => const _NewPlaylistDialog(),
    );

    if (name == null || name.trim().isEmpty || !mounted) {
      return;
    }

    final PlaylistsCubit cubit = context.read<PlaylistsCubit>();
    await cubit.createPlaylist(name.trim());

    final Iterable<PlaylistModel> matches = cubit.playlists.where(
      (playlist) => playlist.playlist == name.trim(),
    );

    if (matches.isEmpty) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'Failed to create playlist');
      }
      return;
    }

    await _addTo(matches.last.id);
  }
}

class _NewPlaylistDialog extends StatefulWidget {
  const _NewPlaylistDialog();

  @override
  State<_NewPlaylistDialog> createState() => _NewPlaylistDialogState();
}

class _NewPlaylistDialogState extends State<_NewPlaylistDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Playlist'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Playlist name',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
