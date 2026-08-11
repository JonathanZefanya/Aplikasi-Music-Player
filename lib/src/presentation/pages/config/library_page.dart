import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/src/bloc/home/home_bloc.dart';
import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/core/responsive/responsive.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/data/repositories/home_repository.dart';
import 'package:music/src/data/services/hive_box.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final box = Hive.box(HiveBox.boxName);
  final HomeRepository _repository = sl<HomeRepository>();

  late bool _hideWhatsApp =
      box.get(HiveBox.hideWhatsAppKey, defaultValue: false) as bool;
  late bool _hideTelegram =
      box.get(HiveBox.hideTelegramKey, defaultValue: false) as bool;
  late List<String> _excluded = _repository.excludedFolders;
  late Future<Map<String, List<SongModel>>> _folders = _repository.getFolders();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Themes.getTheme().secondaryColor,
      appBar: AppBar(
        titleSpacing: AppSpacing.xl,
        title: const Text('Library'),
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: ListView(
          padding: context.contentPadding,
          children: [
            SwitchListTile(
              secondary: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Color(0xFF25D366),
              ),
              title: const Text('Hide WhatsApp audio'),
              value: _hideWhatsApp,
              onChanged: (value) {
                setState(() {
                  _hideWhatsApp = value;
                });
                box.put(HiveBox.hideWhatsAppKey, value).then((_) {
                  _refreshLibrary();
                });
              },
            ),
            SwitchListTile(
              secondary: const FaIcon(
                FontAwesomeIcons.telegram,
                color: Color(0xFF0088CC),
              ),
              title: const Text('Hide Telegram audio'),
              value: _hideTelegram,
              onChanged: (value) {
                setState(() {
                  _hideTelegram = value;
                });
                box.put(HiveBox.hideTelegramKey, value).then((_) {
                  _refreshLibrary();
                });
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Excluded folders',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            FutureBuilder<Map<String, List<SongModel>>>(
              future: _folders,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final List<String> folders = snapshot.data!.keys.toList()
                  ..addAll(
                    _excluded.where((path) => !snapshot.data!.containsKey(path)),
                  )
                  ..sort();

                return Column(
                  children: [
                    for (final String folder in folders)
                      CheckboxListTile(
                        value: _excluded.contains(folder),
                        title: Text(
                          folder,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onChanged: (value) => _toggle(folder, value ?? false),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _refreshLibrary() {
    if (!mounted) {
      return;
    }

    context.read<HomeBloc>().add(GetSongsEvent());
  }

  void _toggle(String folder, bool excluded) {
    setState(() {
      _excluded = List<String>.from(_excluded);

      if (excluded) {
        _excluded.add(folder);
      } else {
        _excluded.remove(folder);
      }
    });

    _repository.setExcludedFolders(_excluded).then((_) {
      if (mounted) {
        setState(() {
          _folders = _repository.getFolders();
        });
        _refreshLibrary();
      }
    });
  }
}
