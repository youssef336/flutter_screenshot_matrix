<p align="center"><a href="README.ar.md">العربية</a></p>

<p align="center"><img src="https://raw.githubusercontent.com/youssef336/flutter_screenshot_matrix/main/screenshots/banner.png" alt="flutter_screenshot_matrix banner" width="100%"></p>

<h1 align="center">Flutter Screenshot Matrix</h1>

<p align="center">
  Screenshot every screen of your Flutter app on every device, language, theme and text size, in plain <code>flutter test</code>, and browse them all in one HTML gallery.
</p>

<p align="center">
  <a href="https://pub.dev/packages/flutter_screenshot_matrix"><img src="https://img.shields.io/pub/v/flutter_screenshot_matrix?style=for-the-badge&logo=dart&label=pub.dev" alt="pub.dev"/></a>
  <img src="https://img.shields.io/badge/Flutter-3.35%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.9%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/No%20emulator-flutter%20test-2ea44f?style=for-the-badge" alt="No emulator">
  <img src="https://img.shields.io/badge/Dependencies-SDK%20only-6e40c9?style=for-the-badge" alt="SDK only">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="MIT">
</p>

> **Summary.** `flutter_screenshot_matrix` is a dev-dependency test helper. One call,
> `screenshotMatrix('login', (ctx) => const LoginPage())`, registers a test for every cell of
> *devices × locales × themes × text scales* and renders the screen headlessly in `flutter test`
> (no emulator, no device). Screenshots use **real fonts**, not the black boxes of the test font:
> the app's own fonts from `FontManifest.json` (including package fonts), plus `MaterialIcons` and
> `Roboto` from the Flutter SDK cache. Images are precached before capture. While capturing, layout
> **overflows** (with the source line), **exceptions** and, optionally, **ellipsized / clipped text**
> are recorded per screenshot instead of failing the run. Device presets carry size, pixel ratio,
> safe-area insets and platform; an optional **device frame** draws a bezel, camera cut-out, status
> bar and navigation for store-ready shots. Everything ends up in a self-contained
> `screenshots/index.html` with filters, grouping and red overflow badges. A `golden` mode also
> compares each shot with `matchesGoldenFile` for regression testing. No dependencies beyond the
> Flutter SDK.

You write one line in a test, and it screenshots the screen on every device, language, theme and
text size you want, inside regular `flutter test` with no emulator. At the end you open an HTML page
with all the images side by side, and any image with an overflow gets a red badge.

## ✨ What it does

- 🧮 **A full matrix**: devices × languages × themes × text sizes. Each cell is its own test with a
  clear name (`login · Pixel 7 · ar · dark · 1.3x`), so if one fails you know exactly which one.
- 🔤 **Real fonts, not boxes**: a regular test draws every glyph as a black box. Here it loads:
  - The app's fonts from `FontManifest.json` (the ones in your `pubspec.yaml` and in your packages'),
    and package fonts are registered under both names, `packages/foo/Bar` and `Bar`.
  - `MaterialIcons` and `Roboto` from the Flutter SDK's own cache if the app doesn't bundle them.
  - Roboto is also registered under Apple font names (`CupertinoSystemText` …) so iOS screens don't
    come out as boxes.
- 🖼 **Images show up**: before capturing it runs `precacheImage` for every `Image` and
  `DecorationImage` (so `CircleAvatar` too).
- 📱 **Ready-made devices**: `iphoneSE`, `iphone15`, `iphone15ProMax`, `pixel7`, `galaxyA14`,
  `smallAndroid` and `ipad11`, each with its size, pixel ratio, safe area (status bar, notch,
  home indicator) and platform. You can also make your own device, or use `Device.pixel7.landscape`.
- 🍎 **An iPhone looks like an iPhone**: it sets `defaultTargetPlatform` to the device's platform, so
  the iPhone gets iOS transitions and scrolling (you can turn this off with `useDevicePlatform: false`).
- 🚨 **Automatic checks on every image**:

  | Problem | What happens |
  |---|---|
  | 🟥 overflow | `A RenderFlex overflowed by 39 pixels…` is recorded together with the line in your code (`lib/screens/profile_page.dart:80:11`) |
  | 🟥 exception | Any error in build/layout/paint is recorded and the screen is still captured (the red screen) |
  | 🟧 truncated text | (optional, `detectTextTruncation: true`) text that was ellipsized, stopped at `maxLines`, or was clipped |
  | 🟥 golden | In `golden` mode, if the image differs from the saved one |

  Each kind has a policy: `record` (recorded, and the test stays green), `fail` (captured, then the
  test fails), `ignore` (Flutter handles it as usual). Defaults: overflow → `record`, exceptions → `fail`.
- 🖼 **Device frame** (`frame: true`): rounded corners, a notch or dynamic island, a status bar with
  the clock, network and battery, and navigation buttons at the bottom. The icon color changes based
  on the color of the app underneath, like a real phone. Ready for the store or for a README.
- 🌐 **One gallery**: `screenshots/index.html` with no external files: filter by screen/device/
  language/theme/text size, "issues only", group by, a size slider, and click any image to enlarge it
  and see the issue details. It has a dark mode too.
- 🧪 **Two modes**: `gallery` (only writes images) and `golden` (also compares with
  `matchesGoldenFile`; `--update-goldens` writes, a normal run compares).

## 📦 Installation

Add it to `dev_dependencies` from [pub.dev](https://pub.dev/packages/flutter_screenshot_matrix):

```yaml
dev_dependencies:
  flutter_screenshot_matrix: ^0.1.0
```

```bash
flutter pub get
```

## 🚀 Usage

```dart
// test/screenshots/login_screenshot_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenshot_matrix/flutter_screenshot_matrix.dart';
import 'package:my_app/login_page.dart';

void main() {
  screenshotMatrix(
    'login',
    (ctx) => const LoginPage(),
    // Your app's shell; ctx holds locale, themeMode, device and textScale
    wrap: (child, ctx) => MaterialApp(
      locale: ctx.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ctx.themeMode,
      home: child,
    ),
    devices: const [Device.iphoneSE, Device.iphone15ProMax, Device.pixel7, Device.galaxyA14, Device.ipad11],
    locales: const [Locale('en'), Locale('ar')],
    themes: const [ThemeMode.light, ThemeMode.dark],
    textScales: const [1.0, 1.3],
    setUp: (tester) async {
      // Optional: mock data / providers before the pump
    },
  );
}
```

```bash
flutter test test/screenshots
open screenshots/index.html
```

Images are written to `screenshots/<screen>/<device>__<locale>__<theme>__<scale>.png`.

### ⚙️ Configure it once

Instead of repeating `wrap` and the devices in every file, put them in `test/flutter_test_config.dart`:

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ScreenshotMatrixDefaults.wrap = (child, ctx) =>
      MyApp(home: child, locale: ctx.locale, themeMode: ctx.themeMode);
  ScreenshotMatrixDefaults.devices = const [Device.iphoneSE, Device.pixel7, Device.ipad11];
  ScreenshotMatrixDefaults.locales = const [Locale('en'), Locale('ar')];
  ScreenshotMatrixDefaults.textScales = const [1.0, 1.3];
  await testMain();
}
```

After that, every screen is one line: `screenshotMatrix('settings', (_) => const SettingsPage());`

### 🎛 Options

| Option | Default | Meaning |
|---|---|---|
| `wrap` | A simple `MaterialApp` | The shell (themes, providers, localization) |
| `devices` / `locales` / `themes` / `textScales` | SE + 15 Pro Max + Pixel 7 / `en` / light+dark / `1.0` | The matrix axes |
| `setUp` | — | Runs before the pump (`ScreenshotContext.current` holds the current cell) |
| `beforeCapture` | — | Runs after the pump and before capturing (open a dialog, scroll…) |
| `mode` | `gallery` | Or `golden`, or `--dart-define=SCREENSHOT_MATRIX_MODE=golden` |
| `frame` / `frameStyle` | `false` | The device frame |
| `onOverflow` / `onException` | `record` / `fail` | `record` · `fail` · `ignore` |
| `detectTextTruncation` | `false` | Flag truncated text (yellow warning) |
| `useDevicePlatform` | `true` | `defaultTargetPlatform` = the device's platform |
| `hideDebugBanner` | `true` | Removes the DEBUG banner |
| `settleTimeout` | 2 seconds (fake time) | Animations that never finish (a spinner) won't hang the test |
| `outputDir` / `goldenDir` | `screenshots` / `goldens` | The first is relative to the project root, the second sits next to the test file |

### 🔁 Rebuilding the gallery

Each screen writes a small manifest to `screenshots/.manifest/`, and `index.html` and `manifest.json`
are rebuilt from all of them after every screen (so running test files in parallel is safe, and
running `--plain-name` on a subset keeps the rest). To rebuild it without running the tests:

```bash
dart run flutter_screenshot_matrix:gallery --dir screenshots --title "My app"
```

### 🧪 Golden mode

```bash
flutter test --dart-define=SCREENSHOT_MATRIX_MODE=golden --update-goldens   # write the goldens
flutter test --dart-define=SCREENSHOT_MATRIX_MODE=golden                    # compare
```

## 🧩 The example

`example/` has an app with 3 screens (login, profile, settings) in Arabic and English, with the Cairo
font for Arabic. The profile screen has a **deliberate** overflow in Arabic with the large text size,
and a bio that ellipsizes:

```bash
cd example
flutter test          # 120 images in about 10 seconds
open screenshots/index.html
```

## ❓ FAQ

**Why not golden_toolkit or alchemist?**
Both are built around golden tests (pixel comparison), and golden_toolkit is no longer maintained.
Here the core idea is that you **see** all the screens and catch layout problems; golden is an extra
mode. And there is no dependency other than the SDK.

**Arabic (or Chinese/emoji) characters come out as boxes!**
Tests don't have the system fonts. The font that covers that language has to be in `fonts:` in the
pubspec and used in the theme (like `fontFamily: 'Cairo'` for Arabic), or put it in
`fontFamilyFallback`; `ScreenshotContext.fontFamilyFallback` already holds all of the app's fonts.
If the font isn't an asset, use `ScreenshotMatrixDefaults.extraFonts`.

**Images from the network don't show up.**
`flutter test` returns 400 for any HTTP request. Use assets, or mock the `HttpClient`/image provider
in `setUp`.

**The golden differs between macOS and Linux.**
That's expected; font rendering differs from one OS to another. Generate and compare the goldens on
the same OS (for example, only in CI).

## ⚖️ Limitations

- This is Flutter's rendering in a test, not the real device: no platform views
  (maps, WebView, camera, video), no system fonts and no keyboard.
- The status bar and navigation sizes in the preset devices are approximate, and the frame is a
  simple drawing, not an official mockup.
- The truncated-text check only looks at `Text`/`RichText` (not `TextField` or text drawn with a
  `CustomPainter`).
- An overflow is recorded once per render object (like Flutter itself).

## 🛠 Public API

| Symbol | Role |
|---|---|
| `screenshotMatrix(name, builder, {...})` | registers one test per matrix cell + gallery output |
| `ScreenshotContext` | the cell: `device`, `locale`, `themeMode`, `textScale`, `isRtl`, `id`, `current`, `fontFamilyFallback` |
| `Device` (+ presets, `landscape`, `copyWith`) | size, pixel ratio, safe area, platform, frame shape |
| `ScreenshotMatrixDefaults` | global defaults (set in `flutter_test_config.dart`) |
| `ScreenshotMode`, `IssuePolicy`, `DeviceFrameStyle` | options |
| `Manifest`, `ManifestEntry`, `ScreenshotIssue`, `IssueKind` | manifest model (JSON) |
| `loadScreenshotFonts`, `expandMatrix`, `renderGalleryHtml`, `rebuildGallery`, `composeDeviceFrame`, `findTruncatedText`, `IssueCollector` | building blocks, usable on their own |

## 🏗 Project structure

| File | Role |
|---|---|
| `lib/src/screenshot_matrix.dart` | the test registration and per-cell pipeline |
| `lib/src/fonts.dart` | `FontManifest.json` + SDK Roboto/MaterialIcons loader |
| `lib/src/issues.dart` | overflow / exception interception, text truncation scan |
| `lib/src/frame.dart` | device frame painter |
| `lib/src/device.dart`, `lib/src/context.dart` | presets and matrix expansion |
| `lib/src/manifest.dart`, `lib/src/gallery_writer.dart`, `lib/src/gallery_html.dart` | pure Dart: manifest, fragments, HTML |
| `bin/gallery.dart` | `dart run flutter_screenshot_matrix:gallery` |
| `example/` | demo app (3 screens, en/ar, deliberate overflow) |

## 🧑‍💻 Development

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
cd example && flutter test && open screenshots/index.html
```

## 📄 License

[MIT](LICENSE). The example's Cairo font is under the SIL Open Font License (`example/assets/fonts/Cairo-OFL.txt`).

## 👤 Author

**Youssef Belal Zakaria** · [GitHub @youssef336](https://github.com/youssef336)

⭐ If you like this project, give it a star!
