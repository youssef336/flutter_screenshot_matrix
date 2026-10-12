import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Font families the platform text themes ask for on Apple platforms. In a
/// test there is no system font, so these are mapped to Roboto.
const List<String> _appleSystemFamilies = <String>[
  'CupertinoSystemText',
  'CupertinoSystemDisplay',
  '.AppleSystemUIFont',
  '.SF Pro Text',
  '.SF Pro Display',
  '.SF UI Text',
  '.SF UI Display',
];

/// The result of [loadScreenshotFonts].
class LoadedFonts {
  LoadedFonts._(this.families, this.appFamilies, this.warnings);

  /// Every family registered with the engine (including aliases).
  final Set<String> families;

  /// The families declared in the app's (and its packages') pubspec, in
  /// manifest order. Handy for `ThemeData(fontFamilyFallback: ...)`.
  final List<String> appFamilies;

  /// Problems found while loading (missing SDK fonts, unreadable assets).
  final List<String> warnings;
}

Future<LoadedFonts>? _loading;

/// Loads real fonts into the test engine so screenshots show glyphs instead
/// of the solid boxes of the default test font.
///
/// * Every font in the app's `FontManifest.json` (the `fonts:` section of the
///   app's pubspec and of every package it depends on, plus `MaterialIcons`
///   when `uses-material-design: true`). Package fonts are registered both as
///   `packages/<pkg>/<Family>` and as the bare `<Family>`.
/// * `MaterialIcons` and `Roboto` from the Flutter SDK cache when the app does
///   not bundle them. Roboto is also registered under the Apple system font
///   names so iOS-styled text themes render.
/// * [extraFonts]: family name -> font file paths on disk, for fonts that are
///   not app assets (for example a fallback font for a script your app's fonts
///   do not cover).
///
/// Safe to call many times; fonts are loaded once per test isolate.
Future<LoadedFonts> loadScreenshotFonts({
  Map<String, List<String>> extraFonts = const <String, List<String>>{},
}) {
  return _loading ??= _load(extraFonts);
}

Future<LoadedFonts> _load(Map<String, List<String>> extraFonts) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Set<String> loaded = <String>{};
  final List<String> appFamilies = <String>[];
  final List<String> warnings = <String>[];

  Future<void> register(String family, List<Future<ByteData>> fonts) async {
    if (fonts.isEmpty) {
      return;
    }
    final FontLoader loader = FontLoader(family);
    fonts.forEach(loader.addFont);
    await loader.load();
    loaded.add(family);
  }

  // 1. The app's fonts, from the asset bundle the test runner prepared.
  final Map<String, List<String>> manifest = await readFontManifest(rootBundle);
  for (final MapEntry<String, List<String>> family in manifest.entries) {
    List<Future<ByteData>> data() => <Future<ByteData>>[
      for (final String asset in family.value) rootBundle.load(asset),
    ];
    try {
      await register(family.key, data());
      appFamilies.add(family.key);
      final String? bare = bareFamilyName(family.key);
      if (bare != null && !manifest.containsKey(bare)) {
        await register(bare, data());
      }
    } on Object catch (e) {
      warnings.add('Could not load font family "${family.key}": $e');
    }
  }

  // 2. Material icons and Roboto from the Flutter SDK, when not bundled.
  final Directory? sdkFonts = findSdkMaterialFonts();
  Future<void> registerFiles(String family, List<File> files) =>
      register(family, <Future<ByteData>>[
        for (final File f in files)
          f.readAsBytes().then((Uint8List b) => ByteData.sublistView(b)),
      ]);
  if (sdkFonts == null) {
    warnings.add(
      'Flutter SDK font cache not found (set FLUTTER_ROOT); Roboto and '
      'MaterialIcons were not loaded.',
    );
  } else {
    if (!loaded.contains('MaterialIcons')) {
      final File icons = File('${sdkFonts.path}/MaterialIcons-Regular.otf');
      if (icons.existsSync()) {
        await registerFiles('MaterialIcons', <File>[icons]);
      }
    }
    final List<File> roboto = sdkFonts.listSync().whereType<File>().where((
      File f,
    ) {
      final String name = f.uri.pathSegments.last;
      return name.startsWith('Roboto-') && name.endsWith('.ttf');
    }).toList()..sort((File a, File b) => a.path.compareTo(b.path));
    if (roboto.isEmpty) {
      warnings.add('Roboto not found in ${sdkFonts.path}.');
    } else {
      for (final String family in <String>['Roboto', ..._appleSystemFamilies]) {
        if (!loaded.contains(family)) {
          await registerFiles(family, roboto);
        }
      }
    }
  }

  // 3. Extra fonts from disk.
  for (final MapEntry<String, List<String>> family in extraFonts.entries) {
    final List<File> files = family.value.map(File.new).toList();
    final List<File> missing = files
        .where((File f) => !f.existsSync())
        .toList();
    if (missing.isNotEmpty) {
      warnings.add(
        'Extra font "${family.key}": missing ${missing.map((File f) => f.path).join(', ')}',
      );
      continue;
    }
    await registerFiles(family.key, files);
    appFamilies.add(family.key);
  }

  return LoadedFonts._(loaded, appFamilies, warnings);
}

/// Reads `FontManifest.json` from [bundle]: family -> asset keys.
///
/// Returns an empty map when the app declares no fonts.
Future<Map<String, List<String>>> readFontManifest(AssetBundle bundle) async {
  final String json;
  try {
    json = await bundle.loadString('FontManifest.json', cache: false);
  } on Object {
    return <String, List<String>>{};
  }
  return parseFontManifest(json);
}

/// Parses the content of `FontManifest.json`: family -> asset keys.
Map<String, List<String>> parseFontManifest(String json) {
  final Map<String, List<String>> out = <String, List<String>>{};
  final Object? decoded = jsonDecode(json);
  if (decoded is! List<Object?>) {
    return out;
  }
  for (final Object? family in decoded) {
    if (family is! Map<String, Object?>) {
      continue;
    }
    final Object? name = family['family'];
    final Object? fonts = family['fonts'];
    if (name is! String || fonts is! List<Object?>) {
      continue;
    }
    out[name] = <String>[
      for (final Object? font in fonts)
        if (font is Map<String, Object?> && font['asset'] is String)
          font['asset']! as String,
    ];
  }
  return out;
}

/// `packages/foo/Bar` -> `Bar`; `null` for a family that is already bare.
String? bareFamilyName(String family) {
  final List<String> parts = family.split('/');
  if (parts.length >= 3 && parts.first == 'packages') {
    return parts.sublist(2).join('/');
  }
  return null;
}

/// Finds `bin/cache/artifacts/material_fonts` in the Flutter SDK running this
/// test, from `FLUTTER_ROOT` or by walking up from the test executable.
Directory? findSdkMaterialFonts({
  Map<String, String>? environment,
  String? executable,
}) {
  const String relative = 'bin/cache/artifacts/material_fonts';
  final String? root = (environment ?? Platform.environment)['FLUTTER_ROOT'];
  if (root != null && root.isNotEmpty) {
    final Directory dir = Directory('$root/$relative');
    if (dir.existsSync()) {
      return dir;
    }
  }
  Directory dir = File(executable ?? Platform.resolvedExecutable).parent;
  for (int i = 0; i < 8; i++) {
    final Directory candidate = Directory(
      '${dir.path}/artifacts/material_fonts',
    );
    if (candidate.existsSync()) {
      return candidate;
    }
    final Directory nested = Directory('${dir.path}/$relative');
    if (nested.existsSync()) {
      return nested;
    }
    if (dir.parent.path == dir.path) {
      break;
    }
    dir = dir.parent;
  }
  return null;
}
