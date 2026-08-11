import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:music/src/bloc/theme/theme_bloc.dart';
import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/core/responsive/responsive.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/presentation/pages/config/settings_page.dart';
import 'package:music/src/presentation/pages/home/library_view.dart';
import 'package:music/src/presentation/pages/home/playlists_home_view.dart';
import 'package:music/src/presentation/pages/library/statistics_page.dart';
import 'package:music/src/presentation/widgets/adaptive_nav_scaffold.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final OnAudioQuery _audioQuery = sl<OnAudioQuery>();

  bool _hasPermission = false;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    checkAndRequestPermissions();
  }

  Future checkAndRequestPermissions({bool retry = false}) async {
    _hasPermission = await _audioQuery.checkAndRequest(retryRequest: retry);

    _hasPermission ? setState(() {}) : checkAndRequestPermissions(retry: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        if (!_hasPermission) {
          return _buildPermissionGate();
        }

        return AdaptiveNavScaffold(
          currentIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            AdaptiveDestination(
              icon: Icons.library_music_outlined,
              selectedIcon: Icons.library_music,
              label: 'Library',
              page: LibraryView(),
            ),
            AdaptiveDestination(
              icon: Icons.queue_music_outlined,
              selectedIcon: Icons.queue_music,
              label: 'Playlists',
              page: PlaylistsHomeView(),
            ),
            AdaptiveDestination(
              icon: Icons.bar_chart_outlined,
              selectedIcon: Icons.bar_chart,
              label: 'Stats',
              page: StatisticsPage(embedded: true),
            ),
            AdaptiveDestination(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: 'Settings',
              page: SettingsPage(embedded: true),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionGate() {
    return Scaffold(
      body: Center(
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Library access needed',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Allow access so your music can be listed here.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () async {
                    await Permission.storage.request();
                    await checkAndRequestPermissions(retry: true);
                  },
                  child: const Text('Grant access'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
