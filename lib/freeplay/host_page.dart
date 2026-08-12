import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'card.dart';
import 'repository.dart';

class FreeplayHostPage extends ConsumerWidget {
  final String id;
  const FreeplayHostPage({required this.id, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(freeplayHostProfileProvider(id));
    final open = ref.watch(freeplayHostOpenProvider(id));
    return FScaffold(
      header: FHeader.nested(title: Text('freeplay.host.title'.tr())),
      child: profile.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (_, _) => Center(child: Text('freeplay.host.loadFailed'.tr())),
        data: (host) => host == null
            ? Center(child: Text('freeplay.host.notFound'.tr()))
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundImage: host.avatarUrl == null
                        ? null
                        : NetworkImage(host.avatarUrl!),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    host.displayName,
                    textAlign: TextAlign.center,
                    style: context.theme.typography.body.xl2.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'freeplay.verifiedHost'.tr(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (host.bio.isNotEmpty) Text(host.bio),
                  const SizedBox(height: 16),
                  Text(
                    'freeplay.host.completedCount'.tr(
                      namedArgs: {'count': '${host.completedCount}'},
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'freeplay.host.openListings'.tr(),
                    style: context.theme.typography.body.lg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  open.when(
                    loading: () => const Center(child: FCircularProgress()),
                    error: (_, _) => Text('freeplay.host.openLoadFailed'.tr()),
                    data: (items) => items.isEmpty
                        ? Text('freeplay.host.noOpenListings'.tr())
                        : Column(
                            children: [
                              for (final activity in items) ...[
                                FreeplayCard(activity: activity, compact: true),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
