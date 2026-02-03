## 3.0.0
* Chore: Optimize and restructure the graphics
* Improved: Optimize the drawing tools
* Improved: Optimize drawing and plotting
* Added: Drawing Floating Toolbar Settings
* Added: Drawing lines move and reposition to the initial position

## 2.8.0
* Improved: style

## 2.7.0
* Improved: scaleSensitivity

## 2.6.0
* Added: watermark

## 2.5.0
* Fixed: Optimize gestures

## 2.4.0
* Fixed: Drawing content no longer displays outside the KChart area into indicator regions
* Improved: Drawing boundary detection and clipping for better visual consistency

## 2.3.0
* Improved: Trend angle drawing style optimization for enhanced precision
* Improved: Horizontal ray style synchronized with mainstream trading platforms
* Enhanced: Visual consistency with professional trading interfaces

## 2.2.0
* Enhanced: Drawing content now moves and scales seamlessly with chart interactions
* Improved: Synchronized drawing tool transformations with chart zoom and pan
* Added: Dynamic drawing content positioning that follows chart movements

## 2.1.0
* Fixed: KChart intelligently displays the date and time format of the selected information according to the cycle
* Changed: The kchart price tag is displayed on the right side

## 2.0.0
* Added: Professional drawing tools including Trend Line, Trend Angle, Arrow, Vertical Line, Horizontal Line, Horizontal Ray, Ray, and Cross Line
* Added: Interactive modes for drawing tools: TradingView-style crosshair selection, continuous drawing mode, magnet snapping mode, show/hide drawings, clear all drawings, and precise positioning control
* Added: Vibration feedback during interactions
* Added: Cross line label that indicates the fluctuation range
* Added: Click callback on cross line label for quick order placement

## 1.2.0
* Improved: Selection line optimization

## 1.1.0
* Improved: Gesture interaction and sensitivity response

## 1.0.0
* Added: Enhanced theme system with light/dark theme support
* Added: Improved gesture interactions with better pinch-to-zoom and scroll zoom
* Added: Theme switching functionality with ChartThemeManager
* Improved: Optimized chart styling and visual appearance
* Improved: Enhanced performance for large datasets
* Improved: Better touch responsiveness and smooth animations
* Fixed: Various UI improvements and bug fixes

## 0.7.1
* Improved: Performance optimization on the web

## 0.7.0
* Added: `xFrontPadding` parameter (padding in front, default 100)
* Fixed: KChart and DepthChart onPress selection when they don't fill the whole screen

## 0.6.1
* Added: `chartColors.lineFillInsideColor` configuration
* Added: `materialInfoDialog` config
* Fixed: Duplicate crossLine and crossLine text rendering

## 0.6.0
* Breaking: Removed `bgColor` API (use `chartColors.bgColor` instead)
* Added: TradeLine support
* Fixed: Data handling when `change` or `radio` properties are missing

## 0.5.0
* Fixed: Vertical text alignment and nullable amount support
* Fixed: NowPrice text painting position
* Added: Click to show detailed data functionality
* Added: View display area boundary value drawing
* Added: Always show the current price

## 0.4.1
* Fixed: NPE bug resolution

## 0.4.0
* Changed: Marker values display direction from right to left
* Changed: UI when gridlines are hidden
* Improved: Real-time prices display
* Added: More configuration options

## 0.3.2
* Added: Show or hide grid functionality
* Changed: Multi-language implementation (please migrate to the new way)
* Changed: KDJ period from 14 to 9

## 0.3.1
* Added: More customizable colors

## 0.3.0
* Breaking: Null safety migration
* Added: Line under Touch Dialog

## 0.2.1
* Fixed: UI issues related to zooming

## 0.2.0
* Added: Real-time price display
* Breaking: Customizable UI for KChartWidget (chartStyle and chartColors must be specified)

## 0.1.4
* Added: onSecondaryTap functionality
* Changed: K-line drawing logic

## 0.1.3
* Added: CCI indicator support

## 0.1.2
* Added: Hidden Volume feature

## 0.1.1
* Added: Initial release
