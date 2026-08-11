import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import 'package:music/src/data/services/hive_box.dart';

class AudioEffectsCapabilities {
  final bool bassBoost;
  final bool virtualizer;
  final bool reverb;

  const AudioEffectsCapabilities({
    required this.bassBoost,
    required this.virtualizer,
    required this.reverb,
  });

  static const AudioEffectsCapabilities none = AudioEffectsCapabilities(
    bassBoost: false,
    virtualizer: false,
    reverb: false,
  );
}

class AudioEffectsService {
  static const MethodChannel _channel =
      MethodChannel('com.xeadesta.music/audio_effects');

  final Box<dynamic> _box = Hive.box(HiveBox.boxName);

  int? _sessionId;

  bool get available => Platform.isAndroid;

  bool get bassBoostEnabled =>
      _box.get(HiveBox.bassBoostEnabledKey, defaultValue: false) as bool;

  int get bassBoostStrength =>
      _box.get(HiveBox.bassBoostStrengthKey, defaultValue: 0) as int;

  bool get virtualizerEnabled =>
      _box.get(HiveBox.virtualizerEnabledKey, defaultValue: false) as bool;

  int get virtualizerStrength =>
      _box.get(HiveBox.virtualizerStrengthKey, defaultValue: 0) as int;

  bool get reverbEnabled =>
      _box.get(HiveBox.reverbEnabledKey, defaultValue: false) as bool;

  int get reverbPreset =>
      _box.get(HiveBox.reverbPresetKey, defaultValue: 0) as int;

  Future<void> attach(int sessionId) async {
    if (!available || sessionId == 0 || sessionId == _sessionId) {
      return;
    }

    _sessionId = sessionId;

    try {
      await _channel.invokeMethod<bool>('attach', {'sessionId': sessionId});
      await _reapply();
    } on PlatformException {
      _sessionId = null;
    }
  }

  Future<AudioEffectsCapabilities> capabilities() async {
    if (!available) {
      return AudioEffectsCapabilities.none;
    }

    try {
      final Map<dynamic, dynamic>? raw =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('capabilities');

      if (raw == null) {
        return AudioEffectsCapabilities.none;
      }

      return AudioEffectsCapabilities(
        bassBoost: raw['bassBoost'] == true,
        virtualizer: raw['virtualizer'] == true,
        reverb: raw['reverb'] == true,
      );
    } on PlatformException {
      return AudioEffectsCapabilities.none;
    }
  }

  Future<void> _reapply() async {
    await _invoke('setBassBoostStrength', {'strength': bassBoostStrength});
    await _invoke('setBassBoostEnabled', {'enabled': bassBoostEnabled});
    await _invoke('setVirtualizerStrength', {'strength': virtualizerStrength});
    await _invoke('setVirtualizerEnabled', {'enabled': virtualizerEnabled});
    await _invoke('setReverbPreset', {'preset': reverbPreset});
    await _invoke('setReverbEnabled', {'enabled': reverbEnabled});
  }

  Future<void> _invoke(String method, [Map<String, dynamic>? arguments]) async {
    if (!available) {
      return;
    }

    try {
      await _channel.invokeMethod<bool>(method, arguments);
    } on PlatformException {
      // effect unsupported on this device
    } on MissingPluginException {
      // channel not registered
    }
  }

  Future<void> setBassBoostEnabled(bool enabled) async {
    await _box.put(HiveBox.bassBoostEnabledKey, enabled);
    await _invoke('setBassBoostEnabled', {'enabled': enabled});
  }

  Future<void> setBassBoostStrength(int strength) async {
    await _box.put(HiveBox.bassBoostStrengthKey, strength);
    await _invoke('setBassBoostStrength', {'strength': strength});
  }

  Future<void> setVirtualizerEnabled(bool enabled) async {
    await _box.put(HiveBox.virtualizerEnabledKey, enabled);
    await _invoke('setVirtualizerEnabled', {'enabled': enabled});
  }

  Future<void> setVirtualizerStrength(int strength) async {
    await _box.put(HiveBox.virtualizerStrengthKey, strength);
    await _invoke('setVirtualizerStrength', {'strength': strength});
  }

  Future<void> setReverbEnabled(bool enabled) async {
    await _box.put(HiveBox.reverbEnabledKey, enabled);
    await _invoke('setReverbEnabled', {'enabled': enabled});
  }

  Future<void> setReverbPreset(int preset) async {
    await _box.put(HiveBox.reverbPresetKey, preset);
    await _invoke('setReverbPreset', {'preset': preset});
  }
}
