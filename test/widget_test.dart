import 'package:flutter_test/flutter_test.dart';

import 'package:poleway/main.dart';

void main() {
  testWidgets('Meus Pedidos screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PolewayApp());

    expect(find.text('Meus pedidos'), findsOneWidget);
    expect(find.text('Pole Way'), findsOneWidget);
  });
}
