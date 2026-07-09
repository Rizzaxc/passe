import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../ui/sheet.dart';
import '../../ui/theme.dart';
import 'coaching_controller.dart';

/// Star-rating sheet for a past confirmed coaching session. Half-star
/// granularity to match the `professional_booking_review.rating` CHECK
/// (multiples of 0.5, 0.5–5.0).
void showCoachingReviewSheet(
  BuildContext context, {
  required String bookingId,
  required String professionalId,
  required String professionalName,
}) {
  showPSheet(
    context: context,
    builder: (_) => _ReviewSheet(
      bookingId: bookingId,
      professionalId: professionalId,
      professionalName: professionalName,
    ),
  );
}

class _ReviewSheet extends ConsumerStatefulWidget {
  final String bookingId;
  final String professionalId;
  final String professionalName;

  const _ReviewSheet({
    required this.bookingId,
    required this.professionalId,
    required this.professionalName,
  });

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  double _rating = 5.0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await ref
          .read(coachingBookingActionControllerProvider.notifier)
          .submitReview(
            bookingId: widget.bookingId,
            professionalId: widget.professionalId,
            rating: _rating,
            comment: _commentController.text.trim(),
          );
    } catch (e, st) {
      Talker().handle(e, st, 'Coaching review submit failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: const Text('Không thể gửi đánh giá'),
          alignment: .bottomCenter,
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    showFToast(
      context: context,
      icon: const Icon(FLucideIcons.check),
      title: const Text('Đã gửi đánh giá'),
      alignment: .bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final saving = ref.watch(coachingBookingActionControllerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        PSheetTitle(
          label: 'Đánh Giá',
          trailing: FButton.icon(
            variant: .ghost,
            onPress: () => Navigator.of(context).pop(),
            child: const Icon(FLucideIcons.x),
          ),
        ),
        Text(
          widget.professionalName,
          textAlign: TextAlign.center,
          style: context.theme.typography.body.lg.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        _StarPicker(
          rating: _rating,
          onChanged: (v) => setState(() => _rating = v),
        ),
        Text(
          _rating.toStringAsFixed(1),
          textAlign: TextAlign.center,
          style: context.theme.typography.body.sm.copyWith(
            color: colors.mutedForeground,
          ),
        ),
        FTextField(
          label: const Text('Nhận xét (tuỳ chọn)'),
          hint: 'Buổi tập thế nào?',
          control: FTextFieldControl.managed(controller: _commentController),
          maxLines: 3,
        ),
        FButton(
          onPress: saving ? null : _submit,
          child: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Gửi Đánh Giá'),
        ),
      ],
    );
  }
}

class _StarPicker extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;

  const _StarPicker({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 5; i++)
          _Star(
            fraction: (rating - i).clamp(0.0, 1.0),
            onTap: (half) => onChanged(i + (half ? 0.5 : 1.0)),
          ),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  static const _size = 38.0;

  final double fraction; // 0, 0.5, or 1 — how filled this star is
  final ValueChanged<bool> onTap; // true = tapped the left (half) side

  const _Star({required this.fraction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => onTap(details.localPosition.dx < _size / 2),
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              FLucideIcons.star,
              size: 30,
              color: context.theme.colors.border,
            ),
            if (fraction > 0)
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: const Icon(FLucideIcons.star, size: 30, color: pbStar),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
