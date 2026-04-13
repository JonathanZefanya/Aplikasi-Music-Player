import 'dart:math' as math;

import 'package:flutter/material.dart';

class AlphabetIndexBar extends StatefulWidget {
  const AlphabetIndexBar({
    super.key,
    required this.letters,
    required this.onSelected,
    this.initialLetter,
    this.activeColor,
    this.inactiveColor,
    this.separatorBeforeLastCount,
    this.fillHeight = false,
    this.itemGap = 4,
    this.separatorGap = 8,
    this.width = 28,
    this.horizontalPadding = 4,
    this.verticalPadding = 8,
    this.textStyle,
  });

  final List<String> letters;
  final ValueChanged<String> onSelected;
  final String? initialLetter;
  final Color? activeColor;
  final Color? inactiveColor;
  final int? separatorBeforeLastCount;
  final bool fillHeight;
  final double itemGap;
  final double separatorGap;
  final double width;
  final double horizontalPadding;
  final double verticalPadding;
  final TextStyle? textStyle;

  @override
  State<AlphabetIndexBar> createState() => _AlphabetIndexBarState();
}

class _AlphabetIndexBarState extends State<AlphabetIndexBar> {
  static const double _minItemExtent = 24;

  String? _activeLetter;

  int? get _separatorIndex {
    final count = widget.separatorBeforeLastCount;
    if (count == null || count <= 0) {
      return null;
    }

    final separatorIndex = widget.letters.length - count;
    if (separatorIndex <= 0 || separatorIndex >= widget.letters.length) {
      return null;
    }

    return separatorIndex;
  }

  @override
  void initState() {
    super.initState();
    _activeLetter = widget.initialLetter;
  }

  @override
  void didUpdateWidget(covariant AlphabetIndexBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLetter != oldWidget.initialLetter &&
        widget.initialLetter != _activeLetter) {
      _activeLetter = widget.initialLetter;
    }

    if (_activeLetter != null && !widget.letters.contains(_activeLetter)) {
      _activeLetter = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.letters.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final textStyle = widget.textStyle ?? theme.textTheme.labelSmall;
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;
    final inactiveColor = widget.inactiveColor ??
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72);

    return SizedBox(
      width: widget.width,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedHeight = constraints.hasBoundedHeight &&
              constraints.maxHeight.isFinite &&
              constraints.maxHeight > 0;

          final children = widget.fillHeight && hasBoundedHeight
              ? _buildFilledChildren(
                  context: context,
                  textStyle: textStyle,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  availableHeight: constraints.maxHeight,
                )
              : _buildCompactChildren(
                  context: context,
                  textStyle: textStyle,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                );

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) {
              final letter = _letterForLocalPosition(
                context: context,
                localPosition: details.localPosition,
                availableHeight: hasBoundedHeight ? constraints.maxHeight : null,
              );
              if (letter != null) {
                _activateLetter(letter);
              }
            },
            onTapUp: (_) => _clearActiveLetter(),
            onTapCancel: _clearActiveLetter,
            onVerticalDragDown: (details) {
              final letter = _letterForLocalPosition(
                context: context,
                localPosition: details.localPosition,
                availableHeight: hasBoundedHeight ? constraints.maxHeight : null,
              );
              if (letter != null) {
                _activateLetter(letter);
              }
            },
            onVerticalDragUpdate: (details) {
              final letter = _letterForLocalPosition(
                context: context,
                localPosition: details.localPosition,
                availableHeight: hasBoundedHeight ? constraints.maxHeight : null,
              );
              if (letter != null) {
                _activateLetter(letter);
              }
            },
            onVerticalDragEnd: (_) => _clearActiveLetter(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.horizontalPadding,
                vertical: widget.verticalPadding,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: widget.fillHeight && hasBoundedHeight
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCompactChildren({
    required BuildContext context,
    required TextStyle? textStyle,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final children = <Widget>[];
    final separatorIndex = _separatorIndex;

    for (var index = 0; index < widget.letters.length; index++) {
      children.add(
        _AlphabetIndexLetter(
          letter: widget.letters[index],
          isActive: widget.letters[index] == _activeLetter,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          textStyle: textStyle,
          minExtent: _minItemExtent,
          onSelected: _activateLetter,
        ),
      );

      if (separatorIndex != null && index == separatorIndex) {
        children.add(SizedBox(height: widget.separatorGap));
      } else if (index < widget.letters.length - 1) {
        children.add(SizedBox(height: widget.itemGap));
      }
    }

    return children;
  }

  List<Widget> _buildFilledChildren({
    required BuildContext context,
    required TextStyle? textStyle,
    required Color activeColor,
    required Color inactiveColor,
    required double availableHeight,
  }) {
    final separatorIndex = _separatorIndex;
    final separatorCount = separatorIndex == null ? 0 : 1;
    final usableHeight = math.max(
      1.0,
      availableHeight - widget.verticalPadding * 2 - (separatorCount * widget.separatorGap),
    );
    final itemHeight = usableHeight / widget.letters.length;

    final children = <Widget>[];
    for (var index = 0; index < widget.letters.length; index++) {
      children.add(
        Expanded(
          child: _AlphabetIndexLetter(
            letter: widget.letters[index],
            isActive: widget.letters[index] == _activeLetter,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            textStyle: textStyle,
            minExtent: itemHeight,
            onSelected: _activateLetter,
          ),
        ),
      );

      if (separatorIndex != null && index == separatorIndex) {
        children.add(SizedBox(height: widget.separatorGap));
      }
    }

    return children;
  }

  String? _letterForLocalPosition({
    required BuildContext context,
    required Offset localPosition,
    required double? availableHeight,
  }) {
    if (widget.letters.isEmpty) {
      return null;
    }

    if (widget.fillHeight && availableHeight != null && availableHeight > 0) {
      return _letterForFilledPosition(localPosition.dy, availableHeight);
    }

    return _letterForCompactPosition(localPosition.dy);
  }

  String? _letterForCompactPosition(double localDy) {
    final separatorIndex = _separatorIndex;
    var cursor = widget.verticalPadding;

    for (var index = 0; index < widget.letters.length; index++) {
      final extent = _minItemExtent;
      if (localDy >= cursor && localDy < cursor + extent) {
        return widget.letters[index];
      }
      cursor += extent;

      final isSeparator = separatorIndex != null && index == separatorIndex;
      if (isSeparator) {
        if (localDy < cursor + widget.separatorGap) {
          return widget.letters[math.min(index + 1, widget.letters.length - 1)];
        }
        cursor += widget.separatorGap;
      } else if (index < widget.letters.length - 1) {
        cursor += widget.itemGap;
      }
    }

    return widget.letters.last;
  }

  String? _letterForFilledPosition(double localDy, double availableHeight) {
    final separatorIndex = _separatorIndex;
    final separatorCount = separatorIndex == null ? 0 : 1;
    final usableHeight = math.max(
      1.0,
      availableHeight - widget.verticalPadding * 2 - (separatorCount * widget.separatorGap),
    );
    final itemHeight = usableHeight / widget.letters.length;
    var cursor = widget.verticalPadding;

    for (var index = 0; index < widget.letters.length; index++) {
      if (localDy >= cursor && localDy < cursor + itemHeight) {
        return widget.letters[index];
      }
      cursor += itemHeight;

      if (separatorIndex != null && index == separatorIndex) {
        if (localDy < cursor + widget.separatorGap) {
          return widget.letters[math.min(index + 1, widget.letters.length - 1)];
        }
        cursor += widget.separatorGap;
      }
    }

    return widget.letters.last;
  }

  void _activateLetter(String letter) {
    if (!mounted || _activeLetter == letter) {
      if (mounted) {
        widget.onSelected(letter);
      }
      return;
    }

    setState(() {
      _activeLetter = letter;
    });
    widget.onSelected(letter);
  }

  void _clearActiveLetter() {
    if (!mounted || _activeLetter == null) {
      return;
    }

    setState(() {
      _activeLetter = null;
    });
  }
}

class _AlphabetIndexLetter extends StatelessWidget {
  const _AlphabetIndexLetter({
    required this.letter,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.textStyle,
    required this.minExtent,
    required this.onSelected,
  });

  final String letter;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final TextStyle? textStyle;
  final double minExtent;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? activeColor : inactiveColor;
    final effectiveStyle = (textStyle ?? theme.textTheme.labelSmall)?.copyWith(
      color: color,
      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
      height: 1,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minExtent),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isActive)
            Positioned(
              right: 30,
              child: _AlphabetIndexBubble(
                letter: letter,
                activeColor: activeColor,
              ),
            ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onSelected(letter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: isActive ? activeColor.withValues(alpha: 0.14) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    letter,
                    style: effectiveStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlphabetIndexBubble extends StatelessWidget {
  const _AlphabetIndexBubble({
    required this.letter,
    required this.activeColor,
  });

  final String letter;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final bubbleBackground = Theme.of(context).colorScheme.surface;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      scale: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bubbleBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: activeColor.withValues(alpha: 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: activeColor,
          ),
        ),
      ),
    );
  }
}
