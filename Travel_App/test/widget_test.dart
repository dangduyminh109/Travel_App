import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_app/features/main_screen.dart';
import 'package:travel_app/main.dart';

void main() {
  testWidgets('TravelApp opens main screen without login gate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TravelApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
  });
}
