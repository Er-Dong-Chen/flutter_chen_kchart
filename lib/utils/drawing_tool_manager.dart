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
    int Function(double)? calculateSelectedX, // 新增：屏幕X转索引的函数（直接使用BaseChartPainter的方法）
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

    // 转换屏幕坐标为逻辑坐标
    double? logicalIndex;
    double? logicalPrice;
    if (calculateSelectedX != null && getPriceFromY != null) {
      try {
        int selectedIndex = calculateSelectedX(adjustedPoint.dx);
        logicalIndex = selectedIndex.toDouble();
        logicalPrice = getPriceFromY(adjustedPoint.dy);
        debugPrint('startDrawing坐标转换: 屏幕点($adjustedPoint) -> selectedIndex=$selectedIndex, 索引($logicalIndex), 价格($logicalPrice)');
        
        // 验证数据有效性
        if (logicalIndex.isNaN || logicalIndex.isInfinite) {
          debugPrint('警告: logicalIndex无效: $logicalIndex');
          logicalIndex = null;
        }
        if (logicalPrice.isNaN || logicalPrice.isInfinite) {
          debugPrint('警告: logicalPrice无效: $logicalPrice');
          logicalPrice = null;
        }
      } catch (e) {
        debugPrint('startDrawing坐标转换错误: $e');
        logicalIndex = null;
        logicalPrice = null;
      }
    } else {
      debugPrint('坐标转换函数为null: calculateSelectedX=$calculateSelectedX, getPriceFromY=$getPriceFromY');
    }

    switch (_currentToolType!) {
      case DrawingToolType.trendLine:
        _currentDrawingTool = TrendLineTool(
          id: id,
          startIndex: logicalIndex,  // 逻辑坐标
          startPrice: logicalPrice,  // 逻辑坐标
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建趋势线工具: 逻辑坐标=($logicalIndex, $logicalPrice), isComplete=${_currentDrawingTool!.isComplete}');
        // 趋势线工具改为预览模式，等待设置终点
        _currentDrawingTool!.state = DrawingToolState.drawing;
        _updateDrawingPosition(adjustedPoint);
        break;
      case DrawingToolType.trendAngle:
        _currentDrawingTool = TrendAngleTool(
          id: id,
          startIndex: logicalIndex,  // 起点逻辑坐标
          startPrice: logicalPrice,  // 起点价格
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建趋势角度工具: 逻辑坐标=($logicalIndex, $logicalPrice), isComplete=${_currentDrawingTool!.isComplete}');
        // 趋势角度工具改为预览模式，等待设置终点
        _currentDrawingTool!.state = DrawingToolState.drawing;
        _updateDrawingPosition(adjustedPoint);
        debugPrint(
            '创建趋势角度工具: startPoint=$adjustedPoint, isComplete=${_currentDrawingTool!.isComplete}');
        break;
      case DrawingToolType.arrow:
        _currentDrawingTool = ArrowTool(
          id: id,
          startIndex: logicalIndex,  // 逻辑坐标
          startPrice: logicalPrice,  // 逻辑坐标
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建箭头工具: 逻辑坐标=($logicalIndex, $logicalPrice), isComplete=${_currentDrawingTool!.isComplete}');
        // 箭头工具改为预览模式，等待设置终点
        _currentDrawingTool!.state = DrawingToolState.drawing;
        _updateDrawingPosition(adjustedPoint);
        break;
      case DrawingToolType.verticalLine:
        _currentDrawingTool = VerticalLineTool(
          id: id,
          lineIndex: logicalIndex,  // 逻辑坐标
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建垂直线工具: 逻辑坐标=($logicalIndex), isComplete=${_currentDrawingTool!.isComplete}');
        // 垂直线工具立即完成
        break;
      case DrawingToolType.horizontalLine:
        _currentDrawingTool = HorizontalLineTool(
          id: id,
          priceLevel: logicalPrice,  // 逻辑坐标
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建水平线工具: 逻辑坐标=($logicalPrice), isComplete=${_currentDrawingTool!.isComplete}');
        // 水平线工具立即完成
        break;
      case DrawingToolType.horizontalRay:
        _currentDrawingTool = HorizontalRayTool(
          id: id,
          startIndex: logicalIndex,  // 起点逻辑坐标
          startPrice: logicalPrice,  // 起点价格
          endIndex: logicalIndex! + 10, // 自动设置终点为起点右侧10个索引位置
          endPrice: logicalPrice,        // 终点价格与起点相同（水平线）
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建水平射线工具: 逻辑坐标=($logicalIndex, $logicalPrice), isComplete=${_currentDrawingTool!.isComplete}');
        // 水平射线工具立即完成，无需第二次点击
        break;
      case DrawingToolType.ray:
        _currentDrawingTool = RayTool(
          id: id,
          startIndex: logicalIndex,  // 起点逻辑坐标
          startPrice: logicalPrice,  // 起点价格
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建射线工具: 逻辑坐标=($logicalIndex, $logicalPrice), isComplete=${_currentDrawingTool!.isComplete}');
        // 射线工具改为预览模式，等待设置方向点
        _currentDrawingTool!.state = DrawingToolState.drawing;
        _updateDrawingPosition(adjustedPoint);
        debugPrint(
            '创建射线工具: startPoint=$adjustedPoint, isComplete=${_currentDrawingTool!.isComplete}');
        // 射线工具改为预览模式，等待确定方向
        _currentDrawingTool!.state = DrawingToolState.drawing;
        _updateDrawingPosition(adjustedPoint);
        break;
      case DrawingToolType.crossLine:
        _currentDrawingTool = CrossLineTool(
          id: id,
          centerIndex: logicalIndex,  // 中心点逻辑坐标
          centerPrice: logicalPrice,  // 中心点价格
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        debugPrint(
            '创建十字线工具: 逻辑坐标=($logicalIndex, $logicalPrice), isComplete=${_currentDrawingTool!.isComplete}');
        // 十字线工具立即完成
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
    int Function(double)? calculateSelectedX, // 新增：屏幕X转索引的函数（直接使用BaseChartPainter的方法）
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

    // 转换屏幕坐标为逻辑坐标（更新时也需要）
    double? logicalIndex;
    double? logicalPrice;
    if (calculateSelectedX != null && getPriceFromY != null) {
      try {
        int selectedIndex = calculateSelectedX(adjustedPoint.dx);
        logicalIndex = selectedIndex.toDouble();
        logicalPrice = getPriceFromY(adjustedPoint.dy);
        debugPrint('updateDrawing坐标转换: 屏幕点($adjustedPoint) -> selectedIndex=$selectedIndex, 索引($logicalIndex), 价格($logicalPrice)');
        
        // 验证数据有效性
        if (logicalIndex.isNaN || logicalIndex.isInfinite) {
          debugPrint('警告: updateDrawing logicalIndex无效: $logicalIndex');
          logicalIndex = null;
        }
        if (logicalPrice.isNaN || logicalPrice.isInfinite) {
          debugPrint('警告: updateDrawing logicalPrice无效: $logicalPrice');
          logicalPrice = null;
        }
      } catch (e) {
        debugPrint('updateDrawing坐标转换错误: $e');
        logicalIndex = null;
        logicalPrice = null;
      }
    } else {
      debugPrint('updateDrawing坐标转换函数为null: calculateSelectedX=$calculateSelectedX, getPriceFromY=$getPriceFromY');
    }

    switch (_currentDrawingTool!.type) {
      case DrawingToolType.trendLine:
        final tool = _currentDrawingTool as TrendLineTool;
        tool.endIndex = logicalIndex;       // 设置逻辑坐标
        tool.endPrice = logicalPrice;       // 设置逻辑坐标
        debugPrint('TrendLineTool更新后数据: startIndex=${tool.startIndex}, startPrice=${tool.startPrice}, endIndex=${tool.endIndex}, endPrice=${tool.endPrice}, isComplete=${tool.isComplete}');
        break;
      case DrawingToolType.trendAngle:
        final tool = _currentDrawingTool as TrendAngleTool;
        debugPrint('TrendAngleTool updateDrawing: 屏幕坐标=$adjustedPoint, 逻辑坐标 logicalIndex=$logicalIndex, logicalPrice=$logicalPrice');
        tool.endIndex = logicalIndex;       // 设置逻辑坐标
        tool.endPrice = logicalPrice;       // 设置逻辑坐标
        // 计算角度（基于逻辑坐标）
        if (tool.startIndex != null && tool.startPrice != null && tool.endIndex != null && tool.endPrice != null) {
          final dx = tool.endIndex! - tool.startIndex!;
          final dy = tool.endPrice! - tool.startPrice!;
          tool.angle = (atan2(dy, dx) * 180 / pi).abs();
        }
        break;
      case DrawingToolType.arrow:
        final tool = _currentDrawingTool as ArrowTool;
        tool.endIndex = logicalIndex;       // 设置逻辑坐标
        tool.endPrice = logicalPrice;       // 设置逻辑坐标
        debugPrint('ArrowTool更新后数据: startIndex=${tool.startIndex}, startPrice=${tool.startPrice}, endIndex=${tool.endIndex}, endPrice=${tool.endPrice}, isComplete=${tool.isComplete}');
        break;
      case DrawingToolType.verticalLine:
        final tool = _currentDrawingTool as VerticalLineTool;
        debugPrint('VerticalLineTool updateDrawing: 屏幕坐标=$adjustedPoint, 逻辑坐标 logicalIndex=$logicalIndex');
        tool.lineIndex = logicalIndex;  // 更新逻辑坐标
        break;
      case DrawingToolType.horizontalLine:
        final tool = _currentDrawingTool as HorizontalLineTool;
        debugPrint('HorizontalLineTool updateDrawing: 屏幕坐标=$adjustedPoint, 逻辑坐标 logicalPrice=$logicalPrice');
        tool.priceLevel = logicalPrice;  // 更新逻辑坐标
        break;
      case DrawingToolType.horizontalRay:
        final tool = _currentDrawingTool as HorizontalRayTool;
        debugPrint('HorizontalRayTool updateDrawing: 屏幕坐标=$adjustedPoint, 逻辑坐标 logicalIndex=$logicalIndex, logicalPrice=$logicalPrice');
        // 水平射线只需要起点位置，不需要更新终点
        break;
      case DrawingToolType.ray:
        final tool = _currentDrawingTool as RayTool;
        debugPrint('RayTool updateDrawing: 屏幕坐标=$adjustedPoint, 逻辑坐标 logicalIndex=$logicalIndex, logicalPrice=$logicalPrice');
        tool.directionIndex = logicalIndex;   // 设置方向点逻辑坐标
        tool.directionPrice = logicalPrice;   // 设置方向点价格
        debugPrint('RayTool更新后数据: startIndex=${tool.startIndex}, startPrice=${tool.startPrice}, directionIndex=${tool.directionIndex}, directionPrice=${tool.directionPrice}, isComplete=${tool.isComplete}');
        break;
      case DrawingToolType.crossLine:
        final tool = _currentDrawingTool as CrossLineTool;
        debugPrint('CrossLineTool updateDrawing: 屏幕坐标=$adjustedPoint, 逻辑坐标 logicalIndex=$logicalIndex, logicalPrice=$logicalPrice');
        tool.centerIndex = logicalIndex;  // 更新中心点逻辑坐标
        tool.centerPrice = logicalPrice;  // 更新中心点价格
        debugPrint('CrossLineTool更新后数据: centerIndex=${tool.centerIndex}, centerPrice=${tool.centerPrice}, isComplete=${tool.isComplete}');
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
        'DrawingToolManager.drawTools 开始: 工具数量=${_tools.length}, 当前绘制工具=${_currentDrawingTool != null}');
    debugPrint('绘制参数: size=$size, scaleX=$scaleX, scrollX=$scrollX');

    // 绘制已完成的工具
    for (int i = 0; i < _tools.length; i++) {
      final tool = _tools[i];
      debugPrint('检查工具[$i]: type=${tool.type}, id=${tool.id}, isVisible=${tool.isVisible}, state=${tool.state}, isComplete=${tool.isComplete}');
      
      if (tool is TrendLineTool) {
        debugPrint('TrendLineTool详情: startIndex=${tool.startIndex}, startPrice=${tool.startPrice}, endIndex=${tool.endIndex}, endPrice=${tool.endPrice}');
      }
      
      if (tool.isVisible) {
        debugPrint('开始绘制工具[$i]: ${tool.type}, id=${tool.id}');
        try {
          tool.draw(canvas, size, scaleX, scrollX, getX, getY);
          debugPrint('工具[$i]绘制完成');
        } catch (e) {
          debugPrint('工具[$i]绘制异常: $e');
        }

        // 绘制选中状态的视觉反馈
        if (tool == _selectedTool) {
          _drawSelectionIndicator(canvas, tool);
        }
      } else {
        debugPrint('跳过不可见工具[$i]: ${tool.type}');
      }
    }

    // 绘制正在绘制的工具
    if (_currentDrawingTool != null) {
      debugPrint(
          '绘制当前工具: ${_currentDrawingTool!.type}, 完成状态=${_currentDrawingTool!.isComplete}, state=${_currentDrawingTool!.state}');
      if (_currentDrawingTool is TrendLineTool) {
        final tool = _currentDrawingTool as TrendLineTool;
        debugPrint('当前TrendLineTool详情: startIndex=${tool.startIndex}, startPrice=${tool.startPrice}, endIndex=${tool.endIndex}, endPrice=${tool.endPrice}');
      }
      try {
        _currentDrawingTool!.draw(canvas, size, scaleX, scrollX, getX, getY);
        debugPrint('当前工具绘制完成');
      } catch (e) {
        debugPrint('当前工具绘制异常: $e');
      }
    }
    debugPrint('DrawingToolManager.drawTools 结束');
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
