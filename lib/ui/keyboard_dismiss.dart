import 'package:flutter/material.dart';

/// Applies Passe's mobile tap-outside keyboard behavior to every descendant
/// text input, including Forui fields.
///
/// Flutter deliberately keeps a focused field open for touch events outside
/// the field on iOS and Android. Text fields expose that default as an
/// overridable [EditableTextTapOutsideIntent], so handling the intent once at
/// the app boundary covers current and future input surfaces without requiring
/// a callback on every individual field.
class PKeyboardDismiss extends StatelessWidget {
  static final Map<Type, Action<Intent>> _actions = {
    EditableTextTapOutsideIntent: CallbackAction<EditableTextTapOutsideIntent>(
      onInvoke: (intent) {
        intent.focusNode.unfocus();
        return null;
      },
    ),
  };

  final Widget child;

  const PKeyboardDismiss({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      Actions(actions: _actions, child: child);
}
