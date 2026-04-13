import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/bloc/search/search_bloc.dart';
import 'package:music/src/core/extensions/string_extensions.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/presentation/widgets/song_list_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Themes.getTheme().secondaryColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Themes.getTheme().primaryColor,
        title: TextField(
          onChanged: (value) {
            context.read<SearchBloc>().add(SearchQueryChanged(value));
          },
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search',
            border: InputBorder.none,
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      searchController.clear();
                      context.read<SearchBloc>().add(SearchQueryChanged(''));
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear',
                  ),
          ),
        ),
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (searchController.text.isEmpty) {
              return const SizedBox.shrink();
            }

            if (state is SearchError) {
              return Center(
                child: Text(state.message),
              );
            }

            if (state is SearchLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is! SearchLoaded) {
              return const SizedBox.shrink();
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  if (state.searchResult.songs.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Songs',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${state.searchResult.songs.length} ${'result'.pluralize(state.searchResult.songs.length)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final song in state.searchResult.songs)
                          SongListTile(
                            song: song,
                            songs: state.searchResult.songs,
                          ),
                      ],
                    ),
                  if (state.searchResult.albums.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Albums',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${state.searchResult.albums.length} ${'result'.pluralize(state.searchResult.albums.length)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final album in state.searchResult.albums)
                          ListTile(
                            leading: QueryArtworkWidget(
                              id: album.id,
                              type: ArtworkType.ALBUM,
                              nullArtworkWidget: const Icon(Icons.album),
                            ),
                            title: Text(album.album),
                            subtitle: Text(album.artist ?? 'Unknown'),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/album',
                                arguments: album,
                              );
                            },
                          ),
                      ],
                    ),
                  if (state.searchResult.artists.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Artists',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${state.searchResult.artists.length} ${'result'.pluralize(state.searchResult.artists.length)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final artist in state.searchResult.artists)
                          ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: Colors.grey.withOpacity(0.1),
                              ),
                              child: const Icon(
                                Icons.person_outlined,
                              ),
                            ),
                            title: Text(artist.artist),
                            subtitle: Text(
                              '${artist.numberOfTracks} ${'song'.pluralize(artist.numberOfTracks ?? 0)}',
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/artist',
                                arguments: artist,
                              );
                            },
                          ),
                      ],
                    ),
                  if (state.searchResult.genres.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Genres',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${state.searchResult.genres.length} ${'result'.pluralize(state.searchResult.genres.length)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final genre in state.searchResult.genres)
                          ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: Colors.grey.withOpacity(0.1),
                              ),
                              child: const Icon(
                                Icons.library_music_outlined,
                              ),
                            ),
                            title: Text(genre.genre),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/genre',
                                arguments: genre,
                              );
                            },
                          ),
                      ],
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
