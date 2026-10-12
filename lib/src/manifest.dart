// Pure Dart (no Flutter imports): shared by the test helper and the
// `dart run flutter_screenshot_matrix:gallery` command.

/// What kind of problem was found while capturing a screenshot.
enum IssueKind {
  /// A `RenderFlex` (or other overflow-indicating box) overflowed.
  overflow,

  /// A `Text` was ellipsized or cut at `maxLines`, or clipped horizontally.
  textTruncated,

  /// Any other exception reported while building, laying out or painting.
  exception,

  /// The golden comparison failed (golden mode only).
  golden;

  /// Whether this kind is a hard error (red badge) or a warning (amber).
  bool get isError => this != IssueKind.textTruncated;

  /// Parses [name], falling back to [IssueKind.exception].
  static IssueKind parse(String? name) => IssueKind.values.firstWhere(
    (IssueKind k) => k.name == name,
    orElse: () => IssueKind.exception,
  );
}

/// One problem found while capturing a screenshot.
class ScreenshotIssue {
  /// Creates an issue.
  const ScreenshotIssue({
    required this.kind,
    required this.message,
    this.source,
    this.details,
  });

  /// Reads an issue from its JSON form.
  factory ScreenshotIssue.fromJson(Map<String, Object?> json) {
    return ScreenshotIssue(
      kind: IssueKind.parse(json['kind'] as String?),
      message: json['message'] as String? ?? '',
      source: json['source'] as String?,
      details: json['details'] as String?,
    );
  }

  /// The category.
  final IssueKind kind;

  /// A one-line summary, e.g. `A RenderFlex overflowed by 42 pixels on the
  /// right.`
  final String message;

  /// Where it came from, when known: `lib/login_page.dart:40:18`.
  final String? source;

  /// The full error text (stack traces trimmed).
  final String? details;

  /// The JSON form.
  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind.name,
    'message': message,
    if (source != null) 'source': source,
    if (details != null) 'details': details,
  };

  @override
  String toString() =>
      '[${kind.name}] $message${source == null ? '' : ' ($source)'}';
}

/// One screenshot in the manifest.
class ManifestEntry {
  /// Creates an entry.
  const ManifestEntry({
    required this.id,
    required this.screen,
    required this.deviceId,
    required this.deviceName,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.devicePixelRatio,
    required this.platform,
    required this.locale,
    required this.rtl,
    required this.theme,
    required this.textScale,
    required this.file,
    this.framed = false,
    this.imageWidth = 0,
    this.imageHeight = 0,
    this.issues = const <ScreenshotIssue>[],
  });

  /// Reads an entry from its JSON form.
  factory ManifestEntry.fromJson(Map<String, Object?> json) {
    final Object? issues = json['issues'];
    return ManifestEntry(
      id: json['id'] as String? ?? '',
      screen: json['screen'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      logicalWidth: (json['logicalWidth'] as num?)?.toDouble() ?? 0,
      logicalHeight: (json['logicalHeight'] as num?)?.toDouble() ?? 0,
      devicePixelRatio: (json['devicePixelRatio'] as num?)?.toDouble() ?? 1,
      platform: json['platform'] as String? ?? '',
      locale: json['locale'] as String? ?? '',
      rtl: json['rtl'] as bool? ?? false,
      theme: json['theme'] as String? ?? '',
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1,
      file: json['file'] as String? ?? '',
      framed: json['framed'] as bool? ?? false,
      imageWidth: (json['imageWidth'] as num?)?.toInt() ?? 0,
      imageHeight: (json['imageHeight'] as num?)?.toInt() ?? 0,
      issues: <ScreenshotIssue>[
        if (issues is List<Object?>)
          for (final Object? issue in issues)
            if (issue is Map<String, Object?>) ScreenshotIssue.fromJson(issue),
      ],
    );
  }

  /// Unique id: `<screen>/<file stem>`.
  final String id;

  /// The screen name given to `screenshotMatrix`.
  final String screen;

  /// [Device.id].
  final String deviceId;

  /// [Device.name].
  final String deviceName;

  /// Logical screen width.
  final double logicalWidth;

  /// Logical screen height.
  final double logicalHeight;

  /// Physical pixels per logical pixel.
  final double devicePixelRatio;

  /// `android`, `iOS`, ...
  final String platform;

  /// BCP-47 style tag: `en`, `ar`, `pt-BR`.
  final String locale;

  /// Whether [locale] is a right-to-left language.
  final bool rtl;

  /// `light`, `dark` or `system`.
  final String theme;

  /// The text scale factor.
  final double textScale;

  /// PNG path, relative to the gallery folder.
  final String file;

  /// Whether the PNG includes a device frame.
  final bool framed;

  /// PNG width in pixels.
  final int imageWidth;

  /// PNG height in pixels.
  final int imageHeight;

  /// Problems found while capturing.
  final List<ScreenshotIssue> issues;

  /// Whether any issue is an error (overflow, exception, golden mismatch).
  bool get hasErrors => issues.any((ScreenshotIssue i) => i.kind.isError);

  /// The JSON form.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'screen': screen,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'logicalWidth': logicalWidth,
    'logicalHeight': logicalHeight,
    'devicePixelRatio': devicePixelRatio,
    'platform': platform,
    'locale': locale,
    'rtl': rtl,
    'theme': theme,
    'textScale': textScale,
    'file': file,
    'framed': framed,
    'imageWidth': imageWidth,
    'imageHeight': imageHeight,
    'issues': <Map<String, Object?>>[
      for (final ScreenshotIssue issue in issues) issue.toJson(),
    ],
  };
}

/// All screenshots of a run (or of one screen, for a per-screen fragment).
class Manifest {
  /// Creates a manifest.
  Manifest({required this.entries, DateTime? generatedAt})
    : generatedAt = generatedAt ?? DateTime.now().toUtc();

  /// Reads a manifest from its JSON form.
  factory Manifest.fromJson(Map<String, Object?> json) {
    final Object? entries = json['entries'];
    return Manifest(
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? ''),
      entries: <ManifestEntry>[
        if (entries is List<Object?>)
          for (final Object? e in entries)
            if (e is Map<String, Object?>) ManifestEntry.fromJson(e),
      ],
    );
  }

  /// Format version written to disk.
  static const int formatVersion = 1;

  /// When the manifest was written (UTC).
  final DateTime generatedAt;

  /// The screenshots.
  final List<ManifestEntry> entries;

  /// Screen names in first-seen order.
  List<String> get screens =>
      _distinct(entries.map((ManifestEntry e) => e.screen));

  /// Merges several manifests. Later manifests win on duplicate ids; the
  /// result is sorted by screen, then by the original order.
  static Manifest merge(Iterable<Manifest> manifests) {
    final Map<String, ManifestEntry> byId = <String, ManifestEntry>{};
    DateTime latest = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    for (final Manifest m in manifests) {
      if (m.generatedAt.isAfter(latest)) {
        latest = m.generatedAt;
      }
      for (final ManifestEntry e in m.entries) {
        byId[e.id] = e;
      }
    }
    final List<ManifestEntry> merged = byId.values.toList();
    final List<String> order = _distinct(
      merged.map((ManifestEntry e) => e.screen),
    )..sort();
    final List<ManifestEntry> sorted = <ManifestEntry>[
      for (final String screen in order)
        ...merged.where((ManifestEntry e) => e.screen == screen),
    ];
    return Manifest(entries: sorted, generatedAt: latest);
  }

  /// The JSON form.
  Map<String, Object?> toJson() => <String, Object?>{
    'version': formatVersion,
    'generatedAt': generatedAt.toIso8601String(),
    'entries': <Map<String, Object?>>[
      for (final ManifestEntry e in entries) e.toJson(),
    ],
  };

  static List<String> _distinct(Iterable<String> values) {
    final List<String> out = <String>[];
    for (final String v in values) {
      if (!out.contains(v)) {
        out.add(v);
      }
    }
    return out;
  }
}

/// Turns a screen name into a folder/file-safe slug: `Login (error)` ->
/// `login_error`.
String slugify(String value) {
  final String slug = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return slug.isEmpty ? 'screen' : slug;
}

/// Formats a text scale for ids and labels: `1.0` -> `1.0x`, `1.25` ->
/// `1.25x`.
String formatTextScale(double scale) {
  String text = scale.toStringAsFixed(2);
  if (text.endsWith('0')) {
    text = text.substring(0, text.length - 1);
  }
  return '${text}x';
}

/// Language codes written right-to-left.
const Set<String> rtlLanguages = <String>{
  'ar',
  'arc',
  'ckb',
  'dv',
  'fa',
  'he',
  'iw',
  'khw',
  'ks',
  'ku',
  'ps',
  'sd',
  'ur',
  'yi',
};
