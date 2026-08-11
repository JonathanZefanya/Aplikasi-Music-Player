import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:music/src/core/theme/app_dimens.dart';
import 'package:music/src/core/theme/themes.dart';

class FloatingNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const FloatingNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Floating bar with a raised circular indicator that slides between
/// destinations. The indicator deliberately overflows the top edge of the
/// card, so nothing in this widget may clip it.
class FloatingNavBar extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  static const double _cardHeight = 76;
  static const double _lift = 12;
  static const double _indicator = 52;
  static const double _iconTop = 8;
  static const double _iconSize = 24;

  double get _totalHeight => _cardHeight + _lift;

  /// Centre of the icon, measured from the top of the whole widget.
  double get _iconCenterY => _lift + _iconTop + _iconSize / 2;

  @override
  Widget build(BuildContext context) {
    final Color surface = Themes.getTheme().primaryColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color accent = _accentFor(context, surface, onSurface);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: SizedBox(
          height: _totalHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double slot = constraints.maxWidth / items.length;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildCard(surface, onSurface),
                  _buildIndicator(slot, surface, accent),
                  _buildItems(accent, onSurface),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Color surface, Color onSurface) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: _cardHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Color.alphaBlend(onSurface.withOpacity(0.06), surface)
                  .withOpacity(0.92),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: onSurface.withOpacity(0.08)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(double slot, Color surface, Color accent) {
    return AnimatedPositioned(
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
      left: slot * currentIndex + (slot - _indicator) / 2,
      top: _iconCenterY - _indicator / 2,
      width: _indicator,
      height: _indicator,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Opaque so it reads as a raised disc instead of a smudge.
          color: Color.alphaBlend(accent.withOpacity(0.22), surface),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItems(Color accent, Color onSurface) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: _cardHeight,
      child: Row(
        children: [
          for (int index = 0; index < items.length; index++)
            Expanded(
              child: _NavBarItem(
                item: items[index],
                selected: index == currentIndex,
                accent: accent,
                muted: onSurface.withOpacity(0.55),
                onTap: () => onSelected(index),
              ),
            ),
        ],
      ),
    );
  }

  /// The themed accent is only used when it stays legible on the bar,
  /// otherwise the adaptive text colour takes over.
  Color _accentFor(BuildContext context, Color surface, Color onSurface) {
    final Color primary = Theme.of(context).colorScheme.primary;

    final double a = surface.computeLuminance() + 0.05;
    final double b = primary.computeLuminance() + 0.05;
    final double contrast = max(a, b) / min(a, b);

    return contrast >= 2.2 ? primary : onSurface;
  }
}

class _NavBarItem extends StatelessWidget {
  final FloatingNavItem item;
  final bool selected;
  final Color accent;
  final Color muted;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.selected,
    required this.accent,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
      builder: (context, t, _) {
        final Color color = Color.lerp(muted, accent, t)!;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            children: [
              const SizedBox(height: FloatingNavBar._iconTop),
              Transform.scale(
                scale: 1 + 0.1 * t,
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: color,
                  size: FloatingNavBar._iconSize,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.lerp(
                    FontWeight.w500,
                    FontWeight.w700,
                    t,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
