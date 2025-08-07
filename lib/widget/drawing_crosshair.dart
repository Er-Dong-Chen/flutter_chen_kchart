import 'package:flutter/material.dart';

/// 绘图工具专用的十字线组件
class DrawingCrosshair extends StatelessWidget {
  final Offset position;
  final Size chartSize;
  final bool isSelectingStartPoint;
  final bool isSelectingEndPoint;
  final Color color;
  final double strokeWidth;

  const DrawingCrosshair({
    Key? key,
    required this.position,
    required this.chartSize,
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
  final bool isSelectingStartPoint;
  final bool isSelectingEndPoint;
  final Color color;
  final double strokeWidth;

  DrawingCrosshairPainter({
    required this.position,
    required this.isSelectingStartPoint,
    required this.isSelectingEndPoint,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 绘制垂直线
    _drawDashedLine(
      canvas,
      Offset(position.dx, 0),
      Offset(position.dx, size.height),
      paint,
    );

    // 绘制水平线
    _drawDashedLine(
      canvas,
      Offset(0, position.dy),
      Offset(size.width, position.dy),
      paint,
    );

    // 绘制中心圆圈
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 4.0, centerPaint);

    // 绘制外圈（空心）
    final outerPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(position, 8.0, outerPaint);

    // 绘制状态指示文本
    _drawStatusText(canvas, size);
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

  /// 绘制状态指示文本
  void _drawStatusText(Canvas canvas, Size size) {
    String statusText = '';
    if (isSelectingStartPoint) {
      statusText = '选择起点';
    } else if (isSelectingEndPoint) {
      statusText = '选择终点';
    } else {
      statusText = '选择位置';
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: statusText,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.5),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // 计算文本位置（在十字线右上角）
    double textX = position.dx + 15;
    double textY = position.dy - 25;

    // 确保文本不超出边界
    if (textX + textPainter.width > size.width) {
      textX = position.dx - textPainter.width - 15;
    }
    if (textY < 0) {
      textY = position.dy + 15;
    }

    // 绘制文本背景
    final bgRect = Rect.fromLTWH(
      textX - 4,
      textY - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, Radius.circular(4)),
      bgPaint,
    );

    // 绘制文本
    textPainter.paint(canvas, Offset(textX, textY));
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
