import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:music/src/bloc/player/player_bloc.dart';
import 'package:music/src/data/repositories/player_repository.dart';

class WaveformSeekBar extends StatefulWidget {
  final MusicPlayer player;
  final String seed;
  final Color? activeColor;

  const WaveformSeekBar({
    super.key,
    required this.player,
    required this.seed,
    this.activeColor,
  });

  @override
  State<WaveformSeekBar> createState() => _WaveformSeekBarState();
}

class _WaveformSeekBarState extends State<WaveformSeekBar> {
  static const int _barCount = 64;

  double? _dragProgress;

  List<double> get _amplitudes {
    int state = widget.seed.hashCode & 0x7fffffff;

    return List<double>.generate(_barCount, (index) {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return 0.18 + (state % 1000) / 1000 * 0.82;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.position,
      builder: (context, positionSnapshot) {
        final Duration position = positionSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration?>(
          stream: widget.player.duration,
          builder: (context, durationSnapshot) {
            final Duration duration =
                durationSnapshot.data ?? Duration.zero;

            final double progress = duration.inMilliseconds == 0
                ? 0
                : (position.inMilliseconds / duration.inMilliseconds)
                    .clamp(0.0, 1.0);

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
                        height: 48,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _WaveformPainter(
                            amplitudes: _amplitudes,
                            progress: _dragProgress ?? progress,
                            activeColor: widget.activeColor ??
                                Theme.of(context).colorScheme.primary,
                            inactiveColor: Colors.white.withOpacity(0.28),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _format(position),
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

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) {
      return;
    }

    final double slot = size.width / amplitudes.length;
    final double barWidth = slot * 0.55;
    final double centerY = size.height / 2;
    final int playedBars = (amplitudes.length * progress).round();

    for (int index = 0; index < amplitudes.length; index++) {
      final double barHeight = size.height * amplitudes[index];
      final Paint paint = Paint()
        ..color = index < playedBars ? activeColor : inactiveColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;

      final double x = slot * index + slot / 2;

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.amplitudes != amplitudes;
  }
}
