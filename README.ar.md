<p align="center"><a href="README.md">English</a></p>

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

> **English summary.** `flutter_screenshot_matrix` is a dev-dependency test helper. One call,
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

<div dir="rtl">

بتكتب سطر واحد في test، وهو يصوّرلك الشاشة على كل الأجهزة واللغات والثيمات وأحجام الخط اللي
عايزها، جوه `flutter test` العادي من غير emulator، وفي الآخر تفتح صفحة HTML فيها كل الصور جنب
بعض، والصورة اللي فيها overflow عليها علامة حمرا.

## ✨ بيعمل إيه

- 🧮 **Matrix كامل**: أجهزة × لغات × ثيمات × أحجام خط. كل خانة test لوحدها باسم واضح
  (`login · Pixel 7 · ar · dark · 1.3x`)، فلو واحدة وقعت تعرف هي مين بالظبط.
- 🔤 **خطوط حقيقية مش مربعات**: الـ test العادي بيرسم كل الحروف مربعات سودا. هنا بيتحمّل:
  - خطوط التطبيق من `FontManifest.json` (اللي في `pubspec.yaml` بتاعك وبتاع الباكدجات)،
    والباكدجات بتتسجل بالاسمين `packages/foo/Bar` و `Bar`.
  - `MaterialIcons` و `Roboto` من الـ cache بتاع Flutter SDK نفسه لو التطبيق مش شايلهم.
  - Roboto كمان بيتسجل بأسماء خطوط Apple (`CupertinoSystemText` …) عشان شاشات iOS متطلعش مربعات.
- 🖼 **الصور بتظهر**: قبل التصوير بيعمل `precacheImage` لكل `Image` و `DecorationImage`
  (يعني `CircleAvatar` كمان).
- 📱 **أجهزة جاهزة**: `iphoneSE` و `iphone15` و `iphone15ProMax` و `pixel7` و `galaxyA14` و
  `smallAndroid` و `ipad11`، كل واحد بمقاسه والـ pixel ratio والـ safe area (status bar، notch،
  home indicator) والـ platform. وتقدر تعمل جهاز بنفسك، أو `Device.pixel7.landscape`.
- 🍎 **iPhone شكله iPhone**: بيحط `defaultTargetPlatform` على platform الجهاز، فالـ iPhone ياخد
  transitions و scroll بتاعة iOS (تقدر تقفلها بـ `useDevicePlatform: false`).
- 🚨 **فحص تلقائي لكل صورة**:

  | المشكلة | بيحصل إيه |
  |---|---|
  | 🟥 overflow | `A RenderFlex overflowed by 39 pixels…` بيتسجل ومعاه السطر في كودك (`lib/screens/profile_page.dart:80:11`) |
  | 🟥 exception | أي error في build/layout/paint بيتسجل والشاشة بتتصور برضه (الشاشة الحمرا) |
  | 🟧 نص مقطوع | (اختياري `detectTextTruncation: true`) نص عمل ellipsis أو وقف عند `maxLines` أو اتقص |
  | 🟥 golden | في وضع `golden` لو الصورة مختلفة عن المحفوظة |

  ولكل نوع policy: `record` (يتسجل والـ test يفضل أخضر)، `fail` (تتصور وبعدين الـ test يقع)،
  `ignore` (Flutter يتعامل معاه عادي). الافتراضي: overflow ← `record`، exceptions ← `fail`.
- 🖼 **إطار جهاز** (`frame: true`): حواف مدورة، notch أو dynamic island، status bar فيه الساعة
  والشبكة والبطارية، وأزرار navigation تحت. لون الأيقونات بيتغير حسب لون التطبيق تحتها زي
  الموبايل الحقيقي. جاهزة للـ store أو للـ README.
- 🌐 **Gallery واحدة**: `screenshots/index.html` من غير أي ملفات خارجية: فلتر بالشاشة/الجهاز/
  اللغة/الثيم/حجم الخط، «المشاكل بس»، group by، slider للحجم، وتدوس على أي صورة تكبر وتشوف
  تفاصيل المشكلة. وفيه dark mode.
- 🧪 **وضعين**: `gallery` (يكتب صور وبس) و `golden` (كمان بيقارن بـ `matchesGoldenFile`؛
  `--update-goldens` بيكتب، والتشغيل العادي بيقارن).

## 📦 التثبيت

ضيفه في `dev_dependencies` من [pub.dev](https://pub.dev/packages/flutter_screenshot_matrix):

```yaml
dev_dependencies:
  flutter_screenshot_matrix: ^0.1.0
```

```bash
flutter pub get
```

## 🚀 الاستخدام

```dart
// test/screenshots/login_screenshot_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenshot_matrix/flutter_screenshot_matrix.dart';
import 'package:my_app/login_page.dart';

void main() {
  screenshotMatrix(
    'login',
    (ctx) => const LoginPage(),
    // الـ shell بتاع تطبيقك؛ ctx فيه locale و themeMode و device و textScale
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
      // اختياري: mock data / providers قبل الـ pump
    },
  );
}
```

```bash
flutter test test/screenshots
open screenshots/index.html
```

الصور بتتكتب في `screenshots/<screen>/<device>__<locale>__<theme>__<scale>.png`.

### ⚙️ اضبطها مرة واحدة

بدل ما تكرر الـ `wrap` والأجهزة في كل ملف، حطهم في `test/flutter_test_config.dart`:

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

وبعدها كل شاشة سطر واحد: `screenshotMatrix('settings', (_) => const SettingsPage());`

### 🎛 الخيارات

| الخيار | الافتراضي | يعني |
|---|---|---|
| `wrap` | `MaterialApp` بسيط | الـ shell (themes، providers، localization) |
| `devices` / `locales` / `themes` / `textScales` | SE + 15 Pro Max + Pixel 7 / `en` / light+dark / `1.0` | محاور الـ matrix |
| `setUp` | — | يشتغل قبل الـ pump (`ScreenshotContext.current` فيه الخانة الحالية) |
| `beforeCapture` | — | يشتغل بعد الـ pump وقبل التصوير (افتح dialog، اعمل scroll…) |
| `mode` | `gallery` | أو `golden`، أو `--dart-define=SCREENSHOT_MATRIX_MODE=golden` |
| `frame` / `frameStyle` | `false` | إطار الجهاز |
| `onOverflow` / `onException` | `record` / `fail` | `record` · `fail` · `ignore` |
| `detectTextTruncation` | `false` | علّم على النص المقطوع (warning أصفر) |
| `useDevicePlatform` | `true` | `defaultTargetPlatform` = platform الجهاز |
| `hideDebugBanner` | `true` | يشيل شريط DEBUG |
| `settleTimeout` | 2 ثانية (وقت وهمي) | الأنيميشن اللي مبتخلصش (spinner) مش هتعلّق الـ test |
| `outputDir` / `goldenDir` | `screenshots` / `goldens` | الأول من root المشروع، التاني جنب ملف الـ test |

### 🔁 إعادة بناء الـ gallery

كل شاشة بتكتب manifest صغير في `screenshots/.manifest/`، والـ `index.html` و `manifest.json`
بيتبنوا من كلهم بعد كل شاشة (فتشغيل ملفات test بالتوازي آمن، وتشغيل `--plain-name` على جزء
بيحافظ على الباقي). لو عايز تبنيها تاني من غير ما تشغّل الـ tests:

```bash
dart run flutter_screenshot_matrix:gallery --dir screenshots --title "My app"
```

### 🧪 Golden mode

```bash
flutter test --dart-define=SCREENSHOT_MATRIX_MODE=golden --update-goldens   # اكتب الـ goldens
flutter test --dart-define=SCREENSHOT_MATRIX_MODE=golden                    # قارن
```

## 🧩 الـ example

في `example/` تطبيق فيه 3 شاشات (login، profile، settings) بالعربي والإنجليزي، وخط Cairo
للعربي. شاشة الـ profile فيها overflow **مقصود** في العربي مع الخط الكبير، وbio بيعمل ellipsis:

```bash
cd example
flutter test          # 120 صورة في حوالي 10 ثواني
open screenshots/index.html
```

## ❓ أسئلة

**ليه مش golden_toolkit أو alchemist؟**
الاتنين أساسهم golden tests (مقارنة pixel)، وgolden_toolkit مبقاش بيتحدّث. هنا الأساس إنك
**تشوف** كل الشاشات وتمسك مشاكل الـ layout، والـ golden وضع إضافي. ومفيش dependency غير الـ SDK.

**الحروف العربي (أو الصيني/emoji) طالعة مربعات!**
الـ test مفيهوش خطوط النظام. لازم الخط اللي يغطي اللغة دي يكون في `fonts:` في الـ pubspec
ومستخدم في الـ theme (زي `fontFamily: 'Cairo'` للعربي)، أو حطه في `fontFamilyFallback`؛
`ScreenshotContext.fontFamilyFallback` فيه كل خطوط التطبيق جاهزة. لو الخط مش asset استخدم
`ScreenshotMatrixDefaults.extraFonts`.

**الصور من النت مش ظاهرة.**
الـ `flutter test` بيرجّع 400 لأي HTTP request. استخدم assets أو mock للـ `HttpClient`/الـ image
provider في `setUp`.

**الـ golden بيختلف بين macOS و Linux.**
طبيعي، رسم الخطوط بيختلف من نظام لنظام. ولّد الـ goldens وقارن على نفس النظام (مثلاً في CI بس).

## ⚖️ الحدود

- ده rendering بتاع Flutter في الـ test مش الجهاز الحقيقي: مفيش platform views
  (خرايط، WebView، كاميرا، video) ولا خطوط النظام ولا keyboard.
- مقاسات الـ status bar والـ navigation في الأجهزة الجاهزة تقريبية، والإطار رسم بسيط مش mockup رسمي.
- فحص النص المقطوع بيشوف `Text`/`RichText` بس (مش `TextField` ولا نص مرسوم بـ `CustomPainter`).
- الـ overflow بيتسجل مرة واحدة لكل render object (زي Flutter نفسه).

</div>

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
