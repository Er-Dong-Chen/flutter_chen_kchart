import 'package:flutter/widgets.dart';
import 'package:flutter_chen_kchart/chart_translations.dart';

extension ChartTranslationsMap on Map<String, ChartTranslations> {
  ChartTranslations of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final languageTag = '${locale.languageCode}_${locale.countryCode}';

    return this[languageTag] ?? ChartTranslations();
  }
}
