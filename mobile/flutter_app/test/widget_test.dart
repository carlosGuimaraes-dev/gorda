import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ag_home_organizer_flutter/features/splash/presentation/splash_view.dart';

void main() {
  testWidgets('shows splash branding content', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SplashView(),
        ),
      ),
    );

    expect(find.text('AG'), findsOneWidget);
    expect(find.text('AG Home Organizer International'), findsOneWidget);
  });
}
