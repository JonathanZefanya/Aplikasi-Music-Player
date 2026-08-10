import 'dart:convert';
import 'dart:io';

import 'package:audiotags/audiotags.dart';

class MetadataRepository {
  static const String _lyricsHost = 'lrclib.net';
  static const String _userAgent = 'music-player-flutter (local music player)';

  Future<Tag?> read(String path) async {
    try {
      return await AudioTags.read(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    String path, {
    String? title,
    String? trackArtist,
    String? album,
    String? albumArtist,
    String? genre,
    int? year,
    int? trackNumber,
    String? lyrics,
  }) async {
    final Tag? current = await read(path);

    await AudioTags.write(
      path,
      Tag(
        title: title ?? current?.title,
        trackArtist: trackArtist ?? current?.trackArtist,
        album: album ?? current?.album,
        albumArtist: albumArtist ?? current?.albumArtist,
        genre: genre ?? current?.genre,
        year: year ?? current?.year,
        trackNumber: trackNumber ?? current?.trackNumber,
        trackTotal: current?.trackTotal,
        discNumber: current?.discNumber,
        discTotal: current?.discTotal,
        lyrics: lyrics ?? current?.lyrics,
        pictures: current?.pictures ?? [],
      ),
    );
  }

  Future<String?> embeddedLyrics(String path) async {
    final Tag? tag = await read(path);
    final String? lyrics = tag?.lyrics;

    if (lyrics == null || lyrics.trim().isEmpty) {
      return null;
    }

    return lyrics;
  }

  Future<String?> fetchOnlineLyrics({
    required String title,
    required String artist,
    String? album,
    int? durationSeconds,
  }) async {
    final Map<String, String> query = {
      'track_name': title,
      'artist_name': artist,
      if (album != null && album.isNotEmpty) 'album_name': album,
      if (durationSeconds != null) 'duration': durationSeconds.toString(),
    };

    final String? direct = await _requestLyrics(
      Uri.https(_lyricsHost, '/api/get', query),
    );

    if (direct != null) {
      return direct;
    }

    return _requestLyrics(
      Uri.https(_lyricsHost, '/api/search', {'q': '$artist $title'}),
      fromSearch: true,
    );
  }

  Future<String?> _requestLyrics(Uri uri, {bool fromSearch = false}) async {
    final HttpClient client = HttpClient();

    try {
      final HttpClientRequest request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);

      final HttpClientResponse response = await request.close();

      if (response.statusCode != 200) {
        return null;
      }

      final String body = await response.transform(utf8.decoder).join();
      final dynamic decoded = jsonDecode(body);

      final Map<String, dynamic>? entry = fromSearch
          ? (decoded is List && decoded.isNotEmpty
              ? decoded.first as Map<String, dynamic>
              : null)
          : decoded as Map<String, dynamic>?;

      if (entry == null) {
        return null;
      }

      final String? synced = entry['syncedLyrics'] as String?;
      final String? plain = entry['plainLyrics'] as String?;

      for (final String? candidate in [plain, synced]) {
        if (candidate != null && candidate.trim().isNotEmpty) {
          return candidate;
        }
      }

      return null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
