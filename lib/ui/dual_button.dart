import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A dual button component that joins two FButtons together vertically or horizontally.
/// Flex controls how much the first button occupies total space.
/// An FDivider separates 1px from either side between the buttons.
/// Has internal state to make sure the buttons are mutually exclusive (cant press both).
/// Each button can have its own style, except the conjoining borders
///
/// Example:
/// ```dart
/// FDualButton(
///   firstChild: const Text('Sign In'),
///   secondChild: const Text('Sign Up'),
///   onFirstPressed: onLogin,
///   onSecondPressed: onRegister,
///   firstStyle: FButtonStyle.primary(),
///   secondStyle: FButtonStyle.outline(),
///   axis: .horizontal,
///   flex: 60,
/// )
/// ```
