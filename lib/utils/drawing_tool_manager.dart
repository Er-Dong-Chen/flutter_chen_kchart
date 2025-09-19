import 'package:flutter/material.dart';
import 'dart:math';
import '../entity/drawing_tool_entity.dart';
import '../entity/k_line_entity.dart';
import 'drawing_mode_manager.dart';

// 绘图工具管理器
class DrawingToolManager {
  // 所有绘图工具列表
  final List<DrawingTool> _tools = [];

  // 当前选中的工具类型
  DrawingToolType? _currentToolType;

  // 当前正在绘制的工具
  DrawingTool? _currentDrawingTool;

  // 当前选中的工具
  DrawingTool? _selectedTool;

  // 绘图模式管理器
  final DrawingModeManager _modeManager = DrawingModeManager();

  // 当前绘图位置（用于十字准星）
  Offset? _currentDrawingPosition;

  // 当前绘图工具的属性
  Color _currentColor = const Color(0xFFFFD700);
  double _currentStrokeWidth = 2.0;

  // 事件回调
  VoidCallback? onToolsChanged;
  ValueChanged<DrawingTool?>? onToolSelected;
  ValueChanged<Offset?>? onDrawingPositionChanged; // 新增：绘图位置变化回调

  // 获取所有工具
  List<DrawingTool> get tools => List.unmodifiable(_tools);

  // 获取当前工具类型
  DrawingToolType? get currentToolType => _currentToolType;

  // 获取当前绘制工具
  DrawingTool? get currentDrawingTool => _currentDrawingTool;

  // 获取选中工具
  DrawingTool? get selectedTool => _selectedTool;

  // 获取绘图模式管理器
  DrawingModeManager get modeManager => _modeManager;

  // 获取当前绘图位置
  Offset? get currentDrawingPosition => _currentDrawingPosition;

  // 获取当前颜色
  Color get currentColor => _currentColor;

  // 获取当前线条粗细
  double get currentStrokeWidth => _currentStrokeWidth;

  // 初始化
  DrawingToolManager() {
    _modeManager.onModeChanged = () {
      debugPrint('绘图模式变化: ${_modeManager.getModeDescription()}');
      onToolsChanged?.call();
    };
  }

  // 设置当前工具类型
  void setCurrentToolType(DrawingToolType? type) {
    debugPrint(
        'DrawingToolManager.setCurrentToolType: $_currentToolType -> $type');

    // 如果设置新工具类型，自动启用绘图模式
    if (type != null && !_modeManager.isDrawingModeEnabled) {
      _modeManager.setDrawingMode(true);
    }

    _currentToolType = type;
    _finishCurrentDrawing();
    _clearSelection();
    _updateDrawingPosition(null); // 清除绘图位置
  }

  // 设置当前绘图属性
  void setCurrentColor(Color color) {
    _currentColor = color;
    // 如果有选中的工具，更新其颜色
    if (_selectedTool != null) {
      _selectedTool!.color = color;
      onToolsChanged?.call();
    }
  }

  void setCurrentStrokeWidth(double width) {
    _currentStrokeWidth = width;
    // 如果有选中的工具，更新其线条粗细
    if (_selectedTool != null) {
      _selectedTool!.strokeWidth = width;
      onToolsChanged?.call();
    }
  }

  // 开始绘制新工具
  void startDrawing(
    Offset point, {
    List<KLineEntity>? kLineData,
    double? scaleX,
    double? scrollX,
    double Function(double)? getX,
    double Function(double)? getY,
    double Function(double)? getPriceFromY, // 新增：从Y坐标反推价格的函数
    Rect? chartRect,
  }) {
    debugPrint('DrawingToolManager.startDrawing: $_currentToolType at $point');
    if (_currentToolType == null || !_modeManager.isDrawingModeEnabled) return;

    _finishCurrentDrawing();

    // 应用磁铁吸附
    Offset adjustedPoint = point;
    if (_modeManager.isMagnetMode &&
        kLineData != null &&
        scaleX != null &&
        scrollX != null &&
        getX != null &&
        getY != null &&
        chartRect != null) {
      adjustedPoint = _modeManager.magnetSnap(
        point,
        kLineData,
        scaleX,
        scrollX,
        getX,
        getY,
        chartRect,
      );
    }

    final id = _generateId();
    final properties = {
      'color': _currentColor,
      'strokeWidth': _currentStrokeWidth,
    };

    switch (_currentToolType!) {
      case DrawingToolType.trendLine:
        _currentDrawingTool = TrendLineTool(
          id: id,
          startPoint: adjustedPoint,
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建趋势线工具: startPoint=$adjustedPoint, isComplete=${_currentDrawingTool!.isComplete}');
        break;
      case DrawingToolType.trendAngle:
        _currentDrawingTool = TrendAngleTool(
          id: id,
          startPoint: adjustedPoint,
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建趋势角度工具: startPoint=$adjustedPoint, isComplete=${_currentDrawingTool!.isComplete}');
        break;
      case DrawingToolType.arrow:
        _currentDrawingTool = ArrowTool(
          id: id,
          startPoint: adjustedPoint,
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建箭头工具: startPoint=$adjustedPoint, isComplete=${_currentDrawingTool!.isComplete}');
        break;
      case DrawingToolType.verticalLine:
        _currentDrawingTool = VerticalLineTool(
          id: id,
          xPosition: adjustedPoint.dx,
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建垂直线工具: xPosition=${adjustedPoint.dx}, isComplete=${_currentDrawingTool!.isComplete}');
        // 垂直线工具改为预览模式，不立即完成
        _currentDrawingTool!.state = DrawingToolState.drawing;
        _updateDrawingPosition(adjustedPoint);
        break;
      case DrawingToolType.horizontalLine:
        _currentDrawingTool = HorizontalLineTool(
          id: id,
          yPosition: adjustedPoint.dy,
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建水平线工具: yPosition=${adjustedPoint.dy}, isComplete=${_currentDrawingTool!.isComplete}');
        // 水平线工具改为预览模式，不立即完成
        _currentDrawingTool!.state = DrawingToolState.drawing;
        _updateDrawingPosition(adjustedPoint);
        break;
      case DrawingToolType.horizontalRay:
        // 计算真实价格值
        double realPrice = adjustedPoint.dy;
        if (getPriceFromY != null) {
          // 使用反向转换函数从屏幕Y坐标计算真实价格
          realPrice = getPriceFromY(adjustedPoint.dy);
          debugPrint('水平射线屏幕Y坐标: ${adjustedPoint.dy}，真实价格值: $realPrice');
        } else {
          debugPrint('警告：没有价格转换函数，使用屏幕Y坐标作为价格');
        }

        _currentDrawingTool = HorizontalRayTool(
          id: _generateId(),
          yPosition: adjustedPoint.dy,
          centerX: adjustedPoint.dx,
          priceValue: realPrice, // 使用计算出的真实价格值
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        // 水平射线改为预览模式，不立即完成
        _currentDrawingTool!.state = DrawingToolState.drawing;
        _updateDrawingPosition(adjustedPoint);
        break;
      case DrawingToolType.ray:
        _currentDrawingTool = RayTool(
          id: id,
          startPoint: adjustedPoint,
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建射线工具: startPoint=$adjustedPoint, isComplete=${_currentDrawingTool!.isComplete}');
        // 射线工具改为预览模式，等待确定方向
        _currentDrawingTool!.state = DrawingToolState.drawing;
        _updateDrawingPosition(adjustedPoint);
        break;
      case DrawingToolType.crossLine:
        _currentDrawingTool = CrossLineTool(
          id: id,
          centerPoint: adjustedPoint,
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        // 十字线工具改为预览模式，不立即完成
        _currentDrawingTool!.state = DrawingToolState.drawing;
        _updateDrawingPosition(adjustedPoint);
        break;
    }

    if (_currentDrawingTool != null) {
      // 只有在工具状态不是drawing的情况下才设置为drawing
      // 因为单点工具已经在创建时设置了正确的状态
      if (_currentDrawingTool!.state == DrawingToolState.none) {
        _currentDrawingTool!.state = DrawingToolState.drawing;
      }
      _updateDrawingPosition(adjustedPoint);
      _notifyToolsChanged();
      debugPrint(
          '工具创建完成: state=${_currentDrawingTool!.state}, isComplete=${_currentDrawingTool!.isComplete}');
    }
  }

  // 更新当前绘制工具
  void updateDrawing(
    Offset point, {
    List<KLineEntity>? kLineData,
    double? scaleX,
    double? scrollX,
    double Function(double)? getX,
    double Function(double)? getY,
    double Function(double)? getPriceFromY, // 新增：从Y坐标反推价格的函数
    Rect? chartRect,
  }) {
    if (_currentDrawingTool == null) return;

    // 应用磁铁吸附
    Offset adjustedPoint = point;
    if (_modeManager.isMagnetMode &&
        kLineData != null &&
        scaleX != null &&
        scrollX != null &&
        getX != null &&
        getY != null &&
        chartRect != null) {
      adjustedPoint = _modeManager.magnetSnap(
        point,
        kLineData,
        scaleX,
        scrollX,
        getX,
        getY,
        chartRect,
      );
    }

    switch (_currentDrawingTool!.type) {
      case DrawingToolType.trendLine:
        final tool = _currentDrawingTool as TrendLineTool;
        tool.endPoint = adjustedPoint;
        break;
      case DrawingToolType.trendAngle:
        final tool = _currentDrawingTool as TrendAngleTool;
        tool.endPoint = adjustedPoint;
        // 计算角度
        if (tool.startPoint != null && tool.endPoint != null) {
          final dx = tool.endPoint!.dx - tool.startPoint!.dx;
          final dy = tool.endPoint!.dy - tool.startPoint!.dy;
          tool.angle = (atan2(dy, dx) * 180 / pi).abs();
        }
        break;
      case DrawingToolType.arrow:
        final tool = _currentDrawingTool as ArrowTool;
        tool.endPoint = adjustedPoint;
        break;
      case DrawingToolType.verticalLine:
        final tool = _currentDrawingTool as VerticalLineTool;
        tool.xPosition = adjustedPoint.dx;
        break;
      case DrawingToolType.horizontalLine:
        final tool = _currentDrawingTool as HorizontalLineTool;
        tool.yPosition = adjustedPoint.dy;
        break;
      case DrawingToolType.horizontalRay:
        final tool = _currentDrawingTool as HorizontalRayTool;
        tool.yPosition = adjustedPoint.dy;
        tool.centerX = adjustedPoint.dx;
        // 更新真实价格值
        if (getPriceFromY != null) {
          tool.priceValue = getPriceFromY(adjustedPoint.dy);
          debugPrint('更新水平射线价格: ${tool.priceValue}');
        } else {
          tool.priceValue = adjustedPoint.dy; // 后备方案
        }
        break;
      case DrawingToolType.ray:
        final tool = _currentDrawingTool as RayTool;
        tool.directionPoint = adjustedPoint;
        break;
      case DrawingToolType.crossLine:
        final tool = _currentDrawingTool as CrossLineTool;
        tool.centerPoint = adjustedPoint;
        break;
    }

    _updateDrawingPosition(adjustedPoint);
    _notifyToolsChanged();
  }

  // 完成当前绘制
  void finishDrawing() {
    debugPrint(
        'DrawingToolManager.finishDrawing: $_currentDrawingTool, isComplete: ${_currentDrawingTool?.isComplete}');
    if (_currentDrawingTool != null) {
      debugPrint(
          '当前工具: ${_currentDrawingTool!.type}, 状态: ${_currentDrawingTool!.state}, 完成: ${_currentDrawingTool!.isComplete}');
      if (_currentDrawingTool!.isComplete) {
        // 将工具状态设置为正常状态（非预览状态）
        _currentDrawingTool!.state = DrawingToolState.none;
        _tools.add(_currentDrawingTool!);
        debugPrint('绘图工具已添加，总数: ${_tools.length}');

        // 重要：清除当前绘制工具，这样预览线就会消失
        _currentDrawingTool = null;
        _updateDrawingPosition(null);
        _handleToolCompletion();
      } else {
        debugPrint('工具未完成，无法添加到工具列表');
      }
    } else {
      debugPrint('没有当前绘制工具');
    }
  }

  // 处理工具完成后的操作
  void _handleToolCompletion() {
    // 如果不是持续绘图模式，完成后退出当前工具
    if (!_modeManager.shouldContinueAfterDrawing()) {
      _currentToolType = null;
    }
    _notifyToolsChanged();
  }

  // 取消当前绘制
  void cancelDrawing() {
    debugPrint('DrawingToolManager.cancelDrawing');
    if (_currentDrawingTool != null) {
      _currentDrawingTool = null;
      _updateDrawingPosition(null);
      _notifyToolsChanged();
    }
  }

  // 选择工具
  void selectTool(Offset point) {
    debugPrint('DrawingToolManager.selectTool at $point');
    _clearSelection();

    // 从上到下检测点击的工具
    for (int i = _tools.length - 1; i >= 0; i--) {
      final tool = _tools[i];
      if (tool.isVisible && tool.hitTest(point)) {
        _selectedTool = tool;
        _selectedTool!.state = DrawingToolState.selected;

        // 更新当前颜色和线条粗细为选中工具的属性
        _currentColor = _selectedTool!.color;
        _currentStrokeWidth = _selectedTool!.strokeWidth;

        onToolSelected?.call(_selectedTool);
        debugPrint('选中工具: ${tool.type}, id: ${tool.id}');
        _notifyToolsChanged();
        break;
      }
    }
  }

  // 移动选中的工具
  void moveSelectedTool(Offset delta) {
    if (_selectedTool != null) {
      _selectedTool!.move(delta);
      _notifyToolsChanged();
    }
  }

  // 删除选中的工具
  void deleteSelectedTool() {
    if (_selectedTool != null) {
      _tools.remove(_selectedTool);
      _selectedTool = null;
      onToolSelected?.call(null);
      _notifyToolsChanged();
    }
  }

  // 删除工具
  void deleteTool(String id) {
    final index = _tools.indexWhere((tool) => tool.id == id);
    if (index != -1) {
      final tool = _tools.removeAt(index);
      if (tool == _selectedTool) {
        _selectedTool = null;
        onToolSelected?.call(null);
      }
      _notifyToolsChanged();
    }
  }

  // 清除所有工具
  void clearAllTools() {
    _tools.clear();
    _selectedTool = null;
    _currentDrawingTool = null;
    _updateDrawingPosition(null);
    onToolSelected?.call(null);
    _notifyToolsChanged();
  }

  // 清除选择
  void clearSelection() {
    _clearSelection();
  }

  // 获取指定类型的工具
  List<DrawingTool> getToolsByType(DrawingToolType type) {
    return _tools.where((tool) => tool.type == type).toList();
  }

  // 显示/隐藏工具
  void setToolVisibility(String id, bool visible) {
    final tool = _tools.firstWhere((t) => t.id == id);
    tool.isVisible = visible;
    _notifyToolsChanged();
  }

  // 更新工具属性
  void updateToolProperties(String id, Map<String, dynamic> properties) {
    final tool = _tools.firstWhere((t) => t.id == id);

    if (properties.containsKey('color')) {
      tool.color = properties['color'];
    }
    if (properties.containsKey('strokeWidth')) {
      tool.strokeWidth = properties['strokeWidth'];
    }

    _notifyToolsChanged();
  }

  // 绘制所有工具
  void drawTools(Canvas canvas, Size size, double scaleX, double scrollX,
      double Function(double) getX, double Function(double) getY) {
    debugPrint(
        'DrawingToolManager.drawTools: 工具数量=${_tools.length}, 当前绘制工具=${_currentDrawingTool != null}');

    // 绘制已完成的工具
    for (final tool in _tools) {
      if (tool.isVisible) {
        debugPrint('绘制工具: ${tool.type}, id=${tool.id}');
        tool.draw(canvas, size, scaleX, scrollX, getX, getY);

        // 绘制选中状态的视觉反馈
        if (tool == _selectedTool) {
          _drawSelectionIndicator(canvas, tool);
        }
      }
    }

    // 绘制正在绘制的工具
    if (_currentDrawingTool != null) {
      debugPrint(
          '绘制当前工具: ${_currentDrawingTool!.type}, 完成状态=${_currentDrawingTool!.isComplete}');
      _currentDrawingTool!.draw(canvas, size, scaleX, scrollX, getX, getY);
    }
  }

  // 绘制选中工具的指示器
  void _drawSelectionIndicator(Canvas canvas, DrawingTool tool) {
    final bounds = tool.getBounds();
    if (bounds.isEmpty) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 扩展边界框
    final expandedBounds = bounds.inflate(5.0);
    canvas.drawRect(expandedBounds, paint);

    // 绘制控制点
    final controlPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const double controlSize = 4.0;
    // 四个角的控制点
    final controlPoints = [
      expandedBounds.topLeft,
      expandedBounds.topRight,
      expandedBounds.bottomLeft,
      expandedBounds.bottomRight,
    ];

    for (final point in controlPoints) {
      canvas.drawCircle(point, controlSize, controlPaint);
    }
  }

  // 序列化所有工具
  List<Map<String, dynamic>> serializeTools() {
    return _tools.map((tool) => tool.toJson()).toList();
  }

  // 反序列化工具
  void deserializeTools(List<Map<String, dynamic>> data) {
    _tools.clear();
    _selectedTool = null;
    _currentDrawingTool = null;

    for (final json in data) {
      DrawingTool? tool;
      final type = DrawingToolType.values[json['type']];

      switch (type) {
        case DrawingToolType.trendLine:
          tool = TrendLineTool.fromJson(json);
          break;
        case DrawingToolType.trendAngle:
          tool = TrendAngleTool.fromJson(json);
          break;
        case DrawingToolType.arrow:
          tool = ArrowTool.fromJson(json);
          break;
        case DrawingToolType.verticalLine:
          tool = VerticalLineTool.fromJson(json);
          break;
        case DrawingToolType.horizontalLine:
          tool = HorizontalLineTool.fromJson(json);
          break;
        case DrawingToolType.horizontalRay:
          tool = HorizontalRayTool.fromJson(json);
          break;
        case DrawingToolType.ray:
          tool = RayTool.fromJson(json);
          break;
        case DrawingToolType.crossLine:
          tool = CrossLineTool.fromJson(json);
          break;
      }

      _tools.add(tool);
    }

    _notifyToolsChanged();
  }

  // 获取十字准星显示的价格和时间文本
  String? getCrosshairPriceText(double price, int fixedLength) {
    if (_currentDrawingPosition == null) return null;
    return price.toStringAsFixed(fixedLength);
  }

  String? getCrosshairTimeText(DateTime? time) {
    if (_currentDrawingPosition == null || time == null) return null;
    return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  // 私有方法
  void _finishCurrentDrawing() {
    if (_currentDrawingTool != null) {
      if (_currentDrawingTool!.isComplete) {
        _currentDrawingTool!.state = DrawingToolState.none;
        _tools.add(_currentDrawingTool!);
      }
      _currentDrawingTool = null;
      _updateDrawingPosition(null);
    }
  }

  void _clearSelection() {
    if (_selectedTool != null) {
      _selectedTool!.state = DrawingToolState.none;
      _selectedTool = null;
      onToolSelected?.call(null);
    }
  }

  void _updateDrawingPosition(Offset? position) {
    _currentDrawingPosition = position;
    onDrawingPositionChanged?.call(position);
  }

  void _notifyToolsChanged() {
    onToolsChanged?.call();
  }

  String _generateId() {
    return 'tool_${DateTime.now().millisecondsSinceEpoch}_${_tools.length}';
  }
}
