import 'package:flutter/widgets.dart';

enum ScreenSize { compact, medium, expanded }

extension ResponsiveContext on BuildContext {
  static const double _mediumBreakpoint = 600;
  static const double _expandedBreakpoint = 1024;

  double get screenWidth => MediaQuery.sizeOf(this).width;

  ScreenSize get screenSize {
    final double width = screenWidth;

    if (width >= _expandedBreakpoint) {
      return ScreenSize.expanded;
    }

    if (width >= _mediumBreakpoint) {
      return ScreenSize.medium;
    }

    return ScreenSize.compact;
  }

  bool get isCompact => screenSize == ScreenSize.compact;
  bool get isExpanded => screenSize == ScreenSize.expanded;

  /// Side navigation replaces the bottom bar once there is room for it.
  bool get usesSideNavigation => !isCompact;

  /// Keeps text lines readable instead of stretching edge to edge on tablets.
  double get contentMaxWidth {
    switch (screenSize) {
      case ScreenSize.compact:
        return double.infinity;
      case ScreenSize.medium:
        return 720;
      case ScreenSize.expanded:
        return 1100;
    }
  }

  /// Bottom padding a scrollable needs so its last item clears whatever the
  /// Scaffold stacks below it.
  ///
  /// With `extendBody: true` the Scaffold reports the combined height of the
  /// mini player plus navigation bar through MediaQuery padding, so this
  /// shrinks automatically when nothing is playing and the mini player is gone.
  double get bottomBarInset => MediaQuery.paddingOf(this).bottom + 16;

  /// Horizontal padding that centres a full-width scrollable inside
  /// [contentMaxWidth]. Useful where wrapping in [ContentWidth] would mean
  /// restructuring an existing widget tree.
  EdgeInsets get contentPadding {
    final double maxWidth = contentMaxWidth;

    if (!maxWidth.isFinite) {
      return EdgeInsets.zero;
    }

    final double inset = ((screenWidth - maxWidth) / 2).clamp(
      0.0,
      double.infinity,
    );

    return EdgeInsets.symmetric(horizontal: inset);
  }
}

/// Centers and caps the width of a page body on large screens.
class ContentWidth extends StatelessWidget {
  final Widget child;

  const ContentWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
        child: child,
      ),
    );
  }
}
