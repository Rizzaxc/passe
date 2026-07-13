import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:passe/ui/logo.dart';
import 'package:passe/ui/theme.dart' as ui;

void main() {
  testWidgets('PLogo (stacked) renders mark + wordmark + slogan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FTheme(
          data: ui.pbThemeLight,
          child: const Scaffold(
            body: Center(child: PLogo(variant: PLogoVariant.stacked, size: 72)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Passe'), findsOneWidget);
    expect(find.text('PLAY TOGETHER · WIN TOGETHER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
