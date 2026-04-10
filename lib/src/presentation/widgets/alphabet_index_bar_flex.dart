import 'dart:math' as math;

import 'package:flutter/material.dart';

class AlphabetIndexBar extends StatefulWidget {
  final List<String> letters;
  final ValueChanged<String> onLetterTap;
  final int? separatorBeforeLastCount;
  final double separatorGapHeight;
  final bool fillHeight;

  const AlphabetIndexBar({
    super.key,
    required this.letters,
    required this.onLetterTap,
    this.separatorBeforeLastCount,
    this.separatorGapHeight = 8,
    this.fillHeight = false,
  });

  @override
  State<AlphabetIndexBar> createState() => _AlphabetIndexBarState();
}

class _AlphabetIndexBarState extends State<AlphabetIndexBar> {
  String? _activeLetter;

  static const double _itemExtent = 24;
  static const double _itemGap = 4;
  static const double _verticalPadding = 8;

  @override
  Widget build(BuildContext context) {
    if (widget.letters.isEmpty) {
      return const SizedBox.shrink();
    }

    final int? separatorIndex = _separatorIndex;
    final double naturalHeight = _contentHeight(widget.letters.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool fillHeight = widget.fillHeight && constraints.hasBoundedHeight;
        final double barHeight = fillHeight ? constraints.maxHeight : naturalHeight;
        final double selectionHeight = fillHeight ? barHeight : naturalHeight;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _selectLetter(details.localPosition.dy, selectionHeight),
          onPanDown: (details) => _selectLetter(details.localPosition.dy, selectionHeight),
          onPanStart: (details) => _selectLetter(details.localPosition.dy, selectionHeight),
          onPanUpdate: (details) => _selectLetter(details.localPosition.dy, selectionHeight),
          onPanEnd: (_) => _clearActiveLetter(),
          onPanCancel: _clearActiveLetter,
          child: SizedBox(
            width: 34,
            height: barHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: _verticalPadding,
                ),
                child: fillHeight
                    ? Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildFilledChildren(separatorIndex),
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: _buildCompactChildren(separatorIndex),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _contentHeight(int count) {
    if (count <= 0) {
      return 0;
    }

    final int? separatorIndex = _separatorIndex;

    return (_verticalPadding * 2) +
        (count * _itemExtent) +
        (math.max(0, count - 1) * _itemGap) +
        (separatorIndex == null ? 0 : widget.separatorGapHeight);
  }

  void _selectLetter(double localDy, double availableHeight) {
    if (widget.letters.isEmpty) {
      return;
    }

    final int? separatorIndex = _separatorIndex;

    if (widget.fillHeight) {
      final double separatorHeight = separatorIndex == null ? 0 : widget.separatorGapHeight;
      final double usableHeight = math.max(
        1.0,
        availableHeight - (_verticalPadding * 2) - separatorHeight,
      );
      final double slotHeight = usableHeight / widget.letters.length;
      final double clampedDy = localDy.clamp(0.0, availableHeight - 0.0001);

      double currentTop = _verticalPadding;
      for (int index = 0; index < widget.letters.length; index++) {
        final double itemBottom = currentTop + slotHeight;
        if (clampedDy < itemBottom) {
          _activateLetter(widget.letters[index]);
          return;
        }

        currentTop = itemBottom;

        if (separatorIndex != null && index == separatorIndex) {
          final double separatorBottom = currentTop + widget.separatorGapHeight;
          if (clampedDy < separatorBottom) {
            _activateLetter(widget.letters[math.min(index + 1, widget.letters.length - 1)]);
            return;
          }
          currentTop = separatorBottom;
        }
      }

      return;
    }

    final double contentHeight = _contentHeight(widget.letters.length);
    final double clampedDy = localDy.clamp(0.0, contentHeight - 0.0001);
    double currentTop = _verticalPadding;

    for (int index = 0; index < widget.letters.length; index++) {
      final double itemBottom = currentTop + _itemExtent;
      if (clampedDy < itemBottom) {
        _activateLetter(widget.letters[index]);
        return;
      }

      currentTop = itemBottom;

      if (index != widget.letters.length - 1) {
        final double gapBottom = currentTop + _itemGap;
        if (clampedDy < gapBottom) {
          _activateLetter(widget.letters[index]);
          return;
        }
        currentTop = gapBottom;
      }

      if (separatorIndex != null && index == separatorIndex) {
        final double separatorBottom = currentTop + widget.separatorGapHeight;
        if (clampedDy < separatorBottom) {
          _activateLetter(widget.letters[math.min(index + 1, widget.letters.length - 1)]);
          return;
        }
        currentTop = separatorBottom;
      }
    }
  }

  void _activateLetter(String selectedLetter) {
    if (_activeLetter == selectedLetter) {
      return;
    }

    setState(() {
      _activeLetter = selectedLetter;
    });
    widget.onLetterTap(selectedLetter);
  }

  int? get _separatorIndex {
    final int? tailCount = widget.separatorBeforeLastCount;
    if (tailCount == null || tailCount <= 0) {
      return null;
    }

    if (widget.letters.length <= tailCount) {
      return null;
    }

    return widget.letters.length - tailCount - 1;
  }

  List<Widget> _buildCompactChildren(int? separatorIndex) {
    final items = <Widget>[];

    for (int index = 0; index < widget.letters.length; index++) {
      items.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: index == widget.letters.length - 1 ? 0 : _itemGap,
          ),
          child: _AlphabetIndexLetter(
            letter: widget.letters[index],
            isActive: _activeLetter == widget.letters[index],
          ),
        ),
      );

      if (separatorIndex != null && index == separatorIndex) {
        items.add(const _AlphabetIndexSeparator(height: 8));
      }
    }

    return items;
  }

  List<Widget> _buildFilledChildren(int? separatorIndex) {
    final items = <Widget>[];

    for (int index = 0; index < widget.letters.length; index++) {
      items.add(
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _AlphabetIndexLetter(
                letter: widget.letters[index],
                isActive: _activeLetter == widget.letters[index],
              ),
            ),
          ),
        ),
      );

      if (separatorIndex != null && index == separatorIndex) {
        items.add(SizedBox(height: widget.separatorGapHeight));
      }
    }

    return items;
  }

  void _clearActiveLetter() {
    if (_activeLetter == null) {
      return;
    }

    setState(() {
      _activeLetter = null;
    });
  }
}

class _AlphabetIndexLetter extends StatelessWidget {
  final String letter;
  final bool isActive;

  const _AlphabetIndexLetter({
    required this.letter,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final Color surfaceColor = Theme.of(context).colorScheme.surface;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color activeColor = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.22) : surfaceColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isActive ? activeColor : textColor,
        ),
      ),
    );
  }
}

class _AlphabetIndexSeparator extends StatelessWidget {
  final double height;

  const _AlphabetIndexSeparator({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: height,
      child: Center(
        child: Container(
          width: 18,
          height: 2,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}