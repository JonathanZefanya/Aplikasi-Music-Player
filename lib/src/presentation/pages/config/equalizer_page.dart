import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music/src/core/di/service_locator.dart';
import 'package:music/src/core/responsive/responsive.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/core/theme/themes.dart';
import 'package:music/src/data/repositories/player_repository.dart';
import 'package:music/src/data/services/audio_effects_service.dart';

class EqualizerPage extends StatefulWidget {
  const EqualizerPage({super.key});

  @override
  State<EqualizerPage> createState() => _EqualizerPageState();
}

class _EqualizerPageState extends State<EqualizerPage> {
  final MusicPlayer _player = sl<MusicPlayer>();
  final AudioEffectsService _effects = sl<AudioEffectsService>();

  late final Future<AudioEffectsCapabilities> _capabilities =
      _effects.capabilities();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Themes.getTheme().secondaryColor,
      appBar: AppBar(
        titleSpacing: AppSpacing.xl,
        title: const Text('Equalizer'),
      ),
      body: Ink(
        decoration: Themes.getBackgroundDecoration(),
        child: !Platform.isAndroid
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'The equalizer is only available on Android',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: context.contentPadding,
                children: [
                  StreamBuilder<bool>(
                    initialData: _player.equalizer.enabled,
                    stream: _player.equalizer.enabledStream,
                    builder: (context, snapshot) {
                      final bool enabled = snapshot.data ?? false;

                      return SwitchListTile(
                        secondary: const Icon(Icons.equalizer_outlined),
                        title: const Text('Equalizer'),
                        value: enabled,
                        onChanged: (value) =>
                            _player.setEqualizerEnabled(value),
                      );
                    },
                  ),
                  _buildBands(),
                  const Divider(),
                  StreamBuilder<bool>(
                    initialData: _player.loudnessEnhancer.enabled,
                    stream: _player.loudnessEnhancer.enabledStream,
                    builder: (context, snapshot) {
                      final bool enabled = snapshot.data ?? false;

                      return Column(
                        children: [
                          SwitchListTile(
                            secondary: const Icon(Icons.volume_up_outlined),
                            title: const Text('Loudness enhancer'),
                            subtitle: const Text(
                              'Boost quiet recordings',
                            ),
                            value: enabled,
                            onChanged: (value) =>
                                _player.setLoudnessEnabled(value),
                          ),
                          if (enabled) _buildTargetGain(),
                        ],
                      );
                    },
                  ),
                  const Divider(),
                  _buildEffects(),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _buildEffects() {
    return FutureBuilder<AudioEffectsCapabilities>(
      future: _capabilities,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final AudioEffectsCapabilities caps = snapshot.data!;

        if (!caps.bassBoost && !caps.virtualizer && !caps.reverb) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Play a song first, then reopen this page to set up bass boost, '
              'virtualizer and reverb. Some devices do not support them.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: [
            if (caps.bassBoost)
              _buildStrengthEffect(
                icon: Icons.graphic_eq,
                title: 'Bass boost',
                enabled: _effects.bassBoostEnabled,
                strength: _effects.bassBoostStrength,
                onToggle: (value) async {
                  await _effects.setBassBoostEnabled(value);
                  setState(() {});
                },
                onStrength: (value) async {
                  await _effects.setBassBoostStrength(value);
                  setState(() {});
                },
              ),
            if (caps.virtualizer)
              _buildStrengthEffect(
                icon: Icons.surround_sound_outlined,
                title: 'Virtualizer',
                enabled: _effects.virtualizerEnabled,
                strength: _effects.virtualizerStrength,
                onToggle: (value) async {
                  await _effects.setVirtualizerEnabled(value);
                  setState(() {});
                },
                onStrength: (value) async {
                  await _effects.setVirtualizerStrength(value);
                  setState(() {});
                },
              ),
            if (caps.reverb) _buildReverb(),
          ],
        );
      },
    );
  }

  Widget _buildStrengthEffect({
    required IconData icon,
    required String title,
    required bool enabled,
    required int strength,
    required Future<void> Function(bool) onToggle,
    required Future<void> Function(int) onStrength,
  }) {
    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(icon),
          title: Text(title),
          value: enabled,
          onChanged: onToggle,
        ),
        if (enabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: strength.toDouble().clamp(0, 1000),
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    onChanged: (value) => onStrength(value.round()),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${(strength / 10).round()}%',
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReverb() {
    const List<String> presets = [
      'None',
      'Small room',
      'Medium room',
      'Large room',
      'Medium hall',
      'Large hall',
      'Plate',
    ];

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.blur_on_outlined),
          title: const Text('Reverb'),
          value: _effects.reverbEnabled,
          onChanged: (value) async {
            await _effects.setReverbEnabled(value);
            setState(() {});
          },
        ),
        if (_effects.reverbEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<int>(
              value: _effects.reverbPreset.clamp(0, presets.length - 1),
              decoration: const InputDecoration(
                labelText: 'Preset',
                border: OutlineInputBorder(),
              ),
              items: [
                for (int index = 0; index < presets.length; index++)
                  DropdownMenuItem<int>(
                    value: index,
                    child: Text(presets[index]),
                  ),
              ],
              onChanged: (value) async {
                if (value == null) {
                  return;
                }
                await _effects.setReverbPreset(value);
                setState(() {});
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTargetGain() {
    return StreamBuilder<double>(
      initialData: _player.loudnessEnhancer.targetGain,
      stream: _player.loudnessEnhancer.targetGainStream,
      builder: (context, snapshot) {
        final double gain = snapshot.data ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gain: ${gain.toStringAsFixed(1)} dB'),
              Slider(
                value: gain.clamp(0.0, 10.0),
                min: 0,
                max: 10,
                divisions: 20,
                label: '${gain.toStringAsFixed(1)} dB',
                onChanged: (value) =>
                    _player.loudnessEnhancer.setTargetGain(value),
                onChangeEnd: (value) =>
                    _player.setLoudnessTargetGain(value),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBands() {
    return FutureBuilder<AndroidEqualizerParameters>(
      future: _player.equalizer.parameters,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final AndroidEqualizerParameters parameters = snapshot.data!;

        return Column(
          children: [
            for (int index = 0; index < parameters.bands.length; index++)
              _buildBand(parameters, index),
          ],
        );
      },
    );
  }

  Widget _buildBand(AndroidEqualizerParameters parameters, int index) {
    final AndroidEqualizerBand band = parameters.bands[index];

    return StreamBuilder<double>(
      initialData: band.gain,
      stream: band.gainStream,
      builder: (context, snapshot) {
        final double gain = snapshot.data ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(_formatFrequency(band.centerFrequency)),
              ),
              Expanded(
                child: Slider(
                  value: gain.clamp(
                    parameters.minDecibels,
                    parameters.maxDecibels,
                  ),
                  min: parameters.minDecibels,
                  max: parameters.maxDecibels,
                  onChanged: (value) => band.setGain(value),
                  onChangeEnd: (value) =>
                      _player.setEqualizerBandGain(index, value),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '${gain.toStringAsFixed(1)}dB',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFrequency(double hertz) {
    if (hertz >= 1000) {
      return '${(hertz / 1000).toStringAsFixed(hertz % 1000 == 0 ? 0 : 1)} kHz';
    }

    return '${hertz.round()} Hz';
  }
}
