import 'dart:io';

import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

import 'package:music/src/core/di/service_locator.dart';

class M3uImportResult {
  final String name;
  final List<SongModel> matched;
  final int missing;

  M3uImportResult({
    required this.name,
    required this.matched,
    required this.missing,
  });
}

class M3uRepository {
  final OnAudioQuery _audioQuery = sl<OnAudioQuery>();

  Future<Directory> exportDirectory() async {
    final Directory? external =
        Platform.isAndroid ? await getExternalStorageDirectory() : null;

    final Directory base = external ?? await getApplicationDocumentsDirectory();
    final Directory directory = Directory('${base.path}/playlists');

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<File> export(String playlistName, List<SongModel> songs) async {
    final StringBuffer buffer = StringBuffer('#EXTM3U\n');

    for (final SongModel song in songs) {
      final int seconds =
          song.duration == null ? -1 : (song.duration! / 1000).round();

      buffer.writeln(
        '#EXTINF:$seconds,${song.artist ?? 'Unknown'} - ${song.title}',
      );
      buffer.writeln(song.data);
    }

    final Directory directory = await exportDirectory();
    final File file = File('${directory.path}/${_sanitize(playlistName)}.m3u');

    await file.writeAsString(buffer.toString());

    return file;
  }

  Future<M3uImportResult> parse(File file) async {
    final List<String> lines = await file.readAsLines();
    final String baseDirectory = file.parent.path;

    final List<String> paths = [];

    for (final String raw in lines) {
      final String line = raw.trim();

      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      paths.add(_resolve(line, baseDirectory));
    }

    final List<SongModel> allSongs = await _audioQuery.querySongs();
    final Map<String, SongModel> byPath = {
      for (final SongModel song in allSongs)
        _normalize(song.data): song,
    };

    final Map<String, SongModel> byName = {
      for (final SongModel song in allSongs)
        _fileName(song.data): song,
    };

    final List<SongModel> matched = [];
    int missing = 0;

    for (final String path in paths) {
      final SongModel? song =
          byPath[_normalize(path)] ?? byName[_fileName(path)];

      if (song == null) {
        missing++;
        continue;
      }

      matched.add(song);
    }

    final String name = file.uri.pathSegments.last.replaceAll('.m3u', '');

    return M3uImportResult(
      name: name,
      matched: matched,
      missing: missing,
    );
  }

  String _resolve(String line, String baseDirectory) {
    final String path = line.replaceAll('\\', '/');

    if (path.startsWith('/') || path.contains(':')) {
      return path;
    }

    return '$baseDirectory/$path';
  }

  String _normalize(String path) => path.replaceAll('\\', '/').toLowerCase();

  String _fileName(String path) {
    final String normalized = _normalize(path);
    final int separator = normalized.lastIndexOf('/');

    return separator == -1 ? normalized : normalized.substring(separator + 1);
  }

  String _sanitize(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }
}
