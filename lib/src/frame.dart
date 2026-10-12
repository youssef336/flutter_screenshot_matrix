import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'device.dart';

/// Options for the optional device frame drawn around a screenshot.
@immutable
class DeviceFrameStyle {
  /// Creates a frame style.
  const DeviceFrameStyle({
    this.bezelColor = const Color(0xFF1C1C1F),
    this.edgeColor = const Color(0xFF45454C),
    this.bezelWidth = 12,
    this.time = '9:41',
    this.drawStatusBar = true,
    this.drawSystemNavigation = true,
  });

  /// Fill of the bezel.
  final Color bezelColor;

  /// Thin highlight around the outer edge.
  final Color edgeColor;

  /// Bezel thickness in logical pixels.
  final double bezelWidth;

  /// The clock shown in the status bar.
  final String time;

  /// Whether to draw time, signal, Wi-Fi and battery in the top safe area.
  final bool drawStatusBar;

  /// Whether to draw the home indicator / navigation buttons in the bottom
  /// safe area.
  final bool drawSystemNavigation;
}

/// Draws [screen] (a screenshot of [device] at its pixel ratio) inside a
/// simple device frame: rounded bezel, camera cut-out, status bar and system
/// navigation. Icon colors follow the brightness of the app's own pixels under
/// them, like a real system bar.
///
/// Must run outside the fake-async zone (`tester.runAsync`).
Future<ui.Image> composeDeviceFrame(
  ui.Image screen,
  Device device, {
  DeviceFrameStyle style = const DeviceFrameStyle(),
}) async {
  final double r = screen.width / device.size.width;
  final double bezel = style.bezelWidth * r;
  final double w = screen.width.toDouble();
  final double h = screen.height.toDouble();
  final EdgeInsets inset = device.safeArea * r;
  final double screenRadius = device.screenRadius * r;
  final ui.Size outer = ui.Size(w + 2 * bezel, h + 2 * bezel);

  final ByteData? pixels = await screen.toByteData();
  final bool lightTop = pixels == null
      ? true
      : _isLight(pixels, screen.width, 0, math.max(1, inset.top.round()));
  final bool lightBottom = pixels == null
      ? true
      : _isLight(
          pixels,
          screen.width,
          math.max(0, screen.height - math.max(1, inset.bottom.round())),
          screen.height,
        );
  final Color topInk = lightTop
      ? const Color(0xFF000000)
      : const Color(0xFFFFFFFF);
  final Color bottomInk = lightBottom
      ? const Color(0xC0000000)
      : const Color(0xE0FFFFFF);

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);

  // Bezel.
  final RRect outerRect = RRect.fromRectAndRadius(
    Offset.zero & outer,
    Radius.circular(math.max(screenRadius, 6 * r) + bezel),
  );
  canvas.drawRRect(outerRect, Paint()..color = style.bezelColor);
  canvas.drawRRect(
    outerRect.deflate(r * 0.75),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 1.5
      ..color = style.edgeColor,
  );

  // Screen.
  canvas.save();
  canvas.translate(bezel, bezel);
  final RRect screenRect = RRect.fromRectAndRadius(
    Offset.zero & ui.Size(w, h),
    Radius.circular(screenRadius),
  );
  canvas.clipRRect(screenRect);
  canvas.drawImage(
    screen,
    Offset.zero,
    Paint()..filterQuality = FilterQuality.high,
  );

  if (style.drawStatusBar && inset.top >= 18 * r) {
    _drawStatusBar(canvas, device, w, inset.top, r, topInk, style.time);
  }
  _drawCutout(canvas, device, w, inset.top, r);
  if (style.drawSystemNavigation && inset.bottom > 0) {
    _drawNavigation(canvas, device, w, h, inset.bottom, r, bottomInk);
  }
  canvas.restore();

  final ui.Picture picture = recorder.endRecording();
  try {
    return await picture.toImage(outer.width.round(), outer.height.round());
  } finally {
    picture.dispose();
  }
}

/// Average luminance of rows [fromRow, toRow) of an RGBA buffer > 0.6.
bool _isLight(ByteData rgba, int width, int fromRow, int toRow) {
  double sum = 0;
  int count = 0;
  final int stepX = math.max(1, width ~/ 64);
  final int stepY = math.max(1, (toRow - fromRow) ~/ 16);
  for (int y = fromRow; y < toRow; y += stepY) {
    for (int x = 0; x < width; x += stepX) {
      final int i = (y * width + x) * 4;
      if (i + 3 >= rgba.lengthInBytes) {
        continue;
      }
      final double l =
          (0.2126 * rgba.getUint8(i) +
              0.7152 * rgba.getUint8(i + 1) +
              0.0722 * rgba.getUint8(i + 2)) /
          255;
      sum += l;
      count++;
    }
  }
  return count == 0 || sum / count > 0.6;
}

void _drawCutout(Canvas canvas, Device device, double w, double top, double r) {
  final Paint black = Paint()..color = const Color(0xFF000000);
  switch (device.notch) {
    case DeviceNotch.none:
      break;
    case DeviceNotch.island:
      final Rect pill = Rect.fromCenter(
        center: Offset(w / 2, 11 * r + 18.5 * r),
        width: 125 * r,
        height: 37 * r,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pill, Radius.circular(18.5 * r)),
        black,
      );
    case DeviceNotch.punchHole:
      canvas.drawCircle(
        Offset(w / 2, math.max(top / 2, 12 * r)),
        5.5 * r,
        black,
      );
  }
}

void _drawStatusBar(
  Canvas canvas,
  Device device,
  double w,
  double top,
  double r,
  Color ink,
  String time,
) {
  final bool apple = device.isApple;
  final double fontSize = (apple ? 15 : 13.5) * r;
  final ui.ParagraphBuilder builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontFamily: 'Roboto',
            fontSize: fontSize,
            fontWeight: apple ? FontWeight.w600 : FontWeight.w500,
            textDirection: TextDirection.ltr,
          ),
        )
        ..pushStyle(ui.TextStyle(color: ink))
        ..addText(time);
  final ui.Paragraph clock = builder.build()
    ..layout(ui.ParagraphConstraints(width: w));
  final double clockWidth = clock.maxIntrinsicWidth;
  final double centerY = apple && device.notch == DeviceNotch.island
      ? 11 * r + 18.5 * r
      : top / 2;
  final double iconH = (apple ? 11.5 : 11) * r;

  // Clock.
  final double clockX;
  if (apple && device.notch == DeviceNotch.island) {
    clockX = w * 0.18 - clockWidth / 2;
  } else if (apple) {
    clockX = (w - clockWidth) / 2;
  } else {
    clockX = 16 * r;
  }
  canvas.drawParagraph(clock, Offset(clockX, centerY - clock.height / 2));
  clock.dispose();

  // Right cluster: signal, wifi, battery (right to left).
  final Paint fill = Paint()..color = ink;
  final double batteryW = (apple ? 25 : 12) * r;
  final double batteryH = (apple ? 12 : 18) * r;
  final double right = apple && device.notch == DeviceNotch.island
      ? w * 0.82 + 40 * r
      : w - 14 * r;
  double x = right - batteryW;
  _drawBattery(
    canvas,
    Rect.fromLTWH(x, centerY - batteryH / 2, batteryW, batteryH),
    r,
    ink,
    apple,
  );
  x -= (apple ? 7 : 6) * r + iconH * 1.35;
  _drawWifi(
    canvas,
    Offset(x + iconH * 0.675, centerY + iconH / 2),
    iconH,
    fill,
  );
  x -= (apple ? 6 : 5) * r + iconH * 1.4;
  _drawSignal(
    canvas,
    Rect.fromLTWH(x, centerY - iconH / 2, iconH * 1.4, iconH),
    r,
    fill,
  );
}

void _drawBattery(Canvas canvas, Rect rect, double r, Color ink, bool apple) {
  if (apple) {
    final RRect body = RRect.fromRectAndRadius(rect, Radius.circular(3.5 * r));
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r
        ..color = ink.withValues(alpha: 0.45),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2 * r), Radius.circular(2 * r)),
      Paint()..color = ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.right + r, rect.center.dy - 2 * r, 1.5 * r, 4 * r),
        Radius.circular(r),
      ),
      Paint()..color = ink.withValues(alpha: 0.45),
    );
  } else {
    final Rect body = Rect.fromLTRB(
      rect.left,
      rect.top + 2 * r,
      rect.right,
      rect.bottom,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(1.5 * r)),
      Paint()..color = ink,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.center.dx - 2.5 * r, rect.top, 5 * r, 2 * r),
      Paint()..color = ink,
    );
  }
}

void _drawWifi(Canvas canvas, Offset bottomCenter, double size, Paint fill) {
  // A filled quarter-circle "fan" pointing up, like the system Wi-Fi glyph.
  final double radius = size * 1.05;
  final Path path = Path()
    ..moveTo(bottomCenter.dx, bottomCenter.dy)
    ..arcTo(
      Rect.fromCircle(center: bottomCenter, radius: radius),
      -math.pi * 3 / 4,
      math.pi / 2,
      false,
    )
    ..close();
  canvas.drawPath(path, fill);
}

void _drawSignal(Canvas canvas, Rect rect, double r, Paint fill) {
  const int bars = 4;
  final double gap = 1.6 * r;
  final double barW = (rect.width - gap * (bars - 1)) / bars;
  for (int i = 0; i < bars; i++) {
    final double barH = rect.height * (0.35 + 0.65 * (i + 1) / bars);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left + i * (barW + gap),
          rect.bottom - barH,
          barW,
          barH,
        ),
        Radius.circular(0.8 * r),
      ),
      fill,
    );
  }
}

void _drawNavigation(
  Canvas canvas,
  Device device,
  double w,
  double h,
  double bottom,
  double r,
  Color ink,
) {
  final Paint paint = Paint()..color = ink;
  final double cy = h - bottom / 2;
  if (device.isApple || bottom < 40 * r) {
    // Home indicator / gesture handle.
    final double width = (device.isApple ? 134 : 108) * r;
    final double y = device.isApple ? h - 8 * r - 2.5 * r : cy;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, y), width: width, height: 5 * r),
        Radius.circular(2.5 * r),
      ),
      paint,
    );
    return;
  }
  // Classic three-button navigation: recents, home, back.
  final double s = 7 * r;
  final Paint stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8 * r
    ..color = ink;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.25, cy),
        width: 2 * s,
        height: 2 * s,
      ),
      Radius.circular(2 * r),
    ),
    stroke,
  );
  canvas.drawCircle(Offset(w * 0.5, cy), s * 1.1, stroke);
  final Path back = Path()
    ..moveTo(w * 0.75 - s, cy)
    ..lineTo(w * 0.75 + s * 0.8, cy - s)
    ..lineTo(w * 0.75 + s * 0.8, cy + s)
    ..close();
  canvas.drawPath(back, stroke);
}
