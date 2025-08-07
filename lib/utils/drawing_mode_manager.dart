import 'package:flutter/material.dart';
import '../entity/k_line_entity.dart';

/// 绘图模式管理器
/// 负责管理绘图工具的各种模式状态和辅助功能
class DrawingModeManager {
  // 绘图模式状态
  bool _isDrawingModeEnabled = false;
  bool _isContinuousMode = false;
  bool _isMagnetMode = false;

  // 事件回调
  VoidCallback? onModeChanged;

  // 获取器
  bool get isDrawingModeEnabled => _isDrawingModeEnabled;
  bool get isContinuousMode => _isContinuousMode;
  bool get isMagnetMode => _isMagnetMode;

  /// 切换绘图模式总开关
  void toggleDrawingMode() {
    _isDrawingModeEnabled = !_isDrawingModeEnabled;
    debugPrint('绘图模式已${_isDrawingModeEnabled ? "启用" : "禁用"}');
    _notifyModeChanged();
  }

  /// 设置绘图模式总开关
  void setDrawingMode(bool enabled) {
    if (_isDrawingModeEnabled != enabled) {
      _isDrawingModeEnabled = enabled;
      debugPrint('绘图模式设置为: ${enabled ? "启用" : "禁用"}');
      _notifyModeChanged();
    }
  }

  /// 切换持续绘图模式
  void toggleContinuousMode() {
    _isContinuousMode = !_isContinuousMode;
    debugPrint('持续绘图模式已${_isContinuousMode ? "启用" : "禁用"}');
    _notifyModeChanged();
  }

  /// 设置持续绘图模式
  void setContinuousMode(bool enabled) {
    if (_isContinuousMode != enabled) {
      _isContinuousMode = enabled;
      debugPrint('持续绘图模式设置为: ${enabled ? "启用" : "禁用"}');
      _notifyModeChanged();
    }
  }

  /// 切换磁铁模式
  void toggleMagnetMode() {
    _isMagnetMode = !_isMagnetMode;
    debugPrint('磁铁模式已${_isMagnetMode ? "启用" : "禁用"}');
    _notifyModeChanged();
  }

  /// 设置磁铁模式
  void setMagnetMode(bool enabled) {
    if (_isMagnetMode != enabled) {
      _isMagnetMode = enabled;
      debugPrint('磁铁模式设置为: ${enabled ? "启用" : "禁用"}');
      _notifyModeChanged();
    }
  }

  /// 磁铁吸附功能 - 将点吸附到最近的K线数据点
  Offset magnetSnap(
    Offset point,
    List<KLineEntity>? datas,
    double scaleX,
    double scrollX,
    double Function(double) getX,
    double Function(double) getY,
    Rect chartRect,
  ) {
    if (!_isMagnetMode || datas == null || datas.isEmpty) {
      return point;
    }

    try {
      // 计算最近的K线索引
      double chartWidth = chartRect.width;
      double pointWidth = chartWidth / (datas.length * scaleX);
      int dataIndex =
          ((point.dx - chartRect.left) / pointWidth + scrollX).round();

      // 确保索引在有效范围内
      dataIndex = dataIndex.clamp(0, datas.length - 1);

      if (dataIndex < 0 || dataIndex >= datas.length) {
        return point;
      }

      KLineEntity kLine = datas[dataIndex];

      // 计算K线的各个价格点在屏幕上的Y坐标
      double openY = getY(kLine.open);
      double closeY = getY(kLine.close);
      double highY = getY(kLine.high);
      double lowY = getY(kLine.low);

      // 计算K线在屏幕上的X坐标
      double kLineX = getX(dataIndex.toDouble());

      // 找到距离点击点最近的价格点
      List<Offset> pricePoints = [
        Offset(kLineX, openY), // 开盘价
        Offset(kLineX, closeY), // 收盘价
        Offset(kLineX, highY), // 最高价
        Offset(kLineX, lowY), // 最低价
      ];

      // 计算距离并找到最近的点
      double minDistance = double.infinity;
      Offset snapPoint = point;

      for (Offset pricePoint in pricePoints) {
        double distance = (point - pricePoint).distance;
        if (distance < minDistance) {
          minDistance = distance;
          snapPoint = pricePoint;
        }
      }

      // 只有在合理距离内才吸附（比如50像素内）
      const double snapThreshold = 50.0;
      if (minDistance <= snapThreshold) {
        debugPrint(
            '磁铁吸附: 从 $point 吸附到 $snapPoint (距离: ${minDistance.toStringAsFixed(1)})');
        return snapPoint;
      }
    } catch (e) {
      debugPrint('磁铁吸附计算错误: $e');
    }

    return point;
  }

  /// 检查是否应该在完成绘图后继续绘图模式
  bool shouldContinueAfterDrawing() {
    return _isDrawingModeEnabled && _isContinuousMode;
  }

  /// 重置所有模式状态
  void resetAllModes() {
    _isDrawingModeEnabled = false;
    _isContinuousMode = false;
    _isMagnetMode = false;
    debugPrint('所有绘图模式已重置');
    _notifyModeChanged();
  }

  /// 获取当前模式状态描述
  String getModeDescription() {
    List<String> modes = [];
    if (_isDrawingModeEnabled) modes.add('绘图模式');
    if (_isContinuousMode) modes.add('持续绘图');
    if (_isMagnetMode) modes.add('磁铁吸附');

    return modes.isEmpty ? '正常模式' : modes.join(' + ');
  }

  /// 通知模式状态变化
  void _notifyModeChanged() {
    onModeChanged?.call();
  }
}
