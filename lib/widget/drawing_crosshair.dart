import 'package:flutter/material.dart';

/// 绘图工具专用的十字线组件
class DrawingCrosshair extends StatelessWidget {
  final Offset position;
  final Size chartSize;
  final Rect? chartRect;
  final bool isSelectingStartPoint;
  final bool isSelectingEndPoint;
  final Color color;
  final double strokeWidth;

  const DrawingCrosshair({
    Key? key,
    required this.position,
    required this.chartSize,
    this.chartRect,
    this.isSelectingStartPoint = false,
    this.isSelectingEndPoint = false,
    this.color = Colors.orange,
    this.strokeWidth = 1.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: chartSize,
      painter: DrawingCrosshairPainter(
        position: position,
        chartRect: chartRect,
        isSelectingStartPoint: isSelectingStartPoint,
        isSelectingEndPoint: isSelectingEndPoint,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

/// 绘图十字线画笔
class DrawingCrosshairPainter extends CustomPainter {
  final Offset position;
  final Rect? chartRect;
  final bool isSelectingStartPoint;
  final bool isSelectingEndPoint;
  final Color color;
  final double strokeWidth;

  DrawingCrosshairPainter({
    required this.position,
    required this.chartRect,
    required this.isSelectingStartPoint,
    required this.isSelectingEndPoint,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 绘制垂直线
    _drawDashedLine(
      canvas,
      Offset(position.dx, chartRect?.top ?? 0),
      Offset(position.dx, chartRect?.bottom ?? size.height),
      linePaint,
    );

    // 绘制水平线
    _drawDashedLine(
      canvas,
      Offset(chartRect?.left ?? 0, position.dy),
      Offset(chartRect?.right ?? size.width, position.dy),
      linePaint,
    );

    final outerPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final innerFillPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 1.0)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(position, 10.0, innerFillPaint);
    canvas.drawCircle(position, 10.0, outerPaint);
    canvas.drawCircle(position, 2.2, dotPaint);
  }

  /// 绘制虚线
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashLength = 6.0;
    const double dashSpace = 4.0;

    final double distance = (end - start).distance;
    final Offset direction = (end - start) / distance;

    double currentDistance = 0.0;
    bool drawDash = true;

    while (currentDistance < distance) {
      final double segmentLength = drawDash ? dashLength : dashSpace;
      final double nextDistance =
          (currentDistance + segmentLength).clamp(0.0, distance);

      if (drawDash) {
        final Offset segmentStart = start + direction * currentDistance;
        final Offset segmentEnd = start + direction * nextDistance;
        canvas.drawLine(segmentStart, segmentEnd, paint);
      }

      currentDistance = nextDistance;
      drawDash = !drawDash;
    }
  }

  @override
  bool shouldRepaint(DrawingCrosshairPainter oldDelegate) {
    return position != oldDelegate.position ||
        isSelectingStartPoint != oldDelegate.isSelectingStartPoint ||
        isSelectingEndPoint != oldDelegate.isSelectingEndPoint ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
