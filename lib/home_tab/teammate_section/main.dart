import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../filter.dart';

class TeammateSubtab extends ConsumerWidget {
  const TeammateSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(filterStateProvider);
    return SingleChildScrollView(
      // padding: EdgeInsets.zero,
      child: Column(
        // mainAxisSize: .min,
        children: [
          FHeader.nested(
            titleAlignment: Alignment.centerLeft,

            style: .delta(padding: .value(EdgeInsets.zero)),
            title: Text(
              'home.teammate'.tr(),
              style: context.theme.typography.xl,
            ),
            suffixes: [const FilterWidget()],
          ),
        ],
      ),
    );
  }
}
