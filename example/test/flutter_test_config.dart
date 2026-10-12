import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenshot_matrix/flutter_screenshot_matrix.dart';
import 'package:screenshot_matrix_example/app.dart';

/// Runs before every test file: one place for the app shell and the matrix.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ScreenshotMatrixDefaults.wrap = (Widget child, ScreenshotContext ctx) =>
      ExampleApp(home: child, locale: ctx.locale, themeMode: ctx.themeMode);
  ScreenshotMatrixDefaults.devices = const <Device>[
    Device.iphoneSE,
    Device.iphone15ProMax,
    Device.pixel7,
    Device.galaxyA14,
    Device.ipad11,
  ];
  ScreenshotMatrixDefaults.locales = const <Locale>[Locale('en'), Locale('ar')];
  ScreenshotMatrixDefaults.themes = const <ThemeMode>[
    ThemeMode.light,
    ThemeMode.dark,
  ];
  ScreenshotMatrixDefaults.textScales = const <double>[1.0, 1.3];
  ScreenshotMatrixDefaults.galleryTitle = 'Example app';
  await testMain();
}
