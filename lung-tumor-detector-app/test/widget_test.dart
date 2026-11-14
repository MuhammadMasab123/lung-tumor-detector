// Basic smoke test: the app starts and shows the login screen
// when there is no saved session.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lung_tumor_detector/main.dart';

void main() {
  testWidgets('App starts on the login screen', (WidgetTester tester) async {
    // No saved session, so the auth gate should show the login screen.
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LungTumorDetectorApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign in to\nyour account'), findsOneWidget);
  });
}
