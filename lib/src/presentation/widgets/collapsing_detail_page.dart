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

/// Shared shell for album and artist pages: a collapsing artwork header,
/// play/shuffle actions and the song list.
class CollapsingDetailPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int artworkId;
  final ArtworkType artworkType;
  final IconData fallbackIcon;
  final List<SongModel> songs;
  final bool showAlbumArtInList;

  const CollapsingDetailPage({
    super.key,
    required this.title,
    required this.artworkId,
    required this.artworkType,
    required this.songs,
    this.subtitle,
    this.fallbackIcon = Icons.music_note_outlined,
    this.showAlbumArtInList = false,
  });

  @override
  Widget build(BuildContext context) {
    // A fixed 400 header swallows the whole screen on short phones and looks
    // stranded on tablets, so it tracks the viewport instead.
    final double headerHeight = min(
      MediaQuery.sizeOf(context).height * 0.45,
      context.isCompact ? 380.0 : 320.0,
    );

    return Scaffold(
      bottomNavigationBar: const PlayerBottomAppBar(),
      extendBody: true,
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Themes.getTheme().primaryColor,
              expandedHeight: headerHeight,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                background: _buildBackground(context),
              ),
            ),
            SliverToBoxAdapter(
              child: ContentWidth(child: _buildActions(context)),
            ),
            SliverToBoxAdapter(
              child: ContentWidth(
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
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ContentWidth(
                  child: SongListTile(
                    key: ValueKey(songs[index].id),
                    song: songs[index],
                    songs: songs,
                    showAlbumArt: showAlbumArtInList,
                  ),
                ),
                childCount: songs.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        QueryArtworkWidget(
          id: artworkId,
          type: artworkType,
          size: 10000,
          artworkWidth: double.infinity,
          artworkHeight: double.infinity,
          artworkFit: BoxFit.cover,
          artworkBorder: BorderRadius.zero,
          nullArtworkWidget: Container(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
            child: Icon(fallbackIcon, size: 96),
          ),
        ),
        // Keeps the collapsing title readable over any artwork.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.15),
                Colors.black.withOpacity(0.75),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    if (songs.isEmpty) {
      return const SizedBox.shrink();
    }

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
              onPressed: () {
                context.read<PlayerBloc>().add(
                      PlayerSetShuffleModeEnabled(false),
                    );
                context.read<PlayerBloc>().add(
                      PlayerLoadSongs(
                        songs,
                        sl<MusicPlayer>().getMediaItemFromSong(songs.first),
                      ),
                    );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () {
                context.read<PlayerBloc>().add(
                      PlayerSetShuffleModeEnabled(true),
                    );
                context.read<PlayerBloc>().add(
                      PlayerLoadSongs(
                        songs,
                        sl<MusicPlayer>().getMediaItemFromSong(
                          songs[Random().nextInt(songs.length)],
                        ),
                      ),
                    );
              },
              icon: const Icon(Icons.shuffle),
              label: const Text('Shuffle'),
            ),
          ),
        ],
      ),
    );
  }
}
