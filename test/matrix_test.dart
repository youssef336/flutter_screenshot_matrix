import 'package:flutter/material.dart';
import 'package:flutter_screenshot_matrix/flutter_screenshot_matrix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('expandMatrix', () {
    test(
      'expands every combination in device > locale > theme > scale order',
      () {
        final List<ScreenshotContext> cells = expandMatrix(
          screen: 'Login',
          devices: const <Device>[Device.iphoneSE, Device.pixel7],
          locales: const <Locale>[Locale('en'), Locale('ar')],
          themes: const <ThemeMode>[ThemeMode.light, ThemeMode.dark],
          textScales: const <double>[1.0, 1.3],
        );
        expect(cells, hasLength(16));
        expect(cells.first.id, 'login/iphone_se__en__light__1.0x');
        expect(cells[1].id, 'login/iphone_se__en__light__1.3x');
        expect(cells[2].id, 'login/iphone_se__en__dark__1.0x');
        expect(cells[4].id, 'login/iphone_se__ar__light__1.0x');
        expect(cells.last.id, 'login/pixel_7__ar__dark__1.3x');
        expect(cells.map((ScreenshotContext c) => c.id).toSet(), hasLength(16));
      },
    );

    test('drops duplicates', () {
      final List<ScreenshotContext> cells = expandMatrix(
        screen: 'home',
        devices: const <Device>[Device.pixel7, Device.pixel7],
        locales: const <Locale>[Locale('en'), Locale('en')],
        themes: const <ThemeMode>[ThemeMode.light],
        textScales: const <double>[1.0, 1.0],
      );
      expect(cells, hasLength(1));
    });

    test('rejects empty axes, non-positive scales and clashing device ids', () {
      List<ScreenshotContext> expand({
        List<Device> devices = const <Device>[Device.pixel7],
        List<Locale> locales = const <Locale>[Locale('en')],
        List<double> scales = const <double>[1.0],
      }) => expandMatrix(
        screen: 's',
        devices: devices,
        locales: locales,
        themes: const <ThemeMode>[ThemeMode.light],
        textScales: scales,
      );
      expect(() => expand(devices: <Device>[]), throwsArgumentError);
      expect(() => expand(locales: <Locale>[]), throwsArgumentError);
      expect(() => expand(scales: <double>[0]), throwsArgumentError);
      expect(
        () => expand(
          devices: <Device>[
            Device.pixel7,
            Device.pixel7.copyWith(devicePixelRatio: 3),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('ScreenshotContext', () {
    const ScreenshotContext ar = ScreenshotContext(
      screen: 'Profile (edit)',
      device: Device.galaxyA14,
      locale: Locale('ar', 'EG'),
      themeMode: ThemeMode.dark,
      textScale: 1.25,
    );

    test('derives direction, brightness and file names', () {
      expect(ar.isRtl, isTrue);
      expect(ar.textDirection, TextDirection.rtl);
      expect(ar.brightness, Brightness.dark);
      expect(ar.localeTag, 'ar-EG');
      expect(ar.fileStem, 'galaxy_a14__ar-EG__dark__1.25x');
      expect(ar.id, 'profile_edit/galaxy_a14__ar-EG__dark__1.25x');
      expect(ar.label, 'Galaxy A14 · ar-EG · dark · 1.25x');
    });

    test('LTR locales and system theme', () {
      const ScreenshotContext en = ScreenshotContext(
        screen: 's',
        device: Device.pixel7,
        locale: Locale('en'),
        themeMode: ThemeMode.system,
        textScale: 1,
      );
      expect(en.isRtl, isFalse);
      expect(en.brightness, Brightness.light);
      expect(en.themeName, 'system');
    });
  });

  group('Device', () {
    test('presets have unique ids and sane metrics', () {
      expect(
        Device.all.map((Device d) => d.id).toSet(),
        hasLength(Device.all.length),
      );
      for (final Device d in Device.all) {
        expect(d.size.width, lessThan(d.size.height), reason: d.id);
        expect(d.devicePixelRatio, greaterThan(1), reason: d.id);
      }
      expect(Device.iphone15ProMax.physicalSize, const Size(1290, 2796));
      expect(Device.iphoneSE.isApple, isTrue);
      expect(Device.pixel7.isApple, isFalse);
    });

    test('landscape flips the size and moves the insets', () {
      final Device l = Device.iphone15.landscape;
      expect(l.size, const Size(852, 393));
      expect(l.id, 'iphone_15_landscape');
      expect(l.safeArea.left, 59);
      expect(l.notch, DeviceNotch.none);
    });
  });
}
