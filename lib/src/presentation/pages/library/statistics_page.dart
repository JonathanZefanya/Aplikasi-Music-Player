import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/data/repositories/home_repository.dart';
import 'package:music/src/data/repositories/stats_repository.dart';
import 'package:music/src/core/responsive/responsive.dart';

class StatisticsPage extends StatefulWidget {
  /// When hosted inside the navigation shell the gradient is already painted
  /// by the shell, so this page must not paint it a second time.
  final bool embedded;

  const StatisticsPage({super.key, this.embedded = false});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final StatsRepository _stats = sl<StatsRepository>();
  late Future<List<SongModel>> _songs;

  @override
  void initState() {
    super.initState();
    _songs = sl<HomeRepository>().getSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.embedded ? Colors.transparent : Themes.getTheme().primaryColor,
      appBar: AppBar(
        titleSpacing: AppSpacing.xl,
        title: Text(
          'Statistics',
          style: widget.embedded
              ? Theme.of(context).textTheme.headlineSmall
              : null,
        ),
      ),
      body: Ink(
        decoration:
            widget.embedded ? null : Themes.getBackgroundDecoration(),
        child: FutureBuilder<List<SongModel>>(
          future: _songs,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final Map<String, SongModel> byId = {
              for (final SongModel song in snapshot.data!)
                song.id.toString(): song,
            };

            final DateTime now = DateTime.now();
            final DateTime weekAgo = now.subtract(const Duration(days: 7));
            final DateTime monthAgo = now.subtract(const Duration(days: 30));

            return ListView(
              padding: EdgeInsets.only(bottom: context.bottomBarInset)
                  .add(context.contentPadding),
              children: [
                _sectionTitle('Overview'),
                _tile(
                  Icons.timer_outlined,
                  'Total listening time',
                  _formatDuration(_stats.totalListeningTime()),
                ),
                _tile(
                  Icons.play_circle_outline,
                  'Total plays',
                  '${_stats.playCounts.values.fold(0, (sum, count) => sum + count)}',
                ),
                _sectionTitle('This week'),
                _tile(
                  Icons.calendar_view_week_outlined,
                  'Listening time',
                  _formatDuration(_stats.totalListeningTime(since: weekAgo)),
                ),
                _tile(
                  Icons.queue_music_outlined,
                  'Songs played',
                  '${_stats.playsSince(weekAgo)}',
                ),
                _sectionTitle('This month'),
                _tile(
                  Icons.calendar_month_outlined,
                  'Listening time',
                  _formatDuration(_stats.totalListeningTime(since: monthAgo)),
                ),
                _tile(
                  Icons.queue_music_outlined,
                  'Songs played',
                  '${_stats.playsSince(monthAgo)}',
                ),
                _sectionTitle('Top songs'),
                ..._topSongs(byId),
                _sectionTitle('Favorite artists'),
                ..._topBy(byId, (song) => song.artist),
                _sectionTitle('Favorite albums'),
                ..._topBy(byId, (song) => song.album),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  List<Widget> _topSongs(Map<String, SongModel> byId) {
    final List<MapEntry<String, int>> counts = _stats.playCounts.entries
        .where((entry) => byId.containsKey(entry.key))
        .toList()
      ..sort((first, second) => second.value.compareTo(first.value));

    if (counts.isEmpty) {
      return [const ListTile(title: Text('No plays recorded yet'))];
    }

    return counts.take(5).map((entry) {
      final SongModel song = byId[entry.key]!;

      return ListTile(
        leading: const Icon(Icons.music_note_outlined),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDuration(_stats.listeningTimeOf(entry.key)),
        ),
        trailing: Text('${entry.value}x'),
      );
    }).toList();
  }

  List<Widget> _topBy(
    Map<String, SongModel> byId,
    String? Function(SongModel song) selector,
  ) {
    final Map<String, int> totals = {};

    for (final MapEntry<String, int> entry in _stats.playCounts.entries) {
      final SongModel? song = byId[entry.key];

      if (song == null) {
        continue;
      }

      final String name = selector(song) ?? 'Unknown';
      totals[name] = (totals[name] ?? 0) + entry.value;
    }

    if (totals.isEmpty) {
      return [const ListTile(title: Text('No plays recorded yet'))];
    }

    final List<MapEntry<String, int>> sorted = totals.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));

    return sorted.take(5).map((entry) {
      return ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(
          entry.key,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text('${entry.value}x'),
      );
    }).toList();
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    }

    if (duration.inHours < 1) {
      return '${duration.inMinutes}m';
    }

    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  }
}
