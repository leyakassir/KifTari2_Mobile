import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiftari2/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const KifTari2App());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
