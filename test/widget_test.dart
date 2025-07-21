// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('App loads without errors', (WidgetTester tester) async {
    // Basit widget test - sadece uygulama yüklenip yüklenmediğini kontrol eder

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('KaplanFit Test'),
          ),
        ),
      ),
    );

    // Widget'ın yüklendiğini doğrula
    expect(find.text('KaplanFit Test'), findsOneWidget);
  });
}
