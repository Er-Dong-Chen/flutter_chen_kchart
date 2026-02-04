import 'dart:async' show StreamSink;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_chen_kchart/utils/number_util.dart';

import '../entity/info_window_entity.dart';
import '../entity/k_line_entity.dart';
import '../utils/date_format_util.dart';
import '../utils/drawing_tool_manager.dart';
import 'base_chart_painter.dart';
import 'base_chart_renderer.dart';
import 'main_renderer.dart';
import 'secondary_renderer.dart';
import 'vol_renderer.dart';

class TrendLine {
  final Offset p1;
  final Offset p2;
  final double maxHeight;
  final double scale;

  TrendLine(this.p1, this.p2, this.maxHeight, this.scale);
}

double? trendLineX;

double getTrendLineX() {
  return trendLineX ?? 0;
}

class ChartPainter extends BaseChartPainter {
  final List<TrendLine> lines; //For TrendLine (保留兼容性)
  final bool isTrendLine; //For TrendLine (保留兼容性)
  bool isrecordingCord = false; //For TrendLine (保留兼容性)
  final double selectY; //For TrendLine (保留兼容性)

  // 新增绘图工具支持
  final DrawingToolManager? drawingToolManager;

  static get maxScrollX => BaseChartPainter.maxScrollX;
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer, mSecondaryRenderer;
  StreamSink<InfoWindowEntity?>? sink;
  Color? upColor, dnColor;
  Color? ma5Color, ma10Color, ma30Color;
  Color? volColor;
  Color? macdColor, difColor, deaColor, jColor;
  int fixedLength;
  List<int> maDayList;
  final ChartColors chartColors;
  late Paint selectPointPaint, selectorBorderPaint, nowPricePaint;
  final ChartStyle chartStyle;
  final bool hideGrid;
  final bool showNowPrice;
  final VerticalTextAlignment verticalTextAlignment;

  // 新增：是否显示十字线
  final bool shouldShowCrossLine;

  ChartPainter(
    this.chartStyle,
    this.chartColors, {
    required this.lines, //For TrendLine (保留兼容性)
    required this.isTrendLine, //For TrendLine (保留兼容性)
    required this.selectY, //For TrendLine (保留兼容性)
    this.drawingToolManager, // 新增绘图工具管理器
    required datas,
    required scaleX,
    required scrollX,
    required isLongPass,
    required selectX,
    required xFrontPadding,
    isOnTap,
    isTapShowInfoDialog,
    required this.verticalTextAlignment,
    mainState,
    volHidden,
    secondaryState,
    this.sink,
    bool isLine = false,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
    this.shouldShowCrossLine = false, // 新增：是否显示十字线
    Function(double)? onCrossLineTap, // 新增：十字线点击回调
  }) : super(
          chartStyle,
          datas: datas,
          scaleX: scaleX,
          scrollX: scrollX,
          isLongPress: isLongPass,
          isOnTap: isOnTap,
          isTapShowInfoDialog: isTapShowInfoDialog,
          selectX: selectX,
          mainState: mainState,
          volHidden: volHidden,
          secondaryState: secondaryState,
          xFrontPadding: xFrontPadding,
          isLine: isLine,
          shouldShowCrossLine: shouldShowCrossLine, // 传递十字线显示状态
          onCrossLineTap: onCrossLineTap, // 传递十字线点击回调
        ) {
    selectPointPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..color = this.chartColors.selectFillColor;
    selectorBorderPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..color = this.chartColors.selectBorderColor;
    nowPricePaint = Paint()
      ..strokeWidth = this.chartStyle.nowPriceLineWidth
      ..isAntiAlias = true;
  }

  @override
  void initChartRenderer() {
    if (datas != null && datas!.isNotEmpty) {
      var t = datas![0];
      fixedLength =
          NumberUtil.getMaxDecimalLength(t.open, t.close, t.high, t.low);
    }
    mMainRenderer = MainRenderer(
      mMainRect,
      mMainMaxValue,
      mMainMinValue,
      mTopPadding,
      mainState,
      isLine,
      fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      verticalTextAlignment,
      maDayList,
    );
    if (mVolRect != null) {
      mVolRenderer = VolRenderer(mVolRect!, mVolMaxValue, mVolMinValue,
          mChildPadding, fixedLength, this.chartStyle, this.chartColors);
    }
    if (mSecondaryRect != null) {
      mSecondaryRenderer = SecondaryRenderer(
          mSecondaryRect!,
          mSecondaryMaxValue,
          mSecondaryMinValue,
          mChildPadding,
          secondaryState,
          fixedLength,
          chartStyle,
          chartColors);
    }
  }

  @override
  void drawBg(Canvas canvas, Size size) {
    Paint mBgPaint = Paint();
    Gradient mBgGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: chartColors.bgColor,
    );
    Rect mainRect =
        Rect.fromLTRB(0, 0, mMainRect.width, mMainRect.height + mTopPadding);
    canvas.drawRect(
        mainRect, mBgPaint..shader = mBgGradient.createShader(mainRect));

    if (mVolRect != null) {
      Rect volRect = Rect.fromLTRB(
          0, mVolRect!.top - mChildPadding, mVolRect!.width, mVolRect!.bottom);
      canvas.drawRect(
          volRect, mBgPaint..shader = mBgGradient.createShader(volRect));
    }

    if (mSecondaryRect != null) {
      Rect secondaryRect = Rect.fromLTRB(0, mSecondaryRect!.top - mChildPadding,
          mSecondaryRect!.width, mSecondaryRect!.bottom);
      canvas.drawRect(secondaryRect,
          mBgPaint..shader = mBgGradient.createShader(secondaryRect));
    }
    Rect dateRect =
        Rect.fromLTRB(0, size.height - mBottomPadding, size.width, size.height);
    canvas.drawRect(
        dateRect, mBgPaint..shader = mBgGradient.createShader(dateRect));
  }

  @override
  void drawGrid(canvas) {
    if (!hideGrid) {
      mMainRenderer.drawGrid(canvas, mGridRows, mGridColumns);
      mVolRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
      mSecondaryRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
    }
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
      KLineEntity? curPoint = datas?[i];
      if (curPoint == null) continue;
      KLineEntity lastPoint = i == 0 ? curPoint : datas![i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);

      mMainRenderer.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mVolRenderer?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mSecondaryRenderer?.drawChart(
          lastPoint, curPoint, lastX, curX, size, canvas);
    }

    // 移除了十字线绘制，现在由base_chart_painter负责
    if (isTrendLine == true) drawTrendLines(canvas, size);
    canvas.restore();

    // 在恢复canvas状态后绘制绘图工具，现在传递正确的坐标转换函数和主图边界
    if (drawingToolManager != null) {
      drawingToolManager!.drawTools(
        canvas,
        size,
        scaleX, // 传递当前的缩放比例
        scrollX, // 传递当前的滚动位置
        (index) {
          // 扩展的X坐标转换函数，支持超出数据范围的索引
          // 使用与getX相同的计算逻辑，但不限制索引范围
          final absoluteX = index * mPointWidth + mPointWidth / 2;
          final screenX = translateXtoX(absoluteX);
          return screenX;
        },
        getMainY, // 传递正确的Y坐标转换函数（价格转屏幕坐标）
      );
    }
  }

  @override
  void drawVerticalText(canvas) {
    var textStyle = getTextStyle(this.chartColors.defaultTextColor);
    if (!hideGrid) {
      mMainRenderer.drawVerticalText(canvas, textStyle, mGridRows);
    }
    mVolRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
    mSecondaryRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    if (datas == null) return;
    if (mGridColumns <= 0) return;

    double columnSpace = size.width / mGridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    const minGap = 8.0;

    Map<String, Object>? buildLabel(int i) {
      final translateX = xToTranslateX(columnSpace * i);
      if (translateX < startX || translateX > stopX) return null;
      final index = indexOfTranslateX(translateX);
      if (datas?[index] == null) return null;
      final tp = getTextPainter(getDate(datas![index].time), null);
      final y = size.height - (mBottomPadding - tp.height) / 2 - tp.height;
      var x = columnSpace * i - tp.width / 2;
      if (x < 0) x = 0;
      if (x > size.width - tp.width) x = size.width - tp.width;
      return {'x': x, 'y': y, 'tp': tp};
    }

    final first = buildLabel(0);
    final last = buildLabel(mGridColumns);

    if (first == null && last == null) return;

    if (first != null && last != null) {
      final firstX = first['x'] as double;
      final firstTp = first['tp'] as TextPainter;
      final lastX = last['x'] as double;
      if (firstX + firstTp.width + minGap > lastX) {
        final lastTp = last['tp'] as TextPainter;
        final lastY = last['y'] as double;
        lastTp.paint(canvas, Offset(lastX, lastY));
        return;
      }
    }

    double lastRight = -1e9;
    double reservedLeft = double.infinity;

    if (last != null) {
      reservedLeft = (last['x'] as double) - minGap;
    }

    if (first != null) {
      final x = first['x'] as double;
      final y = first['y'] as double;
      final tp = first['tp'] as TextPainter;
      tp.paint(canvas, Offset(x, y));
      lastRight = x + tp.width;
    }

    for (var i = 1; i <= mGridColumns - 1; ++i) {
      final label = buildLabel(i);
      if (label == null) continue;
      final x = label['x'] as double;
      final tp = label['tp'] as TextPainter;
      final right = x + tp.width;
      if (x <= lastRight + minGap) continue;
      if (right >= reservedLeft) continue;
      final y = label['y'] as double;
      tp.paint(canvas, Offset(x, y));
      lastRight = right;
    }

    if (last != null) {
      final x = last['x'] as double;
      final y = last['y'] as double;
      final tp = last['tp'] as TextPainter;
      tp.paint(canvas, Offset(x, y));
    }

//    double translateX = xToTranslateX(0);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStartIndex].id));
//      tp.paint(canvas, Offset(0, y));
//    }
//    translateX = xToTranslateX(size.width);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStopIndex].id));
//      tp.paint(canvas, Offset(size.width - tp.width, y));
//    }
  }

  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    // 使用手指位置
    double x = selectX;
    double y = selectY;

    // 确保Y坐标在主图区域内
    if (y < mTopPadding) y = mTopPadding;
    if (y > mMainRect.bottom) y = mMainRect.bottom;

    // 根据Y坐标计算对应的价格
    double currentPrice = mMainRenderer.getYFromPrice(y);

    // 获取最新价格（最后一个数据点的收盘价）
    double latestPrice = 0;
    if (datas != null && datas!.isNotEmpty) {
      latestPrice = datas!.last.close;
    }

    // 计算涨跌幅
    double changeAmount = currentPrice - latestPrice;
    double changePercent =
        latestPrice != 0 ? (changeAmount / latestPrice) * 100 : 0;

    // 创建价格文本（简化显示）
    String priceText = currentPrice.toStringAsFixed(fixedLength);
    String changeText =
        "${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%";

    // 使用默认文本颜色
    Color textColor = chartColors.defaultTextColor;

    // 绘制价格文本
    TextPainter priceTp = getTextPainter(priceText, textColor);
    TextPainter changeTp = getTextPainter(changeText, textColor);

    double textHeight = priceTp.height;
    double priceWidth = priceTp.width;
    double changeWidth = changeTp.width;
    double maxWidth = math.max(priceWidth, changeWidth);

    double w1 = 8;
    double w2 = 6;
    double lineSpacing = 2; // 行间距
    double totalTextHeight = textHeight * 2 + lineSpacing; // 两行文本总高度
    double r = totalTextHeight / 2 + w2; // 背景框半高

    // 计算文本垂直居中位置
    double topMargin = (totalTextHeight - textHeight * 2 - lineSpacing) / 2;
    double priceY = y - totalTextHeight / 2 + topMargin; // 价格文本Y位置（顶对齐到背景框内）
    double changeY = priceY + textHeight + lineSpacing; // 涨跌幅文本Y位置

    double textX;
    bool isLeft = false;

    // 判断标签应该显示在左侧还是右侧
    if (x < mWidth / 2) {
      isLeft = false;
      textX = 1;

      // 绘制统一背景
      Path path = Path();
      path.moveTo(textX, y - r);
      path.lineTo(textX, y + r);
      path.lineTo(maxWidth + 2 * w1, y + r);
      path.lineTo(maxWidth + 2 * w1 + w2, y);
      path.lineTo(maxWidth + 2 * w1, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);

      // 绘制文本
      priceTp.paint(canvas, Offset(textX + w1, priceY));
      changeTp.paint(canvas, Offset(textX + w1, changeY));
    } else {
      isLeft = true;
      textX = mWidth - maxWidth - 1 - 2 * w1 - w2;

      // 绘制统一背景
      Path path = Path();
      path.moveTo(textX, y);
      path.lineTo(textX + w2, y + r);
      path.lineTo(mWidth - 2, y + r);
      path.lineTo(mWidth - 2, y - r);
      path.lineTo(textX + w2, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);

      // 绘制文本
      priceTp.paint(canvas, Offset(textX + w1 + w2, priceY));
      changeTp.paint(canvas, Offset(textX + w1 + w2, changeY));
    }

    // 绘制底部时间标签（仍然基于最近的数据点）
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);

    TextPainter dateTp =
        getTextPainter(getDate(point.time), chartColors.crossTextColor);
    double dateWidth = dateTp.width;
    double dateX = x;
    double dateY = size.height - mBottomPadding;

    if (dateX < dateWidth + 2 * w1) {
      dateX = 1 + dateWidth / 2 + w1;
    } else if (mWidth - dateX < dateWidth + 2 * w1) {
      dateX = mWidth - 1 - dateWidth / 2 - w1;
    }

    final labelPaddingX = 8.0;
    final labelPaddingY = 4.0;
    final labelHeight = dateTp.height + labelPaddingY * 2;
    final labelTop =
        dateY + (mBottomPadding - labelHeight).clamp(0.0, mBottomPadding) / 2;
    final labelRect = Rect.fromLTRB(
      dateX - dateWidth / 2 - labelPaddingX,
      labelTop,
      dateX + dateWidth / 2 + labelPaddingX,
      labelTop + labelHeight,
    );
    final labelRRect = RRect.fromRectAndRadius(labelRect, Radius.circular(4));
    canvas.drawRRect(labelRRect, selectPointPaint);
    canvas.drawRRect(labelRRect, selectorBorderPaint);

    dateTp.paint(
        canvas, Offset(dateX - dateWidth / 2, labelTop + labelPaddingY));

    //长按显示这条数据详情
    sink?.add(InfoWindowEntity(point, isLeft: isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    //长按显示按中的数据
    if (isLongPress || (isTapShowInfoDialog && isOnTap)) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }
    //松开显示最后一条数据
    mMainRenderer.drawText(canvas, data, x);
    mVolRenderer?.drawText(canvas, data, x);
    mSecondaryRenderer?.drawText(canvas, data, x);
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine == true) return;
    double lineSize = 20;
    double lineToTextOffset = 5;

    Paint linePaint = Paint()
      ..strokeWidth = 1
      ..color = chartColors.minColor;

    //绘制最大值和最小值
    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //画右边
      TextPainter tp = getTextPainter(
        mMainLowMinValue.toStringAsFixed(fixedLength),
        chartColors.minColor,
      );

      canvas.drawLine(
        Offset(x, y),
        Offset(x + lineSize, y),
        linePaint,
      );

      tp.paint(
        canvas,
        Offset(
          x + lineSize + lineToTextOffset,
          y - tp.height / 2,
        ),
      );
    } else {
      TextPainter tp = getTextPainter(
        mMainLowMinValue.toStringAsFixed(fixedLength),
        chartColors.minColor,
      );

      canvas.drawLine(
        Offset(x, y),
        Offset(x - lineSize, y),
        linePaint,
      );

      tp.paint(
        canvas,
        Offset(
          x - tp.width - lineSize - lineToTextOffset,
          y - tp.height / 2,
        ),
      );
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //画右边
      TextPainter tp = getTextPainter(
        mMainHighMaxValue.toStringAsFixed(fixedLength),
        chartColors.maxColor,
      );

      canvas.drawLine(
        Offset(x, y),
        Offset(x + lineSize, y),
        linePaint,
      );

      tp.paint(
        canvas,
        Offset(
          x + lineSize + lineToTextOffset,
          y - tp.height / 2,
        ),
      );
    } else {
      TextPainter tp = getTextPainter(
        mMainHighMaxValue.toStringAsFixed(fixedLength),
        chartColors.maxColor,
      );

      canvas.drawLine(
        Offset(x, y),
        Offset(x - lineSize, y),
        linePaint,
      );

      tp.paint(
        canvas,
        Offset(
          x - tp.width - lineSize - lineToTextOffset,
          y - tp.height / 2,
        ),
      );
    }
  }

  @override
  void drawNowPrice(Canvas canvas) {
    if (!this.showNowPrice) {
      return;
    }

    if (datas == null) {
      return;
    }

    double value = datas!.last.close;
    double y = getMainY(value);

    //视图展示区域边界值绘制
    if (y > getMainY(mMainLowMinValue)) {
      y = getMainY(mMainLowMinValue);
    }

    if (y < getMainY(mMainHighMaxValue)) {
      y = getMainY(mMainHighMaxValue);
    }

    nowPricePaint
      ..color = value >= datas!.last.open
          ? this.chartColors.nowPriceUpColor
          : this.chartColors.nowPriceDnColor;
    //先画横线
    double startX = 0;
    final max = -mTranslateX + mWidth / scaleX;
    final space =
        this.chartStyle.nowPriceLineSpan + this.chartStyle.nowPriceLineLength;
    while (startX < max) {
      canvas.drawLine(
          Offset(startX, y),
          Offset(startX + this.chartStyle.nowPriceLineLength, y),
          nowPricePaint);
      startX += space;
    }
    //再画背景和文本
    TextPainter tp = getTextPainter(
        value.toStringAsFixed(fixedLength), this.chartColors.nowPriceTextColor);

    double offsetX;
    switch (verticalTextAlignment) {
      case VerticalTextAlignment.left:
        offsetX = 0;
        break;
      case VerticalTextAlignment.right:
        offsetX = mWidth - tp.width;
        break;
    }

    double top = y - tp.height / 2;
    canvas.drawRect(
        Rect.fromLTRB(offsetX, top, offsetX + tp.width, top + tp.height),
        nowPricePaint);
    tp.paint(canvas, Offset(offsetX, top));
  }

//For TrendLine
  void drawTrendLines(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    Paint paintY = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1
      ..isAntiAlias = true;
    double x = getX(index);
    trendLineX = x;

    double y = selectY;
    // getMainY(point.close);

    // k线图竖线
    canvas.drawLine(Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);
    Paint paintX = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 1
      ..isAntiAlias = true;
    Paint paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
    if (scaleX >= 1) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 15.0 * scaleX, width: 15.0),
          paint);
    } else {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 10.0, width: 10.0 / scaleX),
          paint);
    }
    if (lines.length >= 1) {
      lines.forEach((element) {
        var y1 = -((element.p1.dy - 35) / element.scale) + element.maxHeight;
        var y2 = -((element.p2.dy - 35) / element.scale) + element.maxHeight;
        var a = (trendLineMax! - y1) * trendLineScale! + trendLineContentRec!;
        var b = (trendLineMax! - y2) * trendLineScale! + trendLineContentRec!;
        var p1 = Offset(element.p1.dx, a);
        var p2 = Offset(element.p2.dx, b);
        canvas.drawLine(
            p1,
            element.p2 == Offset(-1, -1) ? Offset(x, y) : p2,
            Paint()
              ..color = Colors.yellow
              ..strokeWidth = 2);
      });
    }
  }

  ///画交叉线
  void drawCrossLine(Canvas canvas, Size size) {
    // 使用手指位置而不是数据点位置
    double x = selectX;
    double y = selectY;

    // 确保十字线在图表区域内
    if (y < mTopPadding) y = mTopPadding;
    if (y > size.height - mBottomPadding) y = size.height - mBottomPadding;

    // 创建虚线画笔 - 竖线
    Paint paintY = Paint()
      ..color = this.chartColors.hCrossColor // 使用横线相同的颜色确保可见性
      ..strokeWidth = this.chartStyle.hCrossWidth // 使用合适的宽度，而不是过宽的vCrossWidth
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 绘制竖线（纵向线） - 使用虚线
    _drawDashedLine(
      canvas,
      Offset(x, mTopPadding),
      Offset(x, size.height - mBottomPadding),
      paintY,
    );

    // 创建虚线画笔 - 横线
    Paint paintX = Paint()
      ..color = this.chartColors.hCrossColor // 使用横线颜色
      ..strokeWidth = this.chartStyle.hCrossWidth // 使用横线宽度
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 绘制横线 - 使用虚线（只在主图区域绘制）
    _drawDashedLine(
      canvas,
      Offset(0, y),
      Offset(size.width, y),
      paintX,
    );

    // 绘制中心点 - 简化设计，只要内圈实心圆圈
    canvas.drawCircle(
      Offset(x, y),
      2.0, // 半径2.0
      Paint()
        ..color = this.chartColors.hCrossColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  /// 绘制虚线
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashLength = 3.0; // 增加虚线长度
    const double dashSpace = 3.0; // 增加间距

    final double distance = (end - start).distance;
    final Offset direction = (end - start) / distance;

    double currentDistance = 0.0;
    bool drawDash = true;

    while (currentDistance < distance) {
      final double segmentLength = drawDash ? dashLength : dashSpace;
      final double nextDistance =
          (currentDistance + segmentLength).clamp(0.0, distance);

      if (drawDash) {
        final Offset segmentStart = start + direction * currentDistance;
        final Offset segmentEnd = start + direction * nextDistance;
        canvas.drawLine(segmentStart, segmentEnd, paint);
      }

      currentDistance = nextDistance;
      drawDash = !drawDash;
    }
  }

  TextPainter getTextPainter(text, color) {
    if (color == null) {
      color = this.chartColors.defaultTextColor;
    }
    TextSpan span = TextSpan(text: "$text", style: getTextStyle(color));
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String getDate(int? date) => dateFormat(
      DateTime.fromMillisecondsSinceEpoch(
          date ?? DateTime.now().millisecondsSinceEpoch),
      mFormats);

  double getMainY(double y) => mMainRenderer.getY(y);

  /// 点是否在SecondaryRect中
  bool isInSecondaryRect(Offset point) {
    return mSecondaryRect?.contains(point) ?? false;
  }

  /// 点是否在MainRect中
  bool isInMainRect(Offset point) {
    return mMainRect.contains(point);
  }

  /// 检测是否点击了十字线标签
  bool isCrossLineLabelTapped(Offset tapPoint) {
    if (!shouldShowCrossLine) return false;

    double x = selectX;
    double y = selectY;

    // 确保Y坐标在主图区域内
    if (y < mTopPadding) y = mTopPadding;
    if (y > mMainRect.bottom) y = mMainRect.bottom;

    // 计算标签位置和大小
    double w1 = 8;
    double w2 = 6;
    double lineSpacing = 2;
    double textHeight = 12; // 估算文本高度
    double totalTextHeight = textHeight * 2 + lineSpacing;
    double r = totalTextHeight / 2 + w2;
    double maxWidth = 100; // 估算最大宽度

    Rect labelRect;
    if (x < mWidth / 2) {
      // 左侧标签
      labelRect = Rect.fromLTRB(
        1,
        y - r,
        maxWidth + 2 * w1 + w2,
        y + r,
      );
    } else {
      // 右侧标签
      labelRect = Rect.fromLTRB(
        mWidth - maxWidth - 1 - 2 * w1 - w2,
        y - r,
        mWidth - 2,
        y + r,
      );
    }

    return labelRect.contains(tapPoint);
  }

  /// 获取当前十字线位置的价格
  double getCurrentCrossLinePrice() {
    double y = selectY;
    if (y < mTopPadding) y = mTopPadding;
    if (y > mMainRect.bottom) y = mMainRect.bottom;
    return mMainRenderer.getYFromPrice(y);
  }
}
