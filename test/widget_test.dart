import 'package:flutter_test/flutter_test.dart';
import 'package:app_odontologo/main.dart';

void main() {
  testWidgets('DentCalm inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const DentCalmApp());

    expect(find.text('DentCalm'), findsOneWidget);
  });
}
