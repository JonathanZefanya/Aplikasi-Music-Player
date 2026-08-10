import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/presentation/widgets/player_bottom_app_bar.dart';
import 'package:music/src/presentation/widgets/song_list_tile.dart';

class SongListPage extends StatelessWidget {
  final String title;
  final List<SongModel> songs;
  final String emptyMessage;

  const SongListPage({
    super.key,
    required this.title,
    required this.songs,
    this.emptyMessage = 'No songs found',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const PlayerBottomAppBar(),
      appBar: AppBar(
        backgroundColor: Themes.getTheme().primaryColor,
        elevation: 0,
        title: Text(title),
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: songs.isEmpty
            ? Center(child: Text(emptyMessage))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: songs.length,
                itemBuilder: (context, index) => SongListTile(
                  key: ValueKey(songs[index].id),
                  song: songs[index],
                  songs: songs,
                ),
              ),
      ),
    );
  }
}
