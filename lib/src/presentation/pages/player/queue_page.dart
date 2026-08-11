import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/bloc/player/player_bloc.dart';
import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/core/responsive/responsive.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/data/repositories/player_repository.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final player = sl<MusicPlayer>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        titleSpacing: AppSpacing.xl,
        title: const Text('Queue'),
        actions: [
          IconButton(
            onPressed: _confirmClearQueue,
            icon: const Icon(Icons.playlist_remove_outlined),
            tooltip: 'Clear queue',
          ),
        ],
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: StreamBuilder<List<SongModel>>(
          initialData: player.playlist,
          stream: player.queueStream,
          builder: (context, snapshot) {
            final queue = snapshot.data ?? const <SongModel>[];

            if (queue.isEmpty) {
              return const Center(
                child: Text('Queue is empty'),
              );
            }

            return _buildQueueList(queue);
          },
        ),
      ),
    );
  }

  Widget _buildQueueList(List<SongModel> queue) {
    return StreamBuilder<SequenceState?>(
      stream: player.sequenceState,
      builder: (context, snapshot) {
        final sequence = snapshot.data;
        final currentId =
            (sequence?.currentSource?.tag as MediaItem?)?.id;

        return ReorderableListView.builder(
          padding: context.contentPadding.copyWith(
            bottom: context.bottomBarInset,
          ),
          itemCount: queue.length,
          onReorder: (oldIndex, newIndex) {
            final int target = newIndex > oldIndex ? newIndex - 1 : newIndex;
            context.read<PlayerBloc>().add(
                  PlayerMoveInQueue(oldIndex, target),
                );
          },
          itemBuilder: (context, index) {
            final song = queue[index];

            return _buildTile(
              key: ValueKey('${index}_${song.id}'),
              song: song,
              index: index,
              isCurrent: currentId == song.id.toString(),
            );
          },
        );
      },
    );
  }

  Widget _buildTile({
    required Key key,
    required SongModel song,
    required int index,
    required bool isCurrent,
  }) {
    return ListTile(
      key: key,
      onTap: () async {
        await player.seek(Duration.zero, index: index);
        await player.play();
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
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isCurrent ? Theme.of(context).colorScheme.primary : null,
        ),
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
              context.read<PlayerBloc>().add(PlayerRemoveFromQueue(index));
            },
            icon: const Icon(Icons.close_outlined),
            tooltip: 'Remove from queue',
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

  Future<void> _confirmClearQueue() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Queue'),
        content: const Text('Remove all songs from the queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<PlayerBloc>().add(PlayerClearQueue());
    }
  }
}
