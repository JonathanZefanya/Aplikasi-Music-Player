import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/core/router/app_router.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/data/repositories/home_repository.dart';
import 'package:music/src/data/repositories/stats_repository.dart';
import 'package:music/src/presentation/pages/library/song_list_page.dart';

class SmartPlaylistsPage extends StatelessWidget {
  const SmartPlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Themes.getTheme().primaryColor,
        elevation: 0,
        title: const Text('Smart Playlists'),
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.fiber_new_outlined),
              title: const Text('Recently Added'),
              subtitle: const Text('Newest songs on your device'),
              onTap: () => _openRecentlyAdded(context),
            ),
            ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: const Text('Most Played'),
              subtitle: const Text('Sorted by play count'),
              onTap: () => _openMostPlayed(context),
            ),
            ListTile(
              leading: const Icon(Icons.hourglass_empty_outlined),
              title: const Text('Never Played'),
              subtitle: const Text('Songs you have not played yet'),
              onTap: () => _openNeverPlayed(context),
            ),
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('Recently Played'),
              subtitle: const Text('Your listening history'),
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.recentsRoute);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRecentlyAdded(BuildContext context) async {
    final List<SongModel> songs = await sl<HomeRepository>().getRecentlyAdded();

    if (!context.mounted) {
      return;
    }

    _push(context, 'Recently Added', songs);
  }

  Future<void> _openMostPlayed(BuildContext context) async {
    final List<SongModel> songs = await sl<HomeRepository>().getSongs();
    final StatsRepository stats = sl<StatsRepository>();

    songs.removeWhere((song) => stats.playCountOf(song.id.toString()) == 0);
    songs.sort(
      (first, second) => stats
          .playCountOf(second.id.toString())
          .compareTo(stats.playCountOf(first.id.toString())),
    );

    if (!context.mounted) {
      return;
    }

    _push(
      context,
      'Most Played',
      songs,
      empty: 'No song has been played yet',
    );
  }

  Future<void> _openNeverPlayed(BuildContext context) async {
    final List<SongModel> songs = await sl<HomeRepository>().getSongs();
    final StatsRepository stats = sl<StatsRepository>();

    songs.removeWhere((song) => stats.playCountOf(song.id.toString()) > 0);

    if (!context.mounted) {
      return;
    }

    _push(
      context,
      'Never Played',
      songs,
      empty: 'You have played every song',
    );
  }

  void _push(
    BuildContext context,
    String title,
    List<SongModel> songs, {
    String empty = 'No songs found',
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (_) => SongListPage(
          title: title,
          songs: songs,
          emptyMessage: empty,
        ),
      ),
    );
  }
}
