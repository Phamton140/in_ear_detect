import 'package:flutter_test/flutter_test.dart';
import 'package:in_ear_detect/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const KeyDetectApp());
    expect(find.text('◈ KeyDetect'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);
  });
}
