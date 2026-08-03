import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../ui/sheet.dart';
import 'invite_challenge_controller.dart';

/// "Invite another lobby to a challenge" flow — sends a real challenge via the
/// `send_challenge` RPC to the target lobby resolved from its SearchID.
void showInviteChallengeSheet(BuildContext context, String initiatorLobbyId) {
  showPSheet(
    context: context,
    builder: (_) =>
        _InviteChallengeSheet(initiatorLobbyId: initiatorLobbyId),
  );
}

class _InviteChallengeSheet extends ConsumerStatefulWidget {
  final String initiatorLobbyId;

  const _InviteChallengeSheet({required this.initiatorLobbyId});

  @override
  ConsumerState<_InviteChallengeSheet> createState() =>
      _InviteChallengeSheetState();
}

class _InviteChallengeSheetState
    extends ConsumerState<_InviteChallengeSheet> {
  final _searchController = TextEditingController();
  final _noteController = TextEditingController();
  final _scrollController = ScrollController();
  DateTime? _proposedAt;

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickProposedAt() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: _proposedAt ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: TimeOfDay.fromDateTime(_proposedAt ??
          pickedDate.copyWith(hour: 18, minute: 0)),
    );
    if (pickedTime == null) return;
    setState(() {
      _proposedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    final searchId = _searchController.text.trim();
    if (searchId.isEmpty) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: const Text('Nhập SearchID của lobby muốn thách đấu'),
        alignment: .bottomCenter,
      );
      return;
    }

    try {
      await ref
          .read(inviteChallengeControllerProvider(widget.initiatorLobbyId)
              .notifier)
          .invite(
            targetSearchId: searchId,
            proposedAt: _proposedAt,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.flag),
        title: const Text('Đã gửi lời thách đấu'),
        alignment: .bottomCenter,
      );
    } on ChallengeTargetNotFound {
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: const Text('Không tìm thấy lobby với SearchID này'),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      Talker().handle(e, st, 'send challenge failed');
      if (!mounted) return;
      // Surface the server-side guard message (sport mismatch, not open,
      // duplicate) without dumping the raw Postgres error.
      final msg = e.toString();
      final friendly = msg.contains('not open to challengers')
          ? 'Lobby này không mở nhận thách đấu'
          : msg.contains('sport mismatch')
              ? 'Hai lobby khác môn thể thao'
              : msg.contains('already pending')
                  ? 'Đã có lời thách đấu đang chờ'
                  : msg.contains('own lobby')
                      ? 'Không thể tự thách đấu lobby của mình'
                      : 'Không thể gửi lời thách đấu';
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text(friendly),
        alignment: .bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final sending =
        ref.watch(inviteChallengeControllerProvider(widget.initiatorLobbyId));

    return SingleChildScrollView(
      controller: _scrollController,
      primary: false,
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: 'Mời Thách Đấu',
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),

          // Target lobby
          FTextField(
            label: const Text('SearchID lobby đối thủ'),
            hint: 'vd. r4nb0xx7',
            control: FTextFieldControl.managed(controller: _searchController),
            description: const Text(
              'Đội trưởng lobby kia sẽ nhận được thông báo và có thể chấp nhận hoặc từ chối.',
            ),
          ),

          // Proposed time
          FTappable(
            onPress: _pickProposedAt,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(FLucideIcons.calendar,
                      size: 18, color: colors.secondaryForeground),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đề xuất thời gian',
                      style: context.theme.typography.body.sm
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    _proposedAt == null
                        ? 'Để đối thủ chọn'
                        : _fmtDateTime(_proposedAt!),
                    style: context.theme.typography.body.sm.copyWith(
                      color: _proposedAt == null
                          ? colors.mutedForeground
                          : colors.secondaryForeground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(FLucideIcons.chevronRight,
                      size: 16, color: colors.mutedForeground),
                ],
              ),
            ),
          ),

          // Optional note
          FTextField(
            label: const Text('Lời nhắn (tuỳ chọn)'),
            hint: 'vd. Sân Bách Khoa, BO3, 80k/người',
            control: FTextFieldControl.managed(controller: _noteController),
            maxLines: 3,
          ),

          FButton(
            onPress: sending ? null : _submit,
            child: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Gửi Lời Thách Đấu'),
          ),
        ],
      ),
    );
  }

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String _fmtDateTime(DateTime d) {
    final wd = _weekdays[d.weekday - 1];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$wd ${d.day}/${d.month} · $hh:$mm';
  }
}
