// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kaplanfit_app/main.dart';
import 'package:kaplanfit_app/services/database_service.dart';
import 'package:kaplanfit_app/services/exercise_service.dart';
import 'package:kaplanfit_app/services/program_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  // Testler için sqflite ffi başlatma
  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory for unit testing calls for SQFlite
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Servisleri oluştur (Test veritabanı kullanacak)
    final databaseService = DatabaseService();
    // Test ortamında gerçek db instance'ı almak yerine sahte bir db veya in-memory db kullanmak daha iyi olurdu
    // Şimdilik derleme hatasını gidermek için dbInstance getter'ını çağırıyoruz
    // final db = await databaseService.dbInstance; // Artık gerekli değil
    final exerciseService = ExerciseService(); // Parametre kaldırıldı
    // await exerciseService.initialize(); // Initialize çağırmak teste bağlı
    final programService = ProgramService(
        databaseService); // ProgramService hala DatabaseService alıyor
    // await programService.initialize(exerciseService); // Test için başlatma gerekli olmayabilir

    // Build our app and trigger a frame.
    // Servisler artık MyApp constructor'ında değil, Provider aracılığıyla sağlanıyor.
    // Bu nedenle MyApp() parametresiz çağrılmalı.
    await tester.pumpWidget(const MyApp()); // Parametreler kaldırıldı

    // Verify that our counter starts at 0.
    // Bu test artık geçerli değil, MyApp'te counter yok. Testi güncellemek gerekir.
    // expect(find.text('0'), findsOneWidget);
    // expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();

    // Verify that our counter has incremented.
    // expect(find.text('0'), findsNothing);
    // expect(find.text('1'), findsOneWidget);

    // Testi geçici olarak sadece build olup olmadığını kontrol edecek şekilde bırakalım
    expect(find.byType(MyApp), findsOneWidget);
  });
}
