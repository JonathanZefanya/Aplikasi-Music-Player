import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/presentation/widgets/collapsing_detail_page.dart';

class ArtistPage extends StatefulWidget {
  final ArtistModel artist;

  const ArtistPage({super.key, required this.artist});

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  List<SongModel> _songs = [];

  @override
  void initState() {
    super.initState();
    _getSongs();
  }

  Future<void> _getSongs() async {
    final OnAudioQuery audioQuery = sl<OnAudioQuery>();

    final List<SongModel> songs = await audioQuery.queryAudiosFrom(
      AudiosFromType.ARTIST_ID,
      widget.artist.id,
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
      title: widget.artist.artist,
      artworkId: widget.artist.id,
      artworkType: ArtworkType.ARTIST,
      fallbackIcon: Icons.person_outline,
      songs: _songs,
      showAlbumArtInList: true,
    );
  }
}
