# K-Chart 绘图工具使用指南

## 📝 概述

K-Chart 绘图工具库提供了专业的技术分析绘图功能，采用TradingView风格的交互体验，支持多种绘图工具和智能交互模式。库基于Flutter Canvas技术，提供高性能的实时绘图能力。

## 🎯 核心功能

### 绘图工具类型

- **📈 趋势线 (TrendLine)**: 连接两个价格点的直线，支持延伸
- **📐 趋势角度 (TrendAngle)**: 带角度显示的趋势线，显示倾斜角度
- **🔗 箭头 (Arrow)**: 方向性标记箭头，用于标注重要点位
- **📏 垂直线 (VerticalLine)**: 垂直时间线，标记时间节点
- **➖ 水平线 (HorizontalLine)**: 水平价格线，标记关键价位
- **📡 水平射线 (HorizontalRay)**: 水平延伸射线，支持单向延伸
- **🔦 射线 (Ray)**: 从起点延伸的射线
- **✚ 十字线 (CrossLine)**: 十字标记，用于精确定位

### 高级交互模式

- **🎯 TradingView风格十字线**: 专业的橙色虚线十字线，实时位置提示
- **🔄 连续绘制模式**: 绘制完成后自动继续使用同一工具
- **🧲 磁铁吸附模式**: 自动吸附到K线的关键数据点（开高低收）
- **👁️ 显示隐藏切换**: 一键显示/隐藏所有绘图内容
- **🗑️ 智能删除功能**: 支持单个删除和批量清除
- **✏️ 实时编辑**: 选中工具后可修改样式属性
- **💾 状态持久化**: 绘图数据支持序列化保存和恢复

## 🚀 快速开始

### 1. 基本集成

```dart
import 'package:k_chart/k_chart.dart';

class MyChart extends StatefulWidget {
  @override
  _MyChartState createState() => _MyChartState();
}

class _MyChartState extends State<MyChart> {
  late DrawingToolManager _drawingToolManager;

  @override
  void initState() {
    super.initState();

    // 创建绘图工具管理器
    _drawingToolManager = DrawingToolManager();

    // 设置事件回调
    _drawingToolManager.onToolsChanged = () {
      setState(() {}); // 刷新UI以反映工具变化
    };

    _drawingToolManager.onToolSelected = (tool) {
      print('选中工具: ${tool?.displayName}');
    };
  }

  @override
  Widget build(BuildContext context) {
    return KChartWidget(
      data: klineData, // 您的K线数据
      enableDrawingTools: true, // 启用绘图工具
      drawingToolManager: _drawingToolManager, // 传入管理器
      // ... 其他K线图参数
    );
  }
}
```

### 2. 完整的工具栏UI实现

```dart
Widget _buildDrawingToolbar() {
  return Container(
    padding: EdgeInsets.all(8.0),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Column(
      children: [
        // 模式控制区
        Row(
          children: [
            // 绘图模式总开关
            Switch(
              value: _drawingToolManager.modeManager.isDrawingModeEnabled,
              onChanged: (value) {
                _drawingToolManager.modeManager.setDrawingMode(value);
                setState(() {});
              },
            ),
            Text('绘图模式'),
            SizedBox(width: 16),

            // 连续绘制模式
            Switch(
              value: _drawingToolManager.modeManager.isContinuousMode,
              onChanged: (value) {
                _drawingToolManager.modeManager.setContinuousMode(value);
                setState(() {});
              },
            ),
            Text('连续绘制'),
            SizedBox(width: 16),

            // 磁铁吸附模式
            Switch(
              value: _drawingToolManager.modeManager.isMagnetMode,
              onChanged: (value) {
                _drawingToolManager.modeManager.setMagnetMode(value);
                setState(() {});
              },
            ),
            Text('磁铁吸附'),
          ],
        ),

        SizedBox(height: 8),

        // 工具选择区
        Wrap(
          spacing: 8.0,
          children: DrawingToolType.values.map((toolType) {
            final isSelected = _drawingToolManager.currentToolType == toolType;
            return ElevatedButton.icon(
              onPressed: () => _toggleDrawingTool(toolType),
              icon: Icon(_getToolIcon(toolType)),
              label: Text(_getToolDisplayName(toolType)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                foregroundColor: isSelected ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ),

        SizedBox(height: 8),

        // 操作控制区
        Row(
          children: [
            // 样式设置
            _buildColorPicker(),
            SizedBox(width: 8),
            _buildStrokeWidthSlider(),
            Spacer(),

            // 操作按钮
            IconButton(
              onPressed: _deleteSelectedDrawing,
              icon: Icon(Icons.delete),
              tooltip: '删除选中',
            ),
            IconButton(
              onPressed: _clearAllDrawings,
              icon: Icon(Icons.clear_all),
              tooltip: '清除全部',
            ),
          ],
        ),
      ],
    ),
  );
}

void _toggleDrawingTool(DrawingToolType toolType) {
  if (_drawingToolManager.currentToolType == toolType) {
    // 取消当前工具
    _drawingToolManager.setCurrentToolType(null);
    _drawingToolManager.modeManager.setDrawingMode(false);
  } else {
    // 选择新工具
    _drawingToolManager.setCurrentToolType(toolType);
    _drawingToolManager.modeManager.setDrawingMode(true);
  }
  setState(() {});
}

Widget _buildColorPicker() {
  return DropdownButton<Color>(
    value: _drawingToolManager.currentColor,
    items: [
      Colors.orange,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
    ].map((color) => DropdownMenuItem(
      value: color,
      child: Container(
        width: 20,
        height: 20,
        color: color,
      ),
    )).toList(),
    onChanged: (color) {
      if (color != null) {
        _drawingToolManager.setCurrentColor(color);
        setState(() {});
      }
    },
  );
}

Widget _buildStrokeWidthSlider() {
  return SizedBox(
    width: 100,
    child: Slider(
      value: _drawingToolManager.currentStrokeWidth,
      min: 1.0,
      max: 5.0,
      divisions: 4,
      label: '${_drawingToolManager.currentStrokeWidth.toInt()}px',
      onChanged: (value) {
        _drawingToolManager.setCurrentStrokeWidth(value);
        setState(() {});
      },
    ),
  );
}
```

## 📱 TradingView风格交互详解

### 专业十字线系统
采用橙色虚线十字线，提供清晰的位置指示：

- **视觉设计**: 橙色虚线 + 中心圆点 + 外圈边框
- **状态提示**: 动态显示"选择起点"、"选择终点"等文字提示
- **实时跟随**: 十字线随手势或鼠标实时移动
- **精确定位**: 点击位置基于十字线中心确定

### 单点工具交互流程
```
1. 选择工具 → 十字线出现 + "选择位置"提示
2. 移动定位 → 十字线实时跟随手势
3. 点击确认 → 完成绘图，十字线消失
```

### 双点工具交互流程
```
1. 选择工具 → 十字线出现 + "选择起点"提示
2. 移动定位起点 → 十字线跟随
3. 点击确认起点 → 提示变为"选择终点"
4. 移动定位终点 → 十字线跟随 + 实时预览线条
5. 点击确认终点 → 完成绘图，十字线消失
```

### 工具选择和编辑
```
1. 普通模式 → 点击工具可选中并显示高亮
2. 选中状态 → 可修改颜色、线条粗细等属性
3. 拖拽移动 → 支持整体移动工具位置
4. 删除操作 → 选中后可单独删除
```

## 🔧 完整API参考

### DrawingToolManager 核心方法

```dart
// ==== 工具类型管理 ====
drawingToolManager.setCurrentToolType(DrawingToolType.trendLine); // 设置当前工具
drawingToolManager.setCurrentToolType(null); // 取消选择
DrawingToolType? currentTool = drawingToolManager.currentToolType; // 获取当前工具

// ==== 工具实例管理 ====
drawingToolManager.clearAllTools(); // 清除所有工具
drawingToolManager.deleteSelectedTool(); // 删除选中的工具
drawingToolManager.selectTool(position); // 选择指定位置的工具
List<DrawingTool> allTools = drawingToolManager.tools; // 获取所有工具列表

// ==== 绘图流程控制 ====
drawingToolManager.startDrawing(toolType, point, kLineData); // 开始绘制
drawingToolManager.updateDrawing(point, kLineData); // 更新绘制
drawingToolManager.finishDrawing(); // 完成绘制
drawingToolManager.cancelDrawing(); // 取消绘制

// ==== 样式设置 ====
drawingToolManager.setCurrentColor(Colors.red); // 设置绘图颜色
drawingToolManager.setCurrentStrokeWidth(2.5); // 设置线条粗细
Color currentColor = drawingToolManager.currentColor; // 获取当前颜色
double strokeWidth = drawingToolManager.currentStrokeWidth; // 获取当前线宽

// ==== 状态查询 ====
bool isDrawingMode = drawingToolManager.modeManager.isDrawingModeEnabled;
DrawingTool? selectedTool = drawingToolManager.selectedTool;
DrawingTool? currentDrawing = drawingToolManager.currentDrawingTool;
```

### DrawingModeManager 模式管理

```dart
// ==== 绘图模式总开关 ====
drawingToolManager.modeManager.setDrawingMode(true); // 启用绘图模式
drawingToolManager.modeManager.toggleDrawingMode(); // 切换绘图模式
bool isEnabled = drawingToolManager.modeManager.isDrawingModeEnabled;

// ==== 连续绘制模式 ====
drawingToolManager.modeManager.setContinuousMode(true); // 启用连续绘制
drawingToolManager.modeManager.toggleContinuousMode(); // 切换连续绘制
bool isContinuous = drawingToolManager.modeManager.isContinuousMode;

// ==== 磁铁吸附模式 ====
drawingToolManager.modeManager.setMagnetMode(true); // 启用磁铁吸附
drawingToolManager.modeManager.toggleMagnetMode(); // 切换磁铁吸附
bool isMagnet = drawingToolManager.modeManager.isMagnetMode;

// ==== 模式描述 ====
String description = drawingToolManager.modeManager.getModeDescription(); // 获取当前模式描述
```

### 事件回调系统

```dart
// ==== 工具变化监听 ====
drawingToolManager.onToolsChanged = () {
  print('绘图工具列表发生变化');
  setState(() {}); // 刷新UI
};

// ==== 工具选择监听 ====
drawingToolManager.onToolSelected = (DrawingTool? tool) {
  if (tool != null) {
    print('选中工具: ${tool.displayName}');
    print('工具颜色: ${tool.color}');
    print('线条粗细: ${tool.strokeWidth}');
  } else {
    print('取消选择工具');
  }
};

// ==== 绘图位置监听 ====
drawingToolManager.onDrawingPositionChanged = (Offset? position) {
  if (position != null) {
    print('绘图位置: ${position.dx}, ${position.dy}');
  }
};

// ==== 模式变化监听 ====
drawingToolManager.modeManager.onModeChanged = () {
  print('绘图模式发生变化');
  print(drawingToolManager.modeManager.getModeDescription());
};
```

### DrawingTool 工具属性

```dart
// 每个绘图工具都包含以下属性：
DrawingTool tool = drawingToolManager.selectedTool!;

// ==== 基础属性 ====
String id = tool.id; // 唯一标识符
DrawingToolType type = tool.type; // 工具类型
DateTime createTime = tool.createTime; // 创建时间
Color color = tool.color; // 颜色
double strokeWidth = tool.strokeWidth; // 线条粗细
bool isVisible = tool.isVisible; // 是否可见
DrawingToolState state = tool.state; // 工具状态

// ==== 显示信息 ====
String displayName = tool.displayName; // 显示名称（中文）
IconData icon = tool.icon; // 对应图标

// ==== 状态方法 ====
bool isComplete = tool.isComplete; // 是否绘制完成
Rect bounds = tool.getBounds(); // 获取边界框
bool hitTest = tool.hitTest(point); // 点击检测
tool.move(offset); // 移动工具

// ==== 序列化 ====
Map<String, dynamic> json = tool.toJson(); // 导出为JSON
DrawingTool? restored = DrawingTool.fromJson(json); // 从JSON恢复
```

## ⚙️ 高级配置

### 自定义绘图样式

```dart
// 全局默认样式
drawingToolManager.setCurrentColor(const Color(0xFFFFD700)); // 金色
drawingToolManager.setCurrentStrokeWidth(2.0);

// 工具特定样式（选中工具后修改）
if (drawingToolManager.selectedTool != null) {
  drawingToolManager.selectedTool!.color = Colors.red;
  drawingToolManager.selectedTool!.strokeWidth = 3.0;
}
```

### 磁铁吸附配置

```dart
// 启用磁铁模式后，绘图点会自动吸附到：
// - K线的开盘价
// - K线的最高价
// - K线的最低价
// - K线的收盘价

drawingToolManager.modeManager.setMagnetMode(true);
```

### 数据持久化

```dart
// 导出所有绘图数据
List<Map<String, dynamic>> exportData = drawingToolManager.tools
    .map((tool) => tool.toJson())
    .toList();

// 保存到本地存储
await prefs.setString('drawing_tools', jsonEncode(exportData));

// 恢复绘图数据
String? savedData = prefs.getString('drawing_tools');
if (savedData != null) {
  List<dynamic> toolList = jsonDecode(savedData);
  for (var toolData in toolList) {
    DrawingTool? tool = DrawingTool.fromJson(toolData);
    if (tool != null) {
      drawingToolManager.addTool(tool);
    }
  }
}
```

## 🎨 最佳实践

### 1. 状态管理
```dart
// 推荐在StatefulWidget中管理绘图状态
class ChartPage extends StatefulWidget {
  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  late DrawingToolManager _drawingToolManager;

  @override
  void initState() {
    super.initState();
    _setupDrawingManager();
  }

  void _setupDrawingManager() {
    _drawingToolManager = DrawingToolManager();
    _drawingToolManager.onToolsChanged = () => setState(() {});
  }
}
```

### 2. 用户体验优化
```dart
// 自动显示帮助提示
void _showDrawingHint(DrawingToolType toolType) {
  String hint = '';
  switch (toolType) {
    case DrawingToolType.trendLine:
      hint = '点击选择起点，再点击选择终点';
      break;
    case DrawingToolType.horizontalLine:
      hint = '点击选择水平线的价格位置';
      break;
    // ... 其他工具提示
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(hint), duration: Duration(seconds: 2)),
  );
}
```

### 3. 性能优化
```dart
// 限制绘图工具数量，避免性能问题
const int MAX_TOOLS = 50;

void _addToolWithLimit(DrawingTool tool) {
  if (drawingToolManager.tools.length >= MAX_TOOLS) {
    drawingToolManager.removeOldestTool(); // 移除最早的工具
  }
  drawingToolManager.addTool(tool);
}
```

### 4. 错误处理
```dart
try {
  drawingToolManager.setCurrentToolType(DrawingToolType.trendLine);
} catch (e) {
  print('设置绘图工具失败: $e');
  // 显示错误提示给用户
}
```

## 🐛 常见问题

### Q: 绘图工具无法显示？
**A**: 检查以下设置：
```dart
// 1. 确保启用了绘图工具
KChartWidget(
  enableDrawingTools: true, // ✅ 必须设置为true
  drawingToolManager: _drawingToolManager, // ✅ 必须传入管理器
)

// 2. 确保启用了绘图模式
_drawingToolManager.modeManager.setDrawingMode(true);

// 3. 确保选择了工具类型
_drawingToolManager.setCurrentToolType(DrawingToolType.trendLine);
```

### Q: 十字线不显示？
**A**: 十字线只在绘图过程中显示：
```dart
// 选择工具后，十字线会自动出现
_drawingToolManager.setCurrentToolType(DrawingToolType.trendLine);
// 绘图完成后，十字线会自动消失
```

### Q: 磁铁吸附不工作？
**A**: 确保启用磁铁模式且有K线数据：
```dart
_drawingToolManager.modeManager.setMagnetMode(true);
// 需要确保传入了有效的K线数据
```

### Q: 绘图工具无法选中？
**A**: 检查绘图模式状态：
```dart
// 关闭绘图模式才能选中已有工具
_drawingToolManager.modeManager.setDrawingMode(false);
// 然后点击工具进行选择
```

## 🔗 相关资源

- **核心文件**: `lib/utils/drawing_tool_manager.dart`
- **工具实体**: `lib/entity/drawing_tool_entity.dart`
- **十字线组件**: `lib/widget/drawing_crosshair.dart`
- **示例代码**: `example/lib/widget.dart`

---

> 💡 **提示**: 这个绘图工具库采用了专业的技术分析软件交互模式，为用户提供直观、精确的绘图体验。建议结合示例代码进行学习和实践。