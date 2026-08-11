import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:music/src/core/di/service_locator.dart';

class ArtworkPalette {
  final OnAudioQuery _audioQuery = sl<OnAudioQuery>();
  final Map<int, Color?> _cache = {};

  /// Drops the cached colour so edited artwork is re-read.
  void invalidate(int songId) {
    _cache.remove(songId);
  }

  Future<Color?> dominantColor(int songId) async {
    if (_cache.containsKey(songId)) {
      return _cache[songId];
    }

    Color? color;

    try {
      final Uint8List? artwork = await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        size: 200,
      );

      if (artwork != null && artwork.isNotEmpty) {
        final PaletteGenerator palette =
            await PaletteGenerator.fromImageProvider(
          MemoryImage(artwork),
          size: const Size(200, 200),
          maximumColorCount: 8,
        );

        color = palette.vibrantColor?.color ??
            palette.dominantColor?.color ??
            palette.mutedColor?.color;
      }
    } catch (_) {
      color = null;
    }

    _cache[songId] = color;

    return color;
  }
}
