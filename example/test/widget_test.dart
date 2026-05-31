import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skywalking_dart_example/main.dart';

void main() {
  testWidgets('demo home shows native gRPC hint and send button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DemoPage()),
    );

    expect(find.text('Send sample'), findsOneWidget);
    expect(find.textContaining('gRPC'), findsOneWidget);
    expect(find.textContaining('Tap to send native trace'), findsOneWidget);
  });
}
