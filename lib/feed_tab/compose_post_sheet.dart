import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../core/model/wall_post.dart';
import '../ui/main.dart';
import 'compose_controller.dart';
import 'tag_picker_sheet.dart';

/// Compose a wall post: pick the session it came from, add 1–4 photos, an
/// optional caption, up to 5 tags, and how long it should live.
///
/// A full-screen page (not a [showPSheet] bottom sheet) — the flow has too
/// many steps to sit well at bottom-sheet height, and its first step (just a
/// session list) is short enough that a height-to-content sheet would look
/// like a small, half-empty sheet rather than a real compose flow.
///
/// [lobbyId] pre-filters the session list — used when opened from inside a
/// lobby's feed rather than from the Feed tab.
void showComposePostSheet(BuildContext context, {String? lobbyId}) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _ComposePostScreen(lobbyId: lobbyId),
    ),
  );
}

class _ComposePostScreen extends ConsumerStatefulWidget {
  final String? lobbyId;

  const _ComposePostScreen({this.lobbyId});

  @override
  ConsumerState<_ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends ConsumerState<_ComposePostScreen> {
  PostableSession? _session;
  final List<XFile> _images = [];
  final _caption = TextEditingController();
  List<TaggableUser> _tagged = const [];
  int _ttlDays = 7;
  bool _submitting = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picked = await ref
          .read(composePostControllerProvider.notifier)
          .pickImages();
      if (picked.isEmpty || !mounted) return;
      setState(() {
        _images
          ..clear()
          ..addAll(picked);
      });
    } catch (e, st) {
      Talker().handle(e, st, 'Pick images failed');
    }
  }

  Future<void> _submit() async {
    final session = _session;
    if (session == null || _images.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(composePostControllerProvider.notifier)
          .submit(
            activityId: session.activityId,
            bookingId: session.bookingId,
            images: _images,
            caption: _caption.text.trim(),
            ttlDays: _ttlDays,
            taggedUserIds: _tagged.map((t) => t.userId).toList(),
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.check),
        title: Text('feed.posted'.tr()),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      Talker().handle(e, st, 'Create wall post failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('feed.postFailed'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(postableSessionsProvider);

    return FScaffold(
      header: FHeader.nested(
        title: Text('feed.compose'.tr()),
        prefixes: [FHeaderAction.x(onPress: () => Navigator.of(context).pop())],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            // ── 1. Which session — always a dropdown, even with zero
            // options. Why it might be empty/unusable (still loading, failed
            // to load, or genuinely no postable session) is a tooltip on an
            // info icon, not a replacement for the field. ──
            _SessionPicker(
              sessionsAsync: sessionsAsync,
              lobbyId: widget.lobbyId,
              selected: _session,
              onChanged: (s) => setState(() {
                _session = s;
                _tagged = const [];
              }),
            ),

            // ── 2. Photos ─────────────────────────────────────────────
            PSectionHeader(title: 'feed.photos'.tr()),
            if (_images.isEmpty)
              FButton(
                variant: .outline,
                prefix: const Icon(FLucideIcons.imagePlus),
                onPress: _pickImages,
                child: Text('feed.addPhotos'.tr()),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: context.theme.style.borderRadius.sm,
                        child: Image.file(
                          File(_images[i].path),
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  FButton(
                    variant: .ghost,
                    onPress: _pickImages,
                    child: Text(
                      'feed.changePhotos'.tr(
                        namedArgs: {'count': '${_images.length}'},
                      ),
                    ),
                  ),
                ],
              ),

            // ── 3. Caption ────────────────────────────────────────────
            FTextField(
              label: Text('feed.caption'.tr()),
              hint: 'feed.captionHint'.tr(),
              maxLines: 2,
              maxLength: 140,
              control: FTextFieldControl.managed(controller: _caption),
            ),

            // ── 4. Tags — disabled until a session is picked, since the
            // candidate list (attendees/lobby members) comes from it. ──
            FTile(
              prefix: const Icon(FLucideIcons.atSign),
              title: Text('feed.tagPeople'.tr()),
              details: Text(
                _session == null
                    ? 'feed.tagNeedsSession'.tr()
                    : (_tagged.isEmpty
                          ? 'feed.tagNone'.tr()
                          : _tagged.map((t) => t.username).join(', ')),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              suffix: const Icon(FLucideIcons.chevronRight),
              onPress: _session == null
                  ? null
                  : () async {
                      final result = await showTagPickerSheet(
                        context,
                        activityId: _session!.activityId,
                        bookingId: _session!.bookingId,
                        initial: _tagged,
                      );
                      if (result != null && mounted) {
                        setState(() => _tagged = result);
                      }
                    },
            ),

            // ── 5. TTL ────────────────────────────────────────────────
            PSectionHeader(title: 'feed.ttl'.tr()),
            PSegmentedButton<int>(
              values: const [1, 3, 7],
              selected: _ttlDays,
              format: (v) =>
                  Text('feed.ttlDays'.tr(namedArgs: {'count': '$v'})),
              onChange: (v) {
                if (v != null) setState(() => _ttlDays = v);
              },
            ),

            FButton(
              onPress: _session == null || _images.isEmpty || _submitting
                  ? null
                  : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('feed.post'.tr()),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// The session dropdown. Always rendered — even with zero eligible
/// sessions — so the form's shape never jumps around; the "why is this
/// empty/disabled" explanation is a tooltip on an info icon next to the
/// label rather than a `PEmptySectionPlaceholder` swapped in for the field.
class _SessionPicker extends StatelessWidget {
  final AsyncValue<List<PostableSession>> sessionsAsync;
  final String? lobbyId;
  final PostableSession? selected;
  final ValueChanged<PostableSession?> onChanged;

  const _SessionPicker({
    required this.sessionsAsync,
    required this.lobbyId,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final sessions = (sessionsAsync.value ?? const [])
        .where((s) => lobbyId == null || s.lobbyId == lobbyId)
        .toList();
    final isLoading = sessionsAsync.isLoading;

    // You can only post about something you actually turned up to in the
    // last week — when that's not true (yet, or at all), say why instead of
    // just leaving the field disabled with no explanation.
    final disclaimer = sessionsAsync.hasError
        ? 'feed.sessionsError'.tr()
        : (!isLoading && sessions.isEmpty)
        ? 'feed.noPostableSessions'.tr()
        : null;

    return FSelect<PostableSession>.rich(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('feed.pickSession'.tr()),
          if (disclaimer != null) ...[
            const SizedBox(width: 6),
            FTooltip(
              // `hover` defaults to true and wraps the child in a
              // `Listener(onPointerDown: exit)` meant for desktop mouse use
              // — on a touch screen this fires on *every* tap-down (including
              // the one that's about to re-open it) and forces a hide right
              // before our own `onTap: controller.toggle` runs, so a second
              // tap just closes-then-immediately-reopens instead of staying
              // closed. We drive show/hide entirely via tap, so turn it off.
              hover: false,
              tipBuilder: (context, controller) => Padding(
                padding: const EdgeInsets.all(4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(disclaimer),
                ),
              ),
              builder: (context, controller, child) => TapRegion(
                // FTooltip's built-in dismissal is hover-exit / long-press-
                // release / focus-loss — none of which happen on a touch
                // screen from an ordinary tap elsewhere. TapRegion adds that:
                // tapping anywhere outside this icon (including the tooltip
                // bubble itself, which lives in a separate overlay entry)
                // closes it.
                onTapOutside: (_) => controller.hide(),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.toggle,
                  // The icon glyph alone is a ~15px hit target — pad it out
                  // to something actually tappable on a touch screen.
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: child,
                  ),
                ),
              ),
              child: Icon(
                FLucideIcons.info,
                size: 15,
                color: colors.mutedForeground,
              ),
            ),
          ],
        ],
      ),
      hint: 'feed.pickSessionHint'.tr(),
      format: (s) => s.sourceLabel ?? 'feed.untitledSession'.tr(),
      autoHide: true,
      enabled: !isLoading && sessions.isNotEmpty,
      control: FSelectControl.lifted(value: selected, onChange: onChanged),
      children: [
        for (final s in sessions)
          FSelectItem(
            prefix: Icon(
              s.isLesson ? FLucideIcons.graduationCap : FLucideIcons.users,
              color: colors.primary,
            ),
            title: Text(s.sourceLabel ?? 'feed.untitledSession'.tr()),
            subtitle: Text(_subtitle(context, s)),
            value: s,
            enabled: !s.alreadyPosted,
          ),
      ],
    );
  }

  String _subtitle(BuildContext context, PostableSession s) {
    final parts = [
      DateFormat('EEEE, d/M', context.locale.toString()).format(s.startTime),
      if (s.venueName != null && s.venueName!.isNotEmpty) s.venueName!,
      if (s.alreadyPosted) 'feed.alreadyPosted'.tr(),
    ];
    return parts.join(' · ');
  }
}
