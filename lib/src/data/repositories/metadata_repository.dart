import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

  Future<void> writeArtwork(String path, Uint8List bytes) async {
    final Tag? current = await read(path);

    await AudioTags.write(
      path,
      Tag(
        title: current?.title,
        trackArtist: current?.trackArtist,
        album: current?.album,
        albumArtist: current?.albumArtist,
        genre: current?.genre,
        year: current?.year,
        trackNumber: current?.trackNumber,
        trackTotal: current?.trackTotal,
        discNumber: current?.discNumber,
        discTotal: current?.discTotal,
        lyrics: current?.lyrics,
        pictures: [
          Picture(
            pictureType: PictureType.coverFront,
            mimeType: _mimeTypeOf(bytes),
            bytes: bytes,
          ),
        ],
      ),
    );
  }

  MimeType _mimeTypeOf(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return MimeType.png;
    }

    return MimeType.jpeg;
  }

  Future<Uint8List?> downloadArtwork({
    required String title,
    required String artist,
    String? album,
  }) async {
    final String term = [artist, title].where((part) => part.isNotEmpty).join(' ');

    if (term.trim().isEmpty) {
      return null;
    }

    final Uri searchUri = Uri.https('itunes.apple.com', '/search', {
      'term': term,
      'entity': 'song',
      'limit': '1',
    });

    final String? body = await _get(searchUri);

    if (body == null) {
      return null;
    }

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(body) as Map<String, dynamic>;
      final List<dynamic> results = decoded['results'] as List<dynamic>;

      if (results.isEmpty) {
        return null;
      }

      final String? artworkUrl =
          (results.first as Map<String, dynamic>)['artworkUrl100'] as String?;

      if (artworkUrl == null) {
        return null;
      }

      return _download(
        Uri.parse(artworkUrl.replaceAll('100x100bb', '600x600bb')),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _get(Uri uri) async {
    final HttpClient client = HttpClient();

    try {
      final HttpClientRequest request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);

      final HttpClientResponse response = await request.close();

      if (response.statusCode != 200) {
        return null;
      }

      return await response.transform(utf8.decoder).join();
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<Uint8List?> _download(Uri uri) async {
    final HttpClient client = HttpClient();

    try {
      final HttpClientRequest request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);

      final HttpClientResponse response = await request.close();

      if (response.statusCode != 200) {
        return null;
      }

      final List<int> bytes = [];

      await for (final List<int> chunk in response) {
        bytes.addAll(chunk);
      }

      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
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
