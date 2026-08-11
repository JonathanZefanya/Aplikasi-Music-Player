import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/bloc/player/player_bloc.dart';
import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/core/extensions/string_extensions.dart';
import 'package:music/src/core/responsive/responsive.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/data/repositories/player_repository.dart';
import 'package:music/src/presentation/widgets/player_bottom_app_bar.dart';
import 'package:music/src/presentation/widgets/song_list_tile.dart';

class SongListPage extends StatelessWidget {
  final String title;
  final List<SongModel> songs;
  final String emptyMessage;
  final IconData emptyIcon;

  const SongListPage({
    super.key,
    required this.title,
    required this.songs,
    this.emptyMessage = 'No songs found',
    this.emptyIcon = Icons.music_off_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const PlayerBottomAppBar(),
      appBar: AppBar(
        titleSpacing: AppSpacing.xl,
        title: Text(title),
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: ContentWidth(
          child: songs.isEmpty
              ? EmptyState(icon: emptyIcon, message: emptyMessage)
              : SongListBody(songs: songs),
        ),
      ),
    );
  }
}

/// Play/shuffle actions, a count, then the songs. Shared by every screen that
/// shows a flat list of songs.
class SongListBody extends StatelessWidget {
  final List<SongModel> songs;
  final bool showAlbumArt;

  const SongListBody({
    super.key,
    required this.songs,
    this.showAlbumArt = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildActions(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              '${songs.length} ${'song'.pluralize(songs.length)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => SongListTile(
              key: ValueKey(songs[index].id),
              song: songs[index],
              songs: songs,
              showAlbumArt: showAlbumArt,
            ),
            childCount: songs.length,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: context.bottomBarInset)),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _play(context, songs.first, shuffle: false),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () => _play(
                context,
                songs[Random().nextInt(songs.length)],
                shuffle: true,
              ),
              icon: const Icon(Icons.shuffle),
              label: const Text('Shuffle'),
            ),
          ),
        ],
      ),
    );
  }

  void _play(BuildContext context, SongModel song, {required bool shuffle}) {
    context.read<PlayerBloc>().add(PlayerSetShuffleModeEnabled(shuffle));
    context.read<PlayerBloc>().add(
          PlayerLoadSongs(
            songs,
            sl<MusicPlayer>().getMediaItemFromSong(song),
          ),
        );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
