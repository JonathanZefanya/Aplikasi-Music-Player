import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/data/repositories/home_repository.dart';
import 'package:music/src/presentation/pages/library/song_list_page.dart';

class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key});

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  late Future<Map<String, List<SongModel>>> _folders;

  @override
  void initState() {
    super.initState();
    _folders = sl<HomeRepository>().getFolders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Themes.getTheme().primaryColor,
        elevation: 0,
        title: const Text('Folders'),
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: FutureBuilder<Map<String, List<SongModel>>>(
          future: _folders,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final Map<String, List<SongModel>> folders = snapshot.data!;
            final List<String> paths = folders.keys.toList()
              ..sort((first, second) =>
                  _name(first).toLowerCase().compareTo(_name(second).toLowerCase()));

            if (paths.isEmpty) {
              return const Center(child: Text('No folders found'));
            }

            return ListView.builder(
              itemCount: paths.length,
              itemBuilder: (context, index) {
                final String path = paths[index];
                final List<SongModel> songs = folders[path]!;

                return ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(
                    _name(path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text('${songs.length}'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<dynamic>(
                        builder: (_) => SongListPage(
                          title: _name(path),
                          songs: songs,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _name(String path) {
    final int separator = path.lastIndexOf('/');
    return separator == -1 ? path : path.substring(separator + 1);
  }
}
