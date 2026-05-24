// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

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
