import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';

class PSearchField extends StatelessWidget {
  final String? hint;
  final Widget? label;
  final TextEditingController controller;
  final ValueChanged<String>? onChange;

  const PSearchField({
    super.key,
    this.hint,
    this.label,
    required this.controller,
    this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return FTextField(
      hint: hint,
      label: label,
      autocorrect: false,
      prefixBuilder: (context, style, states) {
        return Padding(
          padding: EdgeInsets.fromLTRB(8, 4, 0, 4),
          child: Icon(Icons.search),
        );
      },
      suffixBuilder: (context, style, states) {
        if (controller.text.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.fromLTRB(0, 4, 8, 4),
          child: GestureDetector(
            onTap: () {
              controller.clear();
              onChange?.call('');
            },
            child: Icon(FIcons.x),
          ),
        );
      },
      control: FTextFieldControl.managed(
        controller: controller,
        onChange: onChange != null
            ? (value) => onChange!(value.text)
            : null,
      ),
    );
  }
}
