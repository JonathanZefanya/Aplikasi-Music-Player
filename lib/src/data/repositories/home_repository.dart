import 'package:hive/hive.dart';
import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/data/services/hive_box.dart';
import 'package:on_audio_query/on_audio_query.dart';

class HomeRepository {
  final OnAudioQuery _audioQuery = sl<OnAudioQuery>();
  final Box<dynamic> _box = Hive.box(HiveBox.boxName);

  Future<List<SongModel>> getSongs() async {
    // get all songs
    var songs = await _audioQuery.querySongs(
      sortType: SongSortType.values[_box.get(
        HiveBox.songSortTypeKey,
        defaultValue: SongSortType.TITLE.index,
      )],
      orderType: OrderType.values[_box.get(
        HiveBox.songOrderTypeKey,
        defaultValue: OrderType.ASC_OR_SMALLER.index,
      )],
    );

    // remove songs less than n seconds long (n * 1000 milliseconds)
    // and less than 10 MB in size
    songs.removeWhere((song) {
      return (song.duration ?? 0) <
              _box.get(HiveBox.minSongDurationKey, defaultValue: 0) * 1000 ||
          (song.size) <
              _box.get(HiveBox.minSongSizeKey, defaultValue: 0) * 1024;
    });

    songs.removeWhere((song) => isExcluded(song.data));

    return songs;
  }

  bool isExcluded(String path) {
    final String normalized = path.replaceAll('\\', '/').toLowerCase();

    if (_box.get(HiveBox.hideWhatsAppKey, defaultValue: false) as bool &&
        normalized.contains('whatsapp')) {
      return true;
    }

    if (_box.get(HiveBox.hideTelegramKey, defaultValue: false) as bool &&
        normalized.contains('telegram')) {
      return true;
    }

    for (final String folder in excludedFolders) {
      if (normalized.startsWith(folder.replaceAll('\\', '/').toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  List<String> get excludedFolders => List<String>.from(
        _box.get(HiveBox.excludedFoldersKey, defaultValue: <String>[]) as List,
      );

  Future<void> setExcludedFolders(List<String> folders) async {
    await _box.put(HiveBox.excludedFoldersKey, folders);
  }

  Future<List<SongModel>> getRecentlyAdded() async {
    final List<SongModel> songs = await getSongs();

    songs.sort(
      (first, second) => (second.dateAdded ?? 0).compareTo(first.dateAdded ?? 0),
    );

    return songs;
  }

  Future<Map<String, List<SongModel>>> getFolders() async {
    final List<SongModel> songs = await getSongs();
    final Map<String, List<SongModel>> folders = {};

    for (final SongModel song in songs) {
      final String path = song.data.replaceAll('\\', '/');
      final int separator = path.lastIndexOf('/');
      final String folder = separator == -1 ? '/' : path.substring(0, separator);

      folders.putIfAbsent(folder, () => []).add(song);
    }

    return folders;
  }

  Future<List<ArtistModel>> getArtists() async {
    return await _audioQuery.queryArtists();
  }

  Future<List<AlbumModel>> getAlbums() async {
    return await _audioQuery.queryAlbums();
  }

  Future<List<GenreModel>> getGenres() async {
    return await _audioQuery.queryGenres();
  }

  Future<List<PlaylistModel>> getPlaylists() async {
    return await _audioQuery.queryPlaylists();
  }

  Future<void> sortSongs(int songSortType, int orderType) async {
    await _box.put(HiveBox.songSortTypeKey, songSortType);
    await _box.put(HiveBox.songOrderTypeKey, orderType);
  }
}
