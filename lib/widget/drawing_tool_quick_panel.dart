import 'package:flutter/material.dart';
import '../chart_style.dart';
import '../entity/drawing_tool_entity.dart';
import '../utils/drawing_tool_manager.dart';

class DrawingToolQuickPanel extends StatefulWidget {
  final DrawingToolManager manager;
  final DrawingTool tool;
  final VoidCallback onDelete;

  const DrawingToolQuickPanel({
    super.key,
    required this.manager,
    required this.tool,
    required this.onDelete,
  });

  @override
  State<DrawingToolQuickPanel> createState() => _DrawingToolQuickPanelState();
}

enum _QuickPopupType { none, color, stroke, style }

class _DrawingToolQuickPanelState extends State<DrawingToolQuickPanel> {
  final _colorKey = GlobalKey();
  final _strokeKey = GlobalKey();
  final _styleKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  _QuickPopupType _popupType = _QuickPopupType.none;

  @override
  void dispose() {
    _hidePopup();
    super.dispose();
  }

  void _hidePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _popupType = _QuickPopupType.none;
  }

  void _togglePopup(_QuickPopupType type) {
    if (_popupType == type) {
      setState(_hidePopup);
      return;
    }
    setState(() {
      _hidePopup();
      _popupType = type;
      _overlayEntry = _buildOverlay(type);
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    });
  }

  OverlayEntry _buildOverlay(_QuickPopupType type) {
    final chartColors = ChartThemeManager.getColors();
    final isDark = ChartThemeManager.currentTheme == ChartTheme.dark;

    final anchorKey = switch (type) {
      _QuickPopupType.color => _colorKey,
      _QuickPopupType.stroke => _strokeKey,
      _QuickPopupType.style => _styleKey,
      _QuickPopupType.none => _colorKey,
    };

    final renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final panelBox = context.findRenderObject() as RenderBox?;
    final overlayBox = Overlay.of(context, rootOverlay: true)
        .context
        .findRenderObject() as RenderBox?;

    final anchor =
        renderBox != null ? renderBox.localToGlobal(Offset.zero) : Offset.zero;
    final anchorSize = renderBox?.size ?? Size.zero;
    final overlaySize = overlayBox?.size ?? MediaQuery.of(context).size;
    final panelOffset = panelBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    final popupSize = switch (type) {
      _QuickPopupType.color => const Size(112, 78),
      _QuickPopupType.stroke => const Size(112, 78),
      _QuickPopupType.style => const Size(120, 86),
      _QuickPopupType.none => const Size(0, 0),
    };

    final left = (anchor.dx + anchorSize.width / 2 - popupSize.width / 2)
        .clamp(8.0, overlaySize.width - popupSize.width - 8.0)
        .toDouble();

    final topPreferred = panelOffset.dy - popupSize.height - 10;
    final top = topPreferred
        .clamp(8.0, overlaySize.height - popupSize.height - 8.0)
        .toDouble();

    return OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(_hidePopup),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: popupSize.width,
            height: popupSize.height,
            child: Material(
              color: Colors.transparent,
              child: _popupCard(
                chartColors: chartColors,
                isDark: isDark,
                child: switch (type) {
                  _QuickPopupType.color => _ColorPopup(
                      current: widget.manager.currentColor,
                      chartColors: chartColors,
                      isDark: isDark,
                      onSelected: (c) {
                        widget.manager.setCurrentColor(c);
                        setState(_hidePopup);
                      },
                    ),
                  _QuickPopupType.stroke => _StrokePopup(
                      current: widget.manager.currentStrokeWidth,
                      color: widget.manager.currentColor,
                      chartColors: chartColors,
                      isDark: isDark,
                      onSelected: (w) {
                        widget.manager.setCurrentStrokeWidth(w);
                        setState(_hidePopup);
                      },
                    ),
                  _QuickPopupType.style => _LineStylePopup(
                      current: widget.manager.currentLineStyle,
                      color: widget.manager.currentColor,
                      strokeWidth: widget.manager.currentStrokeWidth,
                      chartColors: chartColors,
                      isDark: isDark,
                      onSelected: (s) {
                        widget.manager.setCurrentLineStyle(s);
                        setState(_hidePopup);
                      },
                    ),
                  _QuickPopupType.none => const SizedBox.shrink(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _popupCard({
    required ChartColors chartColors,
    required bool isDark,
    required Widget child,
  }) {
    final borderColor =
        chartColors.gridColor.withValues(alpha: isDark ? 0.35 : 0.9);
    return Container(
      decoration: BoxDecoration(
        color: chartColors.selectFillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chartColors = ChartThemeManager.getColors();
    final isDark = ChartThemeManager.currentTheme == ChartTheme.dark;
    final toolbarBg = chartColors.bgColor.isNotEmpty
        ? chartColors.bgColor.first
        : chartColors.selectFillColor;
    final toolbarBorder =
        chartColors.gridColor.withValues(alpha: isDark ? 0.22 : 0.85);
    final toolbarShadowAlpha = isDark ? 0.30 : 0.10;
    final deleteColor = chartColors.defaultTextColor.withValues(alpha: 0.90);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: toolbarBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: toolbarBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: toolbarShadowAlpha),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarIconButton(
              key: _colorKey,
              onTap: () => _togglePopup(_QuickPopupType.color),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.manager.currentColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: toolbarBorder),
                ),
              ),
            ),
            _ToolbarLineButton(
              key: _strokeKey,
              onTap: () => _togglePopup(_QuickPopupType.stroke),
              child: CustomPaint(
                size: const Size(40, 16),
                painter: _LinePreviewPainter(
                  style: DrawingLineStyle.solid,
                  color: widget.manager.currentColor,
                  strokeWidth:
                      widget.manager.currentStrokeWidth.clamp(1.0, 5.0),
                ),
              ),
            ),
            _ToolbarLineButton(
              key: _styleKey,
              onTap: () => _togglePopup(_QuickPopupType.style),
              child: CustomPaint(
                size: const Size(40, 16),
                painter: _LinePreviewPainter(
                  style: widget.manager.currentLineStyle,
                  color: widget.manager.currentColor,
                  strokeWidth:
                      widget.manager.currentStrokeWidth.clamp(1.0, 5.0),
                ),
              ),
            ),
            _ToolbarIconButton(
              onTap: widget.onDelete,
              child: Icon(
                Icons.delete_outline,
                size: 20,
                color: deleteColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _ToolbarIconButton({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Center(child: child),
      ),
    );
  }
}

class _ToolbarLineButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _ToolbarLineButton({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 30,
        width: 56,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _ColorPopup extends StatelessWidget {
  final Color current;
  final ChartColors chartColors;
  final bool isDark;
  final ValueChanged<Color> onSelected;

  const _ColorPopup({
    required this.current,
    required this.chartColors,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      const Color(0xFFFF5252),
      const Color(0xFFFF9800),
      const Color(0xFFFFD700),
      const Color(0xFF00C853),
      const Color(0xFF2962FF),
      const Color(0xFF7C4DFF),
    ];

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Center(
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in colors)
              _ColorSquare(
                color: c,
                selected: c.toARGB32() == current.toARGB32(),
                borderColor: chartColors.selectBorderColor,
                isDark: isDark,
                onTap: () => onSelected(c),
              )
          ],
        ),
      ),
    );
  }
}

class _ColorSquare extends StatelessWidget {
  final Color color;
  final bool selected;
  final Color borderColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ColorSquare({
    required this.color,
    required this.selected,
    required this.borderColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shadowAlpha = isDark ? 0.22 : 0.14;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? borderColor : Colors.transparent,
            width: selected ? 1.0 : 0,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: borderColor.withValues(alpha: shadowAlpha),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _StrokePopup extends StatelessWidget {
  final double current;
  final Color color;
  final ChartColors chartColors;
  final bool isDark;
  final ValueChanged<double> onSelected;

  const _StrokePopup({
    required this.current,
    required this.color,
    required this.chartColors,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [1.0, 3.0, 5.0];
    final selectedWidth = _nearestStroke(items, current);
    final unselectedColor =
        chartColors.defaultTextColor.withValues(alpha: isDark ? 0.85 : 0.75);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final w in items) ...[
            InkWell(
              onTap: () => onSelected(w),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(double.infinity, 10),
                    painter: _StrokePreviewPainter(
                      color: w.roundToDouble() == selectedWidth.roundToDouble()
                          ? color
                          : unselectedColor,
                      strokeWidth: w,
                    ),
                  ),
                ),
              ),
            ),
            if (w != items.last) const SizedBox(height: 3),
          ]
        ],
      ),
    );
  }

  double _nearestStroke(List<double> options, double value) {
    if (options.isEmpty) return value;
    var best = options.first;
    var bestDist = (best - value).abs();
    for (final v in options.skip(1)) {
      final d = (v - value).abs();
      if (d < bestDist || (d == bestDist && v > best)) {
        best = v;
        bestDist = d;
      }
    }
    return best;
  }
}

class _StrokePreviewPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _StrokePreviewPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final y = size.height / 2;
    canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), paint);
  }

  @override
  bool shouldRepaint(covariant _StrokePreviewPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

class _LineStylePopup extends StatelessWidget {
  final DrawingLineStyle current;
  final Color color;
  final double strokeWidth;
  final ChartColors chartColors;
  final bool isDark;
  final ValueChanged<DrawingLineStyle> onSelected;

  const _LineStylePopup({
    required this.current,
    required this.color,
    required this.strokeWidth,
    required this.chartColors,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      DrawingLineStyle.solid,
      DrawingLineStyle.dotted,
      DrawingLineStyle.dashed,
    ];
    final unselectedColor =
        chartColors.defaultTextColor.withValues(alpha: isDark ? 0.85 : 0.75);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final s in items) ...[
            InkWell(
              onTap: () => onSelected(s),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(double.infinity, 10),
                    painter: _LinePreviewPainter(
                      style: s,
                      color: s == current ? color : unselectedColor,
                      strokeWidth: strokeWidth.clamp(1.0, 5.0),
                    ),
                  ),
                ),
              ),
            ),
            if (s != items.last) const SizedBox(height: 4),
          ]
        ],
      ),
    );
  }
}

class _LinePreviewPainter extends CustomPainter {
  final DrawingLineStyle style;
  final Color color;
  final double strokeWidth;

  _LinePreviewPainter({
    required this.style,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(4, size.height / 2);
    final end = Offset(size.width - 4, size.height / 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    switch (style) {
      case DrawingLineStyle.solid:
        canvas.drawLine(start, end, paint);
        return;
      case DrawingLineStyle.dashed:
        _drawDashed(canvas, start, end, paint);
        return;
      case DrawingLineStyle.dotted:
        _drawDotted(canvas, start, end, paint);
        return;
    }
  }

  void _drawDashed(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 10.0;
    const dashSpace = 8.0;
    final distance = (end - start).distance;
    if (distance <= 0) return;
    final dir = (end - start) / distance;
    var d = 0.0;
    while (d < distance) {
      final next = (d + dashLength).clamp(0.0, distance).toDouble();
      canvas.drawLine(start + dir * d, start + dir * next, paint);
      d = next + dashSpace;
    }
  }

  void _drawDotted(Canvas canvas, Offset start, Offset end, Paint paint) {
    final distance = (end - start).distance;
    if (distance <= 0) return;
    final dir = (end - start) / distance;
    final dotRadius = (paint.strokeWidth * 0.6).clamp(1.0, 2.2).toDouble();
    final step = (dotRadius * 3.2).clamp(6.0, 12.0).toDouble();
    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    var d = 0.0;
    while (d <= distance) {
      canvas.drawCircle(start + dir * d, dotRadius, dotPaint);
      d += step;
    }
  }

  @override
  bool shouldRepaint(covariant _LinePreviewPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
