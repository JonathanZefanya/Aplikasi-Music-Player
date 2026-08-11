import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music/src/bloc/recents/recents_bloc.dart';
import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/core/responsive/responsive.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/data/repositories/player_repository.dart';
import 'package:music/src/presentation/pages/library/song_list_page.dart';
import 'package:music/src/presentation/widgets/player_bottom_app_bar.dart';

class RecentsPage extends StatefulWidget {
  const RecentsPage({super.key});

  @override
  State<RecentsPage> createState() => _RecentsPageState();
}

class _RecentsPageState extends State<RecentsPage> {
  final player = sl<MusicPlayer>();

  @override
  void initState() {
    super.initState();
    // Dispatch the FetchRecents event
    context.read<RecentsBloc>().add(FetchRecents());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // current song, play/pause button, song progress bar, song queue button
      bottomNavigationBar: const PlayerBottomAppBar(),
      extendBody: true,
      appBar: AppBar(
        titleSpacing: AppSpacing.xl,
        title: const Text('Recents'),
      ),
      body: Ink(
        height: double.infinity,
        width: double.infinity,
        decoration: Themes.getBackgroundDecoration(),
        child: StreamBuilder<SequenceState?>(
          stream: player.sequenceState,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              context.read<RecentsBloc>().add(FetchRecents());
            }

            return BlocBuilder<RecentsBloc, RecentsState>(
              buildWhen: (_, current) => current is RecentsLoaded,
              builder: (context, state) {
                if (state is RecentsLoaded) {
                  return _buildBody(state);
                } else {
                  return const SizedBox();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(RecentsLoaded state) {
    if (state.songs.isEmpty) {
      return const EmptyState(
        icon: Icons.history_outlined,
        message: 'Nothing played yet.\nSongs you play will show up here.',
      );
    }

    return ContentWidth(child: SongListBody(songs: state.songs));
  }
}
