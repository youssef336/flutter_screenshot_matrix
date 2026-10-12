import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenshot_matrix/flutter_screenshot_matrix.dart';
import 'package:flutter_screenshot_matrix/src/fonts.dart';
import 'package:flutter_screenshot_matrix/src/issues.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _overflowingRow() => const Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: SizedBox(
      width: 100,
      child: Row(children: <Widget>[SizedBox(width: 160, height: 10)]),
    ),
  ),
);

void main() {
  group('IssueCollector', () {
    testWidgets('records a RenderFlex overflow instead of failing', (
      WidgetTester tester,
    ) async {
      final IssueCollector collector = IssueCollector()..start();
      try {
        await tester.pumpWidget(_overflowingRow());
      } finally {
        collector.stop();
      }
      expect(tester.takeException(), isNull);
      final ScreenshotIssue issue = collector.issues.single;
      expect(issue.kind, IssueKind.overflow);
      expect(
        issue.message,
        'A RenderFlex overflowed by 60 pixels on the right.',
      );
      expect(issue.source, startsWith('test/issues_test.dart:'));
      expect(issue.details, isNot(contains('◢◤')));
      expect(collector.shouldFail, isFalse);
    });

    testWidgets('fail policy marks the cell as failing', (
      WidgetTester tester,
    ) async {
      final IssueCollector collector = IssueCollector(
        onOverflow: IssuePolicy.fail,
      )..start();
      try {
        await tester.pumpWidget(_overflowingRow());
      } finally {
        collector.stop();
      }
      expect(collector.shouldFail, isTrue);
    });

    testWidgets('records build exceptions as exceptions', (
      WidgetTester tester,
    ) async {
      final IssueCollector collector = IssueCollector(
        onException: IssuePolicy.record,
      )..start();
      try {
        await tester.pumpWidget(
          Builder(builder: (_) => throw StateError('boom')),
        );
      } finally {
        collector.stop();
      }
      final ScreenshotIssue issue = collector.issues.single;
      expect(issue.kind, IssueKind.exception);
      expect(issue.message, contains('boom'));
      expect(issue.details, contains('Stack:'));
      expect(collector.shouldFail, isFalse);
    });

    testWidgets('ignore policy hands the error back to the framework', (
      WidgetTester tester,
    ) async {
      final IssueCollector collector = IssueCollector(
        onOverflow: IssuePolicy.ignore,
      )..start();
      try {
        await tester.pumpWidget(_overflowingRow());
      } finally {
        collector.stop();
      }
      expect(collector.issues, isEmpty);
      expect(tester.takeException(), isA<FlutterError>());
    });
  });

  testWidgets('findTruncatedText finds ellipsized and clipped text only', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            SizedBox(
              width: 50,
              child: Text(
                'a long sentence that cannot fit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                'nowrap clipped text',
                softWrap: false,
                overflow: TextOverflow.clip,
              ),
            ),
            Text('fits'),
            Offstage(
              child: SizedBox(
                width: 10,
                child: Text('hidden overflow', maxLines: 1),
              ),
            ),
          ],
        ),
      ),
    );
    final List<ScreenshotIssue> found = findTruncatedText(
      tester.renderObject(find.byType(Column)),
    );
    expect(found.map((ScreenshotIssue i) => i.message), <Matcher>[
      allOf(contains('a long sentence'), contains('ellipsized')),
      allOf(contains('nowrap'), contains('clipped')),
    ]);
    expect(found.every((ScreenshotIssue i) => !i.kind.isError), isTrue);
  });

  test('sourceLocationOf prefers project files over the SDK', () {
    const String text =
        'at file:///sdk/packages/flutter/lib/src/widgets/basic.dart:10:2\n'
        'The relevant error-causing widget was:\n'
        '  Row Row:file:///work/app/lib/home.dart:42:7';
    expect(sourceLocationOf(text, root: '/work/app'), 'lib/home.dart:42:7');
    expect(sourceLocationOf('no location'), isNull);
  });

  group('fonts', () {
    test('parseFontManifest reads families and assets', () {
      final Map<String, List<String>> fonts = parseFontManifest('''
[
  {"family": "Cairo", "fonts": [{"asset": "assets/fonts/Cairo.ttf"}]},
  {"family": "packages/cupertino_icons/CupertinoIcons",
   "fonts": [{"asset": "packages/cupertino_icons/assets/CupertinoIcons.ttf"}]},
  {"family": "Broken"}
]''');
      expect(fonts.keys, <String>[
        'Cairo',
        'packages/cupertino_icons/CupertinoIcons',
      ]);
      expect(fonts['Cairo'], <String>['assets/fonts/Cairo.ttf']);
      expect(parseFontManifest('{}'), isEmpty);
    });

    test('bareFamilyName strips the package prefix', () {
      expect(bareFamilyName('packages/foo/Bar'), 'Bar');
      expect(bareFamilyName('Bar'), isNull);
    });

    test('finds the SDK material fonts', () {
      final Directory? dir = findSdkMaterialFonts();
      expect(dir, isNotNull);
      expect(File('${dir!.path}/Roboto-Regular.ttf').existsSync(), isTrue);
      expect(
        findSdkMaterialFonts(
          environment: const <String, String>{},
          executable: '/nonexistent/bin/tester',
        ),
        isNull,
      );
    });

    test('loads Roboto, MaterialIcons and the Apple aliases', () async {
      final LoadedFonts fonts = await loadScreenshotFonts();
      expect(
        fonts.families,
        containsAll(<String>['Roboto', 'MaterialIcons', 'CupertinoSystemText']),
      );
      expect(fonts.warnings, isEmpty);
    });
  });
}
