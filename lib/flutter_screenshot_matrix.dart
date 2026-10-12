/// Screenshot every screen across devices x locales x themes x text scales in
/// plain `flutter test`, with real fonts, overflow detection, optional device
/// frames, golden comparison and a filterable HTML gallery.
library;

export 'src/context.dart' show ScreenshotContext, expandMatrix;
export 'src/device.dart' show Device, DeviceNotch;
export 'src/fonts.dart'
    show LoadedFonts, loadScreenshotFonts, parseFontManifest, bareFamilyName;
export 'src/frame.dart' show DeviceFrameStyle, composeDeviceFrame;
export 'src/gallery_html.dart' show renderGalleryHtml;
export 'src/gallery_writer.dart' show rebuildGallery;
export 'src/issues.dart'
    show IssuePolicy, IssueCollector, findTruncatedText, issueFromErrorDetails;
export 'src/manifest.dart'
    show IssueKind, ScreenshotIssue, ManifestEntry, Manifest;
export 'src/screenshot_matrix.dart'
    show
        ScreenBuilder,
        ScreenWrapper,
        ScreenshotHook,
        ScreenshotMode,
        ScreenshotMatrixDefaults,
        defaultScreenshotWrap,
        screenshotMatrix;
