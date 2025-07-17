import 'package:example/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_chen_kchart/k_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        title: 'BTC K线演示',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const KChartPage(),
      ),
    );
  }
}

class KChartPage extends StatefulWidget {
  const KChartPage({super.key});

  @override
  State<KChartPage> createState() => _KChartPageState();
}

class _KChartPageState extends State<KChartPage> {
  // 主题状态
  bool _isDarkTheme = false;

  // 主题切换方法
  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
      // 切换ChartThemeManager的主题
      if (_isDarkTheme) {
        ChartThemeManager.setTheme(ChartTheme.dark);
      } else {
        ChartThemeManager.setTheme(ChartTheme.light);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KChart演示'),
        actions: [
          // 主题切换按钮
          GestureDetector(
            onTap: _toggleTheme,
            child: Container(
              margin: EdgeInsets.only(right: 16.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _isDarkTheme ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: _isDarkTheme ? Colors.grey[600]! : Colors.grey[400]!,
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                    size: 18.sp,
                    color: _isDarkTheme ? Colors.white : Colors.grey[700],
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    _isDarkTheme ? '暗色' : '亮色',
                    style: TextStyle(
                      color: _isDarkTheme ? Colors.white : Colors.grey[700],
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: KChartView(
          height: double.infinity,
          symbol: "BTCUSDT",
          isDarkTheme: _isDarkTheme,
        ),
      ),
    );
  }
}
