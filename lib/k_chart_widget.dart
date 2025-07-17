import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chen_kchart/chart_translations.dart';
import 'package:flutter_chen_kchart/extension/map_ext.dart';
import 'package:flutter_chen_kchart/k_chart.dart';

enum MainState { MA, BOLL, NONE }

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
  @Deprecated('Use `translations` instead.')
  final bool isChinese;
  final bool showNowPrice;
  final bool showInfoDialog;
  final bool materialInfoDialog; // Material风格的信息弹窗
  final Map<String, ChartTranslations> translations;
  final List<String> timeFormat;

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
    @Deprecated('Use `translations` instead.') this.isChinese = false,
    this.showNowPrice = true,
    this.showInfoDialog = true,
    this.materialInfoDialog = true,
    this.translations = kChartTranslations,
    this.timeFormat = TimeFormat.YEAR_MONTH_DAY,
    this.onLoadMore,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
    this.flingTime = 350, // 更短惯性动画
    this.flingRatio = 0.9, // 更自然的惯性距离
    this.flingCurve = Curves.easeOutCubic, // 丝滑曲线
    this.isOnDrag,
    this.verticalTextAlignment = VerticalTextAlignment.left,
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
  double _lastScale = 1.0;
  bool isScale = false, isDrag = false, isLongPress = false, isOnTap = false;
  Offset? _scaleCenter; // 缩放中心点
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

  // 获取当前绘图模式状态
  bool get _isDrawingMode {
    if (!widget.enableDrawingTools) return false;
    return _drawingToolManager.currentToolType != null;
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
        debugPrint('KChartWidget: 使用外部传入的绘图工具管理器');
      } else {
        _drawingToolManager = DrawingToolManager();
        debugPrint('KChartWidget: 创建新的绘图工具管理器');
      }

      _drawingToolManager.onToolsChanged = () {
        debugPrint('KChartWidget: 绘图工具发生变化，刷新UI');
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

    super.dispose();
  }

  // 程序化缩放方法
  Future<void> scaleTo(double targetScale,
      {Duration? duration, Offset? center}) async {
    if (!mounted) return;

    // 输入验证
    if (targetScale.isNaN || targetScale.isInfinite) {
      debugPrint('KChart: Invalid scale value: $targetScale');
      return;
    }

    targetScale = targetScale.clamp(widget.minScale, widget.maxScale);

    // 如果缩放值没有变化，直接返回
    if ((targetScale - _currentScale).abs() < 0.001) {
      return;
    }

    try {
      if (widget.enableScaleAnimation && duration != null) {
        _scaleCenter = center;

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
      // 缩放后，调整mScrollX让焦点保持在原地
      mScrollX = (contentX - center.dx / mScaleX)
          .clamp(0.0, ChartPainter.maxScrollX)
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
          // 可以在这里添加触觉反馈
          if (widget.enableScaleHapticFeedback) {
            // HapticFeedback.lightImpact();
          }
        }
      });
    }
  }

  // 获取当前缩放比例
  double get currentScale => _currentScale;

  @override
  Widget build(BuildContext context) {
    if (widget.datas != null && widget.datas!.isEmpty) {
      mScrollX = mSelectX = 0.0;
      mScaleX = 1.0;
    }
    final _painter = ChartPainter(
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

                    _updateScale(newScale, details.position);
                  }
                }
              : null,
          child: GestureDetector(
            onTapUp: (details) {
              debugPrint(
                  'KChartWidget.onTapUp: 绘图模式=$_isDrawingMode, 当前工具=${widget.enableDrawingTools ? _drawingToolManager.currentToolType : "未启用"}');

              if (!isLongPress && !isScale) {
                _stopAnimation();
              }

              // 处理绘图工具的点击事件
              if (widget.enableDrawingTools && _isDrawingMode) {
                final localPosition = details.localPosition;
                debugPrint(
                    '绘图模式点击: 位置=$localPosition, 当前工具类型=${_drawingToolManager.currentToolType}');

                if (_drawingToolManager.currentToolType != null) {
                  if (_drawingToolManager.currentDrawingTool == null) {
                    // 开始绘制新工具
                    debugPrint('开始绘制新工具');
                    _drawingToolManager.startDrawing(localPosition);
                  } else {
                    // 完成当前绘制
                    debugPrint('完成当前绘制');
                    _drawingToolManager.updateDrawing(localPosition);
                    _drawingToolManager.finishDrawing();
                  }
                  return;
                } else {
                  // 选择模式 - 选择或移动工具
                  debugPrint('选择模式');
                  _drawingToolManager.selectTool(localPosition);
                  return;
                }
              }

              if (!widget.isTrendLine &&
                  _painter.isInMainRect(details.localPosition)) {
                isOnTap = true;
                if (mSelectX != details.localPosition.dx &&
                    widget.isTapShowInfoDialog) {
                  mSelectX = details.localPosition.dx;
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
                  lines
                      .add(TrendLine(a.p1, p1, trendLineMax!, trendLineScale!));
                  waitingForOtherPairofCords = false;
                } else {
                  waitingForOtherPairofCords = true;
                }
                notifyChanged();
              }
            },
            onHorizontalDragDown: (details) {
              isOnTap = false;
              _stopAnimation();
              _onDragChanged(true);
            },
            onHorizontalDragUpdate: (details) {
              if (isScale || isLongPress) return;

              // 只要不是绘图模式，直接平移
              if (!(widget.enableDrawingTools &&
                  _isDrawingMode &&
                  _drawingToolManager.currentDrawingTool != null)) {
                mScrollX = (mScrollX + (details.primaryDelta ?? 0) / mScaleX)
                    .clamp(0.0, ChartPainter.maxScrollX)
                    .toDouble();
                notifyChanged();
                return;
              }

              // 绘图模式下的拖拽
              if (widget.enableDrawingTools &&
                  _isDrawingMode &&
                  _drawingToolManager.currentDrawingTool != null) {
                _drawingToolManager.updateDrawing(details.localPosition);
                notifyChanged();
                return;
              }
            },
            onHorizontalDragEnd: (DragEndDetails details) {
              var velocity = details.velocity.pixelsPerSecond.dx;
              _onFling(velocity);
            },
            onHorizontalDragCancel: () => _onDragChanged(false),
            onScaleStart: (details) {
              if (!widget.enablePinchZoom) return;
              isScale = true;
              _lastScale = mScaleX;
              _scaleCenter = details.focalPoint;
            },
            onScaleUpdate: (details) {
              if (!widget.enablePinchZoom || isDrag || isLongPress) return;

              // 优化：只要有缩放就响应，提升灵敏度，非线性放大
              double delta = details.scale - 1.0;
              double sensitivity = widget.scaleSensitivity;
              // 非线性放大（1.5次方），让小幅度手势也有明显缩放
              double factor = delta >= 0
                  ? 1.0 + (pow(delta.abs(), 1.5) * sensitivity)
                  : 1.0 - (pow(delta.abs(), 1.5) * sensitivity);
              final newScale = _lastScale * factor;

              _updateScale(newScale,
                  widget.enableScaleCenterPoint ? _scaleCenter : null);
            },
            onScaleEnd: (_) {
              if (!widget.enablePinchZoom) return;
              isScale = false;
              _lastScale = mScaleX;
              _scaleCenter = null;
            },
            onLongPressStart: (details) {
              isOnTap = false;
              isLongPress = true;
              if ((mSelectX != details.localPosition.dx ||
                      mSelectY != details.globalPosition.dy) &&
                  !widget.isTrendLine) {
                mSelectX = details.localPosition.dx;
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
              if ((mSelectX != details.localPosition.dx ||
                      mSelectY != details.globalPosition.dy) &&
                  !widget.isTrendLine) {
                mSelectX = details.localPosition.dx;
                mSelectY = details.globalPosition.dy;
                notifyChanged();
              }
              if (widget.isTrendLine) {
                mSelectX =
                    mSelectX + (details.localPosition.dx - changeinXposition!);
                changeinXposition = details.localPosition.dx;
                mSelectY =
                    mSelectY + (details.globalPosition.dy - changeinYposition!);
                changeinYposition = details.globalPosition.dy;
                notifyChanged();
              }
            },
            onLongPressEnd: (details) {
              isLongPress = false;
              enableCordRecord = true;
              mInfoWindowStream?.sink.add(null);
              notifyChanged();
            },
            child: Stack(
              children: <Widget>[
                CustomPaint(
                  size: Size(double.infinity, double.infinity),
                  painter: _painter,
                ),
                if (widget.showInfoDialog) _buildInfoDialog(),
              ],
            ),
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
    target = target.clamp(0.0, ChartPainter.maxScrollX).toDouble();

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
          if ((!isLongPress && !isOnTap) ||
              widget.isLine == true ||
              !snapshot.hasData ||
              snapshot.data?.kLineEntity == null) return Container();
          KLineEntity entity = snapshot.data!.kLineEntity;
          double upDown = entity.change ?? entity.close - entity.open;
          double upDownPercent = entity.ratio ?? (upDown / entity.open) * 100;
          final double? entityAmount = entity.amount;
          infos = [
            getDate(entity.time),
            entity.open.toStringAsFixed(widget.fixedLength),
            entity.high.toStringAsFixed(widget.fixedLength),
            entity.low.toStringAsFixed(widget.fixedLength),
            entity.close.toStringAsFixed(widget.fixedLength),
            "${upDown > 0 ? "+" : ""}${upDown.toStringAsFixed(widget.fixedLength)}",
            "${upDownPercent > 0 ? "+" : ''}${upDownPercent.toStringAsFixed(2)}%",
            if (entityAmount != null) entityAmount.toInt().toString()
          ];
          final dialogPadding = 4.0;
          final dialogWidth = mWidth / 3;
          return Container(
            margin: EdgeInsets.only(
                left: snapshot.data!.isLeft
                    ? dialogPadding
                    : mWidth - dialogWidth - dialogPadding,
                top: 25),
            width: dialogWidth,
            decoration: BoxDecoration(
                color:
                    currentChartColors.selectFillColor.withValues(alpha: 0.9),
                border: Border.all(
                    color: currentChartColors.selectBorderColor, width: 0.5)),
            child: ListView.builder(
              padding: EdgeInsets.all(dialogPadding),
              itemCount: infos.length,
              itemExtent: 14.0,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final translations = widget.isChinese
                    ? kChartTranslations['zh_CN']!
                    : widget.translations.of(context);

                return _buildItem(
                  infos[index],
                  translations.byIndex(index),
                );
              },
            ),
          );
        });
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

  String getDate(int? date) => dateFormat(
      DateTime.fromMillisecondsSinceEpoch(
          date ?? DateTime.now().millisecondsSinceEpoch),
      widget.timeFormat);
}
