import 'dart:convert';
import 'dart:io';

import 'package:flutter_screenshot_matrix/flutter_screenshot_matrix.dart';
import 'package:flutter_screenshot_matrix/src/gallery_writer.dart';
import 'package:flutter_screenshot_matrix/src/manifest.dart';
import 'package:flutter_test/flutter_test.dart';

ManifestEntry entry(
  String screen,
  String stem, {
  List<ScreenshotIssue>? issues,
}) {
  return ManifestEntry(
    id: '$screen/$stem',
    screen: screen,
    deviceId: 'pixel_7',
    deviceName: 'Pixel 7',
    logicalWidth: 412,
    logicalHeight: 915,
    devicePixelRatio: 2.625,
    platform: 'android',
    locale: 'ar',
    rtl: true,
    theme: 'dark',
    textScale: 1.3,
    file: '$screen/$stem.png',
    imageWidth: 1082,
    imageHeight: 2402,
    issues: issues ?? const <ScreenshotIssue>[],
  );
}

void main() {
  test('manifest JSON round trip', () {
    final Manifest m = Manifest(
      generatedAt: DateTime.utc(2026, 10, 12),
      entries: <ManifestEntry>[
        entry(
          'login',
          'a',
          issues: const <ScreenshotIssue>[
            ScreenshotIssue(
              kind: IssueKind.overflow,
              message: 'A RenderFlex overflowed by 4 pixels on the right.',
              source: 'lib/login.dart:10:5',
            ),
          ],
        ),
      ],
    );
    final Manifest back = Manifest.fromJson(
      jsonDecode(jsonEncode(m.toJson())) as Map<String, Object?>,
    );
    expect(back.generatedAt, DateTime.utc(2026, 10, 12));
    expect(back.entries.single.toJson(), m.entries.single.toJson());
    expect(back.entries.single.hasErrors, isTrue);
    expect(back.entries.single.issues.single.kind, IssueKind.overflow);
  });

  test('tolerates unknown / missing fields', () {
    final Manifest m = Manifest.fromJson(<String, Object?>{
      'entries': <Object?>[
        <String, Object?>{
          'id': 'x/y',
          'issues': <Object?>[
            <String, Object?>{'kind': 'brandNew', 'message': 'm'},
            'garbage',
          ],
        },
        42,
      ],
    });
    expect(m.entries, hasLength(1));
    expect(m.entries.single.issues.single.kind, IssueKind.exception);
    expect(m.entries.single.devicePixelRatio, 1);
  });

  test('merge: later wins, grouped by screen name', () {
    final Manifest a = Manifest(
      entries: <ManifestEntry>[entry('settings', '1'), entry('login', '1')],
    );
    final Manifest b = Manifest(
      entries: <ManifestEntry>[
        entry(
          'login',
          '1',
          issues: const <ScreenshotIssue>[
            ScreenshotIssue(kind: IssueKind.textTruncated, message: 't'),
          ],
        ),
        entry('login', '2'),
      ],
    );
    final Manifest merged = Manifest.merge(<Manifest>[a, b]);
    expect(merged.entries.map((ManifestEntry e) => e.id), <String>[
      'login/1',
      'login/2',
      'settings/1',
    ]);
    expect(merged.entries.first.issues, hasLength(1));
    expect(merged.entries.first.hasErrors, isFalse);
    expect(merged.screens, <String>['login', 'settings']);
  });

  test('slugify and formatTextScale', () {
    expect(slugify('Login (error state)'), 'login_error_state');
    expect(slugify('  '), 'screen');
    expect(slugify('check-out'), 'check-out');
    expect(formatTextScale(1), '1.0x');
    expect(formatTextScale(1.3), '1.3x');
    expect(formatTextScale(1.25), '1.25x');
    expect(formatTextScale(2), '2.0x');
  });

  group('gallery files', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('matrix_gallery_'));
    tearDown(() => dir.deleteSync(recursive: true));

    void touch(String path) => (File(
      '${dir.path}/$path',
    )..createSync(recursive: true)).writeAsBytesSync(<int>[0]);

    test('merges fragments, prunes missing PNGs, writes html + json', () {
      touch('login/a.png');
      touch('profile/a.png');
      writeFragment(
        dir,
        'login',
        Manifest(
          entries: <ManifestEntry>[entry('login', 'a'), entry('login', 'gone')],
        ),
      );
      writeFragment(
        dir,
        'profile',
        Manifest(entries: <ManifestEntry>[entry('profile', 'a')]),
      );

      final Manifest m = rebuildGallery(dir, title: 'My <app>');
      expect(m.entries.map((ManifestEntry e) => e.id), <String>[
        'login/a',
        'profile/a',
      ]);
      final String html = File('${dir.path}/index.html').readAsStringSync();
      expect(html, contains('<title>My &lt;app&gt;</title>'));
      final Map<String, Object?> json =
          jsonDecode(File('${dir.path}/manifest.json').readAsStringSync())
              as Map<String, Object?>;
      expect((json['entries']! as List<Object?>).length, 2);
      expect(readFragment(dir, 'login')!.entries, hasLength(2));
      // No temp files left behind.
      expect(
        dir
            .listSync(recursive: true)
            .where((FileSystemEntity f) => f.path.endsWith('.tmp')),
        isEmpty,
      );
    });

    test('falls back to manifest.json when there are no fragments', () {
      touch('login/a.png');
      File('${dir.path}/manifest.json').writeAsStringSync(
        jsonEncode(
          Manifest(entries: <ManifestEntry>[entry('login', 'a')]).toJson(),
        ),
      );
      expect(rebuildGallery(dir).entries, hasLength(1));
      expect(File('${dir.path}/index.html').existsSync(), isTrue);
    });
  });
}
