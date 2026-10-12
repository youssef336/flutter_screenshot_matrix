import 'dart:convert';

import 'package:flutter_screenshot_matrix/flutter_screenshot_matrix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Manifest manifest(String message) => Manifest(
    entries: <ManifestEntry>[
      ManifestEntry(
        id: 'login/pixel_7__ar__dark__1.0x',
        screen: 'login',
        deviceId: 'pixel_7',
        deviceName: 'Pixel 7',
        logicalWidth: 412,
        logicalHeight: 915,
        devicePixelRatio: 2.625,
        platform: 'android',
        locale: 'ar',
        rtl: true,
        theme: 'dark',
        textScale: 1,
        file: 'login/pixel_7__ar__dark__1.0x.png',
        issues: <ScreenshotIssue>[
          ScreenshotIssue(kind: IssueKind.overflow, message: message),
        ],
      ),
    ],
  );

  String embeddedJson(String html) {
    final RegExpMatch m = RegExp(
      r'<script type="application/json" id="manifest">(.*?)</script>',
      dotAll: true,
    ).firstMatch(html)!;
    return m.group(1)!;
  }

  test('is self-contained and embeds the manifest', () {
    final String html = renderGalleryHtml(
      manifest('overflowed'),
      title: 'Demo',
    );
    expect(html, startsWith('<!doctype html>'));
    expect(html, contains('<title>Demo</title>'));
    expect(html, isNot(contains('<link')));
    expect(html, isNot(contains('src="http')));
    final Map<String, Object?> data =
        jsonDecode(embeddedJson(html)) as Map<String, Object?>;
    final List<Object?> entries = data['entries']! as List<Object?>;
    expect(
      (entries.single! as Map<String, Object?>)['file'],
      'login/pixel_7__ar__dark__1.0x.png',
    );
    // Filters, grouping and the red overflow badge are wired up.
    for (final String hook in <String>[
      'issues only',
      'group by',
      'overflow ×',
      'badge error',
    ]) {
      expect(html, contains(hook));
    }
  });

  test('data cannot break out of the script element', () {
    const String evil = '</script><script>alert(1)</script><!--';
    final String html = renderGalleryHtml(manifest(evil), title: '{{DATA}}');
    final String json = embeddedJson(html);
    expect(json, isNot(contains('<')));
    final Map<String, Object?> data = jsonDecode(json) as Map<String, Object?>;
    final Map<String, Object?> e =
        (data['entries']! as List<Object?>).single! as Map<String, Object?>;
    final Map<String, Object?> issue =
        (e['issues']! as List<Object?>).single! as Map<String, Object?>;
    expect(issue['message'], evil);
    // The title is escaped text, not a second copy of the data.
    expect(html, contains('<title>{{DATA}}</title>'));
    expect('<script type="application/json"'.allMatches(html), hasLength(1));
  });
}
