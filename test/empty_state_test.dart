import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnloop/presentation/widgets/states/empty_state.dart';

void main() {
  testWidgets('EmptyState displays message and icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            message: 'No Data Found',
            icon: Icons.inbox,
          ),
        ),
      ),
    );

    expect(find.text('No Data Found'), findsOneWidget);
    expect(find.byIcon(Icons.inbox), findsOneWidget);
  });
}
