import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// widget for spinning a wheel
class WidgetSpinningWheel extends StatefulWidget {
  final List<String> labels;
  final Function(String label) onSpinComplete;
  final double size;
  final double defaultSpeed;
  final List<Color>? colours;
  final TextStyle? textStyle;
  final bool shouldVibrate;
  const WidgetSpinningWheel({
    super.key,
    required this.labels,
    required this.onSpinComplete,
    required this.size,
    this.defaultSpeed = 0.3,
    this.colours,
    this.textStyle,
    this.shouldVibrate = true,
  });

  @override
  State<WidgetSpinningWheel> createState() => _WidgetSpinningWheelState();
}

class _WidgetSpinningWheelState extends State<WidgetSpinningWheel> {
  double rateOfSlowDown = 0;
  double currentOffset = 0;
  double currentSpeed = 0;
  Timer? timer;

  late List<double> labelValues =
      List<double>.generate(widget.labels.length, (index) => 1);

  /// the angles for the angle limits
  late List<double> labelLimits =
      List<double>.generate(widget.labels.length, (index) {
    double anglePerSection = (2 * pi) / widget.labels.length;
    return anglePerSection + index * anglePerSection;
  });

  /// the current label based on the offset
  String get currentLabel {
    double angle = currentOffset.remainder(2 * pi);
    for (int i = 0; i < labelLimits.length; i++) {
      double limit = labelLimits[i];
      if (angle < limit) {
        return widget.labels.reversed.toList()[i];
      }
    }

    throw ('cannot find');
  }

  /// the starting label before it starts spinning
  late String previousLabel = currentLabel;

  /// spins the wheel
  void spin({double? withSpeed}) {
    if (timer != null) timer?.cancel();
    currentSpeed = withSpeed ?? widget.defaultSpeed;
    rateOfSlowDown = Random().nextDouble() / 500;

    timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      // update speed
      currentSpeed -= rateOfSlowDown;
      currentSpeed = currentSpeed.clamp(0, 1);

      currentOffset += currentSpeed;

      if (widget.shouldVibrate) {
        String latestCurrentLabel = currentLabel;
        if (previousLabel != latestCurrentLabel) {
          previousLabel = latestCurrentLabel;
          HapticFeedback.lightImpact();
        }
      }

      if (currentSpeed == 0) {
        widget.onSpinComplete(currentLabel);

        timer.cancel();
      }

      if (mounted) {
        setState(() {});
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: GestureDetector(
        onTap: () {
          spin();
        },
        onVerticalDragUpdate: (details) {
          int multiplier = -1;

          // check if left or right
          if (details.localPosition.dx >= widget.size / 2) {
            multiplier = 1;
          }

          currentOffset += multiplier * details.delta.dy / 50;
          setState(() {});
        },
        onVerticalDragEnd: (details) {
          double velocity = details.velocity.pixelsPerSecond.dy.abs() / 10000;
          spin(withSpeed: velocity);
        },
        onHorizontalDragUpdate: (details) {
          int multiplier = 1;

          // check if top or bottom half
          if (details.localPosition.dy >= widget.size / 2) {
            multiplier = -1;
          }

          currentOffset += multiplier * details.delta.dx / 50;
          setState(() {});
        },
        onHorizontalDragEnd: (details) {
          double velocity = details.velocity.pixelsPerSecond.dx.abs() / 10000;
          spin(withSpeed: velocity);
        },
        child: PieChart(
          data: labelValues,
          labels: widget.labels,
          angleOffset: currentOffset,
          radius: 1000,
          customColours: widget.colours ??
              [
                Colors.red,
                Colors.green,
                Colors.blue,
                Colors.yellow,
                Colors.orange,
                Colors.purple,
              ],
          textStyle: widget.textStyle ?? const TextStyle(),
        ),
      ),
    );
  }
}

/// generated by chatgpt
class PieChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final double angleOffset;
  final double radius;
  final List<Color> customColours;
  final TextStyle textStyle;

  const PieChart({
    super.key,
    required this.data,
    required this.labels,
    required this.customColours,
    required this.textStyle,
    this.angleOffset = 0,
    this.radius = 100,
  });

  @override
  Widget build(BuildContext context) {
    double total =
        data.fold(0, (previousValue, element) => previousValue + element);
    final startAngle = 0 - pi / 2 + angleOffset;

    return CustomPaint(
      painter: _PieChartPainter(
        data,
        labels,
        total,
        startAngle,
        customColours,
        textStyle,
      ),
      size: Size.fromRadius(radius),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final double total;
  final double startAngle;
  final List<Color> customColours;
  final TextStyle textStyle;

  _PieChartPainter(
    this.data,
    this.labels,
    this.total,
    this.startAngle,
    this.customColours,
    this.textStyle,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;

    double sweepAngle = 0;

    for (int i = 0; i < data.length; i++) {
      final ratio = data[i] / total;
      final sweepRad = ratio * 2 * pi;

      paint.color = _getColor(i);

      canvas.drawArc(rect, startAngle + sweepAngle, sweepRad, true, paint);

      final labelAngle = startAngle + sweepAngle + sweepRad / 2;
      final labelX = center.dx + (radius * 0.6) * cos(labelAngle);
      final labelY = center.dy + (radius * 0.6) * sin(labelAngle);
      final labelOffset = Offset(labelX, labelY);

      _drawLabel(canvas, labels[i], labelOffset);

      sweepAngle += sweepRad;
    }
  }

  void _drawLabel(Canvas canvas, String label, Offset offset) {
    final textSpan = TextSpan(
      text: label,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textOffset = Offset(
        offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2);

    textPainter.paint(canvas, textOffset);
  }

  Color _getColor(int index) {
    return customColours[index % customColours.length];
  }

  @override
  bool shouldRepaint(_PieChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.labels != labels ||
        oldDelegate.total != total ||
        oldDelegate.startAngle != startAngle;
  }
}
