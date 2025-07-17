# K线图主题系统演示应用

这是一个完整的K线图主题系统演示应用，展示了所有新功能的使用方法。

## 主要功能

### 🎨 主题系统
- **亮色/暗色主题切换**：支持实时切换主题
- **主题系统开关**：可以启用或禁用主题系统
- **自动主题适配**：UI元素自动适配当前主题

### 📊 数据源
- **币安API集成**：使用币安官方API获取实时数据
- **多交易对支持**：BTCUSDT、ETHUSDT、BNBUSDT、ADAUSDT、DOTUSDT
- **多时间周期**：1m、3m、5m、15m、30m、1h、2h、4h、6h、8h、12h、1d、3d、1w、1M
- **深度图数据**：实时获取买卖盘深度数据

### 🔧 图表功能
- **分时/K线切换**：支持分时图和K线图切换
- **技术指标**：MA、BOLL、MACD、KDJ、RSI、WR、CCI
- **成交量显示**：可显示/隐藏成交量
- **网格显示**：可显示/隐藏网格线
- **现价显示**：可显示/隐藏当前价格线
- **趋势线**：支持趋势线绘制
- **信息窗口**：点击显示详细信息

### 🎯 自定义功能
- **自定义UI**：一键切换自定义颜色和样式
- **样式重置**：快速重置为默认样式
- **copyWith方法**：基于现有主题创建自定义配置

## 界面说明

### 顶部工具栏
- **主题切换按钮**：在亮色和暗色主题之间切换
- **主题系统开关**：启用或禁用主题系统

### 控制面板
- **交易对选择**：下拉选择不同的交易对
- **时间周期选择**：下拉选择不同的时间周期
- **功能按钮**：各种图表功能的开关按钮
- **主题信息显示**：显示当前主题状态

### 图表区域
- **K线图/分时图**：主要的图表显示区域
- **深度图**：买卖盘深度显示
- **加载指示器**：数据加载时显示

## 使用方法

### 1. 运行应用
```bash
cd modules/k_chart/example
flutter run
```

### 2. 基本操作
- 点击顶部的主题切换按钮切换亮色/暗色主题
- 点击主题系统开关启用或禁用主题系统
- 使用下拉菜单选择不同的交易对和时间周期
- 点击功能按钮切换各种图表功能

### 3. 自定义操作
- 点击"自定义UI"按钮应用自定义颜色和样式
- 点击"重置样式"按钮恢复默认设置

## 技术特性

### 主题系统集成
```dart
// 启用主题系统
KChartWidget(
  data,
  enableTheme: true, // 使用主题系统颜色
)

// 禁用主题系统，使用自定义颜色
KChartWidget(
  data,
  enableTheme: false,
  chartColors: customColors,
  chartStyle: customStyle,
)
```

### 币安API集成
```dart
// K线数据
final url = 'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=$interval&limit=500';

// 深度数据
final url = 'https://api.binance.com/api/v3/depth?symbol=$symbol&limit=100';
```

### 主题管理
```dart
// 切换主题
ChartThemeManager.toggleTheme();

// 获取当前主题颜色
ChartColors colors = ChartThemeManager.getColors();
```

## 文件结构

```
example/
├── lib/
│   └── main.dart              # 主应用文件
├── pubspec.yaml               # 依赖配置
├── assets/                    # 资源文件
│   ├── depth.json            # 深度数据示例
│   └── chatData.json         # K线数据示例
└── README.md                 # 本文档
```

## 依赖项

- `flutter`: Flutter框架
- `http`: HTTP请求库
- `k_chart`: K线图组件库

## 注意事项

1. **网络连接**：需要网络连接才能获取币安API数据
2. **API限制**：币安API有请求频率限制，请合理使用
3. **主题切换**：主题切换会立即生效，无需重启应用
4. **数据更新**：切换交易对或时间周期会自动重新获取数据

## 扩展功能

### 添加新的交易对
在`_symbols`列表中添加新的交易对：
```dart
final List<String> _symbols = ['BTCUSDT', 'ETHUSDT', 'NEWPAIR'];
```

### 添加新的时间周期
在`_intervals`列表中添加新的时间周期：
```dart
final List<String> _intervals = ['1m', '5m', 'NEWINTERVAL'];
```

### 自定义颜色方案
使用`copyWith`方法创建自定义颜色：
```dart
ChartColors.light().copyWith(
  kLineColor: Colors.red,
  upColor: Colors.green,
  dnColor: Colors.red,
)
```

## 故障排除

### 数据加载失败
- 检查网络连接
- 确认币安API服务正常
- 查看控制台错误信息

### 主题不生效
- 确认`enableTheme`参数设置正确
- 检查`ChartThemeManager`是否正确导入
- 确认主题切换后调用了`setState()`

### 样式异常
- 检查`chartColors`和`chartStyle`参数
- 确认颜色值格式正确
- 验证样式参数范围
