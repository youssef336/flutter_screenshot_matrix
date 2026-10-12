# Changelog

## 0.1.0

First release.

- `screenshotMatrix(...)`: one test per device x locale x theme x text scale, in plain
  `flutter test` (no emulator).
- Real fonts: the app's `FontManifest.json` (app + package fonts), plus `MaterialIcons` and
  `Roboto` from the Flutter SDK cache; Roboto also stands in for the Apple system fonts.
- Images (`Image`, `DecorationImage`) are precached before capture.
- Device presets (`iphoneSE`, `iphone15`, `iphone15ProMax`, `pixel7`, `galaxyA14`,
  `smallAndroid`, `ipad11`) with size, pixel ratio, safe-area insets and platform;
  `Device.landscape`.
- Issues recorded per screenshot: layout overflows (with source line), exceptions,
  optional text truncation, golden mismatches. Policies: `record`, `fail`, `ignore`.
- Two modes: `gallery` (PNGs) and `golden` (also `matchesGoldenFile`; switch with
  `--dart-define=SCREENSHOT_MATRIX_MODE=golden`).
- Optional device frame (`frame: true`): bezel, camera cut-out, status bar and system
  navigation that follow the app's own colors.
- Self-contained `screenshots/index.html` gallery (filters, grouping, size slider,
  issue badges, lightbox) built from per-screen manifest fragments, safe with parallel
  test files.
- `dart run flutter_screenshot_matrix:gallery` rebuilds the gallery from the manifest.
- `ScreenshotMatrixDefaults` to configure the app shell and matrix once in
  `flutter_test_config.dart`.
