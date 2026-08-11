import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/presentation/pages/library/song_list_page.dart';

class GenrePage extends StatefulWidget {
  final GenreModel genre;

  const GenrePage({super.key, required this.genre});

  @override
  State<GenrePage> createState() => _GenrePageState();
}

class _GenrePageState extends State<GenrePage> {
  List<SongModel> _songs = [];

  @override
  void initState() {
    super.initState();
    _getSongs();
  }

  Future<void> _getSongs() async {
    final OnAudioQuery audioQuery = sl<OnAudioQuery>();
    final List<SongModel> songs = await audioQuery.queryAudiosFrom(
      AudiosFromType.GENRE_ID,
      widget.genre.id,
    );

    // remove songs less than 10 seconds long (10,000 milliseconds)
    songs.removeWhere((song) => (song.duration ?? 0) < 10000);

    if (!mounted) {
      return;
    }

    setState(() {
      _songs = songs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SongListPage(
      title: widget.genre.genre,
      songs: _songs,
      emptyMessage: 'No songs in this genre',
    );
  }
}
