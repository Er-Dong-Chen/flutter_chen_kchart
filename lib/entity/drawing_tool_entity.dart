import 'dart:math';
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

  /// 获取绘制时的Paint对象
  Paint getPaint({double? opacity}) {
    return Paint()
      ..color = color.withValues(alpha: opacity ?? 1.0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
  }

  /// 获取填充Paint对象
  Paint getFillPaint({double? opacity}) {
    return Paint()
      ..color = color.withValues(alpha: opacity ?? 1.0)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
  }

  /// 绘制选中状态的视觉反馈
  void drawSelectionIndicator(Canvas canvas, {double highlightOpacity = 0.3}) {
    if (state != DrawingToolState.selected) return;

    final bounds = getBounds();
    if (bounds.isEmpty) return;

    // 绘制高亮背景
    final highlightPaint = Paint()
      ..color = color.withValues(alpha: highlightOpacity)
      ..style = PaintingStyle.fill;

    canvas.drawRect(bounds.inflate(3.0), highlightPaint);

    // 绘制选中边框
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(bounds.inflate(5.0), borderPaint);
  }

  /// 计算两点之间的距离
  static double distanceBetweenPoints(Offset p1, Offset p2) {
    return (p1 - p2).distance;
  }

  /// 计算点到线段的距离
  static double distanceFromPointToLine(
      Offset point, Offset lineStart, Offset lineEnd) {
    final a = point.dx - lineStart.dx;
    final b = point.dy - lineStart.dy;
    final c = lineEnd.dx - lineStart.dx;
    final d = lineEnd.dy - lineStart.dy;

    final dot = a * c + b * d;
    final lenSq = c * c + d * d;

    if (lenSq == 0) return DrawingTool.distanceBetweenPoints(point, lineStart);

    final param = dot / lenSq;

    Offset projection;
    if (param < 0) {
      projection = lineStart;
    } else if (param > 1) {
      projection = lineEnd;
    } else {
      projection = Offset(lineStart.dx + param * c, lineStart.dy + param * d);
    }

    return DrawingTool.distanceBetweenPoints(point, projection);
  }

  /// 获取工具类型的显示名称
  String get displayName {
    switch (type) {
      case DrawingToolType.trendLine:
        return '趋势线';
      case DrawingToolType.trendAngle:
        return '趋势角度';
      case DrawingToolType.arrow:
        return '箭头';
      case DrawingToolType.verticalLine:
        return '垂直线';
      case DrawingToolType.horizontalLine:
        return '水平线';
      case DrawingToolType.horizontalRay:
        return '水平射线';
      case DrawingToolType.ray:
        return '射线';
      case DrawingToolType.crossLine:
        return '十字线';
    }
  }

  /// 获取工具类型的图标
  IconData get icon {
    switch (type) {
      case DrawingToolType.trendLine:
        return Icons.trending_up;
      case DrawingToolType.trendAngle:
        return Icons.straighten;
      case DrawingToolType.arrow:
        return Icons.arrow_forward;
      case DrawingToolType.verticalLine:
        return Icons.vertical_align_center;
      case DrawingToolType.horizontalLine:
        return Icons.horizontal_rule;
      case DrawingToolType.horizontalRay:
        return Icons.arrow_right_alt;
      case DrawingToolType.ray:
        return Icons.call_made;
      case DrawingToolType.crossLine:
        return Icons.add;
    }
  }
}

// 趋势线
class TrendLineTool extends DrawingTool {
  // 逻辑坐标系统
  double? startIndex; // 起点对应的K线索引
  double? startPrice; // 起点对应的价格
  double? endIndex;   // 终点对应的K线索引  
  double? endPrice;   // 终点对应的价格
  
  bool extendLeft;
  bool extendRight;

  TrendLineTool({
    required String id,
    this.startIndex,
    this.startPrice,
    this.endIndex,
    this.endPrice,
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
        'TrendLineTool.draw 开始: id=$id, state=$state, 逻辑坐标 startIndex=$startIndex, startPrice=$startPrice, endIndex=$endIndex, endPrice=$endPrice');

    final paint = Paint()
      ..color =
          color.withValues(alpha: state == DrawingToolState.drawing ? 0.6 : 1.0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 使用逻辑坐标系统
    if (startIndex != null && startPrice != null) {
      try {
        // 现在getX函数已经返回正确的屏幕坐标
        final startScreenX = getX(startIndex!);
        final startScreenY = getY(startPrice!);
        final startPoint = Offset(startScreenX, startScreenY);
        debugPrint('TrendLineTool.draw: 起点 逻辑($startIndex, $startPrice) -> 屏幕($startScreenX, $startScreenY)');
        
        if (endIndex != null && endPrice != null) {
          // 有终点数据，绘制完整线条
          final endScreenX = getX(endIndex!);
          final endScreenY = getY(endPrice!);
          final endPoint = Offset(endScreenX, endScreenY);
          debugPrint('TrendLineTool.draw: 终点 逻辑($endIndex, $endPrice) -> 屏幕($endScreenX, $endScreenY)');
          debugPrint('绘制完整趋势线: 从 $startPoint 到 $endPoint, state=$state');

          // 检查点是否有效
          if (startPoint.dx.isFinite && startPoint.dy.isFinite && 
              endPoint.dx.isFinite && endPoint.dy.isFinite) {
            // 如果是预览状态，绘制虚线
            if (state == DrawingToolState.drawing) {
              _drawDashedLine(canvas, startPoint, endPoint, paint);
              debugPrint('绘制虚线趋势线');
            } else {
              canvas.drawLine(startPoint, endPoint, paint);
              debugPrint('绘制实线趋势线');
            }

            // 如果需要延伸
            if (extendLeft || extendRight) {
              final dx = endPoint.dx - startPoint.dx;
              final dy = endPoint.dy - startPoint.dy;

              if (extendLeft && dx != 0) {
                final extendedStart =
                    Offset(0, startPoint.dy - (startPoint.dx * dy / dx));
                canvas.drawLine(startPoint, extendedStart, paint);
              }

              if (extendRight && dx != 0) {
                final extendedEnd = Offset(size.width,
                    endPoint.dy + ((size.width - endPoint.dx) * dy / dx));
                canvas.drawLine(endPoint, extendedEnd, paint);
              }
            }
          } else {
            debugPrint('警告：无效的绘制点 startPoint=$startPoint, endPoint=$endPoint');
          }
        } else {
          // 只有起点数据，绘制起点标记
          debugPrint('绘制趋势线起点: $startPoint (只有起点数据)');
          if (startPoint.dx.isFinite && startPoint.dy.isFinite) {
            canvas.drawCircle(startPoint, 4.0, paint..style = PaintingStyle.fill);
            // 绘制起点周围的小圆圈指示器
            canvas.drawCircle(startPoint, 6.0, paint..style = PaintingStyle.stroke);
            debugPrint('绘制起点标记完成');
          } else {
            debugPrint('警告：无效的起点 $startPoint');
          }
        }
      } catch (e) {
        debugPrint('TrendLineTool.draw 绘制异常: $e');
      }
    } else {
      debugPrint('TrendLineTool.draw: 没有起点逻辑坐标数据 startIndex=$startIndex, startPrice=$startPrice');
    }
  }

  /// 绘制虚线
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    double distance = (end - start).distance;
    double dashCount = (distance / (dashWidth + dashSpace)).floor().toDouble();

    for (int i = 0; i < dashCount; ++i) {
      double startOffset = i * (dashWidth + dashSpace);
      double endOffset = startOffset + dashWidth;

      if (endOffset > distance) endOffset = distance;

      Offset dashStart = start + (end - start) * (startOffset / distance);
      Offset dashEnd = start + (end - start) * (endOffset / distance);

      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool hitTest(Offset point) {
    // 需要通过坐标转换函数来判断，这里暂时返回false
    // TODO: 实现基于逻辑坐标的点击检测
    return false;
  }

  @override
  Rect getBounds() {
    // 需要通过坐标转换函数来计算边界，这里暂时返回零矩形
    // TODO: 实现基于逻辑坐标的边界计算
    return Rect.zero;
  }

  @override
  void move(Offset delta) {
    // 移动逻辑坐标系统的工具需要特殊处理
    // TODO: 实现基于逻辑坐标的移动逻辑
  }

  @override
  bool get isComplete => 
    startIndex != null && startPrice != null && endIndex != null && endPrice != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'startIndex': startIndex,
      'startPrice': startPrice,
      'endIndex': endIndex,
      'endPrice': endPrice,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'extendLeft': extendLeft,
      'extendRight': extendRight,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static TrendLineTool fromJson(Map<String, dynamic> json) {
    return TrendLineTool(
      id: json['id'],
      startIndex: json['startIndex']?.toDouble(),
      startPrice: json['startPrice']?.toDouble(),
      endIndex: json['endIndex']?.toDouble(),
      endPrice: json['endPrice']?.toDouble(),
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
      extendLeft: json['extendLeft'] ?? false,
      extendRight: json['extendRight'] ?? false,
    );
  }
}

// 趋势角度工具
class TrendAngleTool extends DrawingTool {
  // 逻辑坐标系统
  double? startIndex;  // 起点K线索引
  double? startPrice;  // 起点价格
  double? endIndex;    // 终点K线索引
  double? endPrice;    // 终点价格
  double? angle;       // 角度值（计算得出）

  TrendAngleTool({
    required String id,
    this.startIndex,
    this.startPrice,
    this.endIndex,
    this.endPrice,
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
    debugPrint(
        'TrendAngleTool.draw 开始: id=$id, state=$state, 逻辑坐标 startIndex=$startIndex, startPrice=$startPrice, endIndex=$endIndex, endPrice=$endPrice');

    if (startIndex == null || startPrice == null) {
      debugPrint('TrendAngleTool.draw: 没有起点逻辑坐标数据');
      return;
    }

    final paint = Paint()
      ..color =
          color.withValues(alpha: state == DrawingToolState.drawing ? 0.6 : 1.0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    try {
      // 使用逻辑坐标系统，转换为屏幕坐标
      final startScreenX = getX(startIndex!);
      final startScreenY = getY(startPrice!);
      final startPoint = Offset(startScreenX, startScreenY);
      
      debugPrint('TrendAngleTool.draw: 起点 逻辑($startIndex, $startPrice) -> 屏幕($startScreenX, $startScreenY)');

      if (!startScreenX.isFinite || !startScreenY.isFinite) {
        debugPrint('警告：无效的起点屏幕坐标');
        return;
      }

      if (endIndex != null && endPrice != null) {
        // 绘制完整的趋势角度线
        final endScreenX = getX(endIndex!);
        final endScreenY = getY(endPrice!);
        final endPoint = Offset(endScreenX, endScreenY);
        
        debugPrint('TrendAngleTool.draw: 终点 逻辑($endIndex, $endPrice) -> 屏幕($endScreenX, $endScreenY)');

        if (endScreenX.isFinite && endScreenY.isFinite) {
          debugPrint('绘制完整趋势角度线: 从 $startPoint 到 $endPoint');

          // 绘制趋势角度工具：主线实线，参考线和角度弧虚线
          // 1. 绘制主趋势线（始终实线）
          canvas.drawLine(startPoint, endPoint, paint);
          
          // 2. 绘制水平参考线（始终虚线）
          final horizontalEndPoint = _getHorizontalReferencePoint(startPoint, endPoint);
          _drawDashedLine(canvas, startPoint, horizontalEndPoint, paint);
          
          // 3. 绘制角度弧线（始终虚线）
          _drawAngleArc(canvas, startPoint, endPoint, paint, true);
          
          debugPrint('绘制趋势角度：实线主线 + 虚线参考线和角度弧');

          // 计算并显示角度文本
          if (state != DrawingToolState.drawing) {
            _drawAngleText(canvas, startPoint, endPoint);
          }
        }
      } else {
        // 只有起点，绘制起点标记
        _drawPointMarker(canvas, startPoint, paint);
        debugPrint('绘制趋势角度线起点: $startPoint （只有起点数据）');
      }
    } catch (e) {
      debugPrint('TrendAngleTool.draw 绘制异常: $e');
    }
  }

  /// 获取水平参考线终点
  /// 固定从起点向右延伸两个网格宽度，用于角度参考（角度从右边0度开始计算）
  Offset _getHorizontalReferencePoint(Offset startPoint, Offset endPoint) {
    // 计算两个网格宽度（水平线再宽一倍长度）
    const double gridWidth = 120.0;
    
    // 固定从起点向右延伸两个网格宽度作为水平参考线
    return Offset(startPoint.dx + gridWidth, startPoint.dy);
  }

  /// 绘制点标记
  void _drawPointMarker(Canvas canvas, Offset point, Paint paint) {
    const double radius = 3.0;
    canvas.drawCircle(point, radius, paint..style = PaintingStyle.fill);
    canvas.drawCircle(point, radius + 2.0, paint..style = PaintingStyle.stroke);
  }

  /// 绘制角度弧线（像TradingView那样的角度指示弧）
  void _drawAngleArc(Canvas canvas, Offset startPoint, Offset endPoint, Paint paint, bool isDashed) {
    final dx = endPoint.dx - startPoint.dx;
    final dy = endPoint.dy - startPoint.dy;
    
    if (dx.abs() < 1 && dy.abs() < 1) return; // 太小的角度不绘制
    
    // 计算角度
    final angleRadians = atan2(-dy, dx);
    final angleDegrees = (angleRadians * 180 / pi).abs();
    
    // 只有角度大于5度小于175度时才绘制弧线
    if (angleDegrees < 5 || angleDegrees > 175) return;
    
    // 弧线半径（根据线段长度调整，但不超过50像素）
    final lineLength = (endPoint - startPoint).distance;
    final arcRadius = (lineLength * 0.2).clamp(20.0, 50.0);
    
    // 绘制角度弧
    final rect = Rect.fromCircle(center: startPoint, radius: arcRadius);
    
    // 计算起始和结束角度
    final startAngle = 0.0; // 水平向右为0度
    final sweepAngle = -angleRadians; // 角度扫过的弧度
    
    if (isDashed) {
      // 绘制虚线弧（简化处理，绘制几条短弧）
      final segments = 8;
      final segmentAngle = sweepAngle / segments;
      for (int i = 0; i < segments; i += 2) { // 只绘制奇数段实现虚线效果
        canvas.drawArc(
          rect,
          startAngle + i * segmentAngle,
          segmentAngle,
          false,
          paint,
        );
      }
    } else {
      // 绘制实线弧
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }
  
  /// 绘制角度文本
  void _drawAngleText(Canvas canvas, Offset startPoint, Offset endPoint) {
    // 计算角度
    final dx = endPoint.dx - startPoint.dx;
    final dy = endPoint.dy - startPoint.dy;
    if (dx != 0) {
      final angleRadians = atan2(-dy, dx); // 注意 Y 坐标反向
      final angleDegrees = (angleRadians * 180 / pi).abs(); // 显示绝对值角度
      
      // 将文本放置在角度弧线附近
      final lineLength = (endPoint - startPoint).distance;
      final arcRadius = (lineLength * 0.2).clamp(20.0, 50.0);
      final textRadius = arcRadius + 15; // 文本距离起点的距离
      
      final textAngle = angleRadians / 2; // 文本放在角度的中间位置
      final textX = startPoint.dx + cos(textAngle) * textRadius;
      final textY = startPoint.dy - sin(textAngle) * textRadius; // Y坐标反向
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${angleDegrees.toStringAsFixed(1)}°',
          style: TextStyle(
            color: color, 
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(textX - textPainter.width / 2, textY - textPainter.height / 2));
    }
  }

  /// 绘制虚线
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    double distance = (end - start).distance;
    double dashCount = (distance / (dashWidth + dashSpace)).floor().toDouble();

    for (int i = 0; i < dashCount; ++i) {
      double startOffset = i * (dashWidth + dashSpace);
      double endOffset = startOffset + dashWidth;

      if (endOffset > distance) endOffset = distance;

      Offset dashStart = start + (end - start) * (startOffset / distance);
      Offset dashEnd = start + (end - start) * (endOffset / distance);

      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool hitTest(Offset point) {
    // 需要通过坐标转换函数来判断，这里暂时返回false
    // TODO: 实现基于逻辑坐标的点击检测
    return false;
  }

  @override
  Rect getBounds() {
    // 需要通过坐标转换函数来计算边界，这里暂时返回零矩形
    // TODO: 实现基于逻辑坐标的边界计算
    return Rect.zero;
  }

  @override
  void move(Offset delta) {
    // 移动逻辑坐标系统的工具需要特殊处理
    // TODO: 实现基于逻辑坐标的移动逻辑
  }

  @override
  bool get isComplete => startIndex != null && startPrice != null && endIndex != null && endPrice != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'startIndex': startIndex,
      'startPrice': startPrice,
      'endIndex': endIndex,
      'endPrice': endPrice,
      'angle': angle,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static TrendAngleTool fromJson(Map<String, dynamic> json) {
    return TrendAngleTool(
      id: json['id'],
      startIndex: json['startIndex']?.toDouble(),
      startPrice: json['startPrice']?.toDouble(),
      endIndex: json['endIndex']?.toDouble(),
      endPrice: json['endPrice']?.toDouble(),
      angle: json['angle']?.toDouble(),
      color: Color(json['color']),
      strokeWidth: json['strokeWidth']?.toDouble() ?? 2.0,
    );
  }
}

// 箭头工具
class ArrowTool extends DrawingTool {
  // 逻辑坐标系统
  double? startIndex; // 起点对应的K线索引
  double? startPrice; // 起点对应的价格
  double? endIndex;   // 终点对应的K线索引  
  double? endPrice;   // 终点对应的价格
  
  double arrowHeadSize;

  ArrowTool({
    required String id,
    this.startIndex,
    this.startPrice,
    this.endIndex,
    this.endPrice,
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
    debugPrint(
        'ArrowTool.draw 开始: id=$id, state=$state, 逻辑坐标 startIndex=$startIndex, startPrice=$startPrice, endIndex=$endIndex, endPrice=$endPrice');

    final paint = Paint()
      ..color =
          color.withValues(alpha: state == DrawingToolState.drawing ? 0.6 : 1.0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 使用逻辑坐标系统
    if (startIndex != null && startPrice != null) {
      try {
        // 现在getX函数已经返回正确的屏幕坐标
        final startScreenX = getX(startIndex!);
        final startScreenY = getY(startPrice!);
        final startPoint = Offset(startScreenX, startScreenY);
        debugPrint('ArrowTool.draw: 起点 逻辑($startIndex, $startPrice) -> 屏幕($startScreenX, $startScreenY)');
        
        if (endIndex != null && endPrice != null) {
          // 有终点数据，绘制完整箭头 - 修正箭头位置偏差
          final endScreenX = getX(endIndex!);
          final endScreenY = getY(endPrice!);
          final endPoint = Offset(endScreenX, endScreenY);
          debugPrint('ArrowTool.draw: 终点 逻辑($endIndex, $endPrice) -> 屏幕($endScreenX, $endScreenY)');
          debugPrint('绘制完整箭头: 从 $startPoint 到 $endPoint, state=$state');

          // 检查点是否有效
          if (startPoint.dx.isFinite && startPoint.dy.isFinite && 
              endPoint.dx.isFinite && endPoint.dy.isFinite) {
            // 如果是预览状态，绘制虚线
            if (state == DrawingToolState.drawing) {
              _drawDashedLine(canvas, startPoint, endPoint, paint);
              debugPrint('绘制虚线箭头');
            } else {
              // 绘制箭头主体
              canvas.drawLine(startPoint, endPoint, paint);
              debugPrint('绘制实线箭头');
            }

            // 计算箭头头部 - 修正角度计算，确保箭头精确指向终点
            final direction = (endPoint - startPoint).direction;
            final arrowAngle = 2.618; // 约150度角，更接近标准箭头
            final arrowHead1 = endPoint + Offset.fromDirection(direction + arrowAngle, arrowHeadSize);
            final arrowHead2 = endPoint + Offset.fromDirection(direction - arrowAngle, arrowHeadSize);

            // 绘制箭头头部
            if (state == DrawingToolState.drawing) {
              _drawDashedLine(canvas, endPoint, arrowHead1, paint);
              _drawDashedLine(canvas, endPoint, arrowHead2, paint);
            } else {
              canvas.drawLine(endPoint, arrowHead1, paint);
              canvas.drawLine(endPoint, arrowHead2, paint);
            }
          } else {
            debugPrint('警告：无效的绘制点 startPoint=$startPoint, endPoint=$endPoint');
          }
        } else {
          // 只有起点数据，绘制起点标记
          debugPrint('绘制箭头起点: $startPoint (只有起点数据)');
          if (startPoint.dx.isFinite && startPoint.dy.isFinite) {
            canvas.drawCircle(startPoint, 4.0, paint..style = PaintingStyle.fill);
            // 绘制起点周围的小圆圈指示器
            canvas.drawCircle(startPoint, 6.0, paint..style = PaintingStyle.stroke);
            debugPrint('绘制起点标记完成');
          } else {
            debugPrint('警告：无效的起点 $startPoint');
          }
        }
      } catch (e) {
        debugPrint('ArrowTool.draw 绘制异常: $e');
      }
    } else {
      debugPrint('ArrowTool.draw: 没有起点逻辑坐标数据 startIndex=$startIndex, startPrice=$startPrice');
    }
  }

  /// 绘制虚线
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    double distance = (end - start).distance;
    double dashCount = (distance / (dashWidth + dashSpace)).floor().toDouble();

    for (int i = 0; i < dashCount; ++i) {
      double startOffset = i * (dashWidth + dashSpace);
      double endOffset = startOffset + dashWidth;

      if (endOffset > distance) endOffset = distance;

      Offset dashStart = start + (end - start) * (startOffset / distance);
      Offset dashEnd = start + (end - start) * (endOffset / distance);

      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool hitTest(Offset point) {
    // 需要通过坐标转换函数来判断，这里暂时返回false
    // TODO: 实现基于逻辑坐标的点击检测
    return false;
  }

  @override
  Rect getBounds() {
    // 需要通过坐标转换函数来计算边界，这里暂时返回零矩形
    // TODO: 实现基于逻辑坐标的边界计算
    return Rect.zero;
  }

  @override
  void move(Offset delta) {
    // 移动逻辑坐标系统的工具需要特殊处理
    // TODO: 实现基于逻辑坐标的移动逻辑
  }

  @override
  bool get isComplete => 
    startIndex != null && startPrice != null && endIndex != null && endPrice != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'startIndex': startIndex,
      'startPrice': startPrice,
      'endIndex': endIndex,
      'endPrice': endPrice,
      'arrowHeadSize': arrowHeadSize,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static ArrowTool fromJson(Map<String, dynamic> json) {
    return ArrowTool(
      id: json['id'],
      startIndex: json['startIndex']?.toDouble(),
      startPrice: json['startPrice']?.toDouble(),
      endIndex: json['endIndex']?.toDouble(),
      endPrice: json['endPrice']?.toDouble(),
      arrowHeadSize: json['arrowHeadSize'] ?? 10.0,
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
    );
  }
}

// 垂直线工具
class VerticalLineTool extends DrawingTool {
  // 逻辑坐标系统
  double? lineIndex; // 垂直线对应的K线索引
  DateTime? timePoint; // 对应的时间点

  VerticalLineTool({
    required String id,
    this.lineIndex,
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
    debugPrint('VerticalLineTool.draw 开始: id=$id, state=$state, 逻辑坐标 lineIndex=$lineIndex');
    
    if (lineIndex == null) {
      debugPrint('VerticalLineTool.draw: 没有逻辑坐标数据 lineIndex=$lineIndex');
      return;
    }

    final paint = Paint()
      ..color =
          color.withValues(alpha: state == DrawingToolState.drawing ? 0.6 : 1.0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    try {
      // 使用逻辑坐标系统，转换为屏幕坐标
      final screenX = getX(lineIndex!);
      debugPrint('VerticalLineTool.draw: 逻辑($lineIndex) -> 屏幕($screenX)');

      if (screenX.isFinite) {
        // 更精确的主图区域计算，使用标准的图表布局参数
        final mainChartTop = 30.0; // mTopPadding
        
        // 计算主图区域高度：总显示高度 - 成交量区域高度(20%) - 指标区域高度(20%)
        final displayHeight = size.height - 30.0 - 20.0; // 总显示高度
        double volHeight = displayHeight * 0.2; // 成交量区域高度
        double secondaryHeight = displayHeight * 0.2; // 指标区域高度  
        double mainHeight = displayHeight - volHeight - secondaryHeight;
        
        final mainChartBottom = mainChartTop + mainHeight;
        
        debugPrint('垂直线主图区域计算: top=$mainChartTop, bottom=$mainChartBottom, height=$mainHeight');
        
        // 如果是预览状态，绘制虚线效果
        if (state == DrawingToolState.drawing) {
          _drawDashedLine(canvas, Offset(screenX, mainChartTop),
              Offset(screenX, mainChartBottom), paint);
          debugPrint('绘制虚线垂直线（严格限制在K线主图区域）');
        } else {
          canvas.drawLine(
            Offset(screenX, mainChartTop),
            Offset(screenX, mainChartBottom),
            paint,
          );
          debugPrint('绘制实线垂直线（严格限制在K线主图区域）');
        }
      } else {
        debugPrint('警告：无效的屏幕坐标 screenX=$screenX');
      }
    } catch (e) {
      debugPrint('VerticalLineTool.draw 绘制异常: $e');
    }
  }

  /// 绘制虚线
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    double distance = (end - start).distance;
    double dashCount = (distance / (dashWidth + dashSpace)).floor().toDouble();

    for (int i = 0; i < dashCount; ++i) {
      double startOffset = i * (dashWidth + dashSpace);
      double endOffset = startOffset + dashWidth;

      if (endOffset > distance) endOffset = distance;

      Offset dashStart = start + (end - start) * (startOffset / distance);
      Offset dashEnd = start + (end - start) * (endOffset / distance);

      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool hitTest(Offset point) {
    // 需要通过坐标转换函数来判断，这里暂时返回false
    // TODO: 实现基于逻辑坐标的点击检测
    return false;
  }

  @override
  Rect getBounds() {
    // 需要通过坐标转换函数来计算边界，这里暂时返回零矩形
    // TODO: 实现基于逻辑坐标的边界计算
    return Rect.zero;
  }

  @override
  void move(Offset delta) {
    // 移动逻辑坐标系统的工具需要特殊处理
    // TODO: 实现基于逻辑坐标的移动逻辑
  }

  @override
  bool get isComplete => lineIndex != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'lineIndex': lineIndex,
      'timePoint': timePoint?.millisecondsSinceEpoch,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static VerticalLineTool fromJson(Map<String, dynamic> json) {
    return VerticalLineTool(
      id: json['id'],
      lineIndex: json['lineIndex']?.toDouble(),
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
  // 逻辑坐标系统 - 直接使用priceLevel作为逻辑坐标
  double? priceLevel; // 对应的价格水平（逻辑坐标）

  HorizontalLineTool({
    required String id,
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
    debugPrint('HorizontalLineTool.draw 开始: id=$id, state=$state, 逻辑坐标 priceLevel=$priceLevel');
    
    if (priceLevel == null) {
      debugPrint('HorizontalLineTool.draw: 没有逻辑坐标数据 priceLevel=$priceLevel');
      return;
    }

    final paint = Paint()
      ..color =
          color.withValues(alpha: state == DrawingToolState.drawing ? 0.6 : 1.0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    try {
      // 使用逻辑坐标系统，转换价格为屏幕坐标
      final screenY = getY(priceLevel!);
      debugPrint('HorizontalLineTool.draw: 逻辑($priceLevel) -> 屏幕($screenY)');

      if (screenY.isFinite) {
        // 计算主图区域边界，确保水平线仅在K线区域内显示
        final mainChartTop = 30.0;
        final displayHeight = size.height - 30.0 - 20.0;
        double volHeight = displayHeight * 0.2;
        double secondaryHeight = displayHeight * 0.2;
        double mainHeight = displayHeight - volHeight - secondaryHeight;
        final mainChartBottom = mainChartTop + mainHeight;
        
        // 检查是否在主图区域内，如果超出边界则不绘制
        if (screenY < mainChartTop || screenY > mainChartBottom) {
          debugPrint('水平线超出K线区域边界，不绘制: screenY=$screenY, 边界范围[$mainChartTop, $mainChartBottom]');
          return; // 超出边界时完全不绘制
        }
        
        // 在边界内正常绘制
        // 如果是预览状态，绘制虚线效果
        if (state == DrawingToolState.drawing) {
          _drawDashedLine(
              canvas, Offset(0, screenY), Offset(size.width, screenY), paint);
          debugPrint('绘制虚线水平线');
        } else {
          // 绘制横跨整个图表的水平线
          debugPrint('绘制实线水平线: y=$screenY, 宽度=${size.width}');
          canvas.drawLine(
            Offset(0, screenY),
            Offset(size.width, screenY),
            paint,
          );
        }
      } else {
        debugPrint('警告：无效的屏幕坐标 screenY=$screenY');
      }
    } catch (e) {
      debugPrint('HorizontalLineTool.draw 绘制异常: $e');
    }

    // 水平线不绘制价格标签
  }

  /// 绘制虚线
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    double distance = (end - start).distance;
    double dashCount = (distance / (dashWidth + dashSpace)).floor().toDouble();

    for (int i = 0; i < dashCount; ++i) {
      double startOffset = i * (dashWidth + dashSpace);
      double endOffset = startOffset + dashWidth;

      if (endOffset > distance) endOffset = distance;

      Offset dashStart = start + (end - start) * (startOffset / distance);
      Offset dashEnd = start + (end - start) * (endOffset / distance);

      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool hitTest(Offset point) {
    // 需要通过坐标转换函数来判断，这里暂时返回false
    // TODO: 实现基于逻辑坐标的点击检测
    return false;
  }

  @override
  Rect getBounds() {
    // 需要通过坐标转换函数来计算边界，这里暂时返回零矩形
    // TODO: 实现基于逻辑坐标的边界计算
    return Rect.zero;
  }

  @override
  void move(Offset delta) {
    if (priceLevel == null) return;
    
    // 对于水平线工具，只处理Y方向的移动
    // 这里简化处理：假设delta.dy对应价格的变化比例
    // 实际应用中可能需要更复杂的坐标转换
    
    // 限制移动幅度，避免价格跳跃过大
    final priceChange = -delta.dy * 0.01; // 负号因为屏幕坐标Y向下为正，价格向上为正
    final newPriceLevel = priceLevel! + priceChange;
    
    // 简单的价格范围约束（防止价格变为负数或过大）
    // 实际应用中应该基于当前图表的价格范围进行更精确的约束
    if (newPriceLevel > 0) {
      priceLevel = newPriceLevel;
    }
  }

  @override
  bool get isComplete => priceLevel != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'priceLevel': priceLevel,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static HorizontalLineTool fromJson(Map<String, dynamic> json) {
    return HorizontalLineTool(
      id: json['id'],
      priceLevel: json['priceLevel'],
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
    );
  }
}

// 水平射线工具
class HorizontalRayTool extends DrawingTool {
  // 逻辑坐标系统 - 射线从起点到终点
  double? startIndex;  // 起点K线索引
  double? startPrice;  // 起点价格
  double? endIndex;    // 终点K线索引
  double? endPrice;    // 终点价格（应该与startPrice相同，因为是水平线）

  HorizontalRayTool({
    required String id,
    this.startIndex,
    this.startPrice,
    this.endIndex,
    this.endPrice,
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
  bool get isComplete => startIndex != null && startPrice != null && endIndex != null && endPrice != null;

  @override
  String get displayName => '水平射线';

  @override
  void draw(Canvas canvas, Size size, double scaleX, double scrollX,
      double Function(double) getX, double Function(double) getY) {
    debugPrint(
        'HorizontalRayTool.draw 开始: id=$id, state=$state, 逻辑坐标 startIndex=$startIndex, startPrice=$startPrice, endIndex=$endIndex, endPrice=$endPrice');

    if (startIndex == null || startPrice == null) {
      debugPrint('HorizontalRayTool.draw: 没有起点逻辑坐标数据');
      return;
    }

    // 计算主图区域边界（约占总高度的60%，从顶部30开始）
    final mainChartTop = 30.0;
    final mainChartHeight = size.height * 0.6;
    final mainChartBottom = mainChartTop + mainChartHeight;

    final paint = Paint()
      ..color =
          color.withValues(alpha: state == DrawingToolState.drawing ? 0.6 : 1.0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    try {
      // 使用逻辑坐标系统，转换为屏幕坐标
      final startScreenX = getX(startIndex!);
      final startScreenY = getY(startPrice!);
      
      // 约束起点Y坐标到主图区域
      final constrainedStartY = startScreenY.clamp(mainChartTop, mainChartBottom);
      
      debugPrint('HorizontalRayTool.draw: 起点 逻辑($startIndex, $startPrice) -> 屏幕($startScreenX, $startScreenY) -> 约束($startScreenX, $constrainedStartY)');

      if (startScreenX.isFinite && startScreenY.isFinite) {
        // 更精确的主图区域计算，与其他工具保持一致
        final mainChartTop = 30.0;
        final displayHeight = size.height - 30.0 - 20.0;
        double volHeight = displayHeight * 0.2;
        double secondaryHeight = displayHeight * 0.2;
        double mainHeight = displayHeight - volHeight - secondaryHeight;
        final mainChartBottom = mainChartTop + mainHeight;
        
        // 检查是否在主图区域内，如果超出边界则不绘制
        if (startScreenY < mainChartTop || startScreenY > mainChartBottom) {
          debugPrint('水平射线超出K线区域边界，不绘制: startScreenY=$startScreenY, 边界范围[$mainChartTop, $mainChartBottom]');
          return; // 超出边界时完全不绘制
        }
        
        // 在边界内正常绘制
        // 水平射线：从起点开始，向右延伸到屏幕边界
        final startPoint = Offset(startScreenX, startScreenY);
        final endPoint = Offset(size.width, startScreenY);  // 水平线延伸到右边界

        debugPrint('绘制水平射线: 从起点 $startPoint 到右边界 $endPoint（约束在K线区域）');

        // 如果是预览状态，绘制虚线
        if (state == DrawingToolState.drawing) {
          _drawDashedLine(canvas, startPoint, endPoint, paint);
          debugPrint('绘制虚线水平射线');
        } else {
          canvas.drawLine(startPoint, endPoint, paint);
          debugPrint('绘制实线水平射线');
        }

        // 绘制价格标签（让标签跟随水平射线的位置移动）
        if (state != DrawingToolState.drawing && startPrice != null) {
          // 价格标签的X位置不再固定在屏幕右侧，而是跟随射线的起点
          _drawMovablePriceLabel(canvas, size, startScreenX, startPrice!, startScreenY);
        }
      } else {
        debugPrint('警告：无效的屏幕坐标 startScreenX=$startScreenX, startScreenY=$startScreenY');
      }
    } catch (e) {
      debugPrint('HorizontalRayTool.draw 绘制异常: $e');
    }
  }

  /// 绘制可移动的价格标签（跟随水平射线的位置）
  void _drawMovablePriceLabel(Canvas canvas, Size size, double lineX, double price, double screenY) {
    // 计算价格文本
    final priceText = price.toStringAsFixed(2);

    final textPainter = TextPainter(
      text: TextSpan(
        text: priceText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final labelWidth = textPainter.width + 8;
    final labelHeight = textPainter.height + 4;
    
    // 根据射线起点的位置决定标签位置
    double labelX;
    if (lineX < size.width / 2) {
      // 如果起点在屏幕左侧，标签位于起点右侧
      labelX = lineX + 10;
      // 确保不超出右边界
      if (labelX + labelWidth > size.width) {
        labelX = size.width - labelWidth;
      }
    } else {
      // 如果起点在屏幕右侧，标签位于起点左侧
      labelX = lineX - labelWidth - 10;
      // 确保不超出左边界
      if (labelX < 0) {
        labelX = 0;
      }
    }
    
    final labelRect = Rect.fromLTWH(
      labelX,
      screenY - labelHeight / 2,
      labelWidth,
      labelHeight,
    );

    // 绘制标签背景
    final labelPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(labelRect, labelPaint);

    // 绘制价格文本
    textPainter.paint(
      canvas,
      Offset(
        labelX + 4,
        screenY - textPainter.height / 2,
      ),
    );
  }

  /// 绘制虚线
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    double distance = (end - start).distance;
    double dashCount = (distance / (dashWidth + dashSpace)).floor().toDouble();

    for (int i = 0; i < dashCount; ++i) {
      double startOffset = i * (dashWidth + dashSpace);
      double endOffset = startOffset + dashWidth;

      if (endOffset > distance) endOffset = distance;

      Offset dashStart = start + (end - start) * (startOffset / distance);
      Offset dashEnd = start + (end - start) * (endOffset / distance);

      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool hitTest(Offset point) {
    // 需要通过坐标转换函数来判断，这里暂时返回false
    // TODO: 实现基于逻辑坐标的点击检测
    return false;
  }

  @override
  Rect getBounds() {
    // 需要通过坐标转换函数来计算边界，这里暂时返回零矩形
    // TODO: 实现基于逻辑坐标的边界计算
    return Rect.zero;
  }

  @override
  void move(Offset delta) {
    if (startIndex == null || startPrice == null) return;
    
    // 对于水平射线，移动时需要保持水平特性
    // X方向移动：调整起点的K线索引位置
    final indexChange = delta.dx * 0.01; // 简化的索引变化计算
    final newStartIndex = (startIndex! + indexChange).clamp(0.0, double.maxFinite);
    
    // Y方向移动：调整价格水平，确保起点和终点保持在同一水平
    final priceChange = -delta.dy * 0.01; // 负号因为屏幕坐标Y向下为正，价格向上为正
    final newStartPrice = startPrice! + priceChange;
    
    // 价格范围约束（防止价格变为负数或过大）
    if (newStartPrice > 0) {
      startIndex = newStartIndex;
      startPrice = newStartPrice;
      
      // 保持终点与起点在同一价格水平（水平射线的特性）
      if (endIndex != null) {
        endPrice = startPrice; // 确保终点价格与起点价格一致
      }
    }
  }

  DrawingTool copyWith({
    String? id,
    Color? color,
    double? strokeWidth,
    bool? isVisible,
    DrawingToolState? state,
  }) {
    return HorizontalRayTool(
      id: id ?? this.id,
      startIndex: startIndex,
      startPrice: startPrice,
      endIndex: endIndex,
      endPrice: endPrice,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    )
      ..isVisible = isVisible ?? this.isVisible
      ..state = state ?? this.state;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'startIndex': startIndex,
      'startPrice': startPrice,
      'endIndex': endIndex,
      'endPrice': endPrice,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'isVisible': isVisible,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static HorizontalRayTool fromJson(Map<String, dynamic> json) {
    return HorizontalRayTool(
      id: json['id'],
      startIndex: json['startIndex']?.toDouble(),
      startPrice: json['startPrice']?.toDouble(),
      endIndex: json['endIndex']?.toDouble(),
      endPrice: json['endPrice']?.toDouble(),
      color: Color(json['color'] ?? 0xFF00BFFF),
      strokeWidth: json['strokeWidth']?.toDouble() ?? 2.0,
    )..isVisible = json['isVisible'] ?? true;
  }
}

// 射线工具
class RayTool extends DrawingTool {
  // 逻辑坐标系统
  double? startIndex;      // 起点K线索引
  double? startPrice;      // 起点价格
  double? directionIndex;  // 方向点K线索引（用于计算射线方向）
  double? directionPrice;  // 方向点价格

  RayTool({
    required String id,
    this.startIndex,
    this.startPrice,
    this.directionIndex,
    this.directionPrice,
    Color color = const Color(0xFF00BFFF),
    double strokeWidth = 2.0,
  }) : super(
          id: id,
          type: DrawingToolType.ray,
          createTime: DateTime.now(),
          color: color,
          strokeWidth: strokeWidth,
        );

  /// 计算射线终点（支持360度方向，延伸到整个屏幕区域）
  Offset? _calculateRayEndPointFullScreen(Offset startPoint, double dx, double dy, double canvasWidth, double canvasHeight) {
    debugPrint('射线计算开始: 起点=$startPoint, dx=$dx, dy=$dy, 屏幕大小=${canvasWidth}x$canvasHeight');
    
    // 处理各种特殊情况
    if (dx.abs() < 0.001 && dy.abs() < 0.001) {
      debugPrint('方向向量太小，无法计算射线');
      return null;
    }
    
    List<Offset> intersections = [];
    
    // 计算与屏幕四个边界的交点
    
    // 1. 与左边界的交点 (x = 0)
    if (dx.abs() > 0.001) {
      double t = (0 - startPoint.dx) / dx;
      if (t > 0.001) { // 射线向前方向
        double intersectionY = startPoint.dy + t * dy;
        if (intersectionY >= 0 && intersectionY <= canvasHeight) {
          intersections.add(Offset(0, intersectionY));
          debugPrint('与左边界交点: (0, $intersectionY)');
        }
      }
    }
    
    // 2. 与右边界的交点 (x = canvasWidth)
    if (dx.abs() > 0.001) {
      double t = (canvasWidth - startPoint.dx) / dx;
      if (t > 0.001) {
        double intersectionY = startPoint.dy + t * dy;
        if (intersectionY >= 0 && intersectionY <= canvasHeight) {
          intersections.add(Offset(canvasWidth, intersectionY));
          debugPrint('与右边界交点: ($canvasWidth, $intersectionY)');
        }
      }
    }
    
    // 3. 与上边界的交点 (y = 0) - 关键修复！
    if (dy.abs() > 0.001) {
      double t = (0 - startPoint.dy) / dy;
      if (t > 0.001) {
        double intersectionX = startPoint.dx + t * dx;
        if (intersectionX >= 0 && intersectionX <= canvasWidth) {
          intersections.add(Offset(intersectionX, 0));
          debugPrint('与上边界交点: ($intersectionX, 0) - 支持向上的射线');
        }
      }
    }
    
    // 4. 与下边界的交点 (y = canvasHeight) - 关键修复！
    if (dy.abs() > 0.001) {
      double t = (canvasHeight - startPoint.dy) / dy;
      if (t > 0.001) {
        double intersectionX = startPoint.dx + t * dx;
        if (intersectionX >= 0 && intersectionX <= canvasWidth) {
          intersections.add(Offset(intersectionX, canvasHeight));
          debugPrint('与下边界交点: ($intersectionX, $canvasHeight) - 支持向下的射线');
        }
      }
    }
    
    debugPrint('找到 ${intersections.length} 个交点');
    
    // 选择最近的交点作为终点
    if (intersections.isNotEmpty) {
      // 按距离排序，选择最近的交点
      intersections.sort((a, b) {
        double distA = (a - startPoint).distance;
        double distB = (b - startPoint).distance;
        return distA.compareTo(distB);
      });
      
      final closestPoint = intersections.first;
      final distance = (closestPoint - startPoint).distance;
      
      debugPrint('选择最近的交点: $closestPoint，距离: $distance');
      return closestPoint;
    }
    
    debugPrint('未找到任何交点，返回默认终点');
    
    // 如果没有找到交点，使用简单的线性延伸
    const double extension = 1000;
    return Offset(
      (startPoint.dx + dx * extension).clamp(0, canvasWidth),
      (startPoint.dy + dy * extension).clamp(0, canvasHeight)
    );
  }

  @override
  void draw(Canvas canvas, Size size, double scaleX, double scrollX,
      double Function(double) getX, double Function(double) getY) {
    debugPrint(
        'RayTool.draw 开始: id=$id, state=$state, 逻辑坐标 startIndex=$startIndex, startPrice=$startPrice, directionIndex=$directionIndex, directionPrice=$directionPrice');

    if (startIndex == null || startPrice == null) {
      debugPrint('RayTool.draw: 没有起点逻辑坐标数据');
      return;
    }

    // 计算主图区域边界（约占总高度的60%，从顶部30开始）
    final mainChartTop = 30.0;
    final mainChartHeight = size.height * 0.6;
    final mainChartBottom = mainChartTop + mainChartHeight;

    final paint = Paint()
      ..color =
          color.withValues(alpha: state == DrawingToolState.drawing ? 0.6 : 1.0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    try {
      // 使用逻辑坐标系统，转换为屏幕坐标
      final startScreenX = getX(startIndex!);
      final startScreenY = getY(startPrice!);
      
      // 射线起点不约束到主图区域，保持原始坐标用于计算方向
      final startPoint = Offset(startScreenX, startScreenY);
      
      debugPrint('RayTool.draw: 起点 逻辑($startIndex, $startPrice) -> 屏幕($startScreenX, $startScreenY)');

      if (!startScreenX.isFinite || !startScreenY.isFinite) {
        debugPrint('警告：无效的起点屏幕坐标');
        return;
      }

      if (directionIndex != null && directionPrice != null) {
        // 绘制完整的射线 - 支持360度方向及整个屏幕区域
        final directionScreenX = getX(directionIndex!);
        final directionScreenY = getY(directionPrice!);
        
        // 不约束方向点坐标，保持原始坐标用于方向计算
        final directionPoint = Offset(directionScreenX, directionScreenY);
        
        debugPrint('RayTool.draw: 方向点 逻辑($directionIndex, $directionPrice) -> 屏幕($directionScreenX, $directionScreenY)');

        if (directionScreenX.isFinite && directionScreenY.isFinite) {
          debugPrint('绘制射线: 从 $startPoint 到方向 $directionPoint');

          // 计算射线方向向量（使用原始坐标）
          final dx = directionScreenX - startScreenX;
          final dy = directionScreenY - startScreenY;
          
          // 使用限制在K线主图区域的射线计算方法，与垂直线保持一致
          // 计算主图区域边界
          final mainChartTop = 30.0; // mTopPadding
          final displayHeight = size.height - 30.0 - 20.0; // 总显示高度
          double volHeight = displayHeight * 0.2; // 成交量区域高度
          double secondaryHeight = displayHeight * 0.2; // 指标区域高度  
          double mainHeight = displayHeight - volHeight - secondaryHeight;
          final mainChartBottom = mainChartTop + mainHeight;
          
          Offset? endPoint = _calculateRayEndPointMainChart(
            startPoint, 
            dx, 
            dy, 
            size.width, 
            mainChartTop,
            mainChartBottom
          );
          
          if (endPoint != null) {
            debugPrint('计算得到射线终点: $endPoint');
            
            // 如果是预览状态，绘制虚线
            if (state == DrawingToolState.drawing) {
              _drawDashedLine(canvas, startPoint, endPoint, paint);
              debugPrint('绘制虚线射线');
            } else {
              // 绘制射线
              canvas.drawLine(startPoint, endPoint, paint);
              debugPrint('绘制实线射线');
            }
          } else {
            debugPrint('无法计算射线终点，跳过绘制');
          }
        }
      } else {
        // 只有起点，绘制起点标记
        _drawPointMarker(canvas, startPoint, paint);
        debugPrint('绘制射线起点: $startPoint （只有起点数据）');
      }
    } catch (e) {
      debugPrint('RayTool.draw 绘制异常: $e');
    }
  }

  /// 绘制点标记
  void _drawPointMarker(Canvas canvas, Offset point, Paint paint) {
    const double radius = 3.0;
    canvas.drawCircle(point, radius, paint..style = PaintingStyle.fill);
    canvas.drawCircle(point, radius + 2.0, paint..style = PaintingStyle.stroke);
  }

  /// 计算射线终点（仅在K线主图区域内，与垂直线保持一致）
  Offset? _calculateRayEndPointMainChart(Offset startPoint, double dx, double dy, double canvasWidth, double chartTop, double chartBottom) {
    debugPrint('射线主图区域计算: 起点=$startPoint, dx=$dx, dy=$dy, 主图边界=($chartTop, $chartBottom)');
    
    // 处理各种特殊情况
    if (dx.abs() < 0.001 && dy.abs() < 0.001) {
      debugPrint('方向向量太小，无法计算射线');
      return null;
    }
    
    List<Offset> intersections = [];
    
    // 计算与主图区域四个边界的交点
    
    // 1. 与左边界的交点 (x = 0)
    if (dx.abs() > 0.001) {
      double t = (0 - startPoint.dx) / dx;
      if (t > 0.001) { // 射线向前方向
        double intersectionY = startPoint.dy + t * dy;
        if (intersectionY >= chartTop && intersectionY <= chartBottom) {
          intersections.add(Offset(0, intersectionY));
          debugPrint('与左边界交点: (0, $intersectionY)');
        }
      }
    }
    
    // 2. 与右边界的交点 (x = canvasWidth)
    if (dx.abs() > 0.001) {
      double t = (canvasWidth - startPoint.dx) / dx;
      if (t > 0.001) {
        double intersectionY = startPoint.dy + t * dy;
        if (intersectionY >= chartTop && intersectionY <= chartBottom) {
          intersections.add(Offset(canvasWidth, intersectionY));
          debugPrint('与右边界交点: ($canvasWidth, $intersectionY)');
        }
      }
    }
    
    // 3. 与上边界的交点 (y = chartTop)
    if (dy.abs() > 0.001) {
      double t = (chartTop - startPoint.dy) / dy;
      if (t > 0.001) {
        double intersectionX = startPoint.dx + t * dx;
        if (intersectionX >= 0 && intersectionX <= canvasWidth) {
          intersections.add(Offset(intersectionX, chartTop));
          debugPrint('与K线上边界交点: ($intersectionX, $chartTop)');
        }
      }
    }
    
    // 4. 与下边界的交点 (y = chartBottom)
    if (dy.abs() > 0.001) {
      double t = (chartBottom - startPoint.dy) / dy;
      if (t > 0.001) {
        double intersectionX = startPoint.dx + t * dx;
        if (intersectionX >= 0 && intersectionX <= canvasWidth) {
          intersections.add(Offset(intersectionX, chartBottom));
          debugPrint('与K线下边界交点: ($intersectionX, $chartBottom)');
        }
      }
    }
    
    debugPrint('在K线主图区域找到 ${intersections.length} 个交点');
    
    // 选择最近的交点作为终点
    if (intersections.isNotEmpty) {
      // 按距离排序，选择最近的交点
      intersections.sort((a, b) {
        double distA = (a - startPoint).distance;
        double distB = (b - startPoint).distance;
        return distA.compareTo(distB);
      });
      
      final closestPoint = intersections.first;
      final distance = (closestPoint - startPoint).distance;
      
      debugPrint('选择最近的交点: $closestPoint，距离: $distance');
      return closestPoint;
    }
    
    debugPrint('未在K线主图区域找到交点');
    return null;
  }

  // 注：旧的_calculateRayEndPoint方法已被_calculateRayEndPointFullScreen替代
  Offset? _calculateRayEndPoint(Offset startPoint, double dx, double dy, double canvasWidth, double chartTop, double chartBottom) {
    // 处理各种特殊情况
    if (dx == 0 && dy == 0) {
      debugPrint('方向向量为零，无法计算射线');
      return null;
    }
    
    // 使用放大的参数来计算射线的终点，保证可以到达边界
    const double rayLength = 10000; // 足够大的值保证可以到达任意边界
    
    // 单位化方向向量
    final length = (dx * dx + dy * dy).abs() > 0 ? (dx * dx + dy * dy).abs() : 1.0;
    final normalizedDx = dx / length;
    final normalizedDy = dy / length;
    
    // 计算射线的理论终点（很远的位置）
    final theoreticalEndX = startPoint.dx + normalizedDx * rayLength;
    final theoreticalEndY = startPoint.dy + normalizedDy * rayLength;
    
    debugPrint('射线方向计算: dx=$dx, dy=$dy, 理论终点=($theoreticalEndX, $theoreticalEndY)');
    
    // 计算与边界的交点
    List<Offset> intersections = [];
    
    // 与各个边界计算交点
    
    // 1. 与左边界的交点 (x = 0)
    if (dx != 0) {
      double t = (0 - startPoint.dx) / dx;
      if (t > 0.001) { // 小的正值阿值防止数值误差
        double intersectionY = startPoint.dy + t * dy;
        if (intersectionY >= chartTop && intersectionY <= chartBottom) {
          intersections.add(Offset(0, intersectionY));
          debugPrint('与左边界交点: (0, $intersectionY)');
        }
      }
    }
    
    // 2. 与右边界的交点 (x = canvasWidth)
    if (dx != 0) {
      double t = (canvasWidth - startPoint.dx) / dx;
      if (t > 0.001) {
        double intersectionY = startPoint.dy + t * dy;
        if (intersectionY >= chartTop && intersectionY <= chartBottom) {
          intersections.add(Offset(canvasWidth, intersectionY));
          debugPrint('与右边界交点: ($canvasWidth, $intersectionY)');
        }
      }
    }
    
    // 3. 与上边界的交点 (y = chartTop)
    if (dy != 0) {
      double t = (chartTop - startPoint.dy) / dy;
      if (t > 0.001) {
        double intersectionX = startPoint.dx + t * dx;
        if (intersectionX >= 0 && intersectionX <= canvasWidth) {
          intersections.add(Offset(intersectionX, chartTop));
          debugPrint('与上边界交点: ($intersectionX, $chartTop)');
        }
      }
    }
    
    // 4. 与下边界的交点 (y = chartBottom)
    if (dy != 0) {
      double t = (chartBottom - startPoint.dy) / dy;
      if (t > 0.001) {
        double intersectionX = startPoint.dx + t * dx;
        if (intersectionX >= 0 && intersectionX <= canvasWidth) {
          intersections.add(Offset(intersectionX, chartBottom));
          debugPrint('与下边界交点: ($intersectionX, $chartBottom)');
        }
      }
    }
    
    debugPrint('找到 ${intersections.length} 个交点');
    
    // 选择最近的交点作为终点
    if (intersections.isNotEmpty) {
      // 按距离排序，选择最近的交点
      intersections.sort((a, b) {
        double distA = (a - startPoint).distance;
        double distB = (b - startPoint).distance;
        return distA.compareTo(distB);
      });
      
      final closestPoint = intersections.first;
      final distance = (closestPoint - startPoint).distance;
      
      debugPrint('选择最近的交点: $closestPoint，距离: $distance');
      return closestPoint;
    }
    
    debugPrint('未找到任何交点，返回理论终点');
    // 如果没有找到交点，返回理论终点（这种情况不太可能发生）
    return Offset(theoreticalEndX.clamp(0, canvasWidth), theoreticalEndY.clamp(chartTop, chartBottom));
  }

  /// 绘制虚线
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    double distance = (end - start).distance;
    double dashCount = (distance / (dashWidth + dashSpace)).floor().toDouble();

    for (int i = 0; i < dashCount; ++i) {
      double startOffset = i * (dashWidth + dashSpace);
      double endOffset = startOffset + dashWidth;

      if (endOffset > distance) endOffset = distance;

      Offset dashStart = start + (end - start) * (startOffset / distance);
      Offset dashEnd = start + (end - start) * (endOffset / distance);

      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool hitTest(Offset point) {
    // 需要通过坐标转换函数来判断，这里暂时返回false
    // TODO: 实现基于逻辑坐标的点击检测
    return false;
  }


  @override
  Rect getBounds() {
    // 需要通过坐标转换函数来计算边界，这里暂时返回零矩形
    // TODO: 实现基于逻辑坐标的边界计算
    return Rect.zero;
  }

  @override
  void move(Offset delta) {
    // 移动逻辑坐标系统的工具需要特殊处理
    // TODO: 实现基于逻辑坐标的移动逻辑
  }

  @override
  bool get isComplete => startIndex != null && startPrice != null && directionIndex != null && directionPrice != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'startIndex': startIndex,
      'startPrice': startPrice,
      'directionIndex': directionIndex,
      'directionPrice': directionPrice,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static RayTool fromJson(Map<String, dynamic> json) {
    return RayTool(
      id: json['id'],
      startIndex: json['startIndex']?.toDouble(),
      startPrice: json['startPrice']?.toDouble(),
      directionIndex: json['directionIndex']?.toDouble(),
      directionPrice: json['directionPrice']?.toDouble(),
      color: Color(json['color']),
      strokeWidth: json['strokeWidth']?.toDouble() ?? 2.0,
    );
  }
}

// 十字线工具
class CrossLineTool extends DrawingTool {
  // 逻辑坐标系统
  double? centerIndex; // 中心点K线索引
  double? centerPrice; // 中心点价格

  CrossLineTool({
    required String id,
    this.centerIndex,
    this.centerPrice,
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
    debugPrint(
        'CrossLineTool.draw 开始: id=$id, state=$state, 逻辑坐标 centerIndex=$centerIndex, centerPrice=$centerPrice');

    if (centerIndex == null || centerPrice == null) {
      debugPrint('CrossLineTool.draw: 没有中心点逻辑坐标数据');
      return;
    }

    final paint = Paint()
      ..color =
          color.withValues(alpha: state == DrawingToolState.drawing ? 0.6 : 1.0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    try {
      // 使用逻辑坐标系统，转换为屏幕坐标
      final centerScreenX = getX(centerIndex!);
      final centerScreenY = getY(centerPrice!);
      
      debugPrint('CrossLineTool.draw: 中心点 逻辑($centerIndex, $centerPrice) -> 屏幕($centerScreenX, $centerScreenY)');

      if (!centerScreenX.isFinite || !centerScreenY.isFinite) {
        debugPrint('警告：无效的中心点屏幕坐标');
        return;
      }

      // 使用与垂直线相同的主图区域计算方式
      final mainChartTop = 30.0; // mTopPadding
      
      // 计算主图区域高度：总显示高度 - 成交量区域高度(20%) - 指标区域高度(20%)
      final displayHeight = size.height - 30.0 - 20.0; // 总显示高度
      double volHeight = displayHeight * 0.2; // 成交量区域高度
      double secondaryHeight = displayHeight * 0.2; // 指标区域高度  
      double mainHeight = displayHeight - volHeight - secondaryHeight;
      
      final mainChartBottom = mainChartTop + mainHeight;
      
      debugPrint('十字线主图区域计算: top=$mainChartTop, bottom=$mainChartBottom, height=$mainHeight');

      // 检查十字线中心点是否在主图区域内
      if (centerScreenY < mainChartTop || centerScreenY > mainChartBottom) {
        debugPrint('十字线超出K线区域边界，不绘制: centerScreenY=$centerScreenY, 边界范围[$mainChartTop, $mainChartBottom]');
        return; // 超出边界时完全不绘制
      }

      // 十字线的垂直线也限制在K线主图区域内
      // 如果是预览状态，绘制虚线效果
      if (state == DrawingToolState.drawing) {
        // 绘制虚线垂直线（严格限制在K线主图区域）
        _drawDashedLine(canvas, Offset(centerScreenX, mainChartTop),
            Offset(centerScreenX, mainChartBottom), paint);

        // 绘制虚线水平线（横跨整个宽度）
        _drawDashedLine(canvas, Offset(0, centerScreenY),
            Offset(size.width, centerScreenY), paint);
        debugPrint('绘制虚线十字线（垂直线限制在K线区域）');
      } else {
        // 绘制垂直线（严格限制在K线主图区域）
        canvas.drawLine(
          Offset(centerScreenX, mainChartTop),
          Offset(centerScreenX, mainChartBottom),
          paint,
        );

        // 绘制水平线（横跨整个宽度）
        canvas.drawLine(
          Offset(0, centerScreenY),
          Offset(size.width, centerScreenY),
          paint,
        );
        debugPrint('绘制实线十字线（垂直线限制在K线区域）');
      }
    } catch (e) {
      debugPrint('CrossLineTool.draw 绘制异常: $e');
    }
  }

  /// 绘制虚线
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    double distance = (end - start).distance;
    double dashCount = (distance / (dashWidth + dashSpace)).floor().toDouble();

    for (int i = 0; i < dashCount; ++i) {
      double startOffset = i * (dashWidth + dashSpace);
      double endOffset = startOffset + dashWidth;

      if (endOffset > distance) endOffset = distance;

      Offset dashStart = start + (end - start) * (startOffset / distance);
      Offset dashEnd = start + (end - start) * (endOffset / distance);

      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool hitTest(Offset point) {
    // 需要通过坐标转换函数来判断，这里暂时返回false
    // TODO: 实现基于逻辑坐标的点击检测
    return false;
  }

  @override
  Rect getBounds() {
    // 需要通过坐标转换函数来计算边界，这里暂时返回零矩形
    // TODO: 实现基于逻辑坐标的边界计算
    return Rect.zero;
  }

  @override
  void move(Offset delta) {
    if (centerIndex == null || centerPrice == null) return;
    
    // 对于十字线，需要同时处理X和Y方向的移动
    
    // X方向移动：调整中心点的K线索引位置
    final indexChange = delta.dx * 0.01; // 简化的索引变化计算
    final newCenterIndex = (centerIndex! + indexChange).clamp(0.0, double.maxFinite);
    
    // Y方向移动：调整价格水平
    final priceChange = -delta.dy * 0.01; // 负号因为屏幕坐标Y向下为正，价格向上为正
    final newCenterPrice = centerPrice! + priceChange;
    
    // 价格范围约束（防止价格变为负数或过大）
    if (newCenterPrice > 0) {
      centerIndex = newCenterIndex;
      centerPrice = newCenterPrice;
    }
  }

  @override
  bool get isComplete => centerIndex != null && centerPrice != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'centerIndex': centerIndex,
      'centerPrice': centerPrice,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'createTime': createTime.millisecondsSinceEpoch,
    };
  }

  static CrossLineTool fromJson(Map<String, dynamic> json) {
    return CrossLineTool(
      id: json['id'],
      centerIndex: json['centerIndex']?.toDouble(),
      centerPrice: json['centerPrice']?.toDouble(),
      color: Color(json['color']),
      strokeWidth: json['strokeWidth']?.toDouble() ?? 2.0,
    );
  }
}
