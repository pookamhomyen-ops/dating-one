import 'package:flutter_test/flutter_test.dart';
import 'package:dating_one/main.dart';

void main() {
  testWidgets('App launches with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const DatingOneApp());
    await tester.pumpAndSettle();

    expect(find.text('หาเพื่อนใหม่'), findsOneWidget);
    expect(find.text('ฟีด'), findsOneWidget);
    expect(find.text('แชท'), findsOneWidget);
    expect(find.text('โปรไฟล์'), findsOneWidget);
  });
}
