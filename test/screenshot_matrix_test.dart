import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenshot_matrix/flutter_screenshot_matrix.dart';
import 'package:flutter_test/flutter_test.dart';

const String _out = 'build/screenshot_matrix_test';

/// PNG width/height from the IHDR chunk.
(int, int) _pngSize(File file) {
  final ByteData data = ByteData.sublistView(file.readAsBytesSync());
  return (data.getUint32(16), data.getUint32(20));
}

class _Card extends StatelessWidget {
  const _Card();

  @override
  Widget build(BuildContext context) {
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: const Text('Card')),
      body: Row(
        children: <Widget>[
          const Icon(Icons.star),
          // Overflows only with the long (Arabic) label.
          SizedBox(width: ar ? 900 : 100, height: 20),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(() {
    final Directory dir = Directory(_out);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  screenshotMatrix(
    'card',
    (_) => const _Card(),
    devices: const <Device>[Device.pixel7, Device.iphoneSE],
    locales: const <Locale>[Locale('en'), Locale('ar')],
    themes: const <ThemeMode>[ThemeMode.light],
    textScales: const <double>[1.0],
    outputDir: _out,
    galleryTitle: 'Package test',
  );

  screenshotMatrix(
    'framed',
    (_) => const Scaffold(body: Center(child: Text('Hello'))),
    devices: const <Device>[Device.iphone15],
    locales: const <Locale>[Locale('en')],
    themes: const <ThemeMode>[ThemeMode.dark],
    textScales: const <double>[1.0],
    frame: true,
    outputDir: _out,
  );

  screenshotMatrix(
    'broken',
    (_) => Builder(builder: (_) => throw StateError('broken screen')),
    devices: const <Device>[Device.pixel7],
    locales: const <Locale>[Locale('en')],
    themes: const <ThemeMode>[ThemeMode.light],
    textScales: const <double>[1.0],
    onException: IssuePolicy.record,
    outputDir: _out,
  );

  test('wrote PNGs, fragments, manifest and gallery', () {
    final Map<String, Object?> json =
        jsonDecode(File('$_out/manifest.json').readAsStringSync())
            as Map<String, Object?>;
    final List<ManifestEntry> entries = Manifest.fromJson(json).entries;
    expect(entries.map((ManifestEntry e) => e.id), <String>[
      'broken/pixel_7__en__light__1.0x',
      'card/pixel_7__en__light__1.0x',
      'card/pixel_7__ar__light__1.0x',
      'card/iphone_se__en__light__1.0x',
      'card/iphone_se__ar__light__1.0x',
      'framed/iphone_15__en__dark__1.0x',
    ]);

    ManifestEntry byId(String id) =>
        entries.firstWhere((ManifestEntry e) => e.id == id);

    // Overflow only in Arabic, recorded with the source line.
    expect(byId('card/pixel_7__en__light__1.0x').issues, isEmpty);
    final ManifestEntry ar = byId('card/pixel_7__ar__light__1.0x');
    expect(ar.rtl, isTrue);
    expect(ar.issues.single.kind, IssueKind.overflow);
    expect(
      ar.issues.single.source,
      startsWith('test/screenshot_matrix_test.dart:'),
    );

    // The exception is recorded and the error screen is still captured.
    expect(
      byId('broken/pixel_7__en__light__1.0x').issues.first.message,
      contains('broken screen'),
    );

    // Physical size = logical size x device pixel ratio.
    final ManifestEntry se = byId('card/iphone_se__en__light__1.0x');
    expect(_pngSize(File('$_out/${se.file}')), (750, 1334));
    expect((se.imageWidth, se.imageHeight), (750, 1334));

    // The frame adds a 12 dp bezel on every side.
    final ManifestEntry framed = byId('framed/iphone_15__en__dark__1.0x');
    expect(framed.framed, isTrue);
    expect(_pngSize(File('$_out/${framed.file}')), (
      393 * 3 + 72,
      852 * 3 + 72,
    ));

    expect(File('$_out/.manifest/card.json').existsSync(), isTrue);
    final String html = File('$_out/index.html').readAsStringSync();
    expect(html, contains('card/pixel_7__ar__light__1.0x.png'));
  });
}
