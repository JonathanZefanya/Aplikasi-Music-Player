import 'package:bloc/bloc.dart';
// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';
import 'package:on_audio_query/on_audio_query.dart';

part 'playlists_state.dart';

class PlaylistsCubit extends Cubit<PlaylistsState> {
  PlaylistsCubit() : super(PlaylistsInitial());

  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<PlaylistModel> playlists = [];

  final Map<int, Map<String, int>> _memberIds = {};

  Future<void> queryPlaylists() async {
    emit(PlaylistsLoading());
    playlists = await _audioQuery.queryPlaylists();
    emit(PlaylistsLoaded(playlists));
  }

  Future<void> createPlaylist(String name) async {
    emit(PlaylistsLoading());
    await _audioQuery.createPlaylist(name);
    playlists = await _audioQuery.queryPlaylists();
    emit(PlaylistsLoaded(playlists));
  }

  Future<void> queryPlaylistSongs(int playlistId) async {
    emit(PlaylistsLoading());
    emit(PlaylistsSongsLoaded(await _resolvePlaylistSongs(playlistId)));
  }

  Future<List<SongModel>> _resolvePlaylistSongs(int playlistId) async {
    final List<SongModel> members = await _audioQuery.queryAudiosFrom(
      AudiosFromType.PLAYLIST,
      playlistId,
    );

    _memberIds[playlistId] = {
      for (final SongModel member in members) member.data: member.id,
    };

    final List<SongModel> allSongs = await _audioQuery.querySongs();
    final Map<String, SongModel> byPath = {
      for (final SongModel song in allSongs) song.data: song,
    };

    return [
      for (final SongModel member in members)
        if (byPath.containsKey(member.data)) byPath[member.data]!,
    ];
  }

  Future<void> addToPlaylist(int playlistId, SongModel song) async {
    emit(PlaylistsLoading());
    await _audioQuery.addToPlaylist(playlistId, song.id);
    await queryPlaylistSongs(playlistId);
  }

  Future<int> addSongsToPlaylist(int playlistId, List<SongModel> songs) async {
    int added = 0;

    for (final SongModel song in songs) {
      if (await _audioQuery.addToPlaylist(playlistId, song.id)) {
        added++;
      }
    }

    return added;
  }

  Future<void> removeFromPlaylist(int playlistId, SongModel song) async {
    final int? memberId = _memberIds[playlistId]?[song.data];

    if (memberId == null) {
      return;
    }

    emit(PlaylistsLoading());
    await _audioQuery.removeFromPlaylist(playlistId, memberId);
    await queryPlaylistSongs(playlistId);
  }

  Future<void> moveInPlaylist(int playlistId, int from, int to) async {
    await _audioQuery.moveItemTo(playlistId, from, to);
    emit(PlaylistsSongsLoaded(await _resolvePlaylistSongs(playlistId)));
  }

  Future<void> deletePlaylist(int playlistId) async {
    emit(PlaylistsLoading());
    await _audioQuery.removePlaylist(playlistId);
    _memberIds.remove(playlistId);
    playlists = await _audioQuery.queryPlaylists();
    emit(PlaylistsLoaded(playlists));
  }

  Future<void> renamePlaylist(int playlistId, String newName) async {
    emit(PlaylistsLoading());
    await _audioQuery.renamePlaylist(playlistId, newName);
    playlists = await _audioQuery.queryPlaylists();
    emit(PlaylistsLoaded(playlists));
  }
}
