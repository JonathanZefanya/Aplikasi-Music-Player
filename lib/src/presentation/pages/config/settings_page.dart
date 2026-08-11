import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/src/bloc/theme/theme_bloc.dart';
import 'package:music/src/core/router/app_router.dart';
import 'package:music/src/core/responsive/responsive.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  /// See [StatisticsPage.embedded].
  final bool embedded;

  const SettingsPage({super.key, this.embedded = false});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    _getPackageInfo();
  }

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  Future<void> _getPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();

    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: widget.embedded
              ? Colors.transparent
              : Themes.getTheme().secondaryColor,
          appBar: AppBar(
            titleSpacing: AppSpacing.xl,
            title: Text(
              'Settings',
              style: widget.embedded
                  ? Theme.of(context).textTheme.headlineSmall
                  : null,
            ),
          ),
          body: Ink(
            decoration:
                widget.embedded ? null : Themes.getBackgroundDecoration(),
            child: ListView(
              // Must sit on the ListView, not the Ink: padding on the wrapper
              // shrinks the scroll viewport instead of adding scrollable room.
              padding: EdgeInsets.only(
                top: 8,
                bottom: context.bottomBarInset,
              ).add(context.contentPadding),
              children: [
                // scan music (ignores songs which don't satisfy the requirements)
                ListTile(
                  leading: const Icon(Icons.wifi_tethering_outlined),
                  title: const Text('Scan Music'),
                  subtitle: const Text(
                    'Filter Musik Mu dan Nikmati',
                  ),
                  onTap: () async {
                    Navigator.of(context).pushNamed(AppRouter.scanRoute);
                  },
                ),
                // library filters
                ListTile(
                  leading: const Icon(Icons.library_music_outlined),
                  title: const Text('Library'),
                  subtitle: const Text(
                    'Sembunyikan audio dan folder tertentu',
                  ),
                  onTap: () async {
                    Navigator.of(context).pushNamed(AppRouter.libraryRoute);
                  },
                ),
                // playback behaviour
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Playback'),
                  subtitle: const Text(
                    'Fade, headphone dan bluetooth',
                  ),
                  onTap: () async {
                    Navigator.of(context).pushNamed(AppRouter.playbackRoute);
                  },
                ),
                // equalizer
                ListTile(
                  leading: const Icon(Icons.equalizer_outlined),
                  title: const Text('Equalizer'),
                  subtitle: const Text(
                    'Atur frekuensi dan penguat kenyaringan',
                  ),
                  onTap: () async {
                    Navigator.of(context).pushNamed(AppRouter.equalizerRoute);
                  },
                ),
                // backup & restore
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Backup & Restore'),
                  subtitle: const Text(
                    'Cadangkan setelan, favorit, dan playlist',
                  ),
                  onTap: () async {
                    Navigator.of(context).pushNamed(AppRouter.backupRoute);
                  },
                ),
                // language
                // TODO: add language selection
                // ListTile(
                //   leading: const Icon(Icons.language_outlined),
                //   title: const Text('Language'),
                //   onTap: () async {},
                // ),
                // theme
                ListTile(
                  leading: const Icon(Icons.color_lens_outlined),
                  title: const Text('Themes'),
                  onTap: () async {
                    Navigator.of(context).pushNamed(AppRouter.themesRoute);
                  },
                ),
                // about
                ListTile(
                  leading: const Icon(Icons.person_pin_rounded),
                  title: const Text('About Developer'),
                  onTap: () async {
                    // show about dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('About Developer'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name: Jonathan Zefanya',
                            ),
                            Text(
                              'GitHub: @jonathanzefanya',
                            ),
                            Text(
                              'Email: jonathan.zefanya16@gmail.com',
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // package info
                _buildPackageInfoTile(context),
              ],
            ),
          ),
        );
      },
    );
  }

  ListTile _buildPackageInfoTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('Version'),
      subtitle: Text(
        _packageInfo.version,
      ),
      onTap: () async {
        // show package info
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Package info'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: ${_packageInfo.appName}',
                ),
                Text(
                  'Package: ${_packageInfo.packageName}',
                ),
                Text(
                  'Version: ${_packageInfo.version}',
                ),
                Text(
                  'Build number: ${_packageInfo.buildNumber}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
