# flutter_chen_kchart

## Flutter 生态首个可商用 K线图表库 / The First Production-Ready K-Line Chart for Flutter

---

## ✨ 特性亮点 / Features

- **原生性能 / Native Performance**：基于 CustomPainter，60fps 丝滑体验
- **多主题支持 / Multiple Themes**：一行切换亮/暗色主题
- **丰富技术指标 / Rich Indicators**：MA、BOLL、MACD、KDJ、RSI、WR、CCI
- **极致交互 / Excellent Interaction**：双指缩放、滚轮缩放、平移、长按详情
- **自定义样式 / Customizable**：颜色、线宽、字体、布局全可配
- **国际化 / Internationalization**：多语言支持
- **性能优化 / Performance**：支持大量数据点不卡顿
- **绘图工具 / Drawing Tools**：趋势线、箭头、标注等绘图工具（开发中）
- **持续维护 / Actively Maintained**：第一个正式商用Flutter K线库，长期更新

---

## 🚀 Why flutter_chen_kchart?

> Flutter has never had a truly production-ready, commercial K-line (candlestick) chart library.  
> Now, you don’t need to embed TradingView via WebView anymore.  
> This is the first open-source, natively performant, fully customizable, and actively maintained K-line chart for Flutter.

---

## 效果展示

![KChart 效果预览](https://er-dong-chen.github.io/images/demo/kchart.gif)

### [Online Demo](https://er-dong-chen.github.io/flutter_chen_kchart/)(需要开VPN)

## 📦 快速开始 / Quick Start

### 1. 添加依赖 / Add Dependency

```yaml
dependencies:
  flutter_chen_kchart: ^1.0.0
```

### 2. 基本用法 / Basic Usage

```dart
import 'package:flutter_chen_kchart/flutter_chen_kchart.dart';

final KChartController _controller = KChartController();

KChartWidget(
  datas,
  controller: _controller,
  enableTheme: true,
  enableDrawingTools: true,
  minScale: 0.1,
  maxScale: 5.0,
  scaleSensitivity: 2.5,
  onScaleChanged: (scale) {
    print('Current scale: ${(scale * 100).toInt()}%');
  },
  // ...更多配置
)
```

### 3. 主题切换 / Theme Switch

```dart
ChartThemeManager.setTheme(ChartTheme.dark); // Dark
ChartThemeManager.setTheme(ChartTheme.light); // Light
ChartThemeManager.toggleTheme(); // Toggle
```

### 4. 程序化控制 / Programmatic Control

```dart
await _controller.zoomIn(factor: 1.2);
await _controller.zoomOut(factor: 1.2);
await _controller.scaleTo(2.0);
await _controller.resetScale();
_controller.saveScaleState();
await _controller.restoreScaleState();
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

## 🖌️ 绘图工具（开发中）/ Drawing Tools (WIP)

- 趋势线、角度线、箭头、标注、斐波那契等

---

## 🏆 商用声明 / Commercial Statement

- **第一个 Flutter 生态正式商用 K线库**
- 完全开源 MIT，免费商用
- 持续维护，欢迎 PR/Issue

---

## 🤝 社区与支持 / Community & Support

- [GitHub](https://github.com/Er-Dong-Chen/flutter_chen_kchart)
- Issue/PR/Discussions 欢迎参与

---

## 📢 结语 / Final Words

> Flutter 终于有了真正可商用的 K线图表库！  
> 不再需要 WebView，不再被 TradingView 限制。  
> 让你的 Flutter 金融应用更专业、更流畅！

---

如需更详细的文档、示例和高级用法，请查阅源码和 example 目录。

如果你满意这个库，请在 GitHub 上点个 Star，欢迎转发推荐给更多 Flutter 开发者！
