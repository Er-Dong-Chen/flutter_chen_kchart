import 'dart:async';

import 'package:flutter/foundation.dart'; // 添加：用于平台检测
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 添加：用于震动反馈
import 'package:flutter_chen_kchart/k_chart.dart';

enum MainState { MA, EMA, BOLL, NONE }

enum SecondaryState { MACD, KDJ, RSI, WR, CCI, NONE }

class TimeFormat {
  static const List<String> YEAR_MONTH_DAY = [yyyy, '-', mm, '-', dd];
  static const List<String> YEAR_MONTH_DAY_WITH_HOUR = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    HH,
    ':',
    nn
  ];
}

// K线图表控制器，提供程序化控制接口
class KChartController {
  _KChartWidgetState? _state;

  // 缩放状态保存
  double? _savedScale;
  double? _savedScrollX;

  void _attach(_KChartWidgetState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  // 缩放到指定比例
  Future<void> scaleTo(double targetScale,
      {Duration? duration, Offset? center}) async {
    await _state?.scaleTo(targetScale, duration: duration, center: center);
  }

  // 放大
  Future<void> zoomIn({double factor = 1.2}) async {
    await _state?.zoomIn(factor: factor);
  }

  // 缩小
  Future<void> zoomOut({double factor = 1.2}) async {
    await _state?.zoomOut(factor: factor);
  }

  // 重置缩放
  Future<void> resetScale() async {
    await _state?.resetScale();
  }

  // 保存当前缩放状态
  void saveScaleState() {
    if (_state != null) {
      _savedScale = _state!.currentScale;
      _savedScrollX = _state!.mScrollX;
    }
  }

  // 恢复保存的缩放状态
  Future<void> restoreScaleState() async {
    if (_savedScale != null && _state != null) {
      await _state!.scaleTo(_savedScale!);
      if (_savedScrollX != null) {
        _state!.mScrollX = _savedScrollX!;
        _state!.notifyChanged();
      }
    }
  }

  // 检查是否有保存的状态
  bool get hasSavedState => _savedScale != null;

  // 清除保存的状态
  void clearSavedState() {
    _savedScale = null;
    _savedScrollX = null;
  }

  // 获取当前缩放比例
  double get currentScale => _state?.currentScale ?? 1.0;

  // 是否达到最小缩放
  bool get isAtMinScale => _state?._isAtMinScale ?? false;

  // 是否达到最大缩放
  bool get isAtMaxScale => _state?._isAtMaxScale ?? false;

  // 新增：触发震动反馈
  void triggerHaptic({String type = 'light'}) {
    _state?.triggerHaptic(type: type);
  }
}

class KChartWidget extends StatefulWidget {
  final List<KLineEntity>? datas;
  final MainState mainState;
  final bool volHidden;
  final SecondaryState secondaryState;
  final Function()? onSecondaryTap;
  final bool isLine;
  final bool isTapShowInfoDialog; //是否开启单击显示详情数据
  final bool hideGrid;
  final bool isChinese;
  final bool showNowPrice;
  final bool showInfoDialog;
  final bool materialInfoDialog; // Material风格的信息弹窗
  final Map<String, ChartTranslations> translations;
  final List<String>? timeFormat;

  //当屏幕滚动到尽头会调用，真为拉到屏幕右侧尽头，假为拉到屏幕左侧尽头
  final Function(bool)? onLoadMore;

  final int fixedLength;
  final List<int> maDayList;
  final int flingTime;
  final double flingRatio;
  final Curve flingCurve;
  final Function(bool)? isOnDrag;
  final ChartColors? chartColors; // 改为可选参数
  final ChartStyle? chartStyle; // 改为可选参数
  final VerticalTextAlignment verticalTextAlignment;
  final bool isTrendLine;
  final double xFrontPadding;
  final bool enableTheme; // 新增：是否启用主题系统

  // 绘图工具相关
  final bool enableDrawingTools; // 是否启用绘图工具
  final DrawingToolManager? drawingToolManager; // 绘图工具管理器

  // 缩放相关配置参数
  final double minScale; // 最小缩放比例
  final double maxScale; // 最大缩放比例
  final double scaleAnimationDuration; // 缩放动画时长（毫秒）
  final Curve scaleAnimationCurve; // 缩放动画曲线
  final bool enableScaleAnimation; // 是否启用缩放动画
  final Function(double)? onScaleChanged; // 缩放变化回调
  final bool enableBoundaryFeedback; // 是否启用边界反馈
  final double scaleSensitivity; // 缩放灵敏度
  final bool enableScaleCenterPoint; // 是否启用缩放中心点控制
  final KChartController? controller; // K线图表控制器
  final bool enablePerformanceMode; // 新增：性能优化模式

  // 双指缩放和滚轮缩放配置
  final bool enablePinchZoom; // 是否启用双指缩放
  final bool enableScrollZoom; // 是否启用滚轮缩放（桌面端）
  final double scrollZoomFactor; // 滚轮缩放倍数
  final bool enableScaleHapticFeedback; // 是否启用缩放触觉反馈

  // 新增：十字线点击回调
  final Function(double price)? onCrossLineTap; // 点击十字线标签的回调

  // 新增：震动效果配置
  final bool enableHapticFeedback; // 是否启用震动反馈
  final bool longPressHaptic; // 长按是否震动
  final bool crossLineTapHaptic; // 点击十字线标签是否震动
  final bool scaleHaptic; // 缩放操作是否震动
  final bool boundaryHaptic; // 到达边界是否震动

  KChartWidget(
    this.datas, {
    this.chartStyle,
    this.chartColors,
    this.enableTheme = true, // 默认启用主题系统
    required this.isTrendLine,
    this.xFrontPadding = 100,
    this.mainState = MainState.MA,
    this.secondaryState = SecondaryState.MACD,
    this.onSecondaryTap,
    this.volHidden = false,
    this.isLine = false,
    this.isTapShowInfoDialog = false,
    this.hideGrid = false,
    this.isChinese = false,
    this.showNowPrice = true,
    this.showInfoDialog = true,
    this.materialInfoDialog = true,
    this.translations = kChartTranslations,
    this.timeFormat,
    this.onLoadMore,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
    this.flingTime = 350, // 更短惯性动画
    this.flingRatio = 0.9, // 更自然的惯性距离
    this.flingCurve = Curves.easeOutCubic, // 丝滑曲线
    this.isOnDrag,
    this.verticalTextAlignment = VerticalTextAlignment.right,
    // 绘图工具配置
    this.enableDrawingTools = false, // 默认关闭绘图工具
    this.drawingToolManager,
    // 缩放配置参数
    this.minScale = 0.1,
    this.maxScale = 5.0,
    this.scaleAnimationDuration = 300.0,
    this.scaleAnimationCurve = Curves.easeOutCubic,
    this.enableScaleAnimation = true,
    this.onScaleChanged,
    this.enableBoundaryFeedback = true,
    this.scaleSensitivity = 2.5, // 默认提升灵敏度
    this.enableScaleCenterPoint = true,
    this.controller,
    this.enablePerformanceMode = false, // 默认关闭性能模式
    // 双指缩放和滚轮缩放配置
    this.enablePinchZoom = true, // 默认启用双指缩放
    this.enableScrollZoom = true, // 默认启用滚轮缩放
    this.scrollZoomFactor = 1.1, // 滚轮缩放倍数
    this.enableScaleHapticFeedback = true, // 默认启用触觉反馈
    this.onCrossLineTap, // 新增：十字线点击回调
    // 新增：震动效果配置
    this.enableHapticFeedback = true, // 默认启用震动反馈
    this.longPressHaptic = true, // 默认长按震动
    this.crossLineTapHaptic = true, // 默认点击十字线标签震动
    this.scaleHaptic = false, // 默认缩放不震动（避免过于频繁）
    this.boundaryHaptic = true, // 默认边界震动
  });

  @override
  _KChartWidgetState createState() => _KChartWidgetState();
}

class _KChartWidgetState extends State<KChartWidget>
    with TickerProviderStateMixin {
  // 优化：将全局变量移到顶部避免重复初始化
  double mScaleX = 1.0, mScrollX = 0.0, mSelectX = 0.0;
  StreamController<InfoWindowEntity?>? mInfoWindowStream;
  double mHeight = 0, mWidth = 0;
  AnimationController? _controller;
  Animation<double>? aniX;

  //For TrendLine
  List<TrendLine> lines = [];
  double? changeinXposition;
  double? changeinYposition;
  double mSelectY = 0.0;
  bool waitingForOtherPairofCords = false;
  bool enableCordRecord = false;
  // 绘图工具相关
  late DrawingToolManager _drawingToolManager;

  // 优化的缩放功能变量
  double _pinchStartScale = 1.0;
  bool isScale = false, isDrag = false, isLongPress = false, isOnTap = false;
  AnimationController? _scaleAnimationController;
  late double _currentScale;

  // 边界反馈相关
  bool _isAtMinScale = false;
  bool _isAtMaxScale = false;
  Timer? _boundaryFeedbackTimer;

  // 性能优化：节流更新
  Timer? _updateThrottleTimer;
  bool _needsUpdate = false;
  static const int _throttleDelay = 16; // 约60fps

  // 新增：十字线延迟消失
  Timer? _crossLineHideTimer;
  static const int _crossLineHideDelay = 5000; // 5秒延迟消失
  bool _shouldShowCrossLine = false; // 是否显示十字线

  // 新增：跟踪当前选中的K线索引
  int _currentSelectedIndex = -1; // 当前选中的K线索引

  // 新增：图表绘制器实例
  ChartPainter? _painter;

  // 新增：绘图工具移动跟踪
  Offset? _drawingStartPosition; // 绘图开始位置
  bool _isDrawingToolMoving = false; // 是否正在移动绘图工具
  static const double _movementThreshold = 5.0; // 移动阈值
  Timer? _movementResetTimer; // 移动状态重置定时器

  // 新增：绘图工具十字线选择模式
  bool _isDrawingCrosshairMode = false; // 是否处于绘图十字线选择模式
  bool _isSelectingStartPoint = false; // 是否正在选择起点
  bool _isSelectingEndPoint = false; // 是否正在选择终点
  Offset? _drawingCrosshairPosition; // 绘图十字线位置

  // 获取当前主题的颜色和样式
  ChartColors get currentChartColors {
    if (widget.enableTheme) {
      return ChartThemeManager.getColors();
    }
    return widget.chartColors ?? ChartThemeManager.getColors();
  }

  ChartStyle get currentChartStyle {
    return widget.chartStyle ?? ChartStyle();
  }

  double getMinScrollX() {
    return mScaleX;
  }

  double _maxScrollXForScale(double scaleX) {
    if (scaleX <= 0 || mWidth <= 0) return 0.0;
    final dataLen = (widget.datas?.length ?? 0) * currentChartStyle.pointWidth;
    final minTranslateX = -dataLen +
        mWidth / scaleX -
        currentChartStyle.pointWidth / 2 -
        widget.xFrontPadding;
    return minTranslateX >= 0 ? 0.0 : minTranslateX.abs();
  }

  // 获取当前绘图模式状态
  bool get _isDrawingMode {
    if (!widget.enableDrawingTools) return false;
    return _drawingToolManager.modeManager.isDrawingModeEnabled &&
        _drawingToolManager.currentToolType != null;
  }

  @override
  void initState() {
    super.initState();
    mInfoWindowStream = StreamController<InfoWindowEntity?>();
    _currentScale = mScaleX;

    // 初始化绘图工具管理器
    if (widget.enableDrawingTools) {
      if (widget.drawingToolManager != null) {
        _drawingToolManager = widget.drawingToolManager!;
      } else {
        _drawingToolManager = DrawingToolManager();
      }

      _drawingToolManager.onToolsChanged = () {
        if (mounted) setState(() {});
      };
    }

    // 连接控制器
    widget.controller?._attach(this);

    // 初始化缩放动画控制器
    if (widget.enableScaleAnimation) {
      _scaleAnimationController = AnimationController(
        duration: Duration(milliseconds: widget.scaleAnimationDuration.toInt()),
        vsync: this,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // 断开控制器连接
    widget.controller?._detach();

    mInfoWindowStream?.close();
    _controller?.dispose();
    _scaleAnimationController?.dispose();
    _boundaryFeedbackTimer?.cancel();
    _updateThrottleTimer?.cancel(); // 清理节流定时器
    _crossLineHideTimer?.cancel(); // 清理十字线隐藏定时器
    _movementResetTimer?.cancel(); // 清理移动状态重置定时器

    super.dispose();
  }

  // 新增：重置绘图移动状态
  void _resetDrawingMovementState() {
    _movementResetTimer?.cancel();
    _movementResetTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted) {
        _isDrawingToolMoving = false;
        debugPrint('自动重置绘图移动状态');
      }
    });
  }

  // 程序化缩放方法
  Future<void> scaleTo(double targetScale,
      {Duration? duration, Offset? center}) async {
    if (!mounted) return;

    // 输入验证
    if (targetScale.isNaN || targetScale.isInfinite) {
      return;
    }

    targetScale = targetScale.clamp(widget.minScale, widget.maxScale);

    // 如果缩放值没有变化，直接返回
    if ((targetScale - _currentScale).abs() < 0.001) {
      return;
    }

    try {
      if (widget.enableScaleAnimation && duration != null) {
        final animationController = AnimationController(
          duration: duration,
          vsync: this,
        );

        final animation = Tween<double>(
          begin: _currentScale,
          end: targetScale,
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: widget.scaleAnimationCurve,
        ));

        animation.addListener(() {
          _updateScale(animation.value, center);
        });

        await animationController.forward();
        animationController.dispose();
      } else {
        _updateScale(targetScale, center);
      }
    } catch (e) {
      debugPrint('KChart: Error during scale animation: $e');
      // 发生错误时直接设置目标缩放值
      _updateScale(targetScale, center);
    }
  }

  // 放大方法
  Future<void> zoomIn({double factor = 1.2}) async {
    if (factor <= 0 || factor.isNaN || factor.isInfinite) {
      debugPrint('KChart: Invalid zoom factor: $factor');
      return;
    }
    await scaleTo(_currentScale * factor);
  }

  // 缩小方法
  Future<void> zoomOut({double factor = 1.2}) async {
    if (factor <= 0 || factor.isNaN || factor.isInfinite) {
      debugPrint('KChart: Invalid zoom factor: $factor');
      return;
    }
    await scaleTo(_currentScale / factor);
  }

  // 重置缩放
  Future<void> resetScale() async {
    await scaleTo(1.0,
        duration:
            Duration(milliseconds: widget.scaleAnimationDuration.toInt()));
  }

  // 更新缩放 - 添加性能优化
  void _updateScale(double newScale, Offset? center) {
    // 输入验证
    if (newScale.isNaN || newScale.isInfinite) {
      debugPrint('KChart: Invalid scale value in _updateScale: $newScale');
      return;
    }

    final oldScale = mScaleX;
    mScaleX = newScale.clamp(widget.minScale, widget.maxScale);
    _currentScale = mScaleX;

    // 检查边界状态
    _isAtMinScale = mScaleX <= widget.minScale;
    _isAtMaxScale = mScaleX >= widget.maxScale;

    // 如果启用了缩放中心点控制
    if (widget.enableScaleCenterPoint &&
        center != null &&
        oldScale > 0 &&
        mWidth > 0 &&
        oldScale != mScaleX) {
      // 计算内容坐标下的焦点
      final contentX = mScrollX + center.dx / oldScale;
      final currentMaxScrollX = _maxScrollXForScale(mScaleX);
      // 缩放后，调整mScrollX让焦点保持在原地
      mScrollX = (contentX - center.dx / mScaleX)
          .clamp(0.0, currentMaxScrollX)
          .toDouble();
    }

    // 触发缩放变化回调
    try {
      widget.onScaleChanged?.call(mScaleX);
    } catch (e) {
      debugPrint('KChart: Error in onScaleChanged callback: $e');
    }

    // 边界反馈
    if (widget.enableBoundaryFeedback) {
      _triggerBoundaryFeedback();
    }

    // 性能优化：根据性能模式选择更新策略
    if (widget.enablePerformanceMode) {
      _throttledNotifyChanged();
    } else {
      notifyChanged();
    }
  }

  // 性能优化：节流更新
  void _throttledNotifyChanged() {
    _needsUpdate = true;
    _updateThrottleTimer?.cancel();
    _updateThrottleTimer = Timer(Duration(milliseconds: _throttleDelay), () {
      if (_needsUpdate && mounted) {
        _needsUpdate = false;
        notifyChanged();
      }
    });
  }

  // 边界反馈
  void _triggerBoundaryFeedback() {
    if (_isAtMinScale || _isAtMaxScale) {
      _boundaryFeedbackTimer?.cancel();
      _boundaryFeedbackTimer = Timer(Duration(milliseconds: 100), () {
        if (mounted) {
          // 触发边界震动反馈
          _triggerBoundaryHaptic();
        }
      });
    }
  }

  // 获取当前缩放比例
  double get currentScale => _currentScale;

  // 新增：公开的震动API
  void triggerHaptic({String type = 'light'}) {
    _triggerHapticFeedback(type);
  }

  // 新增：启动十字线延迟隐藏
  void _startCrossLineHideTimer() {
    _crossLineHideTimer?.cancel();
    _crossLineHideTimer =
        Timer(Duration(milliseconds: _crossLineHideDelay), () {
      if (mounted) {
        setState(() {
          _hideCrossLine();
        });
      }
    });
  }

  // 新增：取消十字线延迟隐藏
  void _cancelCrossLineHideTimer() {
    _crossLineHideTimer?.cancel();
  }

  // 新增：显示十字线
  void _showCrossLine() {
    _shouldShowCrossLine = true;
    _cancelCrossLineHideTimer();
  }

  // 新增：立即隐藏十字线（仅在必要时使用）
  void _hideCrossLine() {
    _shouldShowCrossLine = false;
    _cancelCrossLineHideTimer();
    isLongPress = false;
    isOnTap = false;
    mInfoWindowStream?.sink.add(null);
    _currentSelectedIndex = -1;
  }

  double _snapCrosshairToCandleCenterX(double rawScreenX) {
    if (_painter == null) return rawScreenX;
    final index = _painter!.calculateSelectedX(rawScreenX);
    final centerTranslateX = _painter!.getX(index);
    return _painter!.translateXtoX(centerTranslateX);
  }

  // 新增：震动反馈辅助方法
  void _triggerHapticFeedback(String feedbackType) {
    if (!widget.enableHapticFeedback) return;

    try {
      switch (feedbackType) {
        case 'light':
          HapticFeedback.lightImpact();
          break;
        case 'medium':
          HapticFeedback.mediumImpact();
          break;
        case 'heavy':
          HapticFeedback.heavyImpact();
          break;
        case 'selection':
          HapticFeedback.selectionClick();
          break;
        case 'vibrate':
          HapticFeedback.vibrate();
          break;
      }
    } catch (e) {
      // 静默处理震动失败的情况
      debugPrint('Haptic feedback failed: $e');
    }
  }

  // 新增：长按震动
  void _triggerLongPressHaptic() {
    if (widget.longPressHaptic) {
      _triggerHapticFeedback('medium');
    }
  }

  // 新增：十字线标签点击震动
  void _triggerCrossLineTapHaptic() {
    if (widget.crossLineTapHaptic) {
      _triggerHapticFeedback('light');
    }
  }

  // 新增：缩放震动
  void _triggerScaleHaptic() {
    if (widget.scaleHaptic) {
      _triggerHapticFeedback('selection');
    }
  }

  // 新增：边界震动
  void _triggerBoundaryHaptic() {
    if (widget.boundaryHaptic) {
      _triggerHapticFeedback('heavy');
    }
  }

  // 新增：绘图工具震动
  void _triggerDrawingToolHaptic() {
    if (widget.enableHapticFeedback) {
      _triggerHapticFeedback('selection');
    }
  }

  // 新增：K线选择变化震动
  void _triggerKLineSelectionHaptic() {
    if (!widget.enableHapticFeedback || !widget.longPressHaptic) return;

    // 直接触发震动，无节流控制
    _triggerHapticFeedback('light'); // 使用轻微震动，提供即时反馈
  }

  // 新增：绘图工具点击事件处理
  void _handleDrawingToolTap(Offset localPosition) {
    debugPrint(
        '_handleDrawingToolTap: position=$localPosition, currentToolType=${_drawingToolManager.currentToolType}, drawingModeEnabled=${_drawingToolManager.modeManager.isDrawingModeEnabled}');

    if (_drawingToolManager.currentToolType == null) {
      // 如果没有选择工具，则选择已有的绘图工具
      _drawingToolManager.selectTool(localPosition);
      return;
    }

    final toolType = _drawingToolManager.currentToolType!;

    // 检查是否处于十字线选择模式
    if (_isDrawingCrosshairMode) {
      if (_isSelectingStartPoint) {
        // 确认起点位置
        _confirmStartPoint(localPosition, toolType);
      } else if (_isSelectingEndPoint) {
        // 确认终点位置
        _confirmEndPoint(localPosition, toolType);
      } else {
        // 单点工具确认位置
        _confirmSinglePoint(localPosition, toolType);
      }
      return;
    }

    // 修复：强制设置十字线位置为点击位置，覆盖可能的错误跟踪
    debugPrint('强制设置十字线位置为点击位置: $localPosition');

    // 使用统一的位置更新方法，会自动处理边界限制
    _updateDrawingCrosshairPosition(localPosition, '_handleDrawingToolTap');

    _startDrawingToolSelection(toolType);
  }

  // 开始绘图工具选择流程
  void _startDrawingToolSelection(DrawingToolType toolType) {
    debugPrint('开始绘图工具选择流程: $toolType');

    _isDrawingCrosshairMode = true;

    // 修复：确保十字线位置已正确设置
    if (_drawingCrosshairPosition == null) {
      debugPrint('警告：十字线位置为null，使用屏幕中心作为后备');
      _drawingCrosshairPosition = Offset(mWidth / 2, mHeight / 2);
    } else {
      debugPrint('十字线初始位置: $_drawingCrosshairPosition');
    }

    if (_isSinglePointTool(toolType)) {
      // 单点工具：直接进入位置选择
      _isSelectingStartPoint = false;
      _isSelectingEndPoint = false;
      debugPrint('单点工具：进入位置选择模式');
    } else {
      // 双点工具：先选择起点
      _isSelectingStartPoint = true;
      _isSelectingEndPoint = false;
      debugPrint('双点工具：进入起点选择模式');
    }

    _triggerDrawingToolHaptic();
    notifyChanged();
  }

  // 确认起点位置
  void _confirmStartPoint(Offset localPosition, DrawingToolType toolType) {
    // 修复：使用十字线位置而不是点击位置
    final confirmPosition = _drawingCrosshairPosition ?? localPosition;
    debugPrint('确认起点位置: $confirmPosition (点击位置: $localPosition)');

    // 记录绘图开始位置
    _drawingStartPosition = confirmPosition;
    _isDrawingToolMoving = false;

    // 创建绘图工具并设置起点
    _drawingToolManager.startDrawing(
      confirmPosition,
      kLineData: widget.datas,
      scaleX: mScaleX,
      scrollX: mScrollX,
      getX: (index) => _painter?.getX(index.toInt()) ?? 0,
      getY: (price) => _painter?.mMainRenderer.getY(price) ?? 0,
      getPriceFromY: (screenY) =>
          _painter?.mMainRenderer.getYFromPrice(screenY) ?? screenY,
      calculateSelectedX: (screenX) => _painter?.calculateSelectedXExtended(screenX) ?? 0,
      chartRect: _painter?.mMainRect ?? Rect.zero,
    );

    // 进入终点选择模式
    _isSelectingStartPoint = false;
    _isSelectingEndPoint = true;
    debugPrint('进入终点选择模式');

    _triggerDrawingToolHaptic();
    notifyChanged();
  }

  // 确认终点位置
  void _confirmEndPoint(Offset localPosition, DrawingToolType toolType) {
    // 修复：使用十字线位置而不是点击位置
    final confirmPosition = _drawingCrosshairPosition ?? localPosition;
    debugPrint('确认终点位置: $confirmPosition (点击位置: $localPosition)');

    // 更新终点并完成绘图
    _drawingToolManager.updateDrawing(
      confirmPosition,
      kLineData: widget.datas,
      scaleX: mScaleX,
      scrollX: mScrollX,
      getX: (index) => _painter?.getX(index.toInt()) ?? 0,
      getY: (price) => _painter?.mMainRenderer.getY(price) ?? 0,
      getPriceFromY: (screenY) =>
          _painter?.mMainRenderer.getYFromPrice(screenY) ?? screenY,
      calculateSelectedX: (screenX) => _painter?.calculateSelectedXExtended(screenX) ?? 0,
      chartRect: _painter?.mMainRect ?? Rect.zero,
    );

    _drawingToolManager.finishDrawing();

    // 退出十字线选择模式
    _exitDrawingCrosshairMode();

    debugPrint('双点工具绘制完成');
    _triggerDrawingToolHaptic();
    notifyChanged();
  }

  // 确认单点位置
  void _confirmSinglePoint(Offset localPosition, DrawingToolType toolType) {
    // 修复：使用十字线位置而不是点击位置
    final confirmPosition = _drawingCrosshairPosition ?? localPosition;
    debugPrint('确认单点位置: $confirmPosition (点击位置: $localPosition)');

    // 记录绘图开始位置
    _drawingStartPosition = confirmPosition;
    _isDrawingToolMoving = false;

    // 创建并完成单点工具
    _drawingToolManager.startDrawing(
      confirmPosition,
      kLineData: widget.datas,
      scaleX: mScaleX,
      scrollX: mScrollX,
      getX: (index) => _painter?.getX(index.toInt()) ?? 0,
      getY: (price) => _painter?.mMainRenderer.getY(price) ?? 0,
      getPriceFromY: (screenY) =>
          _painter?.mMainRenderer.getYFromPrice(screenY) ?? screenY,
      calculateSelectedX: (screenX) => _painter?.calculateSelectedXExtended(screenX) ?? 0,
      chartRect: _painter?.mMainRect ?? Rect.zero,
    );

    _drawingToolManager.finishDrawing();

    // 退出十字线选择模式
    _exitDrawingCrosshairMode();

    debugPrint('单点工具绘制完成');
    _triggerDrawingToolHaptic();
    notifyChanged();
  }

  // 退出绘图十字线选择模式
  void _exitDrawingCrosshairMode() {
    _isDrawingCrosshairMode = false;
    _isSelectingStartPoint = false;
    _isSelectingEndPoint = false;
    _drawingCrosshairPosition = null;
    _drawingStartPosition = null;
    _isDrawingToolMoving = false;
    debugPrint('退出绘图十字线选择模式');
  }

  // 新增：判断是否为单点工具
  bool _isSinglePointTool(DrawingToolType toolType) {
    return toolType == DrawingToolType.verticalLine ||
        toolType == DrawingToolType.horizontalLine ||
        toolType == DrawingToolType.crossLine ||
        toolType == DrawingToolType.horizontalRay; // 水平射线也是单点工具
  }

  // 新增：判断是否为需要确定方向的工具（射线类工具）
  bool _isDirectionTool(DrawingToolType toolType) {
    return toolType == DrawingToolType.horizontalRay ||
        toolType == DrawingToolType.ray;
  }

  // 新增：绘图工具开始拖拽事件
  void _handleDrawingPanStart(Offset localPosition) {
    debugPrint(
        '_handleDrawingPanStart: position=$localPosition, currentToolType=${_drawingToolManager.currentToolType}');
    if (_drawingToolManager.currentToolType == null) return;

    // 修复：只有在十字线选择模式下才允许拖拽操作
    if (!_isDrawingCrosshairMode) {
      debugPrint('不在十字线选择模式，忽略拖拽开始');
      return;
    }

    // 在选择终点模式下，拖拽可以更新终点位置
    if (_isSelectingEndPoint &&
        _drawingToolManager.currentDrawingTool != null) {
      _handleDrawingPanUpdate(localPosition);
    }
  }

  // 新增：绘图工具移动事件
  void _handleDrawingPanUpdate(Offset localPosition) {
    debugPrint(
        '_handleDrawingPanUpdate: position=$localPosition, isDrawingCrosshairMode=$_isDrawingCrosshairMode');

    // 修复：只有在十字线选择模式下才处理拖拽更新
    if (!_isDrawingCrosshairMode) {
      debugPrint('不在十字线选择模式，忽略拖拽更新');
      return;
    }

    // 更新十字线位置（会自动处理边界限制）
    _updateDrawingCrosshairPosition(localPosition, '_handleDrawingPanUpdate');

    // 如果在选择终点模式下，实时更新绘图工具的终点
    if (_isSelectingEndPoint &&
        _drawingToolManager.currentDrawingTool != null) {
      // 使用限制后的位置来更新绘图工具
      final actualPosition = _drawingCrosshairPosition ?? localPosition;
      _drawingToolManager.updateDrawing(
        actualPosition,
        kLineData: widget.datas,
        scaleX: mScaleX,
        scrollX: mScrollX,
        getX: (index) => _painter?.getX(index.toInt()) ?? 0,
        getY: (price) => _painter?.mMainRenderer.getY(price) ?? 0,
        getPriceFromY: (screenY) =>
            _painter?.mMainRenderer.getYFromPrice(screenY) ?? screenY,
        calculateSelectedX: (screenX) => _painter?.calculateSelectedXExtended(screenX) ?? 0,
        chartRect: _painter?.mMainRect ?? Rect.zero,
      );
      debugPrint('实时更新终点位置到: $actualPosition');
    }

    notifyChanged(); // 触发重绘以显示十字线移动和实时预览
  }

  // 新增：绘图工具结束拖拽事件
  void _handleDrawingPanEnd() {
    debugPrint(
        '_handleDrawingPanEnd: isDrawingCrosshairMode=$_isDrawingCrosshairMode');

    // 修复：拖拽结束不应该直接完成绘图，应该等待点击确认
    // 这里只需要更新十字线位置，实际的确认需要点击操作
    if (_isDrawingCrosshairMode) {
      debugPrint('拖拽结束，等待点击确认位置');
      // 不做任何操作，等待用户点击确认
    }
  }

  // 新增：统一的十字线位置更新方法
  void _updateDrawingCrosshairPosition(Offset newPosition, String source) {
    final oldPosition = _drawingCrosshairPosition;

    // 检查位置是否有效
    if (newPosition.dx.isNaN ||
        newPosition.dy.isNaN ||
        newPosition.dx.isInfinite ||
        newPosition.dy.isInfinite) {
      debugPrint('警告：无效的十字线位置 $newPosition，来源: $source');
      return;
    }

    // 获取正确的边界限制（使用K线图主区域）
    Rect boundary;
    if (_painter?.mMainRect != null) {
      // 使用K线图主区域作为边界
      boundary = _painter!.mMainRect;
      debugPrint('使用K线图主区域边界: $boundary');
    } else {
      // 后备方案：使用整个组件区域
      boundary = Rect.fromLTWH(0, 0, mWidth, mHeight);
      debugPrint('使用组件边界: $boundary');
    }

    // 应用边界限制，确保十字线在有效区域内
    final clampedPosition = Offset(
      newPosition.dx.clamp(boundary.left, boundary.right),
      newPosition.dy.clamp(boundary.top, boundary.bottom),
    );

    // 计算位置变化距离
    double distance = 0.0;
    if (oldPosition != null) {
      distance = (clampedPosition - oldPosition).distance;
    }

    // 调试信息
    if (newPosition != clampedPosition) {
      debugPrint(
          '十字线位置已限制在边界内 [来源: $source]: $newPosition -> $clampedPosition');
    } else {
      debugPrint(
          '十字线位置更新 [来源: $source]: $oldPosition -> $clampedPosition (距离: ${distance.toStringAsFixed(2)})');
    }

    // 如果位置变化过大，可能是坐标系统问题
    if (oldPosition != null && distance > 100) {
      debugPrint('警告：十字线位置变化过大 (${distance.toStringAsFixed(2)}px)，可能存在坐标系统问题');
    }

    _drawingCrosshairPosition = clampedPosition;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.datas != null && widget.datas!.isEmpty) {
      mScrollX = mSelectX = 0.0;
      mScaleX = 1.0;
    }
    _painter = ChartPainter(
      currentChartStyle,
      currentChartColors,
      lines: lines, //For TrendLine
      xFrontPadding: widget.xFrontPadding,
      isTrendLine: widget.isTrendLine, //For TrendLine
      selectY: mSelectY, //For TrendLine
      drawingToolManager:
          widget.enableDrawingTools ? _drawingToolManager : null, // 新增绘图工具管理器
      datas: widget.datas,
      scaleX: mScaleX,
      scrollX: mScrollX,
      selectX: mSelectX,
      isLongPass: isLongPress,
      isOnTap: isOnTap,
      isTapShowInfoDialog: widget.isTapShowInfoDialog,
      mainState: widget.mainState,
      volHidden: widget.volHidden,
      secondaryState: widget.secondaryState,
      isLine: widget.isLine,
      hideGrid: widget.hideGrid,
      showNowPrice: widget.showNowPrice,
      sink: mInfoWindowStream?.sink,
      fixedLength: widget.fixedLength,
      maDayList: widget.maDayList,
      verticalTextAlignment: widget.verticalTextAlignment,
      shouldShowCrossLine: _shouldShowCrossLine, // 新增：传递十字线显示状态
      onCrossLineTap: widget.onCrossLineTap, // 新增：传递十字线点击回调
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        mHeight = constraints.maxHeight;
        mWidth = constraints.maxWidth;

        return Listener(
          onPointerSignal: widget.enableScrollZoom
              ? (details) {
                  if (details is PointerScrollEvent) {
                    final delta = details.scrollDelta.dy;
                    final zoomFactor = delta > 0
                        ? widget.scrollZoomFactor
                        : 1.0 / widget.scrollZoomFactor;
                    final newScale = _currentScale * zoomFactor;

                    if (_shouldShowCrossLine) {
                      _hideCrossLine();
                    }
                    _updateScale(newScale, details.position);
                  }
                }
              : null,
          onPointerMove: (details) {
            // 优先处理绘图工具的十字线选择模式
            if (widget.enableDrawingTools &&
                _isDrawingMode &&
                _isDrawingCrosshairMode) {
              // 更新十字线位置（会自动处理边界限制）
              _updateDrawingCrosshairPosition(
                  details.localPosition, 'onPointerMove');

              // 如果正在选择终点，实时预览
              if (_isSelectingEndPoint &&
                  _drawingToolManager.currentDrawingTool != null) {
                // 使用限制后的位置来更新绘图工具
                final actualPosition =
                    _drawingCrosshairPosition ?? details.localPosition;
                _drawingToolManager.updateDrawing(
                  actualPosition,
                  kLineData: widget.datas,
                  scaleX: mScaleX,
                  scrollX: mScrollX,
                  getX: (index) => _painter?.getX(index.toInt()) ?? 0,
                  getY: (price) => _painter?.mMainRenderer.getY(price) ?? 0,
                  getPriceFromY: (screenY) =>
                      _painter?.mMainRenderer.getYFromPrice(screenY) ?? screenY,
                  calculateSelectedX: (screenX) => _painter?.calculateSelectedXExtended(screenX) ?? 0,
                  chartRect: _painter?.mMainRect ?? Rect.zero,
                );
              }

              debugPrint('绘图十字线移动: ${_drawingCrosshairPosition}');
              notifyChanged();
              return;
            }

            // 修复：如果处于绘图模式但还没启动十字线选择，也要跟踪位置
            if (widget.enableDrawingTools &&
                _isDrawingMode &&
                !_isDrawingCrosshairMode &&
                _drawingToolManager.currentToolType != null) {
              // 轻量级跟踪鼠标位置，为后续十字线显示做准备
              // 注意：这里不触发重绘，避免干扰
              debugPrint('预跟踪十字线位置: ${details.localPosition}');

              // 获取边界
              Rect boundary;
              if (_painter?.mMainRect != null) {
                boundary = _painter!.mMainRect;
              } else {
                boundary = Rect.fromLTWH(0, 0, mWidth, mHeight);
              }

              // 预设十字线位置（但不立即生效）
              _drawingCrosshairPosition = Offset(
                details.localPosition.dx.clamp(boundary.left, boundary.right),
                details.localPosition.dy.clamp(boundary.top, boundary.bottom),
              );

              return;
            }

            // 处理绘图工具的指针移动（适用于桌面和移动端）
            if (widget.enableDrawingTools &&
                _isDrawingMode &&
                _drawingToolManager.currentDrawingTool != null &&
                _drawingToolManager.currentDrawingTool!.state ==
                    DrawingToolState.drawing) {
              // 检查是否已开始移动
              if (_drawingStartPosition != null) {
                double distance =
                    (details.localPosition - _drawingStartPosition!).distance;
                if (distance > _movementThreshold) {
                  _isDrawingToolMoving = true;
                  debugPrint('绘图工具开始移动，距离: $distance');
                  _resetDrawingMovementState(); // 启动重置定时器
                }
              }

              debugPrint('指针移动更新绘图工具位置: ${details.localPosition}');
              _drawingToolManager.updateDrawing(
                details.localPosition,
                kLineData: widget.datas,
                scaleX: mScaleX,
                scrollX: mScrollX,
                getX: (index) => _painter?.getX(index.toInt()) ?? 0,
                getY: (price) => _painter?.mMainRenderer.getY(price) ?? 0,
                getPriceFromY: (screenY) =>
                    _painter?.mMainRenderer.getYFromPrice(screenY) ?? screenY,
                calculateSelectedX: (screenX) => _painter?.calculateSelectedXExtended(screenX) ?? 0,
                chartRect: _painter?.mMainRect ?? Rect.zero,
              );
              notifyChanged();
            }
          },
          child: MouseRegion(
            onHover: (event) {
              // 优先处理绘图工具的十字线选择模式
              if (widget.enableDrawingTools &&
                  _isDrawingMode &&
                  _isDrawingCrosshairMode) {
                // 更新十字线位置
                _updateDrawingCrosshairPosition(
                    event.localPosition, 'onHover(crosshair)');

                // 如果正在选择终点，实时预览
                if (_isSelectingEndPoint &&
                    _drawingToolManager.currentDrawingTool != null) {
                  // 使用限制后的位置来更新绘图工具
                  final actualPosition =
                      _drawingCrosshairPosition ?? event.localPosition;
                  _drawingToolManager.updateDrawing(
                    actualPosition,
                    kLineData: widget.datas,
                    scaleX: mScaleX,
                    scrollX: mScrollX,
                    getX: (index) => _painter?.getX(index.toInt()) ?? 0,
                    getY: (price) => _painter?.mMainRenderer.getY(price) ?? 0,
                    getPriceFromY: (screenY) =>
                        _painter?.mMainRenderer.getYFromPrice(screenY) ??
                        screenY,
                    calculateSelectedX: (screenX) => _painter?.calculateSelectedXExtended(screenX) ?? 0,
                    chartRect: _painter?.mMainRect ?? Rect.zero,
                  );
                }

                debugPrint('绘图十字线鼠标悬停: ${_drawingCrosshairPosition}');
                notifyChanged();
                return;
              }

              // 修复：如果处于绘图模式但还没启动十字线选择，也要跟踪位置
              if (widget.enableDrawingTools &&
                  _isDrawingMode &&
                  !_isDrawingCrosshairMode &&
                  _drawingToolManager.currentToolType != null) {
                // 轻量级跟踪鼠标位置，为后续十字线显示做准备
                debugPrint('预跟踪十字线位置(hover): ${event.localPosition}');

                // 获取边界
                Rect boundary;
                if (_painter?.mMainRect != null) {
                  boundary = _painter!.mMainRect;
                } else {
                  boundary = Rect.fromLTWH(0, 0, mWidth, mHeight);
                }

                // 预设十字线位置（但不立即生效）
                _drawingCrosshairPosition = Offset(
                  event.localPosition.dx.clamp(boundary.left, boundary.right),
                  event.localPosition.dy.clamp(boundary.top, boundary.bottom),
                );

                return;
              }

              // 处理绘图工具的鼠标悬停移动
              if (widget.enableDrawingTools &&
                  _isDrawingMode &&
                  _drawingToolManager.currentDrawingTool != null &&
                  _drawingToolManager.currentDrawingTool!.state ==
                      DrawingToolState.drawing) {
                // 检查是否已开始移动（桌面端鼠标悬停）
                if (_drawingStartPosition != null) {
                  double distance =
                      (event.localPosition - _drawingStartPosition!).distance;
                  if (distance > _movementThreshold) {
                    _isDrawingToolMoving = true;
                    debugPrint('绘图工具开始鼠标移动，距离: $distance');
                  }
                }

                debugPrint('鼠标悬停更新绘图工具位置: ${event.localPosition}');
                _drawingToolManager.updateDrawing(
                  event.localPosition,
                  kLineData: widget.datas,
                  scaleX: mScaleX,
                  scrollX: mScrollX,
                  getX: (index) => _painter?.getX(index.toInt()) ?? 0,
                  getY: (price) => _painter?.mMainRenderer.getY(price) ?? 0,
                  getPriceFromY: (screenY) =>
                      _painter?.mMainRenderer.getYFromPrice(screenY) ?? screenY,
                  calculateSelectedX: (screenX) => _painter?.calculateSelectedXExtended(screenX) ?? 0,
                  chartRect: _painter?.mMainRect ?? Rect.zero,
                );
                notifyChanged();
              }
            },
            child: GestureDetector(
              onTapUp: (details) {
                if (!isLongPress && !isScale) {
                  _stopAnimation();
                }

                // 检测是否点击了十字线标签
                if (_shouldShowCrossLine &&
                    _painter != null &&
                    _painter!.isCrossLineLabelTapped(details.localPosition)) {
                  double price = _painter!.getCurrentCrossLinePrice();
                  widget.onCrossLineTap?.call(price);
                  _triggerCrossLineTapHaptic(); // 添加：点击十字线标签震动
                  return;
                }

                // 如果十字线正在显示且点击了其他区域，则隐藏十字线
                if (_shouldShowCrossLine &&
                    _painter != null &&
                    _painter!.isInMainRect(details.localPosition)) {
                  _hideCrossLine();
                  notifyChanged();
                  return;
                }

                // 处理绘图工具的点击事件
                if (widget.enableDrawingTools && _isDrawingMode) {
                  final localPosition = details.localPosition;

                  // 如果绘图工具正在移动，则不处理点击事件（避免意外确认）
                  if (_isDrawingToolMoving) {
                    debugPrint('绘图工具正在移动，忽略点击事件');
                    _isDrawingToolMoving = false; // 重置移动状态
                    return;
                  }

                  _handleDrawingToolTap(localPosition);
                  return;
                }

                // 如果点击了其他区域且处于绘图十字线选择模式，则退出该模式
                if (widget.enableDrawingTools && _isDrawingCrosshairMode) {
                  _exitDrawingCrosshairMode();
                  debugPrint('点击其他区域，退出绘图十字线选择模式');
                  notifyChanged();
                  return;
                }

                if (!widget.isTrendLine &&
                    _painter != null &&
                    _painter!.isInMainRect(details.localPosition)) {
                  // 只有在开启单点显示信息对话框且不在十字线模式时才设置isOnTap
                  if (!_shouldShowCrossLine) {
                    isOnTap = true;
                    if (widget.isTapShowInfoDialog) {
                      mSelectX =
                          _snapCrosshairToCandleCenterX(details.localPosition.dx);
                    }
                    notifyChanged();
                  }
                }
                if (widget.isTrendLine && !isLongPress && enableCordRecord) {
                  enableCordRecord = false;
                  Offset p1 = Offset(getTrendLineX(), mSelectY);
                  if (!waitingForOtherPairofCords)
                    lines.add(TrendLine(
                        p1, Offset(-1, -1), trendLineMax!, trendLineScale!));

                  if (waitingForOtherPairofCords) {
                    var a = lines.last;
                    lines.removeLast();
                    lines.add(
                        TrendLine(a.p1, p1, trendLineMax!, trendLineScale!));
                    waitingForOtherPairofCords = false;
                  } else {
                    waitingForOtherPairofCords = true;
                  }
                  notifyChanged();
                }
              },
              onScaleStart: (details) {
                // 如果正在长按，则不启动缩放
                if (isLongPress) {
                  return;
                }

                // Web端：禁用单指缩放，只允许滚轮缩放
                if (kIsWeb) {
                  return;
                }

                // 移动端：检查是否为绘图模式
                if (widget.enableDrawingTools && _isDrawingMode) {
                  // 绘图模式下，处理绘图开始事件
                  if (details.pointerCount == 1) {
                    // 修复：使用localFocalPoint确保坐标系统一致
                    final localPoint = details.localFocalPoint;
                    _handleDrawingPanStart(localPoint);
                    return;
                  }
                }

                isOnTap = false;
                if (_shouldShowCrossLine) {
                  _hideCrossLine();
                }

                _stopAnimation();
                if (details.pointerCount >= 2) {
                  if (!widget.enablePinchZoom) return;
                  _onDragChanged(false);
                  isScale = true;
                  _pinchStartScale = mScaleX;
                  _triggerScaleHaptic();
                } else {
                  isScale = false;
                  _onDragChanged(true);
                }
              },
              onScaleUpdate: (details) {
                // 如果正在长按，则不执行缩放
                if (isLongPress) {
                  return;
                }

                // Web端：禁用手势缩放，只允许滚轮缩放
                if (kIsWeb) {
                  return;
                }

                // 绘图模式下的处理
                if (widget.enableDrawingTools && _isDrawingMode) {
                  if (details.pointerCount == 1) {
                    // 单指移动：处理绘图更新
                    // 修复：使用localFocalPoint确保坐标系统一致
                    final localPoint = details.localFocalPoint;
                    _handleDrawingPanUpdate(localPoint);
                    return;
                  }
                }

                if (_shouldShowCrossLine) {
                  _hideCrossLine();
                }

                if (details.pointerCount >= 2) {
                  if (!widget.enablePinchZoom) return;
                  isScale = true;

                  final sensitivity = widget.scaleSensitivity;
                  final scaleDelta = details.scale - 1.0;
                  final accumulatedDelta = scaleDelta * sensitivity;

                  double factor;
                  if (accumulatedDelta >= 0) {
                    factor = 1.0 + (accumulatedDelta * 2.8);
                  } else {
                    factor = 1.0 + (accumulatedDelta * 3.6);
                  }

                  if (factor.isNaN || factor.isInfinite || factor <= 0) return;

                  final targetScale = _pinchStartScale * factor;
                  final currentFocalPoint = details.localFocalPoint;
                  _updateScale(targetScale,
                      widget.enableScaleCenterPoint ? currentFocalPoint : null);
                  return;
                }

                if (isScale) return;
                final maxScrollX = _maxScrollXForScale(mScaleX);
                mScrollX = (mScrollX + details.focalPointDelta.dx / mScaleX)
                    .clamp(0.0, maxScrollX)
                    .toDouble();
                notifyChanged();
              },
              onScaleEnd: (details) {
                // 如果正在长按，则不结束缩放
                if (isLongPress) {
                  return;
                }

                // Web端：直接返回
                if (kIsWeb) {
                  return;
                }

                // 绘图模式下的处理
                if (widget.enableDrawingTools && _isDrawingMode) {
                  _handleDrawingPanEnd();
                  return;
                }

                if (isScale) {
                  isScale = false;
                  _pinchStartScale = mScaleX;
                  return;
                }

                final velocity = details.velocity.pixelsPerSecond.dx;
                _onFling(velocity);
                _onDragChanged(false);
              },
              onLongPressStart: (details) {
                isOnTap = false;
                isLongPress = true;
                _showCrossLine(); // 显示十字线并取消延迟隐藏
                _triggerLongPressHaptic(); // 添加：长按开始震动

                // 初始化当前选中的K线索引
                if (_painter != null) {
                  _currentSelectedIndex =
                      _painter!.calculateSelectedX(details.localPosition.dx);
                }

                if ((mSelectX !=
                            _snapCrosshairToCandleCenterX(
                                details.localPosition.dx) ||
                        mSelectY !=
                            details.localPosition
                                .dy) && // 修改：使用localPosition.dy而不是globalPosition.dy
                    !widget.isTrendLine) {
                  mSelectX =
                      _snapCrosshairToCandleCenterX(details.localPosition.dx);
                  mSelectY = details.localPosition.dy; // 添加：保存本地Y坐标
                  notifyChanged();
                }
                //For TrendLine
                if (widget.isTrendLine && changeinXposition == null) {
                  mSelectX = changeinXposition = details.localPosition.dx;
                  mSelectY = changeinYposition = details.globalPosition.dy;
                  notifyChanged();
                }
                //For TrendLine
                if (widget.isTrendLine && changeinXposition != null) {
                  changeinXposition = details.localPosition.dx;
                  changeinYposition = details.globalPosition.dy;
                  notifyChanged();
                }
              },
              onLongPressMoveUpdate: (details) {
                _showCrossLine(); // 移动时继续显示十字线并取消延迟隐藏
                if ((mSelectX !=
                            _snapCrosshairToCandleCenterX(
                                details.localPosition.dx) ||
                        mSelectY !=
                            details.localPosition
                                .dy) && // 修改：使用localPosition.dy而不是globalPosition.dy
                    !widget.isTrendLine) {
                  // 检测K线选择变化并触发震动
                  if (_painter != null) {
                    int newSelectedIndex =
                        _painter!.calculateSelectedX(details.localPosition.dx);
                    if (newSelectedIndex != _currentSelectedIndex &&
                        _currentSelectedIndex != -1) {
                      _triggerKLineSelectionHaptic(); // 触发K线选择变化震动
                    }
                    _currentSelectedIndex = newSelectedIndex;
                  }

                  mSelectX =
                      _snapCrosshairToCandleCenterX(details.localPosition.dx);
                  mSelectY = details.localPosition.dy; // 修改：使用本地Y坐标
                  notifyChanged();
                }
                if (widget.isTrendLine) {
                  mSelectX = mSelectX +
                      (details.localPosition.dx - changeinXposition!);
                  changeinXposition = details.localPosition.dx;
                  mSelectY = mSelectY +
                      (details.globalPosition.dy - changeinYposition!);
                  changeinYposition = details.globalPosition.dy;
                  notifyChanged();
                }
              },
              onLongPressEnd: (details) {
                isLongPress = false;
                enableCordRecord = true;
                _startCrossLineHideTimer(); // 开始延迟隐藏十字线
                _currentSelectedIndex = -1; // 重置选中索引
                notifyChanged();
              },
              child: Stack(
                children: <Widget>[
                  CustomPaint(
                    size: Size(double.infinity, double.infinity),
                    painter: _painter,
                  ),
                  // 绘图工具的十字线选择器
                  if (widget.enableDrawingTools &&
                      _isDrawingMode &&
                      _isDrawingCrosshairMode &&
                      _drawingCrosshairPosition != null)
                    DrawingCrosshair(
                      position: _drawingCrosshairPosition!,
                      chartSize: Size(mWidth, mHeight),
                      isSelectingStartPoint: _isSelectingStartPoint,
                      isSelectingEndPoint: _isSelectingEndPoint,
                      color: Colors.orange,
                      strokeWidth: 1.5,
                    ),
                  if (widget.showInfoDialog) _buildInfoDialog(),
                ],
              ),
            ), // 关闭MouseRegion
          ),
        );
      },
    );
  }

  void _stopAnimation({bool needNotify = true}) {
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _onDragChanged(false);
      if (needNotify) {
        notifyChanged();
      }
    }
  }

  void _onDragChanged(bool isOnDrag) {
    isDrag = isOnDrag;
    if (widget.isOnDrag != null) {
      widget.isOnDrag!(isDrag);
    }
  }

  void _onFling(double velocity) {
    double target = mScrollX + velocity * widget.flingRatio / mScaleX;
    target = target.clamp(0.0, _maxScrollXForScale(mScaleX)).toDouble();

    _controller = AnimationController(
      duration: Duration(milliseconds: widget.flingTime),
      vsync: this,
    );
    aniX = Tween<double>(begin: mScrollX, end: target).animate(CurvedAnimation(
      parent: _controller!,
      curve: widget.flingCurve,
    ));
    aniX!.addListener(() {
      mScrollX = aniX!.value;
      notifyChanged();
    });
    aniX!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _onDragChanged(false);
        notifyChanged();
      }
    });
    _controller!.forward();
  }

  void notifyChanged() => setState(() {});

  late List<String> infos;

  Widget _buildInfoDialog() {
    return StreamBuilder<InfoWindowEntity?>(
        stream: mInfoWindowStream?.stream,
        builder: (context, snapshot) {
          if ((!_shouldShowCrossLine &&
                  !(widget.isTapShowInfoDialog && isOnTap)) ||
              widget.isLine == true ||
              snapshot.data == null ||
              snapshot.data?.kLineEntity == null) {
            return Container();
          }

          final entity = snapshot.data!.kLineEntity;
          double upDown = entity.change ?? entity.close - entity.open;
          double upDownPercent = entity.ratio ?? (upDown / entity.open) * 100;

          final translations = widget.isChinese
              ? kChartTranslations['zh_CN']!
              : widget.translations.of(context);

          final dateText = getDate(entity.time);
          final rows = <MapEntry<String, String>>[
            MapEntry(translations.open,
                entity.open.toStringAsFixed(widget.fixedLength)),
            MapEntry(translations.high,
                entity.high.toStringAsFixed(widget.fixedLength)),
            MapEntry(
                translations.low, entity.low.toStringAsFixed(widget.fixedLength)),
            MapEntry(translations.close,
                entity.close.toStringAsFixed(widget.fixedLength)),
            MapEntry(
                translations.changeAmount,
                "${upDown > 0 ? "+" : ""}${upDown.toStringAsFixed(widget.fixedLength)}"),
            MapEntry(
                translations.change,
                "${upDownPercent > 0 ? "+" : ''}${upDownPercent.toStringAsFixed(2)}%"),
            if (entity.amount != null)
              MapEntry(translations.amount, entity.amount!.toInt().toString()),
          ];

          final dialogPadding = 12.0;
          final dialogWidth = 164.0;
          final bgColor =
              currentChartColors.selectFillColor.withValues(alpha: 0.94);
          final borderColor = currentChartColors.selectBorderColor;
          final titleColor = currentChartColors.infoWindowTitleColor;
          final valueColor = currentChartColors.infoWindowNormalColor;

          return Container(
            margin: EdgeInsets.only(
              left: snapshot.data!.isLeft
                  ? dialogPadding
                  : mWidth - dialogWidth - dialogPadding,
              top: 40,
            ),
            width: dialogWidth,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  bgColor,
                  bgColor.withValues(alpha: 0.90),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: borderColor.withValues(alpha: 0.7), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dateText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: valueColor,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == rows.length - 1;
                  return Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: borderColor.withValues(alpha: 0.28),
                                width: 0.5,
                              ),
                            ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _getInfoValueColor(item.value),
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        });
  }

  Color _getInfoValueColor(String value) {
    if (value.startsWith("+")) return currentChartColors.upColor;
    if (value.startsWith("-")) return currentChartColors.dnColor;
    return currentChartColors.infoWindowNormalColor;
  }

  Widget _buildItem(String info, String infoName) {
    Color color = currentChartColors.infoWindowNormalColor;
    if (info.startsWith("+"))
      color = currentChartColors.infoWindowUpColor;
    else if (info.startsWith("-")) color = currentChartColors.infoWindowDnColor;
    final infoWidget = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
            child: Text("$infoName",
                style: TextStyle(
                    color: currentChartColors.infoWindowTitleColor,
                    fontSize: 10.0))),
        Text(info, style: TextStyle(color: color, fontSize: 10.0)),
      ],
    );
    return widget.materialInfoDialog
        ? Material(color: Colors.transparent, child: infoWidget)
        : infoWidget;
  }

  String getDate(int? date) {
    // 获取动态计算的时间格式
    List<String>? formats = widget.timeFormat ?? _painter?.mFormats;
    return dateFormat(
        DateTime.fromMillisecondsSinceEpoch(
            date ?? DateTime.now().millisecondsSinceEpoch),
        formats ?? TimeFormat.YEAR_MONTH_DAY);
  }
}
