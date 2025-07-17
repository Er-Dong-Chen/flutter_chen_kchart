import 'package:flutter/material.dart' show Color;

enum ChartTheme {
  light,
  dark,
}

class ChartColors {
  List<Color> bgColor = [Color(0xff18191d), Color(0xff18191d)];

  Color kLineColor = Color(0xff4C86CD);
  Color lineFillColor = Color(0x554C86CD);
  Color lineFillInsideColor = Color(0x00000000);
  Color ma5Color = Color(0xffC9B885);
  Color ma10Color = Color(0xff6CB0A6);
  Color ma30Color = Color(0xff9979C6);
  Color upColor = Color(0xff4DAA90);
  Color dnColor = Color(0xffC15466);
  Color volColor = Color(0xff4729AE);

  Color macdColor = Color(0xff4729AE);
  Color difColor = Color(0xffC9B885);
  Color deaColor = Color(0xff6CB0A6);

  Color kColor = Color(0xffC9B885);
  Color dColor = Color(0xff6CB0A6);
  Color jColor = Color(0xff9979C6);
  Color rsiColor = Color(0xffC9B885);

  Color defaultTextColor = Color(0xff60738E);

  Color nowPriceUpColor = Color(0xff4DAA90);
  Color nowPriceDnColor = Color(0xffC15466);
  Color nowPriceTextColor = Color(0xffffffff);

  //深度颜色
  Color depthBuyColor = Color(0xff60A893);
  Color depthSellColor = Color(0xffC15866);

  //选中后显示值边框颜色
  Color selectBorderColor = Color(0xff6C7A86);

  //选中后显示值背景的填充颜色
  Color selectFillColor = Color(0xff0D1722);

  //分割线颜色
  Color gridColor = Color(0xff4c5c74);

  Color infoWindowNormalColor = Color(0xffffffff);
  Color infoWindowTitleColor = Color(0xffffffff);
  Color infoWindowUpColor = Color(0xff00ff00);
  Color infoWindowDnColor = Color(0xffff0000);

  Color hCrossColor = Color(0xffffffff);
  Color vCrossColor = Color(0x1Effffff);
  Color crossTextColor = Color(0xffffffff);

  //当前显示内最大和最小值的颜色
  Color maxColor = Color(0xffffffff);
  Color minColor = Color(0xffffffff);

  Color getMAColor(int index) {
    switch (index % 3) {
      case 1:
        return ma10Color;
      case 2:
        return ma30Color;
      default:
        return ma5Color;
    }
  }

  // copyWith方法，方便基于现有主题创建自定义颜色
  ChartColors copyWith({
    List<Color>? bgColor,
    Color? kLineColor,
    Color? lineFillColor,
    Color? lineFillInsideColor,
    Color? ma5Color,
    Color? ma10Color,
    Color? ma30Color,
    Color? upColor,
    Color? dnColor,
    Color? volColor,
    Color? macdColor,
    Color? difColor,
    Color? deaColor,
    Color? kColor,
    Color? dColor,
    Color? jColor,
    Color? rsiColor,
    Color? defaultTextColor,
    Color? nowPriceUpColor,
    Color? nowPriceDnColor,
    Color? nowPriceTextColor,
    Color? depthBuyColor,
    Color? depthSellColor,
    Color? selectBorderColor,
    Color? selectFillColor,
    Color? gridColor,
    Color? infoWindowNormalColor,
    Color? infoWindowTitleColor,
    Color? infoWindowUpColor,
    Color? infoWindowDnColor,
    Color? hCrossColor,
    Color? vCrossColor,
    Color? crossTextColor,
    Color? maxColor,
    Color? minColor,
  }) {
    final newColors = ChartColors();

    newColors.bgColor = bgColor ?? this.bgColor;
    newColors.kLineColor = kLineColor ?? this.kLineColor;
    newColors.lineFillColor = lineFillColor ?? this.lineFillColor;
    newColors.lineFillInsideColor =
        lineFillInsideColor ?? this.lineFillInsideColor;
    newColors.ma5Color = ma5Color ?? this.ma5Color;
    newColors.ma10Color = ma10Color ?? this.ma10Color;
    newColors.ma30Color = ma30Color ?? this.ma30Color;
    newColors.upColor = upColor ?? this.upColor;
    newColors.dnColor = dnColor ?? this.dnColor;
    newColors.volColor = volColor ?? this.volColor;
    newColors.macdColor = macdColor ?? this.macdColor;
    newColors.difColor = difColor ?? this.difColor;
    newColors.deaColor = deaColor ?? this.deaColor;
    newColors.kColor = kColor ?? this.kColor;
    newColors.dColor = dColor ?? this.dColor;
    newColors.jColor = jColor ?? this.jColor;
    newColors.rsiColor = rsiColor ?? this.rsiColor;
    newColors.defaultTextColor = defaultTextColor ?? this.defaultTextColor;
    newColors.nowPriceUpColor = nowPriceUpColor ?? this.nowPriceUpColor;
    newColors.nowPriceDnColor = nowPriceDnColor ?? this.nowPriceDnColor;
    newColors.nowPriceTextColor = nowPriceTextColor ?? this.nowPriceTextColor;
    newColors.depthBuyColor = depthBuyColor ?? this.depthBuyColor;
    newColors.depthSellColor = depthSellColor ?? this.depthSellColor;
    newColors.selectBorderColor = selectBorderColor ?? this.selectBorderColor;
    newColors.selectFillColor = selectFillColor ?? this.selectFillColor;
    newColors.gridColor = gridColor ?? this.gridColor;
    newColors.infoWindowNormalColor =
        infoWindowNormalColor ?? this.infoWindowNormalColor;
    newColors.infoWindowTitleColor =
        infoWindowTitleColor ?? this.infoWindowTitleColor;
    newColors.infoWindowUpColor = infoWindowUpColor ?? this.infoWindowUpColor;
    newColors.infoWindowDnColor = infoWindowDnColor ?? this.infoWindowDnColor;
    newColors.hCrossColor = hCrossColor ?? this.hCrossColor;
    newColors.vCrossColor = vCrossColor ?? this.vCrossColor;
    newColors.crossTextColor = crossTextColor ?? this.crossTextColor;
    newColors.maxColor = maxColor ?? this.maxColor;
    newColors.minColor = minColor ?? this.minColor;

    return newColors;
  }

  // 亮色主题颜色
  static ChartColors light() {
    final colors = ChartColors();
    colors.bgColor = [Color(0xffffffff), Color(0xffffffff)];
    colors.kLineColor = Color(0xff2196F3);
    colors.lineFillColor = Color(0x552196F3);
    colors.lineFillInsideColor = Color(0x00000000);
    colors.ma5Color = Color(0xffFF9800);
    colors.ma10Color = Color(0xff129A48);

    colors.ma30Color = Color(0xff9C27B0);
    colors.upColor = Color(0xff129A48);
    colors.dnColor = Color(0xffEA4747);
    colors.volColor = Color(0xff673AB7);

    colors.macdColor = Color(0xff673AB7);
    colors.difColor = Color(0xffFF9800);
    colors.deaColor = Color(0xff129A48);

    colors.kColor = Color(0xffFF9800);
    colors.dColor = Color(0xff129A48);
    colors.jColor = Color(0xff9C27B0);
    colors.rsiColor = Color(0xffFF9800);

    colors.defaultTextColor = Color(0xff424242);

    colors.nowPriceUpColor = Color(0xff129A48);
    colors.nowPriceDnColor = Color(0xffEA4747);
    colors.nowPriceTextColor = Color(0xFFFFFFFF);

    colors.depthBuyColor = Color(0xff129A48);
    colors.depthSellColor = Color(0xffEA4747);

    colors.selectBorderColor = Color(0xffF8F8F8);
    colors.selectFillColor = Color(0xffF8F8F8);

    colors.gridColor = Color(0xffE0E0E0);

    colors.infoWindowNormalColor = Color(0xff000000);
    colors.infoWindowTitleColor = Color(0xff000000);
    colors.infoWindowUpColor = Color(0xff129A48);
    colors.infoWindowDnColor = Color(0xffEA4747);

    colors.hCrossColor = Color(0xff000000);
    colors.vCrossColor = Color(0x1E000000);
    colors.crossTextColor = Color(0xff000000);

    colors.maxColor = Color(0xff000000);
    colors.minColor = Color(0xff000000);

    return colors;
  }

  // 暗色主题颜色
  static ChartColors dark() {
    final colors = ChartColors();
    colors.bgColor = [Color(0xff18191d), Color(0xff18191d)];
    colors.kLineColor = Color(0xff4C86CD);
    colors.lineFillColor = Color(0x554C86CD);
    colors.lineFillInsideColor = Color(0x00000000);
    colors.ma5Color = Color(0xffC9B885);
    colors.ma10Color = Color(0xff6CB0A6);
    colors.ma30Color = Color(0xff9979C6);
    colors.upColor = Color(0xff129A48);
    colors.dnColor = Color(0xffEA4747);
    colors.volColor = Color(0xff4729AE);

    colors.macdColor = Color(0xff4729AE);
    colors.difColor = Color(0xffC9B885);
    colors.deaColor = Color(0xff6CB0A6);

    colors.kColor = Color(0xffC9B885);
    colors.dColor = Color(0xff6CB0A6);
    colors.jColor = Color(0xff9979C6);
    colors.rsiColor = Color(0xffC9B885);

    colors.defaultTextColor = Color(0xff60738E);

    colors.nowPriceUpColor = Color(0xff129A48);
    colors.nowPriceDnColor = Color(0xffEA4747);
    colors.nowPriceTextColor = Color(0xffffffff);

    colors.depthBuyColor = Color(0xff60A893);
    colors.depthSellColor = Color(0xffC15866);

    colors.selectBorderColor = Color(0xff6C7A86);
    colors.selectFillColor = Color(0xff0D1722);

    colors.gridColor = Color(0xff4c5c74);

    colors.infoWindowNormalColor = Color(0xffffffff);
    colors.infoWindowTitleColor = Color(0xffffffff);
    colors.infoWindowUpColor = Color(0xff00ff00);
    colors.infoWindowDnColor = Color(0xffff0000);

    colors.hCrossColor = Color(0xffffffff);
    colors.vCrossColor = Color(0x1Effffff);
    colors.crossTextColor = Color(0xffffffff);

    colors.maxColor = Color(0xffffffff);
    colors.minColor = Color(0xffffffff);

    return colors;
  }
}

class ChartStyle {
  double topPadding = 30.0;
  double bottomPadding = 20.0;
  double childPadding = 12.0;

  //点与点的距离
  double pointWidth = 11.0;

  //蜡烛宽度
  double candleWidth = 8.5;

  //蜡烛中间线的宽度
  double candleLineWidth = 1.5;

  //vol柱子宽度
  double volWidth = 8.5;

  //macd柱子宽度
  double macdWidth = 3.0;

  //垂直交叉线宽度
  double vCrossWidth = 8.5;

  //水平交叉线宽度
  double hCrossWidth = 0.5;

  //现在价格的线条长度
  double nowPriceLineLength = 1;

  //现在价格的线条间隔
  double nowPriceLineSpan = 1;

  //现在价格的线条粗细
  double nowPriceLineWidth = 1;

  int gridRows = 4;
  int gridColumns = 4;

  //下方時間客製化
  List<String>? dateTimeFormat;

  // copyWith方法，方便自定义样式
  ChartStyle copyWith({
    double? topPadding,
    double? bottomPadding,
    double? childPadding,
    double? pointWidth,
    double? candleWidth,
    double? candleLineWidth,
    double? volWidth,
    double? macdWidth,
    double? vCrossWidth,
    double? hCrossWidth,
    double? nowPriceLineLength,
    double? nowPriceLineSpan,
    double? nowPriceLineWidth,
    int? gridRows,
    int? gridColumns,
    List<String>? dateTimeFormat,
  }) {
    final newStyle = ChartStyle();

    newStyle.topPadding = topPadding ?? this.topPadding;
    newStyle.bottomPadding = bottomPadding ?? this.bottomPadding;
    newStyle.childPadding = childPadding ?? this.childPadding;
    newStyle.pointWidth = pointWidth ?? this.pointWidth;
    newStyle.candleWidth = candleWidth ?? this.candleWidth;
    newStyle.candleLineWidth = candleLineWidth ?? this.candleLineWidth;
    newStyle.volWidth = volWidth ?? this.volWidth;
    newStyle.macdWidth = macdWidth ?? this.macdWidth;
    newStyle.vCrossWidth = vCrossWidth ?? this.vCrossWidth;
    newStyle.hCrossWidth = hCrossWidth ?? this.hCrossWidth;
    newStyle.nowPriceLineLength = nowPriceLineLength ?? this.nowPriceLineLength;
    newStyle.nowPriceLineSpan = nowPriceLineSpan ?? this.nowPriceLineSpan;
    newStyle.nowPriceLineWidth = nowPriceLineWidth ?? this.nowPriceLineWidth;
    newStyle.gridRows = gridRows ?? this.gridRows;
    newStyle.gridColumns = gridColumns ?? this.gridColumns;
    newStyle.dateTimeFormat = dateTimeFormat ?? this.dateTimeFormat;

    return newStyle;
  }
}

class ChartThemeManager {
  static ChartTheme _currentTheme = ChartTheme.light;

  static ChartTheme get currentTheme => _currentTheme;

  static void setTheme(ChartTheme theme) {
    _currentTheme = theme;
  }

  static ChartColors getColors() {
    switch (_currentTheme) {
      case ChartTheme.light:
        return ChartColors.light();
      case ChartTheme.dark:
        return ChartColors.dark();
    }
  }

  static void toggleTheme() {
    _currentTheme =
        _currentTheme == ChartTheme.light ? ChartTheme.dark : ChartTheme.light;
  }
}
