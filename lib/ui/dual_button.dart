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
///   firstStyle: (styles) => styles.primary,
///   secondStyle: (styles) => styles.outline,
///   axis: Axis.horizontal,
///   flex: 60,
/// )
/// ```
class FDualButton extends StatefulWidget {
  final Widget firstChild;
  final Widget secondChild;
  final VoidCallback? onFirstPressed;
  final VoidCallback? onSecondPressed;
  final FButtonStyle Function(FButtonStyles styles)? firstStyle;
  final FButtonStyle Function(FButtonStyles styles)? secondStyle;
  final Axis axis;
  final int flex;

  const FDualButton({
    required this.firstChild,
    required this.secondChild,
    this.onFirstPressed,
    this.onSecondPressed,
    this.firstStyle,
    this.secondStyle,
    this.axis = Axis.horizontal,
    this.flex = 50,
    super.key,
  });

  @override
  State<FDualButton> createState() => _FDualButtonState();
}

class _FDualButtonState extends State<FDualButton> {
  bool _isProcessing = false;

  void _handleFirstPressed() {
    if (_isProcessing || widget.onFirstPressed == null) return;
    setState(() => _isProcessing = true);
    try {
      widget.onFirstPressed!();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleSecondPressed() {
    if (_isProcessing || widget.onSecondPressed == null) return;
    setState(() => _isProcessing = true);
    try {
      widget.onSecondPressed!();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  FButtonStyle _modifyStyle(FButtonStyle Function(FButtonStyles)? styleBuilder, bool isFirst) {
    final theme = FTheme.of(context);
    final baseStyle = styleBuilder?.call(theme.buttonStyles) ?? theme.buttonStyles.primary;

    final baseDecoration = baseStyle.decoration.resolve({});
    final borderRadius = baseDecoration.borderRadius as BorderRadius?;

    BorderRadius modifiedRadius;
    if (widget.axis == Axis.horizontal) {
      if (isFirst) {
        modifiedRadius = (borderRadius ?? BorderRadius.circular(8)).copyWith(
          topRight: Radius.zero,
          bottomRight: Radius.zero,
        );
      } else {
        modifiedRadius = (borderRadius ?? BorderRadius.circular(8)).copyWith(
          topLeft: Radius.zero,
          bottomLeft: Radius.zero,
        );
      }
    } else {
      if (isFirst) {
        modifiedRadius = (borderRadius ?? BorderRadius.circular(8)).copyWith(
          bottomLeft: Radius.zero,
          bottomRight: Radius.zero,
        );
      } else {
        modifiedRadius = (borderRadius ?? BorderRadius.circular(8)).copyWith(
          topLeft: Radius.zero,
          topRight: Radius.zero,
        );
      }
    }

    return baseStyle.copyWith(
      decoration: FWidgetStateMap({
        WidgetState.any: baseDecoration.copyWith(
          borderRadius: modifiedRadius,
        ),
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstStyle = _modifyStyle(widget.firstStyle, true);
    final secondStyle = _modifyStyle(widget.secondStyle, false);

    final children = [
      Expanded(
        flex: widget.flex,
        child: FButton(
          style: (_) => firstStyle,
          onPress: _isProcessing ? null : _handleFirstPressed,
          child: widget.firstChild,
        ),
      ),
      SizedBox(
        width: widget.axis == Axis.horizontal ? 1 : null,
        height: widget.axis == Axis.vertical ? 1 : null,
        child: const FDivider(),
      ),
      Expanded(
        flex: 100 - widget.flex,
        child: FButton(
          style: (_) => secondStyle,
          onPress: _isProcessing ? null : _handleSecondPressed,
          child: widget.secondChild,
        ),
      ),
    ];

    return widget.axis == Axis.horizontal
        ? Row(mainAxisSize: MainAxisSize.min, children: children)
        : Column(mainAxisSize: MainAxisSize.min, children: children);
  }
}
