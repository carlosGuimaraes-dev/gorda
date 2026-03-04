import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ag_home_organizer_flutter/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('login shows role selector in same screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.text('Employee'), findsOneWidget);
    expect(find.text('Manager'), findsOneWidget);
  });

}
