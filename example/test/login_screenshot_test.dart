import 'package:flutter_screenshot_matrix/flutter_screenshot_matrix.dart';
import 'package:screenshot_matrix_example/screens/login_page.dart';

void main() {
  // Store-ready shots: drawn inside a simple device frame.
  screenshotMatrix('login', (_) => const LoginPage(), frame: true);
}
