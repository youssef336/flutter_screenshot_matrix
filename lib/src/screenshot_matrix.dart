import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart' show isTest;

import 'context.dart';
import 'device.dart';
import 'fonts.dart';
import 'frame.dart';
import 'gallery_writer.dart';
import 'issues.dart';
import 'manifest.dart';

/// Builds the screen under test.
typedef ScreenBuilder = Widget Function(ScreenshotContext ctx);

/// Wraps the screen in the app shell (`MaterialApp`, providers, theme...).
typedef ScreenWrapper = Widget Function(Widget child, ScreenshotContext ctx);

/// A hook that runs with the tester; use [ScreenshotContext.current] for the
/// cell being captured.
typedef ScreenshotHook = Future<void> Function(WidgetTester tester);

/// How screenshots are used.
enum ScreenshotMode {
  /// Write PNGs and the HTML gallery. Never fails on pixels.
  gallery,

  /// Also compare every screenshot with a golden file next to the test
  /// (`flutter test --update-goldens` writes them).
  golden,
}

/// Defaults shared by every [screenshotMatrix] call. Set fields once (for
/// example in `test/flutter_test_config.dart`) instead of repeating them.
class ScreenshotMatrixDefaults {
  ScreenshotMatrixDefaults._();

  /// Devices to render on.
  static List<Device> devices = const <Device>[
    Device.iphoneSE,
    Device.iphone15ProMax,
    Device.pixel7,
  ];

  /// Locales to render in.
  static List<Locale> locales = const <Locale>[Locale('en')];

  /// Theme modes to render with.
  static List<ThemeMode> themes = const <ThemeMode>[
    ThemeMode.light,
    ThemeMode.dark,
  ];

  /// Text scale factors to render with.
  static List<double> textScales = const <double>[1.0];

  /// The app shell. `null` uses [defaultScreenshotWrap].
  static ScreenWrapper? wrap;

  /// Gallery folder, relative to the package root (where `flutter test`
  /// runs).
  static String outputDir = 'screenshots';

  /// Golden folder, relative to the test file.
  static String goldenDir = 'goldens';

  /// Title of the gallery page.
  static String galleryTitle = 'Screenshot matrix';

  /// Gallery or golden mode. `--dart-define=SCREENSHOT_MATRIX_MODE=golden`
  /// overrides this default.
  static ScreenshotMode mode = ScreenshotMode.gallery;

  /// Whether to draw a device frame around gallery PNGs.
  static bool frame = false;

  /// The device frame style.
  static DeviceFrameStyle frameStyle = const DeviceFrameStyle();

  /// What to do with layout overflows.
  static IssuePolicy onOverflow = IssuePolicy.record;

  /// What to do with other exceptions.
  static IssuePolicy onException = IssuePolicy.fail;

  /// Whether to look for ellipsized / clipped text.
  static bool detectTextTruncation = false;

  /// Whether to set `defaultTargetPlatform` to the device's platform, so an
  /// iPhone renders Cupertino page transitions, scroll physics and fonts.
  static bool useDevicePlatform = true;

  /// Whether to hide the DEBUG banner of `MaterialApp`/`WidgetsApp`.
  static bool hideDebugBanner = true;

  /// How long to let animations settle before capturing (fake time).
  /// Infinite animations (spinners) simply stop being waited for.
  static Duration settleTimeout = const Duration(seconds: 2);

  /// Whether to write PNGs + `index.html` (on by default in both modes).
  static bool writeGallery = true;

  /// Extra fonts from disk: family -> font file paths.
  static Map<String, List<String>> extraFonts = const <String, List<String>>{};
}

/// The shell used when no `wrap` is given: a `MaterialApp` with the context's
/// locale (with Material localizations, so RTL works), theme mode and the
/// app's bundled fonts as fallbacks.
Widget defaultScreenshotWrap(Widget child, ScreenshotContext ctx) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: ctx.locale,
    supportedLocales: <Locale>[ctx.locale],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    themeMode: ctx.themeMode,
    theme: ThemeData(fontFamilyFallback: ScreenshotContext.fontFamilyFallback),
    darkTheme: ThemeData(
      brightness: Brightness.dark,
      fontFamilyFallback: ScreenshotContext.fontFamilyFallback,
    ),
    home: child,
  );
}

const String _modeDefine = String.fromEnvironment('SCREENSHOT_MATRIX_MODE');

ScreenshotMode _resolveMode(ScreenshotMode? explicit) {
  if (explicit != null) {
    return explicit;
  }
  for (final ScreenshotMode m in ScreenshotMode.values) {
    if (m.name == _modeDefine) {
      return m;
    }
  }
  return ScreenshotMatrixDefaults.mode;
}

/// Registers one test per cell of devices x locales x themes x text scales
/// that renders [builder] inside [wrap], records layout overflows and
/// exceptions, and saves a PNG. After the last cell the screen's manifest
/// fragment is written and `<outputDir>/index.html` is rebuilt.
///
/// ```dart
/// screenshotMatrix(
///   'login',
///   (ctx) => const LoginPage(),
///   wrap: (child, ctx) => MaterialApp(
///     locale: ctx.locale,
///     themeMode: ctx.themeMode,
///     home: child,
///   ),
///   locales: const [Locale('en'), Locale('ar')],
///   textScales: const [1.0, 1.3],
/// );
/// ```
///
/// Every argument left `null` falls back to [ScreenshotMatrixDefaults].
@isTest
void screenshotMatrix(
  String screen,
  ScreenBuilder builder, {
  ScreenWrapper? wrap,
  List<Device>? devices,
  List<Locale>? locales,
  List<ThemeMode>? themes,
  List<double>? textScales,
  ScreenshotHook? setUp,
  ScreenshotHook? beforeCapture,
  ScreenshotMode? mode,
  bool? frame,
  DeviceFrameStyle? frameStyle,
  IssuePolicy? onOverflow,
  IssuePolicy? onException,
  bool? detectTextTruncation,
  bool? useDevicePlatform,
  bool? hideDebugBanner,
  Duration? settleTimeout,
  String? outputDir,
  String? goldenDir,
  String? galleryTitle,
  bool? writeGallery,
  Object? skip,
  Object? tags,
}) {
  final List<ScreenshotContext> cells = expandMatrix(
    screen: screen,
    devices: devices ?? ScreenshotMatrixDefaults.devices,
    locales: locales ?? ScreenshotMatrixDefaults.locales,
    themes: themes ?? ScreenshotMatrixDefaults.themes,
    textScales: textScales ?? ScreenshotMatrixDefaults.textScales,
  );
  final _Options options = _Options(
    wrap: wrap ?? ScreenshotMatrixDefaults.wrap ?? defaultScreenshotWrap,
    setUp: setUp,
    beforeCapture: beforeCapture,
    mode: _resolveMode(mode),
    frame: frame ?? ScreenshotMatrixDefaults.frame,
    frameStyle: frameStyle ?? ScreenshotMatrixDefaults.frameStyle,
    onOverflow: onOverflow ?? ScreenshotMatrixDefaults.onOverflow,
    onException: onException ?? ScreenshotMatrixDefaults.onException,
    detectTextTruncation:
        detectTextTruncation ?? ScreenshotMatrixDefaults.detectTextTruncation,
    useDevicePlatform:
        useDevicePlatform ?? ScreenshotMatrixDefaults.useDevicePlatform,
    hideDebugBanner:
        hideDebugBanner ?? ScreenshotMatrixDefaults.hideDebugBanner,
    settleTimeout: settleTimeout ?? ScreenshotMatrixDefaults.settleTimeout,
    outputDir: Directory(outputDir ?? ScreenshotMatrixDefaults.outputDir),
    goldenDir: goldenDir ?? ScreenshotMatrixDefaults.goldenDir,
    writeGallery: writeGallery ?? ScreenshotMatrixDefaults.writeGallery,
  );
  final String title = galleryTitle ?? ScreenshotMatrixDefaults.galleryTitle;
  final List<ManifestEntry> results = <ManifestEntry>[];

  group('screenshotMatrix: $screen', () {
    setUpAll(() async {
      final LoadedFonts fonts = await loadScreenshotFonts(
        extraFonts: ScreenshotMatrixDefaults.extraFonts,
      );
      ScreenshotContext.fontFamilyFallback = fonts.appFamilies;
      for (final String warning in fonts.warnings) {
        debugPrint('flutter_screenshot_matrix: $warning');
      }
    });

    for (final ScreenshotContext cell in cells) {
      testWidgets(cell.label, (WidgetTester tester) async {
        await _runCell(tester, builder, cell, options, results);
      }, tags: tags);
    }

    tearDownAll(() {
      if (!options.writeGallery || results.isEmpty) {
        return;
      }
      final Set<String> ids = cells.map((ScreenshotContext c) => c.id).toSet();
      final Set<String> fresh = results.map((ManifestEntry e) => e.id).toSet();
      // Keep cells from an earlier run that this run skipped (name filters),
      // drop cells that are no longer part of the matrix.
      final Manifest? previous = readFragment(options.outputDir, screen);
      final List<ManifestEntry> kept = <ManifestEntry>[
        for (final ManifestEntry e in previous?.entries ?? <ManifestEntry>[])
          if (ids.contains(e.id) && !fresh.contains(e.id)) e,
      ];
      final List<String> order = cells
          .map((ScreenshotContext c) => c.id)
          .toList();
      final List<ManifestEntry> entries = <ManifestEntry>[...kept, ...results]
        ..sort(
          (ManifestEntry a, ManifestEntry b) =>
              order.indexOf(a.id).compareTo(order.indexOf(b.id)),
        );
      writeFragment(options.outputDir, screen, Manifest(entries: entries));
      final Manifest all = rebuildGallery(options.outputDir, title: title);
      final int errors = results.where((ManifestEntry e) => e.hasErrors).length;
      debugPrint(
        'flutter_screenshot_matrix: $screen: ${results.length} screenshots'
        '${errors == 0 ? '' : ', $errors with errors'} -> '
        '${options.outputDir.path}/$galleryFileName '
        '(${all.entries.length} in gallery)',
      );
    });
  }, skip: skip);
}

class _Options {
  const _Options({
    required this.wrap,
    required this.setUp,
    required this.beforeCapture,
    required this.mode,
    required this.frame,
    required this.frameStyle,
    required this.onOverflow,
    required this.onException,
    required this.detectTextTruncation,
    required this.useDevicePlatform,
    required this.hideDebugBanner,
    required this.settleTimeout,
    required this.outputDir,
    required this.goldenDir,
    required this.writeGallery,
  });

  final ScreenWrapper wrap;
  final ScreenshotHook? setUp;
  final ScreenshotHook? beforeCapture;
  final ScreenshotMode mode;
  final bool frame;
  final DeviceFrameStyle frameStyle;
  final IssuePolicy onOverflow;
  final IssuePolicy onException;
  final bool detectTextTruncation;
  final bool useDevicePlatform;
  final bool hideDebugBanner;
  final Duration settleTimeout;
  final Directory outputDir;
  final String goldenDir;
  final bool writeGallery;
}

Future<void> _runCell(
  WidgetTester tester,
  ScreenBuilder builder,
  ScreenshotContext cell,
  _Options options,
  List<ManifestEntry> results,
) async {
  final Device device = cell.device;
  final double dpr = device.devicePixelRatio;
  final FakeViewPadding padding = FakeViewPadding(
    left: device.safeArea.left * dpr,
    top: device.safeArea.top * dpr,
    right: device.safeArea.right * dpr,
    bottom: device.safeArea.bottom * dpr,
  );
  tester.view
    ..physicalSize = device.physicalSize
    ..devicePixelRatio = dpr
    ..padding = padding
    ..viewPadding = padding;
  tester.platformDispatcher
    ..localeTestValue = cell.locale
    ..localesTestValue = <Locale>[cell.locale]
    ..textScaleFactorTestValue = cell.textScale
    ..platformBrightnessTestValue = cell.brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  final TargetPlatform? previousPlatform = debugDefaultTargetPlatformOverride;
  final bool previousShadows = debugDisableShadows;
  final bool previousBanner = WidgetsApp.debugAllowBannerOverride;
  if (options.useDevicePlatform) {
    debugDefaultTargetPlatformOverride = device.platform;
  }
  debugDisableShadows = false;
  if (options.hideDebugBanner) {
    WidgetsApp.debugAllowBannerOverride = false;
  }

  final IssueCollector collector = IssueCollector(
    onOverflow: options.onOverflow,
    onException: options.onException,
  );
  final GlobalKey boundaryKey = GlobalKey();
  ScreenshotContext.current = cell;
  collector.start();
  ui.Image? screen;
  ManifestEntry? entry;
  try {
    try {
      if (options.setUp != null) {
        await options.setUp!(tester);
      }
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: options.wrap(builder(cell), cell),
        ),
      );
      await _settle(tester, options.settleTimeout);
      await _precacheImages(tester);
      await _settle(tester, options.settleTimeout);
      if (options.beforeCapture != null) {
        await options.beforeCapture!(tester);
        await _settle(tester, options.settleTimeout);
      }
    } on Object catch (error, stack) {
      if (options.onException == IssuePolicy.ignore) {
        rethrow;
      }
      collector.add(
        ScreenshotIssue(
          kind: IssueKind.exception,
          message: error.toString().split('\n').first,
          source: sourceLocationOf(stack.toString()),
          details:
              '$error\n${stack.toString().split('\n').take(12).join('\n')}',
        ),
      );
    }

    final RenderObject? boundary = boundaryKey.currentContext
        ?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw TestFailure(
        '${cell.id} did not render:\n'
        '${collector.issues.map((ScreenshotIssue i) => '  - $i').join('\n')}',
      );
    }
    if (options.detectTextTruncation) {
      findTruncatedText(boundary).forEach(collector.add);
    }

    screen = (await tester.runAsync(() => boundary.toImage(pixelRatio: dpr)))!;

    String file = '';
    int width = screen.width;
    int height = screen.height;
    if (options.writeGallery) {
      final ui.Image image = screen;
      final Uint8List png = (await tester.runAsync(() async {
        final ui.Image out = options.frame
            ? await composeDeviceFrame(image, device, style: options.frameStyle)
            : image;
        try {
          width = out.width;
          height = out.height;
          final ByteData? bytes = await out.toByteData(
            format: ui.ImageByteFormat.png,
          );
          return bytes!.buffer.asUint8List();
        } finally {
          if (!identical(out, image)) {
            out.dispose();
          }
        }
      }))!;
      file = '${slugify(cell.screen)}/${cell.fileStem}.png';
      final File target = File('${options.outputDir.path}/$file');
      target.parent.createSync(recursive: true);
      target.writeAsBytesSync(png);
    }

    if (options.mode == ScreenshotMode.golden) {
      final String golden =
          '${options.goldenDir}/${slugify(cell.screen)}/${cell.fileStem}.png';
      final int before = collector.issues.length;
      try {
        await expectLater(screen, matchesGoldenFile(golden));
      } on Object catch (failure) {
        // Comparators either throw (TestFailure, FlutterError) or report the
        // diff through FlutterError.onError (handled below).
        collector.add(
          ScreenshotIssue(
            kind: IssueKind.golden,
            message: 'Does not match $golden',
            details: failure is TestFailure
                ? failure.message
                : failure.toString().split('\n').take(8).join('\n'),
          ),
        );
      }
      // Errors reported while comparing are the comparison's verdict.
      for (int i = before; i < collector.issues.length; i++) {
        final ScreenshotIssue reported = collector.issues[i];
        if (reported.kind == IssueKind.exception) {
          collector.issues[i] = ScreenshotIssue(
            kind: IssueKind.golden,
            message: reported.message,
            details: reported.details,
          );
        }
      }
    }

    entry = ManifestEntry(
      id: cell.id,
      screen: cell.screen,
      deviceId: device.id,
      deviceName: device.name,
      logicalWidth: device.size.width,
      logicalHeight: device.size.height,
      devicePixelRatio: dpr,
      platform: device.platform.name,
      locale: cell.localeTag,
      rtl: cell.isRtl,
      theme: cell.themeName,
      textScale: cell.textScale,
      file: file,
      framed: options.frame,
      imageWidth: width,
      imageHeight: height,
      issues: List<ScreenshotIssue>.unmodifiable(collector.issues),
    );
    if (options.writeGallery) {
      results.add(entry);
    }
  } finally {
    collector.stop();
    ScreenshotContext.current = null;
    screen?.dispose();
    debugDefaultTargetPlatformOverride = previousPlatform;
    debugDisableShadows = previousShadows;
    WidgetsApp.debugAllowBannerOverride = previousBanner;
  }

  for (final ScreenshotIssue issue in entry.issues) {
    debugPrint('flutter_screenshot_matrix: ${cell.id}: $issue');
  }
  if (collector.shouldFail) {
    throw TestFailure(
      '${cell.id} has issues:\n'
      '${entry.issues.map((ScreenshotIssue i) => '  - $i').join('\n')}',
    );
  }
}

/// Pumps until nothing is scheduled, but gives up quietly after [timeout] of
/// fake time so infinite animations (progress spinners) do not hang the test.
Future<void> _settle(WidgetTester tester, Duration timeout) async {
  const Duration step = Duration(milliseconds: 100);
  await tester.pump();
  Duration waited = Duration.zero;
  while (tester.binding.hasScheduledFrame && waited < timeout) {
    await tester.pump(step);
    waited += step;
  }
}

/// Decodes every image on screen (outside fake async) so it shows up in the
/// screenshot instead of a blank box.
Future<void> _precacheImages(WidgetTester tester) async {
  final List<(ImageProvider, Element)> targets = <(ImageProvider, Element)>[];
  for (final Element e in find.byType(Image, skipOffstage: false).evaluate()) {
    targets.add(((e.widget as Image).image, e));
  }
  for (final Element e
      in find.byType(DecoratedBox, skipOffstage: false).evaluate()) {
    final Decoration decoration = (e.widget as DecoratedBox).decoration;
    if (decoration is BoxDecoration && decoration.image != null) {
      targets.add((decoration.image!.image, e));
    }
  }
  if (targets.isEmpty) {
    return;
  }
  await tester.runAsync(() async {
    await Future.wait(<Future<void>>[
      for (final (ImageProvider provider, Element element) in targets)
        precacheImage(
          provider,
          element,
          onError: (Object error, StackTrace? stack) {},
        ),
    ]).timeout(const Duration(seconds: 10), onTimeout: () => <void>[]);
  });
  await tester.pump();
}
