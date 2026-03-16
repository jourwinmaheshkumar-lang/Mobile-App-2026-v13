import 'package:flutter_test/flutter_test.dart';
import 'package:director_management/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DirectorHubApp());
    expect(find.text('Director Hub Pro'), findsOneWidget);
  });
}
