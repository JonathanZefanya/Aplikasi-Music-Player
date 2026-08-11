import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/presentation/widgets/collapsing_detail_page.dart';

class AlbumPage extends StatefulWidget {
  final AlbumModel album;

  const AlbumPage({super.key, required this.album});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  List<SongModel> _songs = [];

  @override
  void initState() {
    super.initState();
    _getSongs();
  }

  Future<void> _getSongs() async {
    final OnAudioQuery audioQuery = sl<OnAudioQuery>();

    final List<SongModel> songs = await audioQuery.queryAudiosFrom(
      AudiosFromType.ALBUM_ID,
      widget.album.id,
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
    return CollapsingDetailPage(
      title: widget.album.album,
      subtitle: widget.album.artist,
      artworkId: widget.album.id,
      artworkType: ArtworkType.ALBUM,
      songs: _songs,
    );
  }
}
