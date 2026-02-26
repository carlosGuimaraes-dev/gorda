import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ag_home_organizer_flutter/app/app.dart';

void main() {
  testWidgets('shows splash first and then login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgApp()));

    expect(find.text('AG'), findsOneWidget);
    expect(find.text('AG Home Organizer International'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
