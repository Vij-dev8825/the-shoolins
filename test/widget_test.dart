import 'package:flutter_test/flutter_test.dart';

import 'package:the_shoolins/main.dart';

void main() {
  testWidgets('App renders login screen when logged out', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShoolinsApp());
    await tester.pump();

    expect(find.text('The Shoolins'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
