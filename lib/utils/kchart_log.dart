import 'dart:developer' as developer;

const String _kChartLogName = 'Flutter_Chen_Kchart';

void kchartLog(
  Object? message, {
  int level = 0,
  Object? error,
  StackTrace? stackTrace,
}) {
  developer.log(
    message?.toString() ?? '',
    name: _kChartLogName,
    level: level,
    error: error,
    stackTrace: stackTrace,
  );
}
