import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chen_common/flutter_chen_common.dart';
import 'package:flutter_chen_kchart/k_chart.dart' hide S;
import 'package:flutter_chen_kchart/utils/kchart_log.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class KChartView extends StatefulWidget {
  final String symbol;
  final double? height;
  final bool? isFull;
  final bool? isSimple;
  final bool? isTradeView;
  final bool? enableDrawingTools;
  final bool? isDarkTheme;

  const KChartView({
    super.key,
    required this.symbol,
    this.height,
    this.isFull = false,
    this.isSimple = false,
    this.isTradeView = false,
    this.enableDrawingTools = true,
    this.isDarkTheme = false,
  });

  @override
  State<KChartView> createState() => _KChartViewState();
}

class _KChartViewState extends State<KChartView> {
  List<KLineEntity> dataList = [];
  List<DepthEntity> bids = [];
  List<DepthEntity> asks = [];
  bool isLoading = true;
  MainState mainState = MainState.MA;
  SecondaryState secondaryState = SecondaryState.KDJ;
  bool volHidden = false;
  String interval = '1h';
  bool isLine = false;
  bool isDepth = false;

  ChartStyle chartStyle = ChartStyle();
  final Color selectedColor = Colors.black;
  final Color unselectedColor = Colors.grey;

  Timer? _timer;
  int? _startTime;
  bool noMoreHistory = false;
  bool isLoadingMore = false;
  int? _oldestTime;
  Timer? _loadMoreDebounceTimer;
  final KChartController _chartController = KChartController();

  DrawingToolManager? _drawingToolManager;
  bool _isDrawingMode = false;
  DrawingToolType? _currentDrawingTool;
  bool _isDrawingVisible = true; // 绘图内容可见性控制

  final List<String> mainIntervals = ['15m', '1h', '4h', '1d'];
  final List<String> allIntervals = ['1h'];

  @override
  void initState() {
    super.initState();
    if (widget.isSimple == true) {
      secondaryState = SecondaryState.NONE;
      volHidden = true;
    }

    // 优化：绘图工具初始化
    if (widget.enableDrawingTools == true) {
      _drawingToolManager = DrawingToolManager();

      // 设置绘图工具变化回调
      _drawingToolManager!.onToolsChanged = () {
        if (mounted) setState(() {});
      };

      // 设置工具选中回调
      _drawingToolManager!.onToolSelected = (tool) {
        if (mounted) {
          setState(() {
            // 工具选中时的状态更新
            kchartLog('选中绘图工具: ${tool?.displayName ?? "无"}');
          });
        }
      };

      // 初始化绘图模式 - 默认关闭，用户手动开启
      _drawingToolManager!.modeManager.setDrawingMode(false);
      _isDrawingMode = false;
      _currentDrawingTool = null;

      kchartLog('绘图工具管理器初始化完成');
    }

    fetchKline(false);
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (isLoadingMore) return;

      if (isDepth) {
        fetchDepth();
      } else {
        fetchLatestKline();
      }
    });
  }

  @override
  void didUpdateWidget(KChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果symbol发生变化，重新获取K线数据
    if (widget.symbol != oldWidget.symbol) {
      // 重置状态
      setState(() {
        dataList.clear();
        bids.clear();
        asks.clear();
        isLoading = true;
        noMoreHistory = false;
        isLoadingMore = false;
        _oldestTime = null;
      });

      _chartController.clearSavedState();

      if (isDepth) {
        fetchDepth();
      } else {
        fetchKline(false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loadMoreDebounceTimer?.cancel();
    super.dispose();
  }

  List<DepthEntity> accumulateDepth(List<DepthEntity> list) {
    list.sort((a, b) => a.price.compareTo(b.price));
    double sum = 0;
    return list.map((e) {
      sum += e.vol;
      return DepthEntity(e.price, sum);
    }).toList();
  }

  Future<void> fetchDepth() async {
    try {
      String url =
          'https://api.binance.com/api/v3/depth?symbol=${widget.symbol.toUpperCase()}&limit=500';
      final response = await Dio().get(url);

      List<DepthEntity> rawBids =
          (response.data['bids'] as List).map<DepthEntity>((item) {
        return DepthEntity(double.parse(item[0]), double.parse(item[1]));
      }).toList();

      List<DepthEntity> rawAsks =
          (response.data['asks'] as List).map<DepthEntity>((item) {
        return DepthEntity(double.parse(item[0]), double.parse(item[1]));
      }).toList();

      List<DepthEntity> newBids = accumulateDepth(rawBids);
      List<DepthEntity> newAsks = accumulateDepth(rawAsks);

      if (mounted) {
        setState(() {
          bids = newBids;
          asks = newAsks;
        });
      }
    } catch (e) {
      kchartLog('获取深度数据失败: $e');
    }
  }

  Future<void> fetchKline(bool isLoadMore) async {
    try {
      if (isLoadMore && noMoreHistory) return;

      if (isLoadMore) {
        setState(() => isLoadingMore = true);
      } else {
        setState(() => isLoading = true);
      }

      String url =
          'https://api.binance.com/api/v3/klines?symbol=${widget.symbol.toUpperCase()}&interval=$interval&limit=500';

      if (isLoadMore && dataList.isNotEmpty) {
        _startTime = _oldestTime ?? dataList.first.time;
        url += '&endTime=$_startTime';
      }

      final response = await Dio().get(url);
      List<KLineEntity> newData = response.data.map<KLineEntity>((item) {
        return KLineEntity.fromJson({
          'time': item[0],
          'open': double.parse(item[1]),
          'high': double.parse(item[2]),
          'low': double.parse(item[3]),
          'close': double.parse(item[4]),
          'vol': double.parse(item[5]),
        });
      }).toList();

      if (!mounted) return;

      if (isLoadMore) {
        if (newData.isEmpty) {
          noMoreHistory = true;
        } else {
          DataUtil.calculate(newData);
          setState(() {
            dataList = [...newData, ...dataList];
            _oldestTime = newData.isNotEmpty ? newData.first.time : _oldestTime;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _chartController.hasSavedState) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _chartController.restoreScaleState();
                  _chartController.clearSavedState();
                }
              });
            }
          });
        }
        setState(() => isLoadingMore = false);
      } else {
        DataUtil.calculate(newData);
        setState(() {
          dataList = newData;
          noMoreHistory = false;
          _oldestTime = newData.isNotEmpty ? newData.first.time : null;
        });
        setState(() => isLoading = false);
      }
    } catch (e) {
      log('获取K线数据失败: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          if (isLoadMore) isLoadingMore = false;
        });
      }
    }
  }

  Future<void> fetchLatestKline() async {
    try {
      if (isLoadingMore || dataList.isEmpty) return;

      String url =
          'https://api.binance.com/api/v3/klines?symbol=${widget.symbol}&interval=$interval&limit=2';
      final response = await Dio().get(url);
      List<KLineEntity> newData = response.data.map<KLineEntity>((item) {
        return KLineEntity.fromJson({
          'time': item[0],
          'open': double.parse(item[1]),
          'high': double.parse(item[2]),
          'low': double.parse(item[3]),
          'close': double.parse(item[4]),
          'vol': double.parse(item[5]),
        });
      }).toList();

      if (newData.isEmpty || !mounted) return;

      // 判断是否有新K线
      if (newData.last.time == dataList.last.time) {
        // 只更新最后一根
        dataList[dataList.length - 1] = newData.last;
      } else if ((newData.last.time ?? 0) > (dataList.last.time ?? 0)) {
        // 追加新K线
        dataList.add(newData.last);
      }
      DataUtil.calculate(dataList);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      kchartLog('更新最新K线数据失败: $e');
    }
  }

  void onIntervalChange(String newInterval) {
    Log.d(111);
    setState(() {
      isLine = false;
      isDepth = false;
      isLoadingMore = false;
      _oldestTime = null;
      interval = newInterval;
    });

    _chartController.clearSavedState();

    fetchKline(false);
  }

  void _debouncedLoadMore(bool isNext) {
    if (isLoadingMore || (isNext == true && noMoreHistory)) {
      return;
    }

    _loadMoreDebounceTimer?.cancel();

    _loadMoreDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && !isLoadingMore) {
        if (isNext == true) {
          _chartController.saveScaleState();
          fetchKline(true);
        }
      }
    });
  }

  void _toggleDrawingTool(DrawingToolType? toolType) {
    if (_drawingToolManager == null) return;

    setState(() {
      if (_currentDrawingTool == toolType && toolType != null) {
        // 如果点击的是当前工具，则取消绘图模式
        _currentDrawingTool = null;
        _isDrawingMode = false;
        _drawingToolManager!.setCurrentToolType(null);
        _drawingToolManager!.modeManager.setDrawingMode(false);
        kchartLog('取消绘图工具: $toolType');
      } else {
        // 切换到新的绘图工具
        _currentDrawingTool = toolType;
        _isDrawingMode = toolType != null;
        _drawingToolManager!.setCurrentToolType(toolType);
        _drawingToolManager!.modeManager.setDrawingMode(toolType != null);
        kchartLog('选择绘图工具: $toolType');
      }

      // 同步当前工具状态
      if (toolType != null) {
        kchartLog('绘图模式: $_isDrawingMode, 当前工具: $_currentDrawingTool');
      }
    });
  }

  void _clearAllDrawings() {
    if (_drawingToolManager == null) return;
    _drawingToolManager!.clearAllTools();
    kchartLog('清除所有绘图工具');
    setState(() {}); // 强制刷新UI
  }

  void _toggleDrawingMode() {
    if (_drawingToolManager == null) return;

    setState(() {
      _isDrawingMode = !_isDrawingMode;
      _drawingToolManager!.modeManager.setDrawingMode(_isDrawingMode);

      if (!_isDrawingMode) {
        // 关闭绘图模式时，清除当前工具
        _currentDrawingTool = null;
        _drawingToolManager!.setCurrentToolType(null);
        kchartLog('关闭绘图模式');
      } else {
        kchartLog('开启绘图模式');
      }
    });
  }

  void _toggleContinuousMode() {
    if (_drawingToolManager == null) return;

    setState(() {
      _drawingToolManager!.modeManager.toggleContinuousMode();
      kchartLog('连续绘图模式: ${_drawingToolManager!.modeManager.isContinuousMode}');
    });
  }

  void _toggleMagnetMode() {
    if (_drawingToolManager == null) return;

    setState(() {
      _drawingToolManager!.modeManager.toggleMagnetMode();
      kchartLog('磁铁吸附模式: ${_drawingToolManager!.modeManager.isMagnetMode}');
    });
  }

  void _toggleDrawingVisibility() {
    if (_drawingToolManager == null) return;

    setState(() {
      _isDrawingVisible = !_isDrawingVisible;
      // 切换所有绘图工具的可见性
      for (var tool in _drawingToolManager!.tools) {
        tool.isVisible = _isDrawingVisible;
      }
      kchartLog('绘图可见性: $_isDrawingVisible');
    });
  }

  Widget _buildDrawingToolbar() {
    if (widget.enableDrawingTools != true || _drawingToolManager == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 0.5),
          bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // 模式控制区域
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              children: [
                if (_isDrawingMode) ...[
                  // 连续绘图模式
                  _buildModeToggle(
                    icon: Icons.repeat,
                    label: '连续',
                    isActive: _drawingToolManager!.modeManager.isContinuousMode,
                    onTap: _toggleContinuousMode,
                  ),
                  SizedBox(width: 12.w),
                  // 磁铁吸附模式
                  _buildModeToggle(
                    icon: Icons.auto_fix_high,
                    label: '磁铁',
                    isActive: _drawingToolManager!.modeManager.isMagnetMode,
                    onTap: _toggleMagnetMode,
                  ),
                  SizedBox(width: 12.w),
                  _buildModeToggle(
                    icon: _isDrawingVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    label: _isDrawingVisible ? '显示' : '隐藏',
                    isActive: _isDrawingVisible,
                    onTap: _toggleDrawingVisibility,
                  ),
                  SizedBox(width: 12.w),
                  _buildModeToggle(
                    icon: Icons.delete_outline,
                    label: '清除',
                    isActive: false, // 清除按钮不需要激活状态
                    onTap: _clearAllDrawings,
                  ),
                  SizedBox(width: 12.w),
                  _buildModeToggle(
                    icon: Icons.close,
                    label: '退出',
                    isActive: false,
                    onTap: () => _toggleDrawingMode(),
                  ),
                ],

                const Spacer(),

                // // 工具数量和状态指示
                // Container(
                //   padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                //   decoration: BoxDecoration(
                //     color: _drawingToolManager!.tools.isNotEmpty
                //         ? Colors.green[100]
                //         : Colors.grey[200],
                //     borderRadius: BorderRadius.circular(4.r),
                //   ),
                //   child: Text(
                //     '${_drawingToolManager!.tools.length}个工具',
                //     style: TextStyle(
                //       fontSize: 10.sp,
                //       color: _drawingToolManager!.tools.isNotEmpty
                //           ? Colors.green[700]
                //           : Colors.grey[600],
                //     ),
                //   ),
                // ),
              ],
            ),
          ),

          if (_isDrawingMode) ...[
            SizedBox(height: 8.h),
            // 绘图工具按钮区域
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 8个主工具按钮
                  _buildDrawingToolButton(
                    icon: Icons.show_chart,
                    toolType: DrawingToolType.trendLine,
                    tooltip: '趋势线',
                  ),
                  _buildDrawingToolButton(
                    icon: Icons.architecture,
                    toolType: DrawingToolType.trendAngle,
                    tooltip: '趋势角度',
                  ),
                  _buildDrawingToolButton(
                    icon: Icons.arrow_right_alt,
                    toolType: DrawingToolType.arrow,
                    tooltip: '箭头',
                  ),
                  _buildDrawingToolButton(
                    icon: Icons.vertical_align_center,
                    toolType: DrawingToolType.verticalLine,
                    tooltip: '垂直线',
                  ),
                  _buildDrawingToolButton(
                    icon: Icons.horizontal_rule,
                    toolType: DrawingToolType.horizontalLine,
                    tooltip: '水平线',
                  ),
                  _buildDrawingToolButton(
                    icon: Icons.trending_flat,
                    toolType: DrawingToolType.horizontalRay,
                    tooltip: '水平射线',
                  ),
                  _buildDrawingToolButton(
                    icon: Icons.timeline,
                    toolType: DrawingToolType.ray,
                    tooltip: '射线',
                  ),
                  _buildDrawingToolButton(
                    icon: Icons.add,
                    toolType: DrawingToolType.crossLine,
                    tooltip: '十字线',
                  ),

                  // // 分隔线
                  // Container(
                  //   width: 1,
                  //   height: 24.h,
                  //   margin: EdgeInsets.symmetric(horizontal: 8.w),
                  //   color: Colors.grey[300],
                  // ),

                  // // 功能按钮
                  // _buildActionButton(
                  //   icon: Icons.clear,
                  //   tooltip: '取消工具',
                  //   onPressed: () => _toggleDrawingTool(null),
                  //   color: Colors.orange,
                  // ),
                  // _buildActionButton(
                  //   icon: Icons.delete_outline,
                  //   tooltip: '删除选中',
                  //   onPressed: _deleteSelectedDrawing,
                  //   color: Colors.red,
                  // ),
                  // _buildActionButton(
                  //   icon: Icons.clear_all,
                  //   tooltip: '清除所有',
                  //   onPressed: _clearAllDrawings,
                  //   color: Colors.red,
                  //   isDestructive: true,
                  // ),
                ],
              ),
            ),

            // 使用说明
            if (_currentDrawingTool != null) ...[
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Text(
                  _getToolInstructions(_currentDrawingTool!),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDrawingToolButton({
    required IconData icon,
    required DrawingToolType toolType,
    required String tooltip,
  }) {
    final isSelected = _currentDrawingTool == toolType;

    return IconButton(
      onPressed: () => _toggleDrawingTool(toolType),
      icon: Icon(icon, size: 16.sp),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue[100] : Colors.transparent,
        foregroundColor: isSelected ? Colors.blue[700] : Colors.grey[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.r),
        ),
      ),
    );
  }

  Widget _buildModeToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(
            color: isActive ? Colors.blue[300]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: isActive ? Colors.blue[700] : Colors.grey[600],
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: isActive ? Colors.blue[700] : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getToolDisplayName(DrawingToolType toolType) {
    switch (toolType) {
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

  String _getToolInstructions(DrawingToolType toolType) {
    switch (toolType) {
      case DrawingToolType.trendLine:
        return '点击并拖动以绘制趋势线。';
      case DrawingToolType.trendAngle:
        return '点击并拖动以绘制趋势角度。';
      case DrawingToolType.arrow:
        return '点击并拖动以绘制箭头。';
      case DrawingToolType.verticalLine:
        return '点击并拖动以绘制垂直线。';
      case DrawingToolType.horizontalLine:
        return '点击并拖动以绘制水平线。';
      case DrawingToolType.horizontalRay:
        return '点击选择位置绘制水平射线（从右往左）。';
      case DrawingToolType.ray:
        return '点击并拖动以绘制射线。';
      case DrawingToolType.crossLine:
        return '点击并拖动以绘制十字线。';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 0),
            overlayColor: Colors.transparent,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
      child: SizedBox(
        height: widget.height ?? 400.h,
        child: Column(
          children: [
            // 分时切换
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  spacing: 12.w,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        isLine = !isLine;
                        isDepth = false;
                      }),
                      child: Text('分时',
                              style: TextStyle(
                                  color: isLine && !isDepth
                                      ? selectedColor
                                      : unselectedColor))
                          .paddingOnly(left: 16.w),
                    ),
                    for (var i in mainIntervals)
                      GestureDetector(
                        onTap: () => onIntervalChange(i),
                        child: Text(i,
                            style: TextStyle(
                                color: interval == i && !isDepth
                                    ? selectedColor
                                    : unselectedColor)),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (widget.enableDrawingTools == true &&
                        widget.isSimple == false) ...[
                      GestureDetector(
                        onTap: _toggleDrawingMode,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: _isDrawingMode
                                ? Colors.blue[100]
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(
                              color: _isDrawingMode
                                  ? Colors.blue
                                  : Colors.grey[400]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                size: 16.sp,
                                color: _isDrawingMode
                                    ? Colors.blue[700]
                                    : unselectedColor,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '绘图',
                                style: TextStyle(
                                  color: _isDrawingMode
                                      ? Colors.blue[700]
                                      : unselectedColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 当前工具指示器
                      if (_isDrawingMode && _currentDrawingTool != null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                          child: Text(
                            _getToolDisplayName(_currentDrawingTool!),
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],

                      SizedBox(width: 12.w),
                    ],
                    if (widget.isFull == false && widget.isSimple == false) ...[
                      GestureDetector(
                        onTap: () => setState(() {
                          isDepth = !isDepth;
                          if (isDepth) {
                            fetchDepth();
                          }
                        }),
                        child: Text('深度图',
                            style: TextStyle(
                                color:
                                    isDepth ? selectedColor : unselectedColor)),
                      ).paddingOnly(right: 16.w),
                    ],
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            if (_isDrawingMode && widget.enableDrawingTools == true)
              _buildDrawingToolbar(),
            Expanded(
              child: RepaintBoundary(
                child: isDepth
                    ? DepthChart(
                        bids.reversed.toList(),
                        asks,
                        ChartThemeManager.getColors(), // 使用主题系统的颜色
                        fixedLength: 2,
                      )
                    : KChartWidget(
                        dataList,
                        isLine: isLine,
                        isTrendLine: false,
                        mainState: mainState,
                        secondaryState: secondaryState,
                        volHidden: volHidden,
                        showNowPrice: true,
                        watermark: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              'Flutter_Chen_Kchart',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 2.0
                                  ..color = Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Flutter_Chen_Kchart',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                              ),
                            ),
                          ],
                        ),
                        watermarkOpacity:
                            widget.isDarkTheme == true ? 0.10 : 0.08,
                        watermarkAlignment: Alignment.center,
                        onLoadMore: noMoreHistory ? null : _debouncedLoadMore,
                        controller: _chartController,
                        enableDrawingTools: widget.enableDrawingTools ?? false,
                        drawingToolManager: _drawingToolManager,
                        enableTheme: true,
                        onCrossLineTap: (double price) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('点击了十字线标签，当前位置价格: $price')),
                          );
                        },
                      ),
              ),
            ),
            // 指标切换
            if (!isDepth && widget.isSimple == false)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      mainState = mainState == MainState.MA
                          ? MainState.NONE
                          : MainState.MA;
                    }),
                    child: Text('MA',
                        style: TextStyle(
                            color: mainState == MainState.MA
                                ? selectedColor
                                : unselectedColor)),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      mainState = mainState == MainState.BOLL
                          ? MainState.NONE
                          : MainState.BOLL;
                    }),
                    child: Text('BOLL',
                        style: TextStyle(
                            color: mainState == MainState.BOLL
                                ? selectedColor
                                : unselectedColor)),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      secondaryState = secondaryState == SecondaryState.KDJ
                          ? SecondaryState.NONE
                          : SecondaryState.KDJ;
                    }),
                    child: Text('KDJ',
                        style: TextStyle(
                            color: secondaryState == SecondaryState.KDJ
                                ? selectedColor
                                : unselectedColor)),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      secondaryState = secondaryState == SecondaryState.MACD
                          ? SecondaryState.NONE
                          : SecondaryState.MACD;
                    }),
                    child: Text('MACD',
                        style: TextStyle(
                            color: secondaryState == SecondaryState.MACD
                                ? selectedColor
                                : unselectedColor)),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      secondaryState = secondaryState == SecondaryState.RSI
                          ? SecondaryState.NONE
                          : SecondaryState.RSI;
                    }),
                    child: Text('RSI',
                        style: TextStyle(
                            color: secondaryState == SecondaryState.RSI
                                ? selectedColor
                                : unselectedColor)),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      secondaryState = secondaryState == SecondaryState.WR
                          ? SecondaryState.NONE
                          : SecondaryState.WR;
                    }),
                    child: Text('WR',
                        style: TextStyle(
                            color: secondaryState == SecondaryState.WR
                                ? selectedColor
                                : unselectedColor)),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      secondaryState = secondaryState == SecondaryState.CCI
                          ? SecondaryState.NONE
                          : SecondaryState.CCI;
                    }),
                    child: Text('CCI',
                        style: TextStyle(
                            color: secondaryState == SecondaryState.WR
                                ? selectedColor
                                : unselectedColor)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
