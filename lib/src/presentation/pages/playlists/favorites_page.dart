import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:music/src/bloc/favorites/favorites_bloc.dart';
import 'package:music/src/bloc/song/song_bloc.dart';
import 'package:music/src/core/responsive/responsive.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/presentation/pages/library/song_list_page.dart';
import 'package:music/src/presentation/widgets/player_bottom_app_bar.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    // Dispatch the FetchFavorites event
    context.read<FavoritesBloc>().add(FetchFavorites());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // current song, play/pause button, song progress bar, song queue button
      bottomNavigationBar: const PlayerBottomAppBar(),
      extendBody: true,
      appBar: AppBar(
        titleSpacing: AppSpacing.xl,
        title: const Text('Favorites'),
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: BlocListener<SongBloc, SongState>(
          listener: (context, state) {
            if (state is ToggleFavoriteSuccess) {
              context.read<FavoritesBloc>().add(FetchFavorites());
            }
          },
          child: BlocBuilder<FavoritesBloc, FavoritesState>(
            builder: (context, state) {
              if (state is FavoritesLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is FavoritesLoaded) {
                return _buildBody(state);
              } else if (state is FavoritesError) {
                return Center(
                  child: Text(state.message),
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(state) {
    if (state.favoriteSongs.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border,
        message: 'No favorites yet.\nTap the heart on a song to add it here.',
      );
    }

    return ContentWidth(
      child: SongListBody(songs: state.favoriteSongs),
    );
  }
}
