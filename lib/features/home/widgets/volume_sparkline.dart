import 'package:curvefree/app/theme/curve_colors.dart';
import 'package:flutter/material.dart';

abstract final class SparklineLayout {
  static const double height = 96;
  static const double strokeWidth = 2;
  static const double dotRadius = 3;
}

class VolumeSparkline extends StatelessWidget {
  const VolumeSparkline({super.key, required this.volumes});

  final List<double> volumes;

  @override
  Widget build(BuildContext context) {
    final CurveColors colors = CurveColors.of(context);
    return SizedBox(
      key: const Key('train_trend_sparkline'),
      height: SparklineLayout.height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          volumes: volumes,
          line: colors.primary,
          endpoint: colors.accent,
          baseline: colors.borderStrong,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.volumes,
    required this.line,
    required this.endpoint,
    required this.baseline,
  });

  final List<double> volumes;
  final Color line;
  final Color endpoint;
  final Color baseline;

  @override
  void paint(Canvas canvas, Size size) {
    final double inset =
        SparklineLayout.dotRadius + SparklineLayout.strokeWidth;
    final double width = size.width - inset * 2;
    final double height = size.height - inset * 2;
    if (width <= 0 || height <= 0 || volumes.isEmpty) {
      return;
    }
    double peak = 0;
    for (final double volume in volumes) {
      if (volume > peak) {
        peak = volume;
      }
    }
    final double plotMax = peak <= 0 ? 1 : peak;
    final List<Offset> points = <Offset>[];
    for (int i = 0; i < volumes.length; i++) {
      final double t = volumes.length == 1 ? 0.5 : i / (volumes.length - 1);
      final double dx = inset + width * t;
      final double fraction = volumes[i] <= 0 ? 0 : volumes[i] / plotMax;
      final double dy = inset + height - height * fraction;
      points.add(Offset(dx, dy));
    }
    final Paint baselinePaint = Paint()
      ..color = baseline
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(inset, inset + height),
      Offset(inset + width, inset + height),
      baselinePaint,
    );
    final Paint linePaint = Paint()
      ..color = line
      ..strokeWidth = SparklineLayout.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (points.length == 1) {
      canvas.drawCircle(points.single, SparklineLayout.dotRadius, linePaint);
    } else {
      final Path path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final Offset point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, linePaint);
    }
    final Paint dotPaint = Paint()..color = line;
    for (int i = 0; i < points.length; i++) {
      final bool last = i == points.length - 1;
      dotPaint.color = last ? endpoint : line;
      canvas.drawCircle(points[i], SparklineLayout.dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.volumes != volumes ||
        oldDelegate.line != line ||
        oldDelegate.endpoint != endpoint ||
        oldDelegate.baseline != baseline;
  }
}
