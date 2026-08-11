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
