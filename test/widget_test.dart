import 'package:flutter_test/flutter_test.dart';
import 'package:in_ear_detect/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const InEarDetectApp());
    expect(find.text('◈ in ear detect'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);
  });
}
