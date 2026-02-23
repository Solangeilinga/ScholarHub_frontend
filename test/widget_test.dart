import 'package:flutter_test/flutter_test.dart';
import 'package:scholarhub/main.dart';

void main() {
  testWidgets('ScholarHub smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScholarHubApp());
    expect(find.byType(ScholarHubApp), findsOneWidget);
  });
}