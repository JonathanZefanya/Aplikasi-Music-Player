import 'package:flutter/material.dart';
import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/core/theme/themes.dart';

class AppThemeData {
  static ThemeData getTheme() {
    final theme = Themes.getTheme();
    final textColor = theme.adaptiveTextColor;
    final Color muted = textColor.withOpacity(0.65);
    final Color faint = textColor.withOpacity(0.12);

    final ColorScheme colorScheme = theme.colorScheme.copyWith(
      onPrimary: textColor,
      onSecondary: textColor,
      onSurface: textColor,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: theme.primaryColor,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme(theme.colorScheme.brightness, textColor, muted),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      iconTheme: IconThemeData(color: textColor),
      dividerTheme: DividerThemeData(
        color: faint,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        iconColor: muted,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: muted,
          fontSize: 13,
        ),
        selectedColor: colorScheme.primary,
      ),
      cardTheme: CardThemeData(
        color: textColor.withOpacity(0.06),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: textColor.withOpacity(0.08),
        selectedColor: colorScheme.primary.withOpacity(0.9),
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: textColor,
        unselectedLabelColor: muted,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: textColor,
        inactiveTrackColor: textColor.withOpacity(0.25),
        thumbColor: textColor,
        trackHeight: 3.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: textColor.withOpacity(0.14),
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? textColor : muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: textColor.withOpacity(0.14),
        selectedIconTheme: IconThemeData(color: textColor),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: muted, fontSize: 12),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: theme.primaryColor,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: theme.primaryColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        showDragHandle: true,
        dragHandleColor: muted,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: theme.primaryColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: textColor.withOpacity(0.06),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: textColor.withOpacity(0.4)),
        ),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : muted,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.small),
        ),
      ),
    );
  }

  static TextTheme _textTheme(
    Brightness brightness,
    Color textColor,
    Color muted,
  ) {
    final TextTheme base = ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: textColor,
          displayColor: textColor,
        );

    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
      bodySmall: base.bodySmall?.copyWith(color: muted, height: 1.4),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
