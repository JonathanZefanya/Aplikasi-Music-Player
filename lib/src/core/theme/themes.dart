import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:music/src/data/services/hive_box.dart';
import 'package:path_provider/path_provider.dart';

class Themes {
  static const String customColorThemeName = 'Custom Color';
  static const String customImageThemeName = 'Custom Image';

  static final List<ThemeColor> _themes = [
    PurpleTheme(),
    BlueTheme(),
    GreenTheme(),
    OrangeTheme(),
    YellowTheme(),
    TealTheme(),
    RedTheme(),
    BlackTheme(),
    WhiteTheme(),
    GrayTheme(),
  ];

  static final List<String> _themeNames = [
    'Purple',
    'Blue',
    'Green',
    'Orange',
    'Yellow',
    'Teal',
    'Red',
    'Black',
    'White',
    'Gray',
    customColorThemeName,
    customImageThemeName,
  ];

  static List<ThemeColor> get themes => _themes;
  static List<String> get themeNames => _themeNames;

  static ThemeColor getThemeFromKey(String key) {
    switch (key) {
      case 'Purple':
        return _themes[0];
      case 'Blue':
        return _themes[1];
      case 'Green':
        return _themes[2];
      case 'Orange':
        return _themes[3];
      case 'Yellow':
        return _themes[4];
      case 'Teal':
        return _themes[5];
      case 'Red':
        return _themes[6];
      case 'Black':
        return _themes[7];
      case 'White':
        return _themes[8];
      case 'Gray':
        return _themes[9];
      case customColorThemeName:
        return _getCustomColorTheme();
      case customImageThemeName:
        return _getCustomImageTheme();
      default:
        return _themes[0];
    }
  }

  static Future<void> setTheme(String themeName) async {
    final Box<dynamic> box = Hive.box(HiveBox.boxName);
    await box.put(HiveBox.themeKey, themeName);
  }

  static Future<void> setCustomColorTheme(Color primaryColor) async {
    final Color secondaryColor = _shiftLightness(primaryColor, 0.18);
    final Box<dynamic> box = Hive.box(HiveBox.boxName);
    final String? previousImagePath =
        box.get(HiveBox.customThemeImagePathKey) as String?;

    await box.put(HiveBox.customThemePrimaryColorKey, primaryColor.value);
    await box.put(HiveBox.customThemeSecondaryColorKey, secondaryColor.value);
    await box.put(HiveBox.customThemeImagePathKey, null);
    await box.put(HiveBox.themeKey, customColorThemeName);
    await _deleteFileIfExists(previousImagePath);
  }

  static Future<void> setCustomImageTheme({
    required String imagePath,
    required Color overlayColor,
  }) async {
    final Box<dynamic> box = Hive.box(HiveBox.boxName);
    final String? previousImagePath =
        box.get(HiveBox.customThemeImagePathKey) as String?;
    final String storedImagePath = await _storeCustomThemeImage(imagePath);
    final Color secondaryColor = _shiftLightness(
      overlayColor,
      estimateBrightness(overlayColor) == Brightness.dark ? 0.12 : -0.12,
    );

    await box.put(HiveBox.customThemePrimaryColorKey, overlayColor.value);
    await box.put(HiveBox.customThemeSecondaryColorKey, secondaryColor.value);
    await box.put(HiveBox.customThemeImagePathKey, storedImagePath);
    await box.put(HiveBox.themeKey, customImageThemeName);
    await _deleteFileIfExists(previousImagePath);
  }

  static String getThemeName() {
    final Box<dynamic> box = Hive.box(HiveBox.boxName);
    final String? themeName = box.get(HiveBox.themeKey) as String?;
    return themeName ?? 'Purple';
  }

  static ThemeColor getTheme() {
    final Box<dynamic> box = Hive.box(HiveBox.boxName);
    final String? themeName = box.get(HiveBox.themeKey) as String?;
    return getThemeFromKey(themeName ?? 'Purple');
  }

  static BoxDecoration getBackgroundDecoration() {
    final ThemeColor theme = getTheme();
    final String? imagePath = theme.backgroundImagePath;

    if (imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync()) {
      return BoxDecoration(
        color: theme.primaryColor,
        image: DecorationImage(
          image: FileImage(File(imagePath)),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            theme.overlayColor.withOpacity(0.55),
            BlendMode.darken,
          ),
        ),
      );
    }

    return BoxDecoration(gradient: theme.linearGradient);
  }

  static Color getAdaptiveTextColor(Color color) {
    return estimateBrightness(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  static Brightness estimateBrightness(Color color) {
    return ThemeData.estimateBrightnessForColor(color);
  }

  static ThemeColor _getCustomColorTheme() {
    final Box<dynamic> box = Hive.box(HiveBox.boxName);
    final int primaryValue = box.get(
      HiveBox.customThemePrimaryColorKey,
      defaultValue: const Color(0xff5c03bc).value,
    ) as int;

    final int secondaryValue = box.get(
      HiveBox.customThemeSecondaryColorKey,
      defaultValue: const Color(0xff8b3ff0).value,
    ) as int;

    return CustomColorTheme(
      primaryColor: Color(primaryValue),
      secondaryColor: Color(secondaryValue),
    );
  }

  static ThemeColor _getCustomImageTheme() {
    final Box<dynamic> box = Hive.box(HiveBox.boxName);
    final int primaryValue = box.get(
      HiveBox.customThemePrimaryColorKey,
      defaultValue: const Color(0xff111111).value,
    ) as int;

    final int secondaryValue = box.get(
      HiveBox.customThemeSecondaryColorKey,
      defaultValue: const Color(0xff2d2d2d).value,
    ) as int;

    final String? imagePath =
        box.get(HiveBox.customThemeImagePathKey) as String?;

    return CustomImageTheme(
      overlayColor: Color(primaryValue),
      secondaryColor: Color(secondaryValue),
      imagePath: imagePath,
    );
  }

  static Color _shiftLightness(Color color, double delta) {
    final HSLColor hsl = HSLColor.fromColor(color);
    final double nextLightness = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(nextLightness).toColor();
  }

  static Future<String> _storeCustomThemeImage(String sourcePath) async {
    final File sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      throw StateError('Custom theme image does not exist: $sourcePath');
    }

    final Directory applicationDirectory =
        await getApplicationDocumentsDirectory();
    final Directory themeDirectory = Directory(
      '${applicationDirectory.path}${Platform.pathSeparator}custom_theme_images',
    );

    if (!themeDirectory.existsSync()) {
      await themeDirectory.create(recursive: true);
    }

    final String fileName = _buildCustomThemeImageFileName(sourcePath);
    final File storedFile = await sourceFile.copy(
      '${themeDirectory.path}${Platform.pathSeparator}$fileName',
    );

    return storedFile.path;
  }

  static String _buildCustomThemeImageFileName(String sourcePath) {
    final String normalizedPath = sourcePath.replaceAll('\\', '/');
    final String originalName = normalizedPath.split('/').last;
    final String extensionMatch = RegExp(r'(\.[^./\\]+)$')
            .firstMatch(originalName)
            ?.group(0) ??
        '.png';

    return 'theme_${DateTime.now().microsecondsSinceEpoch}$extensionMatch';
  }

  static Future<void> _deleteFileIfExists(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      return;
    }

    final File file = File(filePath);
    if (!file.existsSync()) {
      return;
    }

    try {
      await file.delete();
    } catch (_) {
      // Ignore cleanup failures so theme changes still succeed.
    }
  }
}

abstract class ThemeColor {
  final String themeName;
  final Color primaryColor;
  final Color secondaryColor;
  final ColorScheme colorScheme;
  final LinearGradient linearGradient;
  final String? backgroundImagePath;
  final Color overlayColor;

  const ThemeColor({
    required this.themeName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.colorScheme,
    required this.linearGradient,
    this.backgroundImagePath,
    this.overlayColor = Colors.transparent,
  });

  Color get adaptiveTextColor => Themes.getAdaptiveTextColor(primaryColor);
}

class CustomColorTheme extends ThemeColor {
  CustomColorTheme({required Color primaryColor, required Color secondaryColor})
      : super(
          themeName: Themes.customColorThemeName,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.deepPurple,
            brightness: Themes.estimateBrightness(primaryColor),
          ),
          linearGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              secondaryColor,
            ],
          ),
        );
}

class CustomImageTheme extends ThemeColor {
  CustomImageTheme({
    required Color overlayColor,
    required Color secondaryColor,
    required String? imagePath,
  }) : super(
          themeName: Themes.customImageThemeName,
          primaryColor: overlayColor,
          secondaryColor: secondaryColor,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blueGrey,
            brightness: Themes.estimateBrightness(overlayColor),
          ),
          linearGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              overlayColor,
              secondaryColor,
            ],
          ),
          backgroundImagePath: imagePath,
          overlayColor: overlayColor,
        );
}

class PurpleTheme extends ThemeColor {
  PurpleTheme()
      : super(
          themeName: 'Purple',
          primaryColor: const Color(0xff0e0725),
          secondaryColor: const Color(0xff5c03bc),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.purple,
            brightness: Brightness.dark,
          ),
          linearGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff0e0725),
              Color(0xff5c03bc),
            ],
          ),
        );
}

class BlueTheme extends ThemeColor {
  BlueTheme()
      : super(
          themeName: 'Blue',
          primaryColor: const Color(0xff000328),
          secondaryColor: const Color(0xFF00458e),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
          ),
          linearGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff000328),
              Color(0xFF00458e),
            ],
          ),
        );
}

class GreenTheme extends ThemeColor {
  GreenTheme()
      : super(
          themeName: 'Green',
          primaryColor: const Color(0xff0c0c0c),
          secondaryColor: const Color(0xFF0f971c),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.green,
            brightness: Brightness.dark,
          ),
          linearGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff0c0c0c),
              Color(0xFF0f971c),
            ],
          ),
        );
}

class OrangeTheme extends ThemeColor {
  OrangeTheme()
      : super(
          themeName: 'Orange',
          primaryColor: const Color(0xff471a0c),
          secondaryColor: const Color(0xFF8A4816),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.orange,
            brightness: Brightness.dark,
          ),
          linearGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff471a0c),
              Color(0xFF8A4816),
            ],
          ),
        );
}

class YellowTheme extends ThemeColor {
  YellowTheme()
      : super(
          themeName: 'Yellow',
          primaryColor: const Color(0xff161616),
          secondaryColor: const Color(0xFFb79c05),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.yellow,
            brightness: Brightness.dark,
          ),
          linearGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff161616),
              Color(0xFFb79c05),
            ],
          ),
        );
}

class TealTheme extends ThemeColor {
  TealTheme()
      : super(
          themeName: 'Teal',
          primaryColor: const Color(0xff0c4741),
          secondaryColor: const Color(0xFF168A7A),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.teal,
            brightness: Brightness.dark,
          ),
          linearGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff0c4741),
              Color(0xFF168A7A),
            ],
          ),
        );
}

class RedTheme extends ThemeColor {
  RedTheme()
      : super(
          themeName: 'Red',
          primaryColor: const Color(0xff1b0a07),
          secondaryColor: const Color(0xFF7f0012),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.red,
            brightness: Brightness.dark,
          ),
          linearGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff1b0a07),
              Color(0xFF7f0012),
            ],
          ),
        );
}

class BlackTheme extends ThemeColor {
  BlackTheme()
      : super(
          themeName: 'Black',
          primaryColor: const Color(0xff000000),
          secondaryColor: const Color(0xFF1B1B1B),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.grey,
            brightness: Brightness.dark,
          ),
          linearGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff000000),
              Color(0xFF1B1B1B),
            ],
          ),
        );
}

class WhiteTheme extends ThemeColor {
  WhiteTheme()
      : super(
          themeName: 'White',
          primaryColor: const Color(0XFFD3CCE3),
          secondaryColor: const Color(0xFFE9E4F0),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.grey,
            brightness: Brightness.light,
          ),
          linearGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0XFFD3CCE3),
              Color(0xFFE9E4F0),
            ],
          ),
        );
}

class GrayTheme extends ThemeColor {
  GrayTheme()
      : super(
          themeName: 'Gray',
          primaryColor: const Color(0xff232526),
          secondaryColor: const Color(0xFF414345),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.grey,
            brightness: Brightness.dark,
          ),
          linearGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff232526),
              Color(0xFF414345),
            ],
          ),
        );
}
