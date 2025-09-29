# flutter_chen_kchart

## Flutter 生态首个可商用 K线图表库 / The First Production-Ready K-Line Chart for Flutter

[![Pub Version](https://img.shields.io/pub/v/flutter_chen_kchart)](https://pub.dev/packages/flutter_chen_kchart)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)


## 🚀 Why flutter_chen_kchart?

> Flutter has never had a truly production-ready, commercial K-line (candlestick) chart library.
> Now, you don't need to embed TradingView via WebView anymore.
> This is the first open-source and commercial K-line chart solution for Flutter.

**选择理由 / Why Choose Us:**
- 🏆 **Flutter 生态首个** 真正达到可商用的 K线图表库
- 🚀 **原生性能** CustomPainter 实现，丝滑流畅
- 🌍 **全平台支持** iOS/Android/Web/Windows/macOS/Linux
- 🔧 **灵活选择** 免费版满足基础需求，商用版提供专业功能
- 📈 **持续更新** 长期维护，功能不断完善

---

## 效果展示 / Effect Display

### [🌐 在线演示 / Online Demo](https://er-dong-chen.github.io/flutter_chen_kchart/)

<div style="display: flex; justify-content: space-between;">
  <img src="https://er-dong-chen.github.io/images/demo/kchart.gif" alt="基础K线图表" style="width: 48%;">
  <img src="https://er-dong-chen.github.io/images/demo/kchart_select.gif" alt="交互选择功能" style="width: 48%;">
</div>

<div style="display: flex; justify-content: space-between;">
  <img src="https://er-dong-chen.github.io/images/demo/kchart_draw1.gif" alt="绘图工具演示" style="width: 48%;">
  <img src="https://er-dong-chen.github.io/images/demo/kchart_draw2.gif" alt="高级绘图功能" style="width: 48%;">
</div>

*注：绘图工具功能仅在商用版 2.x 中提供*

---

## 📦 快速开始 / Quick Start

### 1. 选择版本 / Choose Version

#### 免费版本 1.x
```yaml
dependencies:
  flutter_chen_kchart: ^1.0.0
```

#### 商用版本 2.x
```yaml
dependencies:
  flutter_chen_kchart: ^2.0.0  # 需要商业授权
```

### 2. 基本用法 / Basic Usage

```dart
import 'package:flutter_chen_kchart/flutter_chen_kchart.dart';

final KChartController _controller = KChartController();

KChartWidget(
  datas,
  controller: _controller,
  enableTheme: true,
  minScale: 0.1,
  maxScale: 5.0,
  scaleSensitivity: 2.5,
  onScaleChanged: (scale) {
    print('Current scale: ${(scale * 100).toInt()}%');
  },
  // 商用版独有功能
  enableDrawingTools: true,    // 仅商用版 2.x
  enablePerformanceMode: true, // 仅商用版 2.x
)
```

---

## 🛠️ 配置参数 / Configuration

| 参数/Property         | 类型/Type   | 默认值/Default | 说明/Description                |
|----------------------|-------------|----------------|---------------------------------|
| minScale             | double      | 0.1            | 最小缩放比例 / Min scale        |
| maxScale             | double      | 5.0            | 最大缩放比例 / Max scale        |
| scaleSensitivity     | double      | 2.5            | 缩放灵敏度 / Scale sensitivity  |
| enablePinchZoom      | bool        | true           | 双指缩放 / Pinch zoom           |
| enableScrollZoom     | bool        | true           | 滚轮缩放 / Mouse wheel zoom     |
| enableTheme          | bool        | true           | 启用主题系统 / Enable theme     |
| enableDrawingTools   | bool        | false          | 启用绘图工具 / Drawing tools    |
| enablePerformanceMode| bool        | false          | 性能优化 / Performance mode     |
| controller           | KChartController? | null      | 控制器 / Controller            |
| onScaleChanged       | Function(double)? | null      | 缩放回调 / Scale callback       |

更多参数详见源码和注释。

---

## 📊 技术指标 / Indicators

- MA, BOLL, MACD, KDJ, RSI, WR, CCI

---

## 🖌️ 绘图工具 / Drawing Tools

> **注意：绘图工具仅在商用版 2.x 中提供**

### 支持的绘图工具
- 📈 **趋势线 / 趋势角度** - 支持角度显示
- ↕️ **垂直线 / 水平线** - 精确定位
- ➡️ **射线 / 水平射线** - 延伸至图表边界
- 🏹 **箭头标注** - 重要位置标记
- ✚ **十字线** - 价格时间定位

### 绘图模式
- 🔄 **连续绘制** - 快速添加多个图形
- 🎯 **精确控制** - 像素级精度
- 🧲 **磁铁吸附** - 智能对齐K线
- 👁️ **显示隐藏** - 灵活管理绘图
- 🗑️ **批量清除** - 一键清理

---

## 📚 文档与示例 / Documentation

- 📖 **[API 文档](https://pub.dev/documentation/flutter_chen_kchart/latest/)**
- 🎨 **[绘图工具指南](DRAWING_TOOLS_GUIDE.md)** *(商用版)*
- 💡 **[示例代码](https://github.com/Er-Dong-Chen/flutter_chen_kchart/tree/main/example)**

---

## 捐赠支持 / Donation Support

如果对你有帮助，欢迎捐赠支持开发：

<div style="display: flex; justify-content: space-between;">
  <img src="https://er-dong-chen.github.io/images/wechat.png" alt="微信赞赏" style="width: 48%;">
  <img src="https://er-dong-chen.github.io/images/alipay.png" alt="支付宝捐赠" style="width: 48%;">
</div>


---

**Made with ❤️ by Flutter Community**

*如果这个库对你有帮助，请在 GitHub 上给我们一个 Star ⭐*
