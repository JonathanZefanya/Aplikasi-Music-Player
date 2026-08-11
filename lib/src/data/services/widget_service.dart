import 'dart:io';

import 'package:flutter/services.dart';

class WidgetService {
  static const MethodChannel _channel =
      MethodChannel('com.xeadesta.music/widget');

  String? _lastTitle;
  String? _lastArtist;
  bool? _lastPlaying;

  Future<void> update({
    required String? title,
    required String? artist,
    required bool playing,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }

    if (title == _lastTitle &&
        artist == _lastArtist &&
        playing == _lastPlaying) {
      return;
    }

    _lastTitle = title;
    _lastArtist = artist;
    _lastPlaying = playing;

    try {
      await _channel.invokeMethod<bool>('update', {
        'title': title,
        'artist': artist,
        'playing': playing,
      });
    } on PlatformException {
      // widget unavailable
    } on MissingPluginException {
      // channel not registered
    }
  }
}
