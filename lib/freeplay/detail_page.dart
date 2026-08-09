import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/guest_prompt.dart';
import '../router.dart';
import '../ui/main.dart';
import 'chat_sheet.dart';
import 'model.dart';
import 'repository.dart';

class FreeplayDetailPage extends ConsumerWidget {
  final String id;
  const FreeplayDetailPage({required this.id, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(freeplayDetailProvider(id));
    return FScaffold(
      header: FHeader.nested(title: const Text('Xé vé')),
      child: detail.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (_, _) => const Center(child: Text('Không tải được buổi chơi')),
        data: (activity) => activity == null
            ? const Center(child: Text('Buổi chơi không còn mở'))
            : _Body(activity: activity),
      ),
    );
  }
}

class FreeplayChatLandingPage extends StatefulWidget {
  final String activityId;
  final String requestId;
  const FreeplayChatLandingPage({
    required this.activityId,
    required this.requestId,
    super.key,
  });

  @override
  State<FreeplayChatLandingPage> createState() =>
      _FreeplayChatLandingPageState();
}

class _FreeplayChatLandingPageState extends State<FreeplayChatLandingPage> {
  bool _opened = false;
  @override
  Widget build(BuildContext context) {
    if (!_opened) {
      _opened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showFreeplayChatSheet(context, widget.requestId);
        }
      });
    }
    return FreeplayDetailPage(id: widget.activityId);
  }
}

class _Body extends ConsumerStatefulWidget {
  final FreeplayActivity activity;
  const _Body({required this.activity});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  Future<void> _request() async {
    if (!ensureSignedIn(context, ref) || _busy) return;
    final message = TextEditingController();
    await showFDialog<void>(
      context: context,
      builder: (dialogContext, style, animation) => PConfirmDialog(
        animation: animation,
        title: const Text('Xin một chỗ'),
        body: FTextField(
          control: FTextFieldControl.managed(controller: message),
          hint: 'Lời nhắn cho Host (không bắt buộc)',
          maxLines: 3,
        ),
        actions: [
          FButton(
            variant: .ghost,
            onPress: () => Navigator.pop(dialogContext),
            child: const Text('Để sau'),
          ),
          FButton(
            onPress: () async {
              Navigator.pop(dialogContext);
              setState(() => _busy = true);
              try {
                final requestId = await ref
                    .read(freeplayRepositoryProvider)
                    .requestSeat(widget.activity.id, message: message.text);
                ref.invalidate(freeplayDetailProvider(widget.activity.id));
                ref.invalidate(freeplayFeedProvider);
                if (mounted) await showFreeplayChatSheet(context, requestId);
              } catch (_) {
                if (mounted) {
                  showFToast(
                    context: context,
                    variant: .destructive,
                    title: const Text('Không gửi được yêu cầu'),
                  );
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
    message.dispose();
  }

  Future<void> _cancel() async {
    final requestId = widget.activity.myRequestId;
    if (requestId == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(freeplayRepositoryProvider).cancelRequest(requestId);
      ref.invalidate(freeplayDetailProvider(widget.activity.id));
      ref.invalidate(freeplayFeedProvider);
      ref.invalidate(myFreeplayProvider(false));
    } catch (_) {
      if (mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          title: const Text('Không huỷ được yêu cầu'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final status = a.myRequestStatus;
    final accepted = status == FreeplayRequestStatus.accepted;
    final pending = status == FreeplayRequestStatus.pending;
    final now = DateTime.now();
    final ended = !now.isBefore(a.endTime);
    final viewerHostId = ref.watch(linkedFreeplayHostProvider).value?.id;
    final isHost = viewerHostId == a.hostId;
    final chatWritable =
        a.myRequestId != null &&
        ((pending && !ended) ||
            ((accepted || status == FreeplayRequestStatus.hostCancelled) &&
                now.isBefore(a.endTime.add(const Duration(days: 7)))));
    final canCancel = (pending || accepted) && !ended;
    final canRequest =
        !isHost &&
        !ended &&
        !a.isFull &&
        (status == null || status == FreeplayRequestStatus.cancelled);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(freeplayDetailProvider(a.id));
        await ref.read(freeplayDetailProvider(a.id).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          FTappable(
            onPress: () => FreeplayHostRoute(id: a.hostId).push(context),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: a.hostAvatarUrl == null
                      ? null
                      : NetworkImage(a.hostAvatarUrl!),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.hostName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.typography.body.lg.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text('Host đã xác minh'),
                    ],
                  ),
                ),
                const Icon(FLucideIcons.chevronRight),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            DateFormat('EEEE, d/M · HH:mm', 'vi').format(a.startTime),
            style: context.theme.typography.body.xl.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text('đến ${DateFormat('HH:mm').format(a.endTime)}'),
          const SizedBox(height: 16),
          _Line(
            icon: FLucideIcons.mapPin,
            title: a.venueName,
            subtitle: a.streetAddress,
          ),
          _Line(
            icon: FLucideIcons.users,
            title: '${a.acceptedCount}/${a.capacity} người',
            subtitle: a.isFull ? 'Đã đủ chỗ' : 'Còn ${a.seatsLeft} chỗ',
          ),
          _Line(
            icon: FLucideIcons.badgeDollarSign,
            title:
                '${NumberFormat.decimalPattern('vi').format(a.malePrice)}đ nam · ${NumberFormat.decimalPattern('vi').format(a.femalePrice)}đ nữ',
            subtitle: 'Thanh toán trực tiếp với Host',
          ),
          _Line(
            icon: FLucideIcons.gauge,
            title: a.recommendedSkills.join(' · '),
            subtitle:
                a.mySkill != null && !a.recommendedSkills.contains(a.mySkill)
                ? 'Trình độ của bạn khác mức Host đề xuất'
                : 'Trình độ tự đánh giá',
          ),
          if (a.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(a.description),
          ],
          if (accepted && a.roster.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Người tham gia',
              style: context.theme.typography.body.lg.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            ...a.roster.map(
              (member) => ListTile(
                title: Text(member.username),
                subtitle: member.skill == null ? null : Text(member.skill!),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (chatWritable)
            FButton(
              onPress: () => showFreeplayChatSheet(context, a.myRequestId!),
              child: const Text('Mở trò chuyện'),
            ),
          if (chatWritable && canCancel) const SizedBox(height: 8),
          if (canCancel)
            FButton(
              variant: .outline,
              onPress: _busy ? null : _cancel,
              child: Text(accepted ? 'Huỷ chỗ' : 'Huỷ yêu cầu'),
            ),
          if (canRequest)
            FButton(
              onPress: _busy ? null : _request,
              child: const Text('Xin một chỗ'),
            ),
          if (isHost)
            const Text(
              'Bạn là Host của buổi chơi này.',
              textAlign: TextAlign.center,
            ),
          if (!isHost && !chatWritable && !canCancel && !canRequest)
            Text(
              ended
                  ? 'Buổi chơi đã kết thúc.'
                  : a.isFull && status == null
                  ? 'Buổi chơi đã đủ chỗ.'
                  : switch (status) {
                      FreeplayRequestStatus.declined =>
                        'Yêu cầu đã bị từ chối.',
                      FreeplayRequestStatus.hostCancelled =>
                        'Host đã huỷ buổi chơi.',
                      FreeplayRequestStatus.lapsed => 'Yêu cầu đã hết hạn.',
                      FreeplayRequestStatus.blocked =>
                        'Yêu cầu không còn khả dụng.',
                      _ => 'Yêu cầu không còn hoạt động.',
                    },
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Line({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(
                subtitle,
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
