import 'package:flutter/material.dart';

import 'device.dart';
import 'manifest.dart';

/// One cell of the matrix: the device, locale, theme and text scale a screen
/// is being rendered with. Passed to the screen builder and the `wrap` shell.
@immutable
class ScreenshotContext {
  /// Creates a context.
  const ScreenshotContext({
    required this.screen,
    required this.device,
    required this.locale,
    required this.themeMode,
    required this.textScale,
  });

  /// The context of the screenshot being taken right now, for hooks that only
  /// receive the `WidgetTester`. `null` outside a matrix test.
  static ScreenshotContext? current;

  /// Font families loaded from the app's pubspec, in declaration order. Pass
  /// them to `ThemeData(fontFamilyFallback: ...)` so glyphs missing from the
  /// main font (Arabic, CJK, emoji...) fall back to another bundled font.
  static List<String> fontFamilyFallback = const <String>[];

  /// The screen name given to `screenshotMatrix`.
  final String screen;

  /// The device being simulated.
  final Device device;

  /// The locale (also set as the platform locale).
  final Locale locale;

  /// The theme mode. `dark` also sets the platform brightness to dark.
  final ThemeMode themeMode;

  /// The text scale factor (also set as the platform text scale).
  final double textScale;

  /// The brightness the platform reports.
  Brightness get brightness =>
      themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;

  /// Whether [locale] is written right-to-left.
  bool get isRtl => rtlLanguages.contains(locale.languageCode);

  /// The text direction of [locale].
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// `en`, `ar`, `pt-BR`...
  String get localeTag => locale.toLanguageTag();

  /// `light`, `dark` or `system`.
  String get themeName => themeMode.name;

  /// File name without extension: `pixel_7__ar__dark__1.3x`.
  String get fileStem =>
      '${device.id}__${localeTag}__${themeName}__${formatTextScale(textScale)}';

  /// Unique id: `login/pixel_7__ar__dark__1.3x`.
  String get id => '${slugify(screen)}/$fileStem';

  /// Human readable label used as the test name.
  String get label =>
      '${device.name} · $localeTag · $themeName · ${formatTextScale(textScale)}';

  @override
  bool operator ==(Object other) =>
      other is ScreenshotContext &&
      other.screen == screen &&
      other.device == device &&
      other.locale == locale &&
      other.themeMode == themeMode &&
      other.textScale == textScale;

  @override
  int get hashCode => Object.hash(screen, device, locale, themeMode, textScale);

  @override
  String toString() => 'ScreenshotContext($id)';
}

/// Expands the matrix into one [ScreenshotContext] per combination, in the
/// order device > locale > theme > text scale. Duplicate values are dropped.
List<ScreenshotContext> expandMatrix({
  required String screen,
  required List<Device> devices,
  required List<Locale> locales,
  required List<ThemeMode> themes,
  required List<double> textScales,
}) {
  void requireNonEmpty(List<Object> values, String name) {
    if (values.isEmpty) {
      throw ArgumentError.value(values, name, 'must not be empty');
    }
  }

  requireNonEmpty(devices, 'devices');
  requireNonEmpty(locales, 'locales');
  requireNonEmpty(themes, 'themes');
  requireNonEmpty(textScales, 'textScales');
  for (final double scale in textScales) {
    if (scale <= 0) {
      throw ArgumentError.value(scale, 'textScales', 'must be positive');
    }
  }
  final Set<String> deviceIds = <String>{};
  for (final Device d in devices) {
    if (!deviceIds.add(d.id)) {
      if (!devices
          .where((Device x) => x.id == d.id)
          .every((Device x) => x == d)) {
        throw ArgumentError.value(
          d.id,
          'devices',
          'two different devices share the id',
        );
      }
    }
  }

  final Set<String> seen = <String>{};
  return <ScreenshotContext>[
    for (final Device device in devices)
      for (final Locale locale in locales)
        for (final ThemeMode theme in themes)
          for (final double scale in textScales)
            if (seen.add(
              '${device.id}|${locale.toLanguageTag()}|${theme.name}|$scale',
            ))
              ScreenshotContext(
                screen: screen,
                device: device,
                locale: locale,
                themeMode: theme,
                textScale: scale,
              ),
  ];
}
