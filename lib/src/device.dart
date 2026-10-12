import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The shape of the hardware cut-out drawn by the optional device frame.
enum DeviceNotch {
  /// No cut-out (older phones, tablets).
  none,

  /// A centered punch-hole camera (most Android phones).
  punchHole,

  /// An iPhone-style "dynamic island" pill.
  island,
}

/// A device preset: logical screen size, pixel density and safe-area insets.
///
/// Sizes are in logical pixels, exactly what `MediaQuery.sizeOf` reports on the
/// real device. Safe-area insets are close approximations of the real status
/// bar / home indicator / navigation bar heights.
@immutable
class Device {
  /// Creates a custom device.
  const Device({
    required this.id,
    required this.name,
    required this.size,
    required this.devicePixelRatio,
    this.safeArea = EdgeInsets.zero,
    this.platform = TargetPlatform.android,
    this.screenRadius = 0,
    this.notch = DeviceNotch.none,
  });

  /// iPhone SE (2nd/3rd gen): the smallest iPhone still supported.
  static const Device iphoneSE = Device(
    id: 'iphone_se',
    name: 'iPhone SE',
    size: Size(375, 667),
    devicePixelRatio: 2,
    safeArea: EdgeInsets.only(top: 20),
    platform: TargetPlatform.iOS,
  );

  /// iPhone 15.
  static const Device iphone15 = Device(
    id: 'iphone_15',
    name: 'iPhone 15',
    size: Size(393, 852),
    devicePixelRatio: 3,
    safeArea: EdgeInsets.only(top: 59, bottom: 34),
    platform: TargetPlatform.iOS,
    screenRadius: 55,
    notch: DeviceNotch.island,
  );

  /// iPhone 15 Pro Max: the largest current iPhone.
  static const Device iphone15ProMax = Device(
    id: 'iphone_15_pro_max',
    name: 'iPhone 15 Pro Max',
    size: Size(430, 932),
    devicePixelRatio: 3,
    safeArea: EdgeInsets.only(top: 59, bottom: 34),
    platform: TargetPlatform.iOS,
    screenRadius: 55,
    notch: DeviceNotch.island,
  );

  /// Google Pixel 7.
  static const Device pixel7 = Device(
    id: 'pixel_7',
    name: 'Pixel 7',
    size: Size(412, 915),
    devicePixelRatio: 2.625,
    safeArea: EdgeInsets.only(top: 32, bottom: 24),
    screenRadius: 32,
    notch: DeviceNotch.punchHole,
  );

  /// Samsung Galaxy A14: a popular budget phone with 3-button navigation.
  static const Device galaxyA14 = Device(
    id: 'galaxy_a14',
    name: 'Galaxy A14',
    size: Size(384, 854),
    devicePixelRatio: 2.8125,
    safeArea: EdgeInsets.only(top: 28, bottom: 48),
    screenRadius: 20,
    notch: DeviceNotch.punchHole,
  );

  /// A small 360-wide Android phone (the most common Android viewport).
  static const Device smallAndroid = Device(
    id: 'small_android',
    name: 'Small Android',
    size: Size(360, 640),
    devicePixelRatio: 2,
    safeArea: EdgeInsets.only(top: 24, bottom: 48),
  );

  /// iPad Pro 11-inch, portrait.
  static const Device ipad11 = Device(
    id: 'ipad_11',
    name: 'iPad Pro 11"',
    size: Size(834, 1194),
    devicePixelRatio: 2,
    safeArea: EdgeInsets.only(top: 24, bottom: 20),
    platform: TargetPlatform.iOS,
    screenRadius: 18,
  );

  /// Every built-in preset.
  static const List<Device> all = <Device>[
    iphoneSE,
    iphone15,
    iphone15ProMax,
    pixel7,
    galaxyA14,
    smallAndroid,
    ipad11,
  ];

  /// A short, file-name-safe identifier (`pixel_7`).
  final String id;

  /// A human readable name shown in the gallery (`Pixel 7`).
  final String name;

  /// The logical screen size in portrait.
  final Size size;

  /// Physical pixels per logical pixel.
  final double devicePixelRatio;

  /// Status bar / notch / home indicator insets, in logical pixels.
  final EdgeInsets safeArea;

  /// The platform this device runs. Used for `defaultTargetPlatform` when
  /// `useDevicePlatform` is on, and to pick the status bar style of the frame.
  final TargetPlatform platform;

  /// Corner radius of the physical screen, used by the device frame.
  final double screenRadius;

  /// The camera cut-out drawn by the device frame.
  final DeviceNotch notch;

  /// Whether this is an Apple device.
  bool get isApple =>
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

  /// The screen size in physical pixels.
  Size get physicalSize => size * devicePixelRatio;

  /// The same device rotated to landscape (safe areas move to the sides).
  Device get landscape => copyWith(
    id: '${id}_landscape',
    name: '$name (landscape)',
    size: size.flipped,
    safeArea: EdgeInsets.only(
      left: safeArea.top,
      right: safeArea.top,
      bottom: safeArea.bottom > 0 ? 21 : 0,
    ),
    notch: DeviceNotch.none,
  );

  /// Returns a copy with some fields replaced.
  Device copyWith({
    String? id,
    String? name,
    Size? size,
    double? devicePixelRatio,
    EdgeInsets? safeArea,
    TargetPlatform? platform,
    double? screenRadius,
    DeviceNotch? notch,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      safeArea: safeArea ?? this.safeArea,
      platform: platform ?? this.platform,
      screenRadius: screenRadius ?? this.screenRadius,
      notch: notch ?? this.notch,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Device &&
      other.id == id &&
      other.name == name &&
      other.size == size &&
      other.devicePixelRatio == devicePixelRatio &&
      other.safeArea == safeArea &&
      other.platform == platform &&
      other.screenRadius == screenRadius &&
      other.notch == notch;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    size,
    devicePixelRatio,
    safeArea,
    platform,
    screenRadius,
    notch,
  );

  @override
  String toString() =>
      'Device($id, ${size.width.toStringAsFixed(0)}x'
      '${size.height.toStringAsFixed(0)} @${devicePixelRatio}x)';
}
