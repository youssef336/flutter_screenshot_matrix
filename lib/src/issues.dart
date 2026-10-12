import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'manifest.dart';

/// What to do when a kind of problem shows up while capturing.
enum IssuePolicy {
  /// Record it in the manifest (red badge in the gallery) and keep the test
  /// green.
  record,

  /// Record it, write the screenshot, then fail the test.
  fail,

  /// Do not intercept it: Flutter's test framework handles it as usual (an
  /// error fails the test before a screenshot is written).
  ignore,
}

final RegExp _overflowPattern = RegExp(r'^A (\w+) overflowed by (.+)\.$');
final RegExp _locationPattern = RegExp(r'file://(/[^\s:]+\.dart):(\d+):(\d+)');

/// Whether [details] describes a layout overflow (the yellow-and-black
/// stripes): `A RenderFlex overflowed by 42 pixels on the right.`
bool isOverflowError(FlutterErrorDetails details) =>
    _overflowPattern.hasMatch(_firstLine(details.exceptionAsString()));

/// Converts a reported Flutter error into a [ScreenshotIssue].
ScreenshotIssue issueFromErrorDetails(FlutterErrorDetails details) {
  final String headline = _firstLine(details.exceptionAsString());
  final bool overflow = _overflowPattern.hasMatch(headline);
  final String full = _safeToString(details);
  return ScreenshotIssue(
    kind: overflow ? IssueKind.overflow : IssueKind.exception,
    message: headline,
    source: sourceLocationOf(full),
    details: _trimDetails(full, details.stack, overflow: overflow),
  );
}

/// The first `file:///...dart:line:col` mentioned in [text], relative to the
/// current directory when it is inside it.
String? sourceLocationOf(String text, {String? root}) {
  final Iterable<RegExpMatch> matches = _locationPattern.allMatches(text);
  if (matches.isEmpty) {
    return null;
  }
  // Prefer a location in the project over one inside the Flutter SDK.
  final String base = '${root ?? Directory.current.path}/';
  final RegExpMatch match = matches.firstWhere(
    (RegExpMatch m) => m.group(1)!.startsWith(base),
    orElse: () => matches.first,
  );
  String path = match.group(1)!;
  if (path.startsWith(base)) {
    path = path.substring(base.length);
  }
  return '$path:${match.group(2)}:${match.group(3)}';
}

String _firstLine(String text) {
  final String trimmed = text.trim();
  final int nl = trimmed.indexOf('\n');
  return nl < 0 ? trimmed : trimmed.substring(0, nl).trim();
}

String _safeToString(FlutterErrorDetails details) {
  try {
    return details.toString();
  } on Object {
    return details.exceptionAsString();
  }
}

String _trimDetails(String full, StackTrace? stack, {required bool overflow}) {
  final List<String> lines = full
      .split('\n')
      .where((String l) => !l.contains('◢◤') && l.trim().isNotEmpty)
      .take(overflow ? 30 : 20)
      .toList();
  if (!overflow && stack != null) {
    lines
      ..add('Stack:')
      ..addAll(
        stack
            .toString()
            .split('\n')
            .where((String l) => l.trim().isNotEmpty)
            .take(12),
      );
  }
  return lines.join('\n');
}

/// Intercepts `FlutterError.onError` while one screenshot is being taken.
class IssueCollector {
  /// Creates a collector with the given policies.
  IssueCollector({
    this.onOverflow = IssuePolicy.record,
    this.onException = IssuePolicy.fail,
  });

  /// Policy for layout overflows.
  final IssuePolicy onOverflow;

  /// Policy for every other reported error.
  final IssuePolicy onException;

  /// Everything recorded so far.
  final List<ScreenshotIssue> issues = <ScreenshotIssue>[];

  FlutterExceptionHandler? _previous;
  bool _active = false;

  /// Starts intercepting. Must be paired with [stop].
  void start() {
    assert(!_active, 'IssueCollector.start called twice');
    _active = true;
    _previous = FlutterError.onError;
    FlutterError.onError = handle;
  }

  /// Restores the previous handler.
  void stop() {
    if (!_active) {
      return;
    }
    FlutterError.onError = _previous;
    _previous = null;
    _active = false;
  }

  /// Handles one reported error according to the policies.
  void handle(FlutterErrorDetails details) {
    final IssuePolicy policy = isOverflowError(details)
        ? onOverflow
        : onException;
    if (policy == IssuePolicy.ignore) {
      final FlutterExceptionHandler? previous = _previous;
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }
      return;
    }
    issues.add(issueFromErrorDetails(details));
  }

  /// Adds an issue found some other way (thrown exception, golden mismatch).
  void add(ScreenshotIssue issue) => issues.add(issue);

  /// Whether a recorded issue's policy says the test must fail.
  bool get shouldFail => issues.any((ScreenshotIssue i) {
    switch (i.kind) {
      case IssueKind.overflow:
        return onOverflow == IssuePolicy.fail;
      case IssueKind.exception:
        return onException == IssuePolicy.fail;
      case IssueKind.golden:
        return true;
      case IssueKind.textTruncated:
        return false;
    }
  });
}

/// Finds text that is cut off: ellipsized or stopped at `maxLines`, or a
/// non-wrapping line wider than its box. Offstage subtrees are skipped.
List<ScreenshotIssue> findTruncatedText(RenderObject root) {
  final List<ScreenshotIssue> found = <ScreenshotIssue>[];
  void visit(RenderObject node) {
    if (node is RenderOffstage && node.offstage) {
      return;
    }
    if (node is RenderParagraph && node.hasSize && !node.size.isEmpty) {
      final String? reason = _truncationReason(node);
      if (reason != null) {
        String text = node.text.toPlainText().replaceAll('\n', ' ').trim();
        if (text.length > 60) {
          text = '${text.substring(0, 57)}...';
        }
        found.add(
          ScreenshotIssue(
            kind: IssueKind.textTruncated,
            message: '"$text" is $reason',
          ),
        );
      }
    }
    node.visitChildren(visit);
  }

  visit(root);
  return found;
}

String? _truncationReason(RenderParagraph p) {
  if (p.didExceedMaxLines) {
    return switch (p.overflow) {
      TextOverflow.ellipsis => 'ellipsized',
      TextOverflow.fade => 'faded out',
      _ => 'cut at maxLines (${p.maxLines})',
    };
  }
  if (!p.softWrap) {
    try {
      final double needed = p.getMaxIntrinsicWidth(double.infinity);
      if (needed > p.size.width + 0.5) {
        return 'clipped (needs ${needed.toStringAsFixed(0)}px, '
            'has ${p.size.width.toStringAsFixed(0)}px)';
      }
    } on Object {
      return null;
    }
  }
  return null;
}
