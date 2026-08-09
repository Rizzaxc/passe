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
      header: FHeader.nested(title: const Text('Host')),
      child: profile.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (_, _) => const Center(child: Text('Không tải được Host')),
        data: (host) => host == null
            ? const Center(child: Text('Không tìm thấy Host'))
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
                  const Text('Host đã xác minh', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  if (host.bio.isNotEmpty) Text(host.bio),
                  const SizedBox(height: 16),
                  Text(
                    '${host.completedCount} buổi đã hoàn thành',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Vé đang mở',
                    style: context.theme.typography.body.lg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  open.when(
                    loading: () => const Center(child: FCircularProgress()),
                    error: (_, _) => const Text('Không tải được vé đang mở'),
                    data: (items) => items.isEmpty
                        ? const Text('Host chưa có vé đang mở.')
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
