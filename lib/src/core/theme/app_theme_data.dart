import 'package:flutter/material.dart';
import 'package:music/src/core/theme/themes.dart';

class AppThemeData {
  static ThemeData getTheme() {
    final theme = Themes.getTheme();
    final textColor = theme.adaptiveTextColor;

    return ThemeData(
      colorScheme: theme.colorScheme.copyWith(
        onPrimary: textColor,
        onSecondary: textColor,
        onSurface: textColor,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: theme.primaryColor,
      textTheme: ThemeData(
        brightness: theme.colorScheme.brightness,
      ).textTheme.apply(
            bodyColor: textColor,
            displayColor: textColor,
          ),
      appBarTheme: AppBarTheme(
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: IconThemeData(color: textColor),
      sliderTheme: SliderThemeData(
        activeTrackColor: textColor,
        inactiveTrackColor: textColor.withOpacity(0.35),
        thumbColor: textColor,
        trackHeight: 2.0,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 6.0,
        ),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: theme.primaryColor,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: theme.primaryColor,
      ),
    );
  }
}
