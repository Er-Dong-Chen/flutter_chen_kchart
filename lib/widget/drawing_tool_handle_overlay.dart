import 'package:flutter/material.dart';
import '../entity/drawing_tool_entity.dart';

class DrawingToolHandleOverlay extends StatelessWidget {
  final DrawingTool tool;
  final double Function(double) getX;
  final double Function(double) getY;
  final Rect? chartRect;

  const DrawingToolHandleOverlay({
    super.key,
    required this.tool,
    required this.getX,
    required this.getY,
    this.chartRect,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _DrawingToolHandlePainter(
          tool: tool,
          getX: getX,
          getY: getY,
          chartRect: chartRect,
        ),
      ),
    );
  }
}

class _DrawingToolHandlePainter extends CustomPainter {
  final DrawingTool tool;
  final double Function(double) getX;
  final double Function(double) getY;
  final Rect? chartRect;

  _DrawingToolHandlePainter({
    required this.tool,
    required this.getX,
    required this.getY,
    required this.chartRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final handles = _handlesFor(tool, size);
    if (handles.isEmpty) return;

    final fillPaint = Paint()
      ..color = tool.color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    final dotPaint = Paint()
      ..color = tool.color.withValues(alpha: 1.0)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final clipRect = chartRect;
    if (clipRect != null) {
      canvas.save();
      canvas.clipRect(clipRect);
    }

    for (final p in handles) {
      canvas.drawCircle(p, 7.5, fillPaint);
      canvas.drawCircle(p, 7.5, strokePaint);
      canvas.drawCircle(p, 2.2, dotPaint);
    }

    if (clipRect != null) {
      canvas.restore();
    }
  }

  List<Offset> _handlesFor(DrawingTool t, Size size) {
    if (t is TrendLineTool) {
      if (t.startIndex == null || t.startPrice == null) return const [];
      final start = Offset(getX(t.startIndex!), getY(t.startPrice!));
      if (t.endIndex == null || t.endPrice == null) return [start];
      final end = Offset(getX(t.endIndex!), getY(t.endPrice!));
      return [start, end];
    }

    if (t is TrendAngleTool) {
      if (t.startIndex == null || t.startPrice == null) return const [];
      final start = Offset(getX(t.startIndex!), getY(t.startPrice!));
      if (t.endIndex == null || t.endPrice == null) return [start];
      final end = Offset(getX(t.endIndex!), getY(t.endPrice!));
      return [start, end];
    }

    if (t is ArrowTool) {
      if (t.startIndex == null || t.startPrice == null) return const [];
      final start = Offset(getX(t.startIndex!), getY(t.startPrice!));
      if (t.endIndex == null || t.endPrice == null) return [start];
      final end = Offset(getX(t.endIndex!), getY(t.endPrice!));
      return [start, end];
    }

    if (t is RayTool) {
      if (t.startIndex == null || t.startPrice == null) return const [];
      final start = Offset(getX(t.startIndex!), getY(t.startPrice!));
      if (t.directionIndex == null || t.directionPrice == null) return [start];
      final end = Offset(getX(t.directionIndex!), getY(t.directionPrice!));
      return [start, end];
    }

    if (t is HorizontalRayTool) {
      if (t.startIndex == null || t.startPrice == null) return const [];
      return [Offset(getX(t.startIndex!), getY(t.startPrice!))];
    }

    if (t is VerticalLineTool) {
      if (t.lineIndex == null) return const [];
      final rect = chartRect;
      final y = rect != null ? (rect.top + rect.bottom) / 2 : size.height / 2;
      return [Offset(getX(t.lineIndex!), y)];
    }

    if (t is HorizontalLineTool) {
      if (t.priceLevel == null) return const [];
      final rect = chartRect;
      final x = rect != null ? (rect.left + rect.right) / 2 : size.width / 2;
      return [Offset(x, getY(t.priceLevel!))];
    }

    if (t is CrossLineTool) {
      if (t.centerIndex == null || t.centerPrice == null) return const [];
      return [Offset(getX(t.centerIndex!), getY(t.centerPrice!))];
    }

    return const [];
  }

  @override
  bool shouldRepaint(covariant _DrawingToolHandlePainter oldDelegate) {
    return oldDelegate.tool != tool ||
        oldDelegate.chartRect != chartRect ||
        oldDelegate.getX != getX ||
        oldDelegate.getY != getY;
  }
}
