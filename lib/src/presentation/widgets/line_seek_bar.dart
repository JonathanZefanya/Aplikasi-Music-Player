import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:music/src/bloc/player/player_bloc.dart';
import 'package:music/src/data/repositories/player_repository.dart';

class LineSeekBar extends StatefulWidget {
  final MusicPlayer player;
  final Color? activeColor;

  const LineSeekBar({
    super.key,
    required this.player,
    this.activeColor,
  });

  @override
  State<LineSeekBar> createState() => _LineSeekBarState();
}

class _LineSeekBarState extends State<LineSeekBar> {
  double? _dragProgress;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.position,
      builder: (context, positionSnapshot) {
        final Duration position = positionSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration?>(
          stream: widget.player.duration,
          builder: (context, durationSnapshot) {
            final Duration duration = durationSnapshot.data ?? Duration.zero;

            final double progress = duration.inMilliseconds == 0
                ? 0
                : (position.inMilliseconds / duration.inMilliseconds)
                    .clamp(0.0, 1.0);

            final double shown = _dragProgress ?? progress;

            return Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => _seek(
                        details.localPosition.dx / constraints.maxWidth,
                        duration,
                      ),
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _dragProgress =
                              (details.localPosition.dx / constraints.maxWidth)
                                  .clamp(0.0, 1.0);
                        });
                      },
                      onHorizontalDragEnd: (_) {
                        if (_dragProgress != null) {
                          _seek(_dragProgress!, duration);
                        }
                        setState(() {
                          _dragProgress = null;
                        });
                      },
                      child: SizedBox(
                        height: 32,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _LinePainter(
                            progress: shown,
                            activeColor: widget.activeColor ?? Colors.white,
                            inactiveColor: Colors.white.withOpacity(0.28),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _format(_dragProgress == null
                          ? position
                          : duration * _dragProgress!),
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      _format(duration),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _seek(double ratio, Duration duration) {
    if (duration == Duration.zero) {
      return;
    }

    context.read<PlayerBloc>().add(
          PlayerSeek(
            Duration(
              milliseconds:
                  (duration.inMilliseconds * ratio.clamp(0.0, 1.0)).round(),
            ),
          ),
        );
  }

  String _format(Duration duration) {
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

class _LinePainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  static const double _trackHeight = 4;
  static const double _thumbRadius = 7;

  _LinePainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;
    final double usableWidth = size.width - _thumbRadius * 2;
    final double thumbX = _thumbRadius + usableWidth * progress;

    final Paint track = Paint()
      ..color = inactiveColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _trackHeight;

    canvas.drawLine(
      Offset(_thumbRadius, centerY),
      Offset(size.width - _thumbRadius, centerY),
      track,
    );

    if (progress > 0) {
      final Paint played = Paint()
        ..color = activeColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = _trackHeight;

      canvas.drawLine(
        Offset(_thumbRadius, centerY),
        Offset(thumbX, centerY),
        played,
      );
    }

    canvas.drawCircle(
      Offset(thumbX, centerY),
      _thumbRadius,
      Paint()..color = activeColor,
    );
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
