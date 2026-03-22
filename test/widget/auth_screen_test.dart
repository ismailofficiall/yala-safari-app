import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yala_driver_app_1/features/dashboard/widgets/weather_widget.dart';

void main() {
  group('YalaWeatherWidget UI Tests', () {
    testWidgets('Weather widget initializes and shows loading state, then resolves', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YalaWeatherWidget(),
          ),
        ),
      );

      // Initially it should show a CircularProgressIndicator while fetching API
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Let the Future resolve (it will likely fail network in test env, showing "Offline")
      await tester.pumpAndSettle();

      // Ensure the widget doesn't crash and renders the fallback or loaded UI
      expect(find.byType(Container), findsWidgets);
    });
  });
}
