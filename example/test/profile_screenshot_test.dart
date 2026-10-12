import 'package:flutter_screenshot_matrix/flutter_screenshot_matrix.dart';
import 'package:screenshot_matrix_example/screens/profile_page.dart';
import 'package:screenshot_matrix_example/screens/settings_page.dart';

void main() {
  // The profile page overflows in Arabic / large text on purpose: the
  // overflow is recorded (red badge in the gallery), not a test failure.
  screenshotMatrix(
    'profile',
    (_) => const ProfilePage(),
    detectTextTruncation: true,
  );

  screenshotMatrix('settings', (_) => const SettingsPage());
}
