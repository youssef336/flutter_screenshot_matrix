// Pure Dart (no Flutter imports): shared by the test helper and the
// `dart run flutter_screenshot_matrix:gallery` command.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'gallery_html.dart';
import 'manifest.dart';

/// Sub-folder of the gallery folder holding one manifest fragment per screen.
///
/// Every `flutter test` file runs in its own isolate (often in parallel), so
/// each screen writes its own fragment and the merged `manifest.json` +
/// `index.html` are rebuilt from all fragments after every screen.
const String fragmentsDirName = '.manifest';

/// File name of the merged manifest.
const String manifestFileName = 'manifest.json';

/// File name of the gallery page.
const String galleryFileName = 'index.html';

/// Path of the fragment file for [screen] inside [outputDir].
File fragmentFile(Directory outputDir, String screen) =>
    File('${outputDir.path}/$fragmentsDirName/${slugify(screen)}.json');

/// Reads the fragment previously written for [screen], if any.
Manifest? readFragment(Directory outputDir, String screen) =>
    _readManifest(fragmentFile(outputDir, screen));

/// Writes the fragment for [screen] (atomically).
void writeFragment(Directory outputDir, String screen, Manifest fragment) {
  _writeAtomic(
    fragmentFile(outputDir, screen),
    const JsonEncoder.withIndent('  ').convert(fragment.toJson()),
  );
}

/// Merges every fragment under [outputDir], drops entries whose PNG no longer
/// exists, and (re)writes `manifest.json` and `index.html`.
///
/// When there are no fragments (for example a gallery folder copied from CI
/// without the hidden folder) the existing `manifest.json` is used instead.
/// Returns the merged manifest.
Manifest rebuildGallery(
  Directory outputDir, {
  String title = 'Screenshot matrix',
}) {
  final List<Manifest> parts = <Manifest>[];
  final Directory fragments = Directory('${outputDir.path}/$fragmentsDirName');
  if (fragments.existsSync()) {
    final List<File> files =
        fragments
            .listSync()
            .whereType<File>()
            .where((File f) => f.path.endsWith('.json'))
            .toList()
          ..sort((File a, File b) => a.path.compareTo(b.path));
    for (final File f in files) {
      final Manifest? m = _readManifest(f);
      if (m != null) {
        parts.add(m);
      }
    }
  }
  if (parts.isEmpty) {
    final Manifest? existing = _readManifest(
      File('${outputDir.path}/$manifestFileName'),
    );
    if (existing != null) {
      parts.add(existing);
    }
  }
  final Manifest merged = Manifest.merge(parts);
  final Manifest pruned = Manifest(
    generatedAt: merged.generatedAt,
    entries: <ManifestEntry>[
      for (final ManifestEntry e in merged.entries)
        if (File('${outputDir.path}/${e.file}').existsSync()) e,
    ],
  );
  _writeAtomic(
    File('${outputDir.path}/$manifestFileName'),
    const JsonEncoder.withIndent('  ').convert(pruned.toJson()),
  );
  _writeAtomic(
    File('${outputDir.path}/$galleryFileName'),
    renderGalleryHtml(pruned, title: title),
  );
  return pruned;
}

Manifest? _readManifest(File file) {
  if (!file.existsSync()) {
    return null;
  }
  try {
    final Object? json = jsonDecode(file.readAsStringSync());
    return json is Map<String, Object?> ? Manifest.fromJson(json) : null;
  } on FormatException {
    return null;
  } on FileSystemException {
    return null;
  }
}

final Random _random = Random();

/// Writes [content] to a temp file next to [file], then renames it over
/// [file], so a parallel reader never sees a half-written file.
void _writeAtomic(File file, String content) {
  file.parent.createSync(recursive: true);
  final File tmp = File(
    '${file.path}.$pid.${_random.nextInt(1 << 32).toRadixString(16)}.tmp',
  );
  tmp.writeAsStringSync(content, flush: true);
  tmp.renameSync(file.path);
}
