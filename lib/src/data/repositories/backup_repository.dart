import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/data/services/hive_box.dart';

class BackupFile {
  final File file;
  final String name;
  final int sizeBytes;
  final DateTime modified;

  BackupFile({
    required this.file,
    required this.name,
    required this.sizeBytes,
    required this.modified,
  });
}

class BackupResult {
  final int playlists;
  final int favorites;
  final bool settings;

  BackupResult({
    required this.playlists,
    required this.favorites,
    required this.settings,
  });
}

class BackupRepository {
  final Box<dynamic> _box = Hive.box(HiveBox.boxName);
  final OnAudioQuery _audioQuery = sl<OnAudioQuery>();

  static const int _formatVersion = 1;

  static const List<String> _settingKeys = [
    HiveBox.themeKey,
    HiveBox.customThemePrimaryColorKey,
    HiveBox.customThemeSecondaryColorKey,
    HiveBox.minSongDurationKey,
    HiveBox.minSongSizeKey,
    HiveBox.songSortTypeKey,
    HiveBox.songOrderTypeKey,
    HiveBox.shuffleModeKey,
    HiveBox.loopModeKey,
    HiveBox.speedKey,
    HiveBox.pitchKey,
    HiveBox.fadeDurationKey,
    HiveBox.pauseOnDisconnectKey,
    HiveBox.resumeOnReconnectKey,
    HiveBox.hideWhatsAppKey,
    HiveBox.hideTelegramKey,
    HiveBox.excludedFoldersKey,
  ];

  Future<Directory> backupDirectory() async {
    final Directory? external =
        Platform.isAndroid ? await getExternalStorageDirectory() : null;

    final Directory base = external ?? await getApplicationDocumentsDirectory();
    final Directory directory = Directory('${base.path}/backups');

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<List<BackupFile>> listBackups() async {
    final Directory directory = await backupDirectory();

    final List<File> files = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();

    final List<BackupFile> backups = [];

    for (final File file in files) {
      // Berkas bisa hilang di antara listing dan stat, jadi jangan pernah
      // membaca ukurannya secara sinkron dari widget.
      if (!await file.exists()) {
        continue;
      }

      final FileStat stat = await file.stat();

      backups.add(
        BackupFile(
          file: file,
          name: file.uri.pathSegments.last,
          sizeBytes: stat.size,
          modified: stat.modified,
        ),
      );
    }

    backups.sort((first, second) => second.modified.compareTo(first.modified));

    return backups;
  }

  Future<File> createBackup({
    required bool settings,
    required bool favorites,
    required bool playlists,
  }) async {
    final Map<String, dynamic> payload = {
      'version': _formatVersion,
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (settings) {
      payload['settings'] = {
        for (final String key in _settingKeys)
          if (_box.get(key) != null) key: _box.get(key),
      };
    }

    if (favorites) {
      payload['favorites'] = List<String>.from(
        _box.get(HiveBox.favoriteSongsKey, defaultValue: <String>[]) as List,
      );
    }

    if (playlists) {
      payload['playlists'] = await _exportPlaylists();
    }

    final Directory directory = await backupDirectory();
    final String stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;

    final File file = File('${directory.path}/music-backup-$stamp.json');
    await file.writeAsString(jsonEncode(payload));

    return file;
  }

  Future<List<Map<String, dynamic>>> _exportPlaylists() async {
    final List<PlaylistModel> playlists = await _audioQuery.queryPlaylists();
    final List<Map<String, dynamic>> exported = [];

    for (final PlaylistModel playlist in playlists) {
      final List<SongModel> members = await _audioQuery.queryAudiosFrom(
        AudiosFromType.PLAYLIST,
        playlist.id,
      );

      exported.add({
        'name': playlist.playlist,
        'songs': members.map((song) => song.data).toList(),
      });
    }

    return exported;
  }

  Future<BackupResult> restore(File file) async {
    final Map<String, dynamic> payload =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    bool restoredSettings = false;
    int restoredFavorites = 0;
    int restoredPlaylists = 0;

    final Map<String, dynamic>? settings =
        payload['settings'] as Map<String, dynamic>?;

    if (settings != null) {
      for (final MapEntry<String, dynamic> entry in settings.entries) {
        if (_settingKeys.contains(entry.key)) {
          await _box.put(entry.key, entry.value);
        }
      }
      restoredSettings = true;
    }

    final List<dynamic>? favorites = payload['favorites'] as List<dynamic>?;

    if (favorites != null) {
      final List<String> ids =
          favorites.map((id) => id.toString()).toList(growable: true);
      await _box.put(HiveBox.favoriteSongsKey, ids);
      restoredFavorites = ids.length;
    }

    final List<dynamic>? playlists = payload['playlists'] as List<dynamic>?;

    if (playlists != null) {
      restoredPlaylists = await _restorePlaylists(playlists);
    }

    return BackupResult(
      playlists: restoredPlaylists,
      favorites: restoredFavorites,
      settings: restoredSettings,
    );
  }

  Future<int> _restorePlaylists(List<dynamic> playlists) async {
    final List<SongModel> allSongs = await _audioQuery.querySongs();
    final Map<String, int> idByPath = {
      for (final SongModel song in allSongs) song.data: song.id,
    };

    final List<PlaylistModel> existing = await _audioQuery.queryPlaylists();
    final Set<String> existingNames =
        existing.map((playlist) => playlist.playlist).toSet();

    int restored = 0;

    for (final dynamic entry in playlists) {
      final Map<dynamic, dynamic> item = Map<dynamic, dynamic>.from(entry as Map);
      final String name = item['name'].toString();

      if (existingNames.contains(name)) {
        continue;
      }

      await _audioQuery.createPlaylist(name);

      final List<PlaylistModel> refreshed = await _audioQuery.queryPlaylists();
      final Iterable<PlaylistModel> matches =
          refreshed.where((playlist) => playlist.playlist == name);

      if (matches.isEmpty) {
        continue;
      }

      final int playlistId = matches.last.id;

      for (final dynamic path in List<dynamic>.from(item['songs'] as List)) {
        final int? songId = idByPath[path.toString()];

        if (songId != null) {
          await _audioQuery.addToPlaylist(playlistId, songId);
        }
      }

      restored++;
    }

    return restored;
  }
}
