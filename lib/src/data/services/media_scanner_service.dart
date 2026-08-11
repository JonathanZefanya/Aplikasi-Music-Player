import 'dart:io';

import 'package:flutter/services.dart';

class MediaScannerService {
  static const MethodChannel _channel =
      MethodChannel('com.xeadesta.music/media_scanner');

  /// Re-indexes [paths] so MediaStore picks up tags written by this app.
  /// Resolves once Android reports the scan finished, so callers can safely
  /// re-query the library afterwards.
  Future<bool> scan(List<String> paths) async {
    if (!Platform.isAndroid || paths.isEmpty) {
      return false;
    }

    try {
      final bool? scanned = await _channel.invokeMethod<bool>(
        'scan',
        {'paths': paths},
      );

      return scanned ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
