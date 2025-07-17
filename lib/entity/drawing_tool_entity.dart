import 'package:flutter/material.dart';

// 绘图工具类型枚举
enum DrawingToolType {
  trendLine, // 1. 趋势线
  trendAngle, // 2. 趋势角度
  arrow, // 3. 箭头
  verticalLine, // 4. 垂直线
  horizontalLine, // 5. 水平线
  horizontalRay, // 6. 水平射线
  ray, // 7. 射线
  crossLine, // 8. 十字线
}

// 绘图工具状态枚举
enum DrawingToolState {
  none, // 无绘图状态
  drawing, // 正在绘制
  selected, // 已选中
  editing, // 编辑中
}

// 绘图模式枚举
enum DrawingMode {
  normal, // 普通模式
  magnet, // 磁铁模式 - 自动吸附到K线点
  continuous, // 持续画图模式
}

// 基础绘图工具抽象类
abstract class DrawingTool {
  final String id;
  final DrawingToolType type;
  final DateTime createTime;
  Color color;
  double strokeWidth;
  bool isVisible;
  DrawingToolState state;

  DrawingTool({
    required this.id,
    required this.type,
    required this.createTime,
    this.color = const Color(0xFFFFD700), // 默认金色
    this.strokeWidth = 2.0,
    this.isVisible = true,
    this.state = DrawingToolState.none,
  });

  // 抽象方法：绘制
  void draw(Canvas canvas, Size size, double scaleX, double scrollX,
      double Function(double) getX, double Function(double) getY);

  // 抽象方法：点击检测
  bool hitTest(Offset point);

  // 抽象方法：获取边界框
  Rect getBounds();

  // 抽象方法：移动
  void move(Offset delta);

  // 抽象方法：是否完成绘制
  bool get isComplete;

  // 抽象方法：序列化
  Map<String, dynamic> toJson();

  // 抽象方法：反序列化
  static DrawingTool? fromJson(Map<String, dynamic> json) => null;
}

// 趋势线
class TrendLineTool extends DrawingTool {
  Offset? startPoint;
  Offset? endPoint;
  bool extendLeft;
  bool extendRight;

  TrendLineTool({
    required String id,
    this.startPoint,
    this.endPoint,
    this.extendLeft = false,
    this.extendRight = false,
    Color color = const Color(0xFFFFD700),
    double strokeWidth = 2.0,
  }) : super(
          id: id,
          type: DrawingToolType.trendLine,
          createTime: DateTime.now(),
          color: color,
          strokeWidth: strokeWidth,
        );

  @override
  void draw(Canvas canvas, Size size, double scaleX, double scrollX,
      double Function(double) getX, double Function(double) getY) {
    debugPrint(
        'TrendLineTool.draw: startPoint=$startPoint, endPoint=$endPoint, 完成状态=$isComplete');

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    if (startPoint != null && endPoint != null) {
      debugPrint('绘制趋势线: 从 $startPoint 到 $endPoint');
      canvas.drawLine(startPoint!, endPoint!, paint);

      // 如果需要延伸
      if (extendLeft || extendRight) {
        final dx = endPoint!.dx - startPoint!.dx;
        final dy = endPoint!.dy - startPoint!.dy;

        if (extendLeft && dx != 0) {
          final extendedStart =
              Offset(0, startPoint!.dy - (startPoint!.dx * dy / dx));
          canvas.drawLine(startPoint!, extendedStart, paint);
        }

        if (extendRight && dx != 0) {
          final extendedEnd = Offset(size.width,
              endPoint!.dy + ((size.width - endPoint!.dx) * dy / dx));
          canvas.drawLine(endPoint!, extendedEnd, paint);
        }
      }
    } else if (startPoint != null) {
      debugPrint('绘制趋势线起点: $startPoint');
      // 绘制起点标记
      canvas.drawCircle(startPoint!, 3.0, paint);
    } else {
      debugPrint('TrendLineTool.draw: 没有可绘制的点');
    }
  }

  @override
  bool hitTest(Offset point) {
    if (startPoint == null || endPoint == null) return false;

    // 简单的线段点击检测
    const tolerance = 5.0;
    final distance = _distanceFromPointToLine(point, startPoint!, endPoint!);
    return distance <= tolerance;
  }

  double _distanceFromPointToLine(
      Offset point, Offset lineStart, Offset lineEnd) {
    final a = point.dx - lineStart.dx;
    final b = point.dy - lineStart.dy;
    final c = lineEnd.dx - lineStart.dx;
    final d = lineEnd.dy - lineStart.dy;

    final dot = a * c + b * d;
    final lenSq = c * c + d * d;

    if (lenSq == 0) return (point - lineStart).distance;

    final param = dot / lenSq;

    Offset projection;
    if (param < 0) {
      projection = lineStart;
    } else if (param > 1) {
      projection = lineEnd;
    } else {
      projection = Offset(lineStart.dx + param * c, lineStart.dy + param * d);
    }

    return (point - projection).distance;
  }

  @override
  Rect getBounds() {
    if (startPoint == null) return Rect.zero;
    if (endPoint == null)
      return Rect.fromCenter(center: startPoint!, width: 1, height: 1);

    return Rect.fromPoints(startPoint!, endPoint!);
  }

  @override
  void move(Offset delta) {
    if (startPoint != null) startPoint = startPoint! + delta;
    if (endPoint != null) endPoint = endPoint! + delta;
  }

  @override
  bool get isComplete => startPoint != null && endPoint != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'startPoint': startPoint != null
          ? {'x': startPoint!.dx, 'y': startPoint!.dy}
          : null,
      'endPoint':
          endPoint != null ? {'x': endPoint!.dx, 'y': endPoint!.dy} : null,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'extendLeft': extendLeft,
      'extendRight': extendRight,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static TrendLineTool fromJson(Map<String, dynamic> json) {
    return TrendLineTool(
      id: json['id'],
      startPoint: json['startPoint'] != null
          ? Offset(json['startPoint']['x'], json['startPoint']['y'])
          : null,
      endPoint: json['endPoint'] != null
          ? Offset(json['endPoint']['x'], json['endPoint']['y'])
          : null,
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
      extendLeft: json['extendLeft'] ?? false,
      extendRight: json['extendRight'] ?? false,
    );
  }
}

// 趋势角度工具
class TrendAngleTool extends DrawingTool {
  Offset? startPoint;
  Offset? endPoint;
  double? angle; // 角度值

  TrendAngleTool({
    required String id,
    this.startPoint,
    this.endPoint,
    this.angle,
    Color color = const Color(0xFFFFD700),
    double strokeWidth = 2.0,
  }) : super(
          id: id,
          type: DrawingToolType.trendAngle,
          createTime: DateTime.now(),
          color: color,
          strokeWidth: strokeWidth,
        );

  @override
  void draw(Canvas canvas, Size size, double scaleX, double scrollX,
      double Function(double) getX, double Function(double) getY) {
    if (startPoint == null || endPoint == null) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 绘制趋势线
    canvas.drawLine(startPoint!, endPoint!, paint);

    // 计算并显示角度
    if (angle != null) {
      final center = Offset((startPoint!.dx + endPoint!.dx) / 2,
          (startPoint!.dy + endPoint!.dy) / 2);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${angle!.toStringAsFixed(1)}°',
          style: TextStyle(color: color, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          center - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  @override
  bool hitTest(Offset point) {
    if (startPoint == null || endPoint == null) return false;
    const tolerance = 5.0;
    final distance = _distanceFromPointToLine(point, startPoint!, endPoint!);
    return distance <= tolerance;
  }

  double _distanceFromPointToLine(
      Offset point, Offset lineStart, Offset lineEnd) {
    final a = point.dx - lineStart.dx;
    final b = point.dy - lineStart.dy;
    final c = lineEnd.dx - lineStart.dx;
    final d = lineEnd.dy - lineStart.dy;

    final dot = a * c + b * d;
    final lenSq = c * c + d * d;

    if (lenSq == 0) return (point - lineStart).distance;

    final param = dot / lenSq;

    Offset projection;
    if (param < 0) {
      projection = lineStart;
    } else if (param > 1) {
      projection = lineEnd;
    } else {
      projection = Offset(lineStart.dx + param * c, lineStart.dy + param * d);
    }

    return (point - projection).distance;
  }

  @override
  Rect getBounds() {
    if (startPoint == null) return Rect.zero;
    if (endPoint == null)
      return Rect.fromCenter(center: startPoint!, width: 1, height: 1);
    return Rect.fromPoints(startPoint!, endPoint!);
  }

  @override
  void move(Offset delta) {
    if (startPoint != null) startPoint = startPoint! + delta;
    if (endPoint != null) endPoint = endPoint! + delta;
  }

  @override
  bool get isComplete => startPoint != null && endPoint != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'startPoint': startPoint != null
          ? {'x': startPoint!.dx, 'y': startPoint!.dy}
          : null,
      'endPoint':
          endPoint != null ? {'x': endPoint!.dx, 'y': endPoint!.dy} : null,
      'angle': angle,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static TrendAngleTool fromJson(Map<String, dynamic> json) {
    return TrendAngleTool(
      id: json['id'],
      startPoint: json['startPoint'] != null
          ? Offset(json['startPoint']['x'], json['startPoint']['y'])
          : null,
      endPoint: json['endPoint'] != null
          ? Offset(json['endPoint']['x'], json['endPoint']['y'])
          : null,
      angle: json['angle'],
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
    );
  }
}

// 箭头工具
class ArrowTool extends DrawingTool {
  Offset? startPoint;
  Offset? endPoint;
  double arrowHeadSize;

  ArrowTool({
    required String id,
    this.startPoint,
    this.endPoint,
    this.arrowHeadSize = 10.0,
    Color color = const Color(0xFFFF6B6B),
    double strokeWidth = 2.0,
  }) : super(
          id: id,
          type: DrawingToolType.arrow,
          createTime: DateTime.now(),
          color: color,
          strokeWidth: strokeWidth,
        );

  @override
  void draw(Canvas canvas, Size size, double scaleX, double scrollX,
      double Function(double) getX, double Function(double) getY) {
    if (startPoint == null || endPoint == null) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 绘制箭头主体
    canvas.drawLine(startPoint!, endPoint!, paint);

    // 计算箭头头部
    final direction = (endPoint! - startPoint!).direction;
    final arrowHead1 =
        endPoint! + Offset.fromDirection(direction + 2.5, arrowHeadSize);
    final arrowHead2 =
        endPoint! + Offset.fromDirection(direction - 2.5, arrowHeadSize);

    // 绘制箭头头部
    canvas.drawLine(endPoint!, arrowHead1, paint);
    canvas.drawLine(endPoint!, arrowHead2, paint);
  }

  @override
  bool hitTest(Offset point) {
    if (startPoint == null || endPoint == null) return false;
    const tolerance = 5.0;
    final distance = _distanceFromPointToLine(point, startPoint!, endPoint!);
    return distance <= tolerance;
  }

  double _distanceFromPointToLine(
      Offset point, Offset lineStart, Offset lineEnd) {
    final a = point.dx - lineStart.dx;
    final b = point.dy - lineStart.dy;
    final c = lineEnd.dx - lineStart.dx;
    final d = lineEnd.dy - lineStart.dy;

    final dot = a * c + b * d;
    final lenSq = c * c + d * d;

    if (lenSq == 0) return (point - lineStart).distance;

    final param = dot / lenSq;

    Offset projection;
    if (param < 0) {
      projection = lineStart;
    } else if (param > 1) {
      projection = lineEnd;
    } else {
      projection = Offset(lineStart.dx + param * c, lineStart.dy + param * d);
    }

    return (point - projection).distance;
  }

  @override
  Rect getBounds() {
    if (startPoint == null || endPoint == null) return Rect.zero;
    return Rect.fromPoints(startPoint!, endPoint!);
  }

  @override
  void move(Offset delta) {
    if (startPoint != null) startPoint = startPoint! + delta;
    if (endPoint != null) endPoint = endPoint! + delta;
  }

  @override
  bool get isComplete => startPoint != null && endPoint != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'startPoint': startPoint != null
          ? {'x': startPoint!.dx, 'y': startPoint!.dy}
          : null,
      'endPoint':
          endPoint != null ? {'x': endPoint!.dx, 'y': endPoint!.dy} : null,
      'arrowHeadSize': arrowHeadSize,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static ArrowTool fromJson(Map<String, dynamic> json) {
    return ArrowTool(
      id: json['id'],
      startPoint: json['startPoint'] != null
          ? Offset(json['startPoint']['x'], json['startPoint']['y'])
          : null,
      endPoint: json['endPoint'] != null
          ? Offset(json['endPoint']['x'], json['endPoint']['y'])
          : null,
      arrowHeadSize: json['arrowHeadSize'] ?? 10.0,
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
    );
  }
}

// 垂直线工具
class VerticalLineTool extends DrawingTool {
  double? xPosition;
  DateTime? timePoint; // 对应的时间点

  VerticalLineTool({
    required String id,
    this.xPosition,
    this.timePoint,
    Color color = const Color(0xFF00BFFF),
    double strokeWidth = 2.0,
  }) : super(
          id: id,
          type: DrawingToolType.verticalLine,
          createTime: DateTime.now(),
          color: color,
          strokeWidth: strokeWidth,
        );

  @override
  void draw(Canvas canvas, Size size, double scaleX, double scrollX,
      double Function(double) getX, double Function(double) getY) {
    if (xPosition == null) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(xPosition!, 0),
      Offset(xPosition!, size.height),
      paint,
    );
  }

  @override
  bool hitTest(Offset point) {
    if (xPosition == null) return false;
    const tolerance = 5.0;
    return (point.dx - xPosition!).abs() <= tolerance;
  }

  @override
  Rect getBounds() {
    if (xPosition == null) return Rect.zero;
    return Rect.fromLTWH(
        xPosition! - strokeWidth / 2, 0, strokeWidth, double.infinity);
  }

  @override
  void move(Offset delta) {
    if (xPosition != null) xPosition = xPosition! + delta.dx;
  }

  @override
  bool get isComplete => xPosition != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'xPosition': xPosition,
      'timePoint': timePoint?.millisecondsSinceEpoch,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static VerticalLineTool fromJson(Map<String, dynamic> json) {
    return VerticalLineTool(
      id: json['id'],
      xPosition: json['xPosition'],
      timePoint: json['timePoint'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timePoint'])
          : null,
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
    );
  }
}

// 水平线工具
class HorizontalLineTool extends DrawingTool {
  double? yPosition;
  double? priceLevel; // 对应的价格水平

  HorizontalLineTool({
    required String id,
    this.yPosition,
    this.priceLevel,
    Color color = const Color(0xFF00BFFF),
    double strokeWidth = 2.0,
  }) : super(
          id: id,
          type: DrawingToolType.horizontalLine,
          createTime: DateTime.now(),
          color: color,
          strokeWidth: strokeWidth,
        );

  @override
  void draw(Canvas canvas, Size size, double scaleX, double scrollX,
      double Function(double) getX, double Function(double) getY) {
    debugPrint(
        'HorizontalLineTool.draw: yPosition=$yPosition, priceLevel=$priceLevel');

    if (yPosition == null) {
      debugPrint('HorizontalLineTool.draw: yPosition为null，跳过绘制');
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 绘制横跨整个图表的水平线
    debugPrint('绘制水平线: y=$yPosition, 宽度=${size.width}');
    canvas.drawLine(
      Offset(0, yPosition!),
      Offset(size.width, yPosition!),
      paint,
    );

    // 绘制价格标签
    if (priceLevel != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: priceLevel!.toStringAsFixed(2),
          style: TextStyle(color: color, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(size.width - textPainter.width - 5,
              yPosition! - textPainter.height / 2));
    }
  }

  @override
  bool hitTest(Offset point) {
    if (yPosition == null) return false;
    const tolerance = 5.0;
    return (point.dy - yPosition!).abs() <= tolerance;
  }

  @override
  Rect getBounds() {
    if (yPosition == null) return Rect.zero;
    return Rect.fromLTWH(
        0, yPosition! - strokeWidth / 2, double.infinity, strokeWidth);
  }

  @override
  void move(Offset delta) {
    if (yPosition != null) yPosition = yPosition! + delta.dy;
  }

  @override
  bool get isComplete => yPosition != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'yPosition': yPosition,
      'priceLevel': priceLevel,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static HorizontalLineTool fromJson(Map<String, dynamic> json) {
    return HorizontalLineTool(
      id: json['id'],
      yPosition: json['yPosition'],
      priceLevel: json['priceLevel'],
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
    );
  }
}

// 水平射线工具
class HorizontalRayTool extends DrawingTool {
  Offset? startPoint;
  double? direction; // 方向：1为向右，-1为向左

  HorizontalRayTool({
    required String id,
    this.startPoint,
    this.direction,
    Color color = const Color(0xFF00BFFF),
    double strokeWidth = 2.0,
  }) : super(
          id: id,
          type: DrawingToolType.horizontalRay,
          createTime: DateTime.now(),
          color: color,
          strokeWidth: strokeWidth,
        );

  @override
  void draw(Canvas canvas, Size size, double scaleX, double scrollX,
      double Function(double) getX, double Function(double) getY) {
    if (startPoint == null || direction == null) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 绘制水平射线
    final endX = (direction! > 0 ? size.width : 0).toDouble();
    canvas.drawLine(
      startPoint!,
      Offset(endX, startPoint!.dy),
      paint,
    );
  }

  @override
  bool hitTest(Offset point) {
    if (startPoint == null) return false;
    const tolerance = 5.0;
    return (point.dy - startPoint!.dy).abs() <= tolerance &&
        ((direction! > 0 && point.dx >= startPoint!.dx) ||
            (direction! < 0 && point.dx <= startPoint!.dx));
  }

  @override
  Rect getBounds() {
    if (startPoint == null) return Rect.zero;
    return Rect.fromLTWH(
        0, startPoint!.dy - strokeWidth / 2, double.infinity, strokeWidth);
  }

  @override
  void move(Offset delta) {
    if (startPoint != null) startPoint = startPoint! + delta;
  }

  @override
  bool get isComplete => startPoint != null && direction != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'startPoint': startPoint != null
          ? {'x': startPoint!.dx, 'y': startPoint!.dy}
          : null,
      'direction': direction,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static HorizontalRayTool fromJson(Map<String, dynamic> json) {
    return HorizontalRayTool(
      id: json['id'],
      startPoint: json['startPoint'] != null
          ? Offset(json['startPoint']['x'], json['startPoint']['y'])
          : null,
      direction: json['direction'],
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
    );
  }
}

// 射线工具
class RayTool extends DrawingTool {
  Offset? startPoint;
  Offset? directionPoint;

  RayTool({
    required String id,
    this.startPoint,
    this.directionPoint,
    Color color = const Color(0xFF00BFFF),
    double strokeWidth = 2.0,
  }) : super(
          id: id,
          type: DrawingToolType.ray,
          createTime: DateTime.now(),
          color: color,
          strokeWidth: strokeWidth,
        );

  @override
  void draw(Canvas canvas, Size size, double scaleX, double scrollX,
      double Function(double) getX, double Function(double) getY) {
    if (startPoint == null || directionPoint == null) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 计算射线方向
    final direction = (directionPoint! - startPoint!).direction;
    final length = size.width + size.height; // 足够长的射线

    // 绘制射线
    final endPoint = startPoint! + Offset.fromDirection(direction, length);
    canvas.drawLine(startPoint!, endPoint, paint);
  }

  @override
  bool hitTest(Offset point) {
    if (startPoint == null || directionPoint == null) return false;
    const tolerance = 5.0;
    final direction = (directionPoint! - startPoint!).direction;
    final distance = _distanceFromPointToRay(point, startPoint!, direction);
    return distance <= tolerance;
  }

  double _distanceFromPointToRay(
      Offset point, Offset rayStart, double direction) {
    final rayVector = Offset.fromDirection(direction, 1.0);
    final pointVector = point - rayStart;

    final projection =
        (pointVector.dx * rayVector.dx + pointVector.dy * rayVector.dy)
            .toDouble();
    final rayPoint = rayStart + rayVector * projection;

    return (point - rayPoint).distance;
  }

  @override
  Rect getBounds() {
    if (startPoint == null) return Rect.zero;
    return Rect.fromCenter(center: startPoint!, width: 1, height: 1);
  }

  @override
  void move(Offset delta) {
    if (startPoint != null) startPoint = startPoint! + delta;
    if (directionPoint != null) directionPoint = directionPoint! + delta;
  }

  @override
  bool get isComplete => startPoint != null && directionPoint != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'startPoint': startPoint != null
          ? {'x': startPoint!.dx, 'y': startPoint!.dy}
          : null,
      'directionPoint': directionPoint != null
          ? {'x': directionPoint!.dx, 'y': directionPoint!.dy}
          : null,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static RayTool fromJson(Map<String, dynamic> json) {
    return RayTool(
      id: json['id'],
      startPoint: json['startPoint'] != null
          ? Offset(json['startPoint']['x'], json['startPoint']['y'])
          : null,
      directionPoint: json['directionPoint'] != null
          ? Offset(json['directionPoint']['x'], json['directionPoint']['y'])
          : null,
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
    );
  }
}

// 十字线工具
class CrossLineTool extends DrawingTool {
  Offset? centerPoint;

  CrossLineTool({
    required String id,
    this.centerPoint,
    Color color = const Color(0xFF00BFFF),
    double strokeWidth = 2.0,
  }) : super(
          id: id,
          type: DrawingToolType.crossLine,
          createTime: DateTime.now(),
          color: color,
          strokeWidth: strokeWidth,
        );

  @override
  void draw(Canvas canvas, Size size, double scaleX, double scrollX,
      double Function(double) getX, double Function(double) getY) {
    if (centerPoint == null) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 绘制垂直线
    canvas.drawLine(
      Offset(centerPoint!.dx, 0),
      Offset(centerPoint!.dx, size.height),
      paint,
    );

    // 绘制水平线
    canvas.drawLine(
      Offset(0, centerPoint!.dy),
      Offset(size.width, centerPoint!.dy),
      paint,
    );
  }

  @override
  bool hitTest(Offset point) {
    if (centerPoint == null) return false;
    const tolerance = 5.0;
    return (point.dx - centerPoint!.dx).abs() <= tolerance ||
        (point.dy - centerPoint!.dy).abs() <= tolerance;
  }

  @override
  Rect getBounds() {
    if (centerPoint == null) return Rect.zero;
    return Rect.fromCenter(center: centerPoint!, width: 1, height: 1);
  }

  @override
  void move(Offset delta) {
    if (centerPoint != null) centerPoint = centerPoint! + delta;
  }

  @override
  bool get isComplete => centerPoint != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'centerPoint': centerPoint != null
          ? {'x': centerPoint!.dx, 'y': centerPoint!.dy}
          : null,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static CrossLineTool fromJson(Map<String, dynamic> json) {
    return CrossLineTool(
      id: json['id'],
      centerPoint: json['centerPoint'] != null
          ? Offset(json['centerPoint']['x'], json['centerPoint']['y'])
          : null,
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
    );
  }
}
