import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 18,
    this.opacity = 0.18,
    this.borderRadius = const BorderRadius.vertical(
      top: Radius.circular(25),
    ),
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color tint =
        brightness == Brightness.dark ? Colors.white : Colors.black;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: tint.withOpacity(opacity * 0.5),
            border: Border.all(
              color: tint.withOpacity(opacity),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
