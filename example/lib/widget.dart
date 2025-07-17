import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chen_common/flutter_chen_common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_chen_kchart/k_chart.dart' hide S;

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
    this.enableDrawingTools = false,
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

  final List<String> mainIntervals = ['15m', '1h', '4h', '1d'];
  final List<String> allIntervals = ['1h'];

  @override
  void initState() {
    super.initState();
    if (widget.isSimple == true) {
      secondaryState = SecondaryState.NONE;
      volHidden = true;
    }

    if (widget.enableDrawingTools == true) {
      _drawingToolManager = DrawingToolManager();
      _drawingToolManager!.onToolsChanged = () {
        if (mounted) setState(() {});
      };
      _drawingToolManager!.onToolSelected = (tool) {
        if (mounted) {
          setState(() {
            // 工具选中时的状态更新
          });
        }
      };
      // debugPrint('添加测试绘图工具');
      // _drawingToolManager!.addTestTools();
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
      debugPrint(
          'KChartView symbol 发生变化: ${oldWidget.symbol} -> ${widget.symbol}');

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
    debugPrint('KChartView 销毁，symbol: ${widget.symbol}');
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
      debugPrint('开始获取深度数据，symbol: ${widget.symbol}');

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
        debugPrint('深度数据更新完成，买盘: ${bids.length} 条, 卖盘: ${asks.length} 条');
      }
    } catch (e) {
      debugPrint('获取深度数据失败: $e');
    }
  }

  Future<void> fetchKline(bool isLoadMore) async {
    try {
      if (isLoadMore && noMoreHistory) return;

      debugPrint(
          '开始获取K线数据，symbol:  [32m${widget.symbol} [0m, isLoadMore: $isLoadMore');

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

      debugPrint('K线数据更新完成，共 ${dataList.length} 条数据');
    } catch (e) {
      debugPrint('获取K线数据失败: $e');
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
      debugPrint('更新最新K线数据失败: $e');
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
        } else {
          debugPrint('滑动到最新数据位置');
        }
      }
    });
  }

  void _toggleDrawingTool(DrawingToolType? toolType) {
    debugPrint('切换绘图工具: $toolType, 当前工具: $_currentDrawingTool');
    setState(() {
      if (_currentDrawingTool == toolType) {
        // 如果点击的是当前工具，则取消绘图模式
        _currentDrawingTool = null;
        _isDrawingMode = false;
        _drawingToolManager?.setCurrentToolType(null);
        debugPrint('取消绘图工具选择');
      } else {
        // 切换到新的绘图工具
        _currentDrawingTool = toolType;
        _isDrawingMode = toolType != null;
        _drawingToolManager?.setCurrentToolType(toolType);
        debugPrint('选择绘图工具: $toolType, 绘图模式: $_isDrawingMode');
      }
    });
  }

  void _clearAllDrawings() {
    debugPrint('清除所有绘图工具');
    _drawingToolManager?.clearAllTools();
    setState(() {}); // 强制刷新UI
  }

  void _deleteSelectedDrawing() {
    debugPrint('删除选中的绘图工具');
    _drawingToolManager?.deleteSelectedTool();
    setState(() {}); // 强制刷新UI
  }

  void _toggleDrawingMode() {
    debugPrint('切换绘图模式: 当前状态 $_isDrawingMode -> ${!_isDrawingMode}');
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (!_isDrawingMode) {
        _currentDrawingTool = null;
        _drawingToolManager?.setCurrentToolType(null);
        debugPrint('退出绘图模式，清除当前工具选择');
      } else {
        debugPrint('进入绘图模式');
      }
    });
  }

  Widget _buildDrawingToolbar() {
    if (widget.enableDrawingTools != true || _drawingToolManager == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 8个主工具按钮
            _buildDrawingToolButton(
              icon: Icons.show_chart, // 趋势线
              toolType: DrawingToolType.trendLine,
              tooltip: '趋势线',
            ),
            _buildDrawingToolButton(
              icon: Icons.architecture, // 趋势角度（占位）
              toolType: DrawingToolType.trendAngle,
              tooltip: '趋势角度',
            ),
            _buildDrawingToolButton(
              icon: Icons.arrow_right_alt, // 箭头
              toolType: DrawingToolType.arrow,
              tooltip: '箭头',
            ),
            _buildDrawingToolButton(
              icon: Icons.vertical_align_center, // 垂直线
              toolType: DrawingToolType.verticalLine,
              tooltip: '垂直线',
            ),
            _buildDrawingToolButton(
              icon: Icons.horizontal_rule, // 水平线
              toolType: DrawingToolType.horizontalLine,
              tooltip: '水平线',
            ),
            _buildDrawingToolButton(
              icon: Icons.trending_flat, // 水平射线（占位）
              toolType: DrawingToolType.horizontalRay,
              tooltip: '水平射线',
            ),
            _buildDrawingToolButton(
              icon: Icons.trending_flat, // 射线（占位）
              toolType: DrawingToolType.ray,
              tooltip: '射线',
            ),
            _buildDrawingToolButton(
              icon: Icons.add, // 十字线
              toolType: DrawingToolType.crossLine,
              tooltip: '十字线',
            ),
            // 分隔线
            Container(
              width: 1,
              height: 24.h,
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              color: Colors.grey[300],
            ),
            // 右侧功能按钮（吸附、可见性、删除、清空）
            IconButton(
              onPressed: () {
                // TODO: 吸附功能
              },
              icon: Icon(Icons.auto_fix_high, size: 20.sp),
              tooltip: '吸附',
            ),
            IconButton(
              onPressed: () {
                // TODO: 可见性切换
              },
              icon: Icon(Icons.visibility, size: 20.sp),
              tooltip: '可见性',
            ),
            IconButton(
              onPressed: _deleteSelectedDrawing,
              icon: Icon(Icons.delete_outline, size: 20.sp),
              tooltip: '删除选中',
            ),
            IconButton(
              onPressed: _clearAllDrawings,
              icon: Icon(Icons.clear_all, size: 20.sp),
              tooltip: '清除所有',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingToolButton({
    required IconData icon,
    required DrawingToolType toolType,
    required String tooltip,
  }) {
    final isSelected = _currentDrawingTool == toolType;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: IconButton(
        onPressed: () => _toggleDrawingTool(toolType),
        icon: Icon(icon, size: 20.sp),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue[100] : Colors.transparent,
          foregroundColor: isSelected ? Colors.blue[700] : Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
      ),
    );
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
                        onLoadMore: noMoreHistory ? null : _debouncedLoadMore,
                        controller: _chartController,
                        enableDrawingTools: widget.enableDrawingTools ?? false,
                        drawingToolManager: _drawingToolManager,
                        enableTheme: true,
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
