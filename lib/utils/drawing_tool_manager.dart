import 'package:flutter/material.dart';
import 'dart:math';
import '../entity/drawing_tool_entity.dart';

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

  // 事件回调
  VoidCallback? onToolsChanged;
  ValueChanged<DrawingTool?>? onToolSelected;

  // 获取所有工具
  List<DrawingTool> get tools => List.unmodifiable(_tools);

  // 获取当前工具类型
  DrawingToolType? get currentToolType => _currentToolType;

  // 获取当前绘制工具
  DrawingTool? get currentDrawingTool => _currentDrawingTool;

  // 获取选中工具
  DrawingTool? get selectedTool => _selectedTool;

  // 设置当前工具类型
  void setCurrentToolType(DrawingToolType? type) {
    debugPrint(
        'DrawingToolManager.setCurrentToolType: $_currentToolType -> $type');
    _currentToolType = type;
    _finishCurrentDrawing();
    _clearSelection();
  }

  // 开始绘制新工具
  void startDrawing(Offset point, {Map<String, dynamic>? properties}) {
    debugPrint('DrawingToolManager.startDrawing: $_currentToolType at $point');
    if (_currentToolType == null) return;

    _finishCurrentDrawing();

    final id = _generateId();

    switch (_currentToolType!) {
      case DrawingToolType.trendLine:
        _currentDrawingTool = TrendLineTool(
          id: id,
          startPoint: point,
          color: properties?['color'] ?? const Color(0xFFFFD700),
          strokeWidth: properties?['strokeWidth'] ?? 2.0,
        );
        break;
      case DrawingToolType.trendAngle:
        _currentDrawingTool = TrendAngleTool(
          id: id,
          startPoint: point,
          color: properties?['color'] ?? const Color(0xFFFFD700),
          strokeWidth: properties?['strokeWidth'] ?? 2.0,
        );
        break;
      case DrawingToolType.arrow:
        _currentDrawingTool = ArrowTool(
          id: id,
          startPoint: point,
          color: properties?['color'] ?? const Color(0xFFFF6B6B),
          strokeWidth: properties?['strokeWidth'] ?? 2.0,
        );
        break;
      case DrawingToolType.verticalLine:
        _currentDrawingTool = VerticalLineTool(
          id: id,
          xPosition: point.dx,
          color: properties?['color'] ?? const Color(0xFF00BFFF),
          strokeWidth: properties?['strokeWidth'] ?? 2.0,
        );
        // 垂直线工具创建后立即完成
        _currentDrawingTool!.state = DrawingToolState.none;
        _tools.add(_currentDrawingTool!);
        _currentDrawingTool = null;
        _notifyToolsChanged();
        return;
      case DrawingToolType.horizontalLine:
        _currentDrawingTool = HorizontalLineTool(
          id: id,
          yPosition: point.dy,
          color: properties?['color'] ?? const Color(0xFF00BFFF),
          strokeWidth: properties?['strokeWidth'] ?? 2.0,
        );
        // 水平线工具创建后立即完成
        _currentDrawingTool!.state = DrawingToolState.none;
        _tools.add(_currentDrawingTool!);
        _currentDrawingTool = null;
        _notifyToolsChanged();
        return;
      case DrawingToolType.horizontalRay:
        _currentDrawingTool = HorizontalRayTool(
          id: id,
          startPoint: point,
          color: properties?['color'] ?? const Color(0xFF00BFFF),
          strokeWidth: properties?['strokeWidth'] ?? 2.0,
        );
        break;
      case DrawingToolType.ray:
        _currentDrawingTool = RayTool(
          id: id,
          startPoint: point,
          color: properties?['color'] ?? const Color(0xFF00BFFF),
          strokeWidth: properties?['strokeWidth'] ?? 2.0,
        );
        break;
      case DrawingToolType.crossLine:
        _currentDrawingTool = CrossLineTool(
          id: id,
          centerPoint: point,
          color: properties?['color'] ?? const Color(0xFF00BFFF),
          strokeWidth: properties?['strokeWidth'] ?? 2.0,
        );
        // 十字线工具创建后立即完成
        _currentDrawingTool!.state = DrawingToolState.none;
        _tools.add(_currentDrawingTool!);
        _currentDrawingTool = null;
        _notifyToolsChanged();
        return;
    }

    if (_currentDrawingTool != null) {
      _currentDrawingTool!.state = DrawingToolState.drawing;
      _notifyToolsChanged();
    }
  }

  // 更新当前绘制工具
  void updateDrawing(Offset point) {
    if (_currentDrawingTool == null) return;

    switch (_currentDrawingTool!.type) {
      case DrawingToolType.trendLine:
        final tool = _currentDrawingTool as TrendLineTool;
        tool.endPoint = point;
        break;
      case DrawingToolType.trendAngle:
        final tool = _currentDrawingTool as TrendAngleTool;
        tool.endPoint = point;
        // 计算角度
        if (tool.startPoint != null && tool.endPoint != null) {
          final dx = tool.endPoint!.dx - tool.startPoint!.dx;
          final dy = tool.endPoint!.dy - tool.startPoint!.dy;
          tool.angle = (atan2(dy, dx) * 180 / pi).abs();
        }
        break;
      case DrawingToolType.arrow:
        final tool = _currentDrawingTool as ArrowTool;
        tool.endPoint = point;
        break;
      case DrawingToolType.verticalLine:
        final tool = _currentDrawingTool as VerticalLineTool;
        tool.xPosition = point.dx;
        break;
      case DrawingToolType.horizontalLine:
        final tool = _currentDrawingTool as HorizontalLineTool;
        tool.yPosition = point.dy;
        break;
      case DrawingToolType.horizontalRay:
        final tool = _currentDrawingTool as HorizontalRayTool;
        if (tool.direction == null) {
          tool.direction = point.dx > tool.startPoint!.dx ? 1.0 : -1.0;
        }
        break;
      case DrawingToolType.ray:
        final tool = _currentDrawingTool as RayTool;
        tool.directionPoint = point;
        break;
      case DrawingToolType.crossLine:
        final tool = _currentDrawingTool as CrossLineTool;
        tool.centerPoint = point;
        break;
    }

    _notifyToolsChanged();
  }

  // 完成当前绘制
  void finishDrawing() {
    debugPrint(
        'DrawingToolManager.finishDrawing: $_currentDrawingTool, isComplete: ${_currentDrawingTool?.isComplete}');
    if (_currentDrawingTool != null && _currentDrawingTool!.isComplete) {
      _currentDrawingTool!.state = DrawingToolState.none;
      _tools.add(_currentDrawingTool!);
      debugPrint('绘图工具已添加，总数: ${_tools.length}');
      _currentDrawingTool = null;
      _notifyToolsChanged();
    }
  }

  // 取消当前绘制
  void cancelDrawing() {
    debugPrint('DrawingToolManager.cancelDrawing');
    if (_currentDrawingTool != null) {
      _currentDrawingTool = null;
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
    onToolSelected?.call(null);
    _notifyToolsChanged();
  }

  // 清除选择
  void clearSelection() {
    _clearSelection();
  }

  // 添加测试绘图工具（用于调试）
  void addTestTools() {
    // 添加一条测试趋势线
    final testTrendLine = TrendLineTool(
      id: 'test_trend',
      startPoint: Offset(50, 100),
      endPoint: Offset(300, 250),
      color: Colors.blue,
      strokeWidth: 2.0,
    );
    _tools.add(testTrendLine);

    // 添加一条测试水平线
    final testHorizontalLine = HorizontalLineTool(
      id: 'test_horizontal',
      yPosition: 200.0,
      color: Colors.red,
      strokeWidth: 2.0,
    );
    _tools.add(testHorizontalLine);

    debugPrint('测试绘图工具添加完成，工具数量: ${_tools.length}');
    _notifyToolsChanged();
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

    // 特定工具的属性更新
    switch (tool.type) {
      case DrawingToolType.trendLine:
      case DrawingToolType.trendAngle:
      case DrawingToolType.arrow:
      case DrawingToolType.verticalLine:
      case DrawingToolType.horizontalLine:
      case DrawingToolType.horizontalRay:
      case DrawingToolType.ray:
      case DrawingToolType.crossLine:
        // 这些工具类型不需要特殊属性更新
        break;
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
      }
    }

    // 绘制正在绘制的工具
    if (_currentDrawingTool != null) {
      debugPrint(
          '绘制当前工具: ${_currentDrawingTool!.type}, 完成状态=${_currentDrawingTool!.isComplete}');
      _currentDrawingTool!.draw(canvas, size, scaleX, scrollX, getX, getY);
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

  // 私有方法
  void _finishCurrentDrawing() {
    if (_currentDrawingTool != null) {
      if (_currentDrawingTool!.isComplete) {
        _currentDrawingTool!.state = DrawingToolState.none;
        _tools.add(_currentDrawingTool!);
      }
      _currentDrawingTool = null;
    }
  }

  void _clearSelection() {
    if (_selectedTool != null) {
      _selectedTool!.state = DrawingToolState.none;
      _selectedTool = null;
      onToolSelected?.call(null);
    }
  }

  void _notifyToolsChanged() {
    onToolsChanged?.call();
  }

  String _generateId() {
    return 'tool_${DateTime.now().millisecondsSinceEpoch}_${_tools.length}';
  }
}
