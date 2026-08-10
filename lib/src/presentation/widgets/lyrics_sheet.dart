import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/data/repositories/metadata_repository.dart';

class LyricsSheet extends StatefulWidget {
  final String path;
  final String title;
  final String artist;
  final String album;
  final int? durationMs;

  const LyricsSheet({
    super.key,
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    this.durationMs,
  });

  static Future<void> show(BuildContext context, SongModel song) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LyricsSheet(
        path: song.data,
        title: song.title,
        artist: song.artist ?? '',
        album: song.album ?? '',
        durationMs: song.duration,
      ),
    );
  }

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  final MetadataRepository _repository = sl<MetadataRepository>();

  String? _lyrics;
  bool _loading = true;
  bool _fromOnline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String? embedded = await _repository.embeddedLyrics(widget.path);

    if (!mounted) {
      return;
    }

    setState(() {
      _lyrics = embedded;
      _loading = false;
    });
  }

  Future<void> _fetchOnline() async {
    setState(() => _loading = true);

    final String? online = await _repository.fetchOnlineLyrics(
      title: widget.title,
      artist: widget.artist,
      album: widget.album,
      durationSeconds:
          widget.durationMs == null ? null : (widget.durationMs! / 1000).round(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _lyrics = online;
      _fromOnline = online != null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fromOnline ? 'Lyrics (online)' : 'Lyrics',
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _loading ? null : _fetchOnline,
                      icon: const Icon(Icons.cloud_download_outlined),
                      label: const Text('Fetch online'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _lyrics == null
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No lyrics found in this file.\n'
                                'Try fetching them online.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView(
                            controller: controller,
                            padding: const EdgeInsets.all(24),
                            children: [
                              SelectableText(
                                _lyrics!,
                                style: const TextStyle(height: 1.6),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
