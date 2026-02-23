import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../filter.dart';

class LocationSubtab extends ConsumerWidget {
  const LocationSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(filterStateProvider);
    return SingleChildScrollView(
      child: Column(
        children: [
          FHeader.nested(
            titleAlignment: Alignment.centerLeft,
            style: .delta(padding: .value(EdgeInsets.zero)),
            title: Text(
              'home.location'.tr(),
              style: context.theme.typography.xl,
            ),
            prefixes: [const FilterWidget()],
          ),
        ],
      ),
    );
  }
}
