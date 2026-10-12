// Rebuilds `index.html` and `manifest.json` from the per-screen manifest
// fragments written by `screenshotMatrix`, without running the tests again.
//
//   dart run flutter_screenshot_matrix:gallery [--dir screenshots] [--title "My app"]

import 'dart:io';

import 'package:flutter_screenshot_matrix/src/gallery_writer.dart';
import 'package:flutter_screenshot_matrix/src/manifest.dart';

const String _usage = '''
Rebuilds the screenshot gallery from its manifest.

Usage: dart run flutter_screenshot_matrix:gallery [options]

  --dir <path>     gallery folder (default: screenshots)
  --title <text>   page title (default: Screenshot matrix)
  -h, --help       show this help
''';

void main(List<String> args) {
  String dir = 'screenshots';
  String title = 'Screenshot matrix';
  for (int i = 0; i < args.length; i++) {
    final String arg = args[i];
    String value() {
      if (i + 1 >= args.length) {
        stderr.writeln('Missing value for $arg\n\n$_usage');
        exit(64);
      }
      return args[++i];
    }

    if (arg == '-h' || arg == '--help') {
      stdout.write(_usage);
      return;
    } else if (arg == '--dir') {
      dir = value();
    } else if (arg.startsWith('--dir=')) {
      dir = arg.substring('--dir='.length);
    } else if (arg == '--title') {
      title = value();
    } else if (arg.startsWith('--title=')) {
      title = arg.substring('--title='.length);
    } else {
      stderr.writeln('Unknown argument: $arg\n\n$_usage');
      exit(64);
    }
  }

  final Directory folder = Directory(dir);
  if (!folder.existsSync()) {
    stderr.writeln(
      'No gallery folder at "$dir". Run your screenshot tests first '
      '(flutter test), or pass --dir.',
    );
    exit(66);
  }
  final Manifest manifest = rebuildGallery(folder, title: title);
  final int errors = manifest.entries
      .where((ManifestEntry e) => e.hasErrors)
      .length;
  stdout.writeln(
    'Wrote ${folder.path}/$galleryFileName: ${manifest.entries.length} '
    'screenshots in ${manifest.screens.length} screens, $errors with errors.',
  );
}
