import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:passe/auth/auth_screen.dart';
import 'package:passe/ui/keyboard_dismiss.dart';
import 'package:passe/ui/theme.dart' as ui;

void main() {
  testWidgets('auth form dismisses the keyboard when tapping outside', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: FTheme(
            data: ui.pbThemeLight,
            child: const PKeyboardDismiss(
              child: Scaffold(
                body: Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: AuthForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byType(EditableText).first,
      'guest@example.com',
    );
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tapAt(const Offset(12, 12));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('shared policy covers a bare Forui field like coach profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FTheme(
          data: ui.pbThemeLight,
          child: const PKeyboardDismiss(
            child: Scaffold(
              body: Padding(
                padding: EdgeInsets.only(top: 120),
                child: FTextField(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText), 'HLV Passe');
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tapAt(const Offset(12, 12));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
  });
}
