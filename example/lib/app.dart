import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/login_page.dart';
import 'strings.dart';

/// The app theme. Arabic uses Cairo; other locales use the platform font.
ThemeData buildTheme(Brightness brightness, Locale locale) {
  return ThemeData(
    brightness: brightness,
    colorSchemeSeed: const Color(0xFF0E7C86),
    fontFamily: locale.languageCode == 'ar' ? 'Cairo' : null,
  );
}

/// The app shell, shared by `main()` and the screenshot tests.
class ExampleApp extends StatelessWidget {
  const ExampleApp({
    super.key,
    this.home = const LoginPage(),
    this.locale,
    this.themeMode = ThemeMode.system,
  });

  final Widget home;
  final Locale? locale;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final Locale effective =
        locale ?? WidgetsBinding.instance.platformDispatcher.locale;
    return MaterialApp(
      title: 'Screenshot matrix example',
      locale: locale,
      supportedLocales: Strings.supported,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: themeMode,
      theme: buildTheme(Brightness.light, effective),
      darkTheme: buildTheme(Brightness.dark, effective),
      home: home,
    );
  }
}
