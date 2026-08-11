import 'package:flutter/material.dart';

import 'package:music/src/core/responsive/responsive.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/presentation/pages/home/views/playlists_view.dart';

class PlaylistsHomeView extends StatelessWidget {
  const PlaylistsHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: AppSpacing.xl,
        title: Text(
          'Playlists',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: const ContentWidth(child: PlaylistsView()),
    );
  }
}
