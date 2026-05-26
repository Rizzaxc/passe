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
/// PDualButton(
///   firstChild: const Text('Sign In'),
///   secondChild: const Text('Sign Up'),
///   onFirstPressed: onLogin,
///   onSecondPressed: onRegister,
///   firstVariant: null, // primary (default)
///   secondVariant: .destructive,
///   axis: Axis.horizontal,
///   flex: 60,
/// )
/// ```
class PDualButton extends StatefulWidget {
  final Widget firstChild;
  final Widget secondChild;
  final VoidCallback? onFirstPressed;
  final VoidCallback? onSecondPressed;
  final FButtonVariant? firstVariant;
  final FButtonVariant? secondVariant;
  final Axis axis;
  final int flex;

  /// When true, buttons size to their content instead of using
  /// [Expanded] flex shares. Use this when embedding the widget in a
  /// content-sized slot (e.g. a section-header suffix) where the
  /// default `Expanded` children inside a `MainAxisSize.min` Row would
  /// fail flex resolution.
  final bool compact;

  const PDualButton({
    required this.firstChild,
    required this.secondChild,
    this.onFirstPressed,
    this.onSecondPressed,
    this.firstVariant,
    this.secondVariant,
    this.axis = Axis.horizontal,
    this.flex = 50,
    this.compact = false,
    super.key,
  });

  @override
  State<PDualButton> createState() => _PDualButtonState();
}

class _PDualButtonState extends State<PDualButton> {
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

  FButtonStyleDelta _styleDelta(bool isFirst) {
    BorderRadius radius;
    if (widget.axis == Axis.horizontal) {
      if (isFirst) {
        radius = const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        );
      } else {
        radius = const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        );
      }
    } else {
      if (isFirst) {
        radius = const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        );
      } else {
        radius = const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        );
      }
    }

    return .delta(
      decoration: .delta([.all(.boxDelta(borderRadius: radius))]),
    );
  }

  Widget _wrapFlex(Widget child, int flex) =>
      widget.compact ? child : Expanded(flex: flex, child: child);

  @override
  Widget build(BuildContext context) {
    final firstBtn = FButton(
      variant: widget.firstVariant ?? .primary,
      style: _styleDelta(true),
      onPress: _isProcessing ? null : _handleFirstPressed,
      child: widget.firstChild,
    );

    final secondBtn = FButton(
      variant: widget.secondVariant ?? .primary,
      style: _styleDelta(false),
      onPress: _isProcessing ? null : _handleSecondPressed,
      child: widget.secondChild,
    );

    final children = [
      _wrapFlex(firstBtn, widget.flex),
      SizedBox(
        width: widget.axis == Axis.horizontal ? 1 : null,
        height: widget.axis == Axis.vertical ? 1 : null,
        child: FDivider(axis: widget.axis == Axis.horizontal ? .vertical : .horizontal),
      ),
      _wrapFlex(secondBtn, 100 - widget.flex),
    ];

    return widget.axis == Axis.horizontal
        ? Row(mainAxisSize: MainAxisSize.min, children: children)
        : Column(mainAxisSize: MainAxisSize.min, children: children);
  }
}
