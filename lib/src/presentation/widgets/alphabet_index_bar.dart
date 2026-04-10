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
    final double contentHeight = _contentHeight(widget.letters.length);

    return LayoutBuilder(
          builder: (context, constraints) {
            final bool shouldFillHeight = widget.fillHeight && constraints.hasBoundedHeight;
            final double barHeight = shouldFillHeight
                ? constraints.maxHeight
                : contentHeight;
            final List<Widget> items = shouldFillHeight
                ? _buildFilledItems(separatorIndex)
                : _buildItems(separatorIndex);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _selectLetter(details.localPosition.dy),
          onPanDown: (details) => _selectLetter(details.localPosition.dy),
          onPanStart: (details) => _selectLetter(details.localPosition.dy),
          onPanUpdate: (details) => _selectLetter(details.localPosition.dy),
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
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                            mainAxisSize:
                                shouldFillHeight ? MainAxisSize.max : MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                    children: items,
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

  void _selectLetter(double localDy) {
    if (widget.letters.isEmpty) {
      return;
    }

    final double contentHeight = _contentHeight(widget.letters.length);
    final double clampedDy = localDy.clamp(0.0, contentHeight - 0.0001);
    final int? separatorIndex = _separatorIndex;

    if (widget.fillHeight) {
          final double separatorHeight = separatorIndex == null ? 0 : widget.separatorGapHeight;
          final double slotHeight = math.max(
            1.0,
            (contentHeight - separatorHeight - (_verticalPadding * 2)) /
                widget.letters.length,
          );
          double currentTop = _verticalPadding;
        return;
          for (int index = 0; index < widget.letters.length; index++) {
            final double itemBottom = currentTop + slotHeight;
            if (clampedDy < itemBottom) {
              final String selectedLetter = widget.letters[index];
              if (_activeLetter != selectedLetter) {
                setState(() {
                  _activeLetter = selectedLetter;
                });
                widget.onLetterTap(selectedLetter);
              }
              return;
            }
      }
            currentTop = itemBottom;

            if (separatorIndex != null && index == separatorIndex) {
              final double separatorBottom = currentTop + widget.separatorGapHeight;
              if (clampedDy < separatorBottom) {
                final int nextIndex = math.min(index + 1, widget.letters.length - 1);
                final String selectedLetter = widget.letters[nextIndex];
                if (_activeLetter != selectedLetter) {
                  setState(() {
                    _activeLetter = selectedLetter;
                  });
                  widget.onLetterTap(selectedLetter);
                }
                return;
              }
              currentTop = separatorBottom;
            }
          }
      final double slotHeight = contentHeight / entryCount;
          return;
        }
      int slotIndex = (clampedDy / slotHeight).floor();
        double currentTop = _verticalPadding;
      if (slotIndex >= entryCount) {
        for (int index = 0; index < widget.letters.length; index++) {
          final double itemBottom = currentTop + _itemExtent;
          if (clampedDy < itemBottom) {
            final String selectedLetter = widget.letters[index];
            if (_activeLetter != selectedLetter) {
              setState(() {
                _activeLetter = selectedLetter;
              });
              widget.onLetterTap(selectedLetter);
            }
            return;
          }
        slotIndex = entryCount - 1;
          currentTop = itemBottom;
      }
          if (index != widget.letters.length - 1) {
            final double gapBottom = currentTop + _itemGap;
            if (clampedDy < gapBottom) {
              final String selectedLetter = widget.letters[index];
              if (_activeLetter != selectedLetter) {
                setState(() {
            return LayoutBuilder(
              builder: (context, constraints) {
                final bool fillHeight = widget.fillHeight && constraints.hasBoundedHeight;
                final double barHeight = fillHeight ? constraints.maxHeight : contentHeight;
                final double selectionHeight = fillHeight ? barHeight : contentHeight;
          if (separatorIndex != null && index == separatorIndex) {
            final double separatorBottom = currentTop + widget.separatorGapHeight;
            if (clampedDy < separatorBottom) {
              final int nextIndex = math.min(index + 1, widget.letters.length - 1);
              final String selectedLetter = widget.letters[nextIndex];
              if (_activeLetter != selectedLetter) {
                setState(() {
                  _activeLetter = selectedLetter;
                });
                widget.onLetterTap(selectedLetter);
              }
              return;
            }
            currentTop = separatorBottom;
          }
        }
      }
      final int selectedLetterIndex = _letterIndexFromFillSlot(slotIndex, separatorIndex);
      List<Widget> _buildFilledItems(int? separatorIndex) {
        final items = <Widget>[];
      final String selectedLetter = widget.letters[selectedLetterIndex];
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
      if (_activeLetter != selectedLetter) {
          if (separatorIndex != null && index == separatorIndex) {
            items.add(SizedBox(height: widget.separatorGapHeight));
          }
        }
        setState(() {
        return items;
      }
          _activeLetter = selectedLetter;
        });
        widget.onLetterTap(selectedLetter);
      }
      return;
    }

    double currentTop = _verticalPadding;

    for (int index = 0; index < widget.letters.length; index++) {
      final double itemBottom = currentTop + _itemExtent;
      if (clampedDy < itemBottom) {
        final String selectedLetter = widget.letters[index];
        if (_activeLetter != selectedLetter) {
          setState(() {
            _activeLetter = selectedLetter;
          });
          widget.onLetterTap(selectedLetter);
        }
        return;
      }

      currentTop = itemBottom;

      if (index != widget.letters.length - 1) {
        final double gapBottom = currentTop + _itemGap;
        if (clampedDy < gapBottom) {
          final String selectedLetter = widget.letters[index];
          if (_activeLetter != selectedLetter) {
            setState(() {
              _activeLetter = selectedLetter;
            });
            widget.onLetterTap(selectedLetter);
          }
          return;
        }
        currentTop = gapBottom;
      }

      if (separatorIndex != null && index == separatorIndex) {
        final double separatorBottom = currentTop + widget.separatorGapHeight;
        if (clampedDy < separatorBottom) {
          final int nextIndex = math.min(index + 1, widget.letters.length - 1);
          final String selectedLetter = widget.letters[nextIndex];
          if (_activeLetter != selectedLetter) {
            setState(() {
              _activeLetter = selectedLetter;
            });
            widget.onLetterTap(selectedLetter);
          }
          return;
        }
        currentTop = separatorBottom;
      }
    }
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

  List<Widget> _buildItems(int? separatorIndex) {
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
        items.add(const _AlphabetIndexSeparator());
      }
    }

    return items;
  }

  int _letterIndexFromFillSlot(int slotIndex, int? separatorIndex) {
    if (separatorIndex == null) {
      return slotIndex.clamp(0, widget.letters.length - 1);
    }

    if (slotIndex <= separatorIndex) {
      return slotIndex.clamp(0, widget.letters.length - 1);
    }

    if (slotIndex == separatorIndex + 1) {
      return math.min(separatorIndex + 1, widget.letters.length - 1);
    }

    return (slotIndex - 1).clamp(0, widget.letters.length - 1);
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
  const _AlphabetIndexSeparator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 8,
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