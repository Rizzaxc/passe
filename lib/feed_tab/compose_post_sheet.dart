import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
/// lobby's feed rather than from the Feed tab. [activityId] additionally
/// selects one completed activity, so a History-card action cannot
/// accidentally attach the post to the wrong session.
void showComposePostSheet(
  BuildContext context, {
  String? lobbyId,
  String? activityId,
}) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          _ComposePostScreen(lobbyId: lobbyId, activityId: activityId),
    ),
  );
}

class _ComposePostScreen extends ConsumerStatefulWidget {
  final String? lobbyId;
  final String? activityId;

  const _ComposePostScreen({this.lobbyId, this.activityId});

  @override
  ConsumerState<_ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends ConsumerState<_ComposePostScreen> {
  PostableSession? _session;
  final List<PreparedMedia> _media = [];
  final _caption = TextEditingController();
  List<TaggableUser> _tagged = const [];
  int _ttlDays = 7;
  bool _submitting = false;
  bool _picking = false;
  bool _triedInitialActivity = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    setState(() => _picking = true);
    try {
      final controller = ref.read(composePostControllerProvider.notifier);
      final picked = await controller.pickMedia();
      if (picked.isEmpty || !mounted) return;

      final result = await controller.prepareMedia(picked);
      if (!mounted) return;
      setState(() {
        _media
          ..clear()
          ..addAll(result.accepted);
      });
      for (final r in result.rejected) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text(
            r.reason == MediaRejectReason.tooLong
                ? 'feed.videoTooLong'.tr()
                : 'feed.videoTooLarge'.tr(),
          ),
          alignment: .bottomCenter,
        );
      }
    } catch (e, st) {
      Talker().handle(e, st, 'Pick media failed');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    final session = _session;
    if (session == null || _media.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(composePostControllerProvider.notifier)
          .submit(
            activityId: session.activityId,
            media: _media,
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
    } on TimeoutException catch (e, st) {
      // The client gave up waiting, but create_wall_post's insert isn't
      // cancelled by that — it may well have committed (see
      // compose_controller.dart). Don't tell the user it failed when it may
      // already be live; the feed provider was already invalidated so a
      // real success shows up once they check.
      Talker().handle(e, st, 'Create wall post timed out (outcome unknown)');
      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.clock),
        title: Text('feed.postSlow'.tr()),
        alignment: .bottomCenter,
      );
    } on AlreadyPostedForSessionException {
      // Not a failure in the "something broke" sense — the picker's cached
      // list just said this session was still postable when it wasn't. The
      // controller already invalidated postableSessionsProvider; drop the
      // stale selection here too so re-opening the dropdown shows it greyed
      // out immediately instead of letting the caller submit into the same
      // wall again.
      if (!mounted) return;
      setState(() => _session = null);
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleCheck),
        title: Text('feed.alreadyPostedForSession'.tr()),
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
    final sessions = sessionsAsync.value;
    if (!_triedInitialActivity &&
        widget.activityId != null &&
        sessions != null) {
      _triedInitialActivity = true;
      final initial = sessions.cast<PostableSession?>().firstWhere(
        (session) => session?.activityId == widget.activityId,
        orElse: () => null,
      );
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _session == null) setState(() => _session = initial);
        });
      }
    }

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
              activityId: widget.activityId,
              selected: _session,
              onChanged: (s) => setState(() {
                _session = s;
                _tagged = const [];
              }),
            ),

            // ── 2. Media ──────────────────────────────────────────────
            PSectionHeader(title: 'feed.media'.tr()),
            if (_media.isEmpty)
              FButton(
                variant: .outline,
                prefix: _picking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(FLucideIcons.imagePlus),
                onPress: _picking ? null : _pickMedia,
                child: Text('feed.addMedia'.tr()),
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
                      itemCount: _media.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _MediaThumb(item: _media[i]),
                    ),
                  ),
                  FButton(
                    variant: .ghost,
                    onPress: _picking ? null : _pickMedia,
                    child: Text(
                      'feed.changeMedia'.tr(
                        namedArgs: {'count': '${_media.length}'},
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
              onPress:
                  _session == null ||
                      _session!.alreadyPosted ||
                      _media.isEmpty ||
                      _submitting
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
            // A session can be pre-selected already-posted (e.g. opened from
            // an activity's own "Đăng bài" action for a session the user
            // already covered) — the button above is disabled for it, but a
            // disabled button with no explanation just looks broken.
            if (_session?.alreadyPosted ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'feed.alreadyPostedForSession'.tr(),
                  textAlign: TextAlign.center,
                  style: context.theme.typography.body.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// One thumbnail in the picked-media preview strip. Photos render their own
/// bytes; a video renders its poster-frame thumbnail (or a plain placeholder
/// if thumbnail generation failed) with a play glyph and its duration, so a
/// video item never looks identical to a photo in the picker.
class _MediaThumb extends StatelessWidget {
  final PreparedMedia item;

  const _MediaThumb({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return ClipRRect(
      borderRadius: context.theme.style.borderRadius.sm,
      child: SizedBox(
        width: 84,
        height: 84,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!item.isVideo)
              Image.file(File(item.file.path), fit: BoxFit.cover)
            else if (item.thumbnailBytes != null)
              Image.memory(item.thumbnailBytes!, fit: BoxFit.cover)
            else
              Container(color: colors.muted),
            if (item.isVideo) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
              const Center(
                child: Icon(FLucideIcons.play, color: Colors.white, size: 22),
              ),
              if (item.duration != null)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Text(
                    _durationLabel(item.duration!),
                    style: context.theme.typography.body.xs.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _durationLabel(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// The session dropdown. Always rendered — even with zero eligible
/// sessions — so the form's shape never jumps around; the "why is this
/// empty/disabled" explanation is a tooltip on an info icon next to the
/// label rather than a `PEmptySectionPlaceholder` swapped in for the field.
class _SessionPicker extends StatelessWidget {
  final AsyncValue<List<PostableSession>> sessionsAsync;
  final String? lobbyId;
  final String? activityId;
  final PostableSession? selected;
  final ValueChanged<PostableSession?> onChanged;

  const _SessionPicker({
    required this.sessionsAsync,
    required this.lobbyId,
    required this.activityId,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final sessions = (sessionsAsync.value ?? const [])
        .where(
          (s) =>
              (lobbyId == null || s.lobbyId == lobbyId) &&
              (activityId == null || s.activityId == activityId),
        )
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
      // The select field needs the date as part of a lobby activity's
      // identity: the same lobby can have several postable sessions in the
      // seven-day window. Lesson labels are already person-specific.
      format: (s) => _selectedLabel(context, s),
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

  String _selectedLabel(BuildContext context, PostableSession session) {
    final label = session.sourceLabel ?? 'feed.untitledSession'.tr();
    if (session.lobbyId == null) return label;
    final date = DateFormat(
      'd/M',
      context.locale.toString(),
    ).format(session.startTime);
    return '$label · $date';
  }
}
