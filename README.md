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

### [🌐 App演示 / App Demo](https://www.pgyer.com/kchart-android)

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

## 📋 版本说明 / Version Description

<table>
<tr>
<th width="50%">🆓 免费版本 1.x / Free Version</th>
<th width="50%">💼 商用版本 2.x / Commercial Version</th>
</tr>
<tr>
<td>
<strong>开源免费，MIT 许可</strong><br>
• 基础 K线图表功能<br>
• 基础主题及配置<br>
• 基础技术指标<br>
• 基础交互体验<br>
• 基础性能模式<br>
• 社区支持
</td>
<td>
<strong>商业许可，付费使用</strong><br>
• 全部 1.x 功能<br>
• 高级技术指标<br>
• 专业绘图工具套件<br>
• 高度定制，灵活配置<br>
• TradingView 级交互体验<br>
• 性能优化模式<br>
• 优先技术支持<br>
• 商业授权保障
</td>
</tr>
</table>

---

## ✨ 功能对比 / Feature Comparison

| 功能特性 / Features                     | 免费版 1.x | 商用版 2.x |
|-------------------------------------|:---------:|:---------:|
| **基础功能 / Basic**                    |||
| K线图表 / Candlestick Chart            | ✅ | ✅ |
| 多平台支持 / Cross-Platform              | ✅ | ✅ |
| 双指缩放 / Pinch Zoom                   | ✅ | ✅ |
| 滚轮缩放 / Mouse Wheel Zoom             | ✅ | ✅ |
| 平移 / Pan                            | ✅ | ✅ |
| 长按详情 / Long Press Details           | ✅ | ✅ |
| 点击显示详情 / Click Details              | ✅ | ✅ |
| 实时价格显示 / Real-time Price            | ✅ | ✅ |
| **主题系统 / Theme**                    |||
| 基础亮/暗主题                             | ✅ | ✅ |
| 主题管理器 / Theme Manager               | ✅ | ✅ |
| 主题切换功能 / Theme Toggle               | ✅ | ✅ |
| 高级主题定制                              | ✅ | ✅ |
| 多主题预设                               | ✅ | ✅ |
| **UI 定制 / UI Customization**        |||
| 颜色自定义 / Color Customization         | ✅ | ✅ |
| 网格显示/隐藏 / Grid Toggle               | ✅ | ✅ |
| 详情对话框自定义 / Custom Dialog            | ✅ | ✅ |
| 成交量隐藏 / Hidden Volume               | ✅ | ✅ |
| 更多灵活配置 / Front Padding              | ❌ | ✅ |
| **技术指标 / Indicators**               |||
| MA（移动平均线）                           | ✅ | ✅ |
| BOLL（布林带）                           | ✅ | ✅ |
| MACD                                | ✅ | ✅ |
| KDJ                                 | ✅ | ✅ |
| RSI                                 | ✅ | ✅ |
| WR（威廉指标）                            | ✅ | ✅ |
| CCI                                 | ✅ | ✅ |
| **智能交互 / Smart Interaction**        |||
| 智能十字线 / Intelligent Crosshair       | ❌ | ✅ |
| 震动反馈 / Vibration Feedback           | ❌ | ✅ |
| 十字线标签波动范围 / Crosshair Range         | ❌ | ✅ |
| 十字线标签回调 / Crosshair Callback        | ❌ | ✅ |
| 快速下单 / Quick Order Placement        | ❌ | ✅ |
| TradingView交互优化 / Enhanced Gestures | ❌ | ✅ |
| **绘图工具 / Drawing Tools**            |||
| 趋势线/趋势角度 / Trend Line               | ❌ | ✅ |
| 水平线/垂直线 / H/V Lines                 | ❌ | ✅ |
| 射线/水平射线 / Ray                       | ❌ | ✅ |
| 箭头标注 / Arrow Annotation             | ❌ | ✅ |
| 十字线 / Crosshair Tool                | ❌ | ✅ |
| **绘图模式 / Drawing Modes**            |||
| 单次绘制 / Single Draw                  | ❌ | ✅ |
| 连续绘制 / Continuous Draw              | ❌ | ✅ |
| 精确控制 / Precise Control              | ❌ | ✅ |
| 显示隐藏 / Show/Hide                    | ❌ | ✅ |
| 清除绘图 / Batch Clear                  | ❌ | ✅ |
| 磁铁吸附 / Magnetic Snap                | ❌ | ✅ |
| **性能优化 / Performance**              |||
| 基础性能优化 / Basic Optimization         | ✅ | ✅ |
| Web 性能优化 / Web Optimization         | ✅ | ✅ |
| 大数据集支持 / Large Dataset              | 基础 | 增强 |
| 性能优化模式 / Performance Mode           | ❌ | ✅ |
| **支持服务 / Support**                  |||
| 社区支持 / Community Support            | ✅ | ✅ |
| 优先技术支持 / Priority Support           | ❌ | ✅ |
| 商业授权保障 / Commercial License         | ❌ | ✅ |
| 终身源码授权 / Lifetime Source            | ❌ | 可选 |****

---

## 💰 商用版获取 / Get Commercial Version

### 📞 联系方式 / Contact

- 💬 **微信咨询**：`Chen-Taurus-0510`
- 📧 **邮箱联系**：`1251752648@qq.com`
- 🐛 **GitHub Issues**：[技术问题讨论](https://github.com/Er-Dong-Chen/flutter_chen_kchart/issues)

---

## 📚 文档与示例 / Documentation

- 📖 **[API 文档](https://pub.dev/documentation/flutter_chen_kchart/latest/)**
- 🎨 **[绘图工具指南](DRAWING_TOOLS_GUIDE.md)** *(商用版)*
- 💡 **[示例代码](https://github.com/Er-Dong-Chen/flutter_chen_kchart/tree/main/example)**

---

## 🤝 社区与支持 / Community & Support

- 🌟 **[GitHub](https://github.com/Er-Dong-Chen/flutter_chen_kchart)** - Star 支持我们
- 🐛 **[Issues](https://github.com/Er-Dong-Chen/flutter_chen_kchart/issues)** - Bug 反馈
- 💬 **[Discussions](https://github.com/Er-Dong-Chen/flutter_chen_kchart/discussions)** - 功能讨论
- 📱 **微信群** - 添加微信 备注"入群"

---

## 🎯 路线图 / Roadmap

### v2.x 商用版计划
- [x] v2.0.0 - 绘图工具及模式套件、TradingView交互体验
- [x] 绘图新增完善
- [ ] 高级技术指标
- [ ] 完全对标TradingView/主流交易所KChart

---

## 捐赠支持 / Donation Support

如果免费版对你有帮助，欢迎捐赠支持开发：

<div style="display: flex; justify-content: space-between;">
  <img src="https://er-dong-chen.github.io/images/wechat.png" alt="微信赞赏" style="width: 48%;">
  <img src="https://er-dong-chen.github.io/images/alipay.png" alt="支付宝捐赠" style="width: 48%;">
</div>

---

## 📜 许可证 / License

- **免费版 1.x**: [MIT License](LICENSE)
- **商用版 2.x**: 商业许可证 + 技术支持

---

## 📢 结语 / Final Words

> 🎉 **Flutter 终于有了真正可商用的 K线图表库！**
>
> 🚀 **不再需要 WebView，不再被 TradingView 限制**
>
> 💪 **让你的 Flutter 金融应用更专业、更流畅！**

### 立即开始 / Get Started Now

1. ⭐ **GitHub Star** 支持我们
2. 📦 **安装免费版** 体验功能
3. 💬 **联系我们** 获取商用版
4. 🚀 **构建你的** 专业金融应用

---

**Made with ❤️ by Flutter Community**

*如果这个库对你有帮助，请在 GitHub 上给我们一个 Star ⭐*
