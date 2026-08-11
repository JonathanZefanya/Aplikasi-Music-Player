import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:music/src/core/responsive/responsive.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/data/services/hive_box.dart';

class PlaybackPage extends StatefulWidget {
  const PlaybackPage({super.key});

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  final box = Hive.box(HiveBox.boxName);

  late int _fadeMs = box.get(HiveBox.fadeDurationKey, defaultValue: 0) as int;
  late bool _pauseOnDisconnect =
      box.get(HiveBox.pauseOnDisconnectKey, defaultValue: true) as bool;
  late bool _resumeOnReconnect =
      box.get(HiveBox.resumeOnReconnectKey, defaultValue: true) as bool;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Themes.getTheme().secondaryColor,
      appBar: AppBar(
        titleSpacing: AppSpacing.xl,
        title: const Text('Playback'),
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: ListView(
          padding: context.contentPadding,
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.graphic_eq_outlined),
              title: const Text('Fade in / fade out'),
              subtitle: Text(
                _fadeMs == 0
                    ? 'Off'
                    : '${(_fadeMs / 1000).toStringAsFixed(1)} seconds',
              ),
              value: _fadeMs > 0,
              onChanged: (value) {
                setState(() {
                  _fadeMs = value ? 500 : 0;
                });
                box.put(HiveBox.fadeDurationKey, _fadeMs);
              },
            ),
            if (_fadeMs > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Slider(
                  value: _fadeMs.toDouble(),
                  min: 200,
                  max: 3000,
                  divisions: 28,
                  label: '${(_fadeMs / 1000).toStringAsFixed(1)}s',
                  onChanged: (value) {
                    setState(() {
                      _fadeMs = value.round();
                    });
                  },
                  onChangeEnd: (value) {
                    box.put(HiveBox.fadeDurationKey, value.round());
                  },
                ),
              ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.headset_off_outlined),
              title: const Text('Pause on headphone disconnect'),
              subtitle: const Text(
                'Pause when headphones or bluetooth disconnect',
              ),
              value: _pauseOnDisconnect,
              onChanged: (value) {
                setState(() {
                  _pauseOnDisconnect = value;
                });
                box.put(HiveBox.pauseOnDisconnectKey, value);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.bluetooth_audio_outlined),
              title: const Text('Resume on reconnect'),
              subtitle: const Text(
                'Continue playing when the device connects again',
              ),
              value: _resumeOnReconnect,
              onChanged: (value) {
                setState(() {
                  _resumeOnReconnect = value;
                });
                box.put(HiveBox.resumeOnReconnectKey, value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
