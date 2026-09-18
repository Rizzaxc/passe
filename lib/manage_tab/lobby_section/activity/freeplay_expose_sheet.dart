// Expose a lobby activity's spare seats on the freeplay ("Kèo") feed.
//
// The counterpart of the Host create sheet, minus everything the lobby already
// decided: the session's time and venue come from the activity itself and are
// not editable here — a listing follows its activity. What the manager sets is
// what outsiders are being offered: how many seats, at what price, for whom.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/location_repository.dart';
import '../../../freeplay/repository.dart';
import '../../../logger/talker.dart';
import '../../../ui/main.dart';
import '../feed/home_ground_selector.dart';
import 'freeplay_expose_controller.dart';
import 'upcoming_controller.dart';

Future<void> showFreeplayExposeSheet(
  BuildContext context, {
  required String lobbyId,
  required UpcomingActivity upcoming,
}) => showPSheet(
  context: context,
  maxHeightRatio: 1,
  builder: (_) => _ExposeSheet(lobbyId: lobbyId, upcoming: upcoming),
);

class _ExposeSheet extends ConsumerStatefulWidget {
  final String lobbyId;
  final UpcomingActivity upcoming;

  const _ExposeSheet({required this.lobbyId, required this.upcoming});

  @override
  ConsumerState<_ExposeSheet> createState() => _ExposeSheetState();
}

class _ExposeSheetState extends ConsumerState<_ExposeSheet> {
  late final TextEditingController _capacity = TextEditingController(text: '2');

  /// Prefilled from the activity's own per-head cost when it has one — the
  /// number the lobby already agreed among themselves is almost always what an
  /// extra player should pay. A 'total' cost is deliberately not divided: its
  /// per-head figure moves as members RSVP, and a guest's price must not drift
  /// after they've requested.
  late final TextEditingController _malePrice = TextEditingController(
    text: _prefillPrice,
  );
  late final TextEditingController _femalePrice = TextEditingController(
    text: _prefillPrice,
  );
  final _description = TextEditingController();
  final _skills = <String>{'casual', 'fair'};
  String? _locationId;
  Map<String, String?>? _freeAddress;
  bool _busy = false;

  String get _prefillPrice {
    final amount = widget.upcoming.costAmount;
    if (widget.upcoming.costType != 'per_pax' || amount == null) return '';
    return amount.round().toString();
  }

  /// The activity's venue, or the lobby's home ground. Only when there is
  /// neither does the sheet ask for one.
  bool _needsVenue(LobbyExposureContext context) =>
      widget.upcoming.locationId == null && context.homeGroundId == null;

  String _venueLabel(LobbyExposureContext context) =>
      widget.upcoming.locationName ??
      context.homeGroundName ??
      'lobbyHub.freeplayExpose.noVenue'.tr();

  @override
  void dispose() {
    _capacity.dispose();
    _malePrice.dispose();
    _femalePrice.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit(LobbyExposureContext exposure) async {
    final capacity = int.tryParse(_capacity.text.trim());
    final malePrice = double.tryParse(_malePrice.text.trim());
    final femalePrice = double.tryParse(_femalePrice.text.trim());
    if (capacity == null ||
        capacity < 1 ||
        malePrice == null ||
        malePrice <= 0 ||
        femalePrice == null ||
        femalePrice <= 0 ||
        _skills.isEmpty) {
      showFToast(
        context: context,
        variant: .destructive,
        title: Text('lobbyHub.freeplayExpose.invalid'.tr()),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final locationId = _needsVenue(exposure)
          ? await resolveLocationId(
              pickedId: _locationId,
              freeAddress: _freeAddress,
            )
          : null;
      await ref
          .read(freeplayRepositoryProvider)
          .exposeLobbyActivity(
            widget.upcoming.activity.id!,
            capacity: capacity,
            malePrice: malePrice,
            femalePrice: femalePrice,
            skills: _skills.toList(),
            description: _description.text.trim(),
            locationId: locationId,
          );
      ref.invalidate(freeplayDetailProvider(widget.upcoming.activity.id!));
      ref.invalidate(lobbyUpcomingActivitiesControllerProvider(widget.lobbyId));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e, st) {
      talker.handle(e, st, 'Expose lobby activity for freeplay failed');
      if (mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          title: Text('lobbyHub.freeplayExpose.failed'.tr()),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exposure =
        ref.watch(lobbyExposureContextProvider(widget.lobbyId)).value ??
        LobbyExposureContext.unknown;
    final colors = context.theme.colors;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          PSheetTitle(
            label: 'lobbyHub.freeplayExpose.title'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.pop(context),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          Text(
            'lobbyHub.freeplayExpose.blurb'.tr(),
            style: context.theme.typography.body.sm.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          FTileGroup(
            children: [
              FTile(
                prefix: const Icon(FLucideIcons.calendar),
                title: Text(
                  formatMatchDateTime(widget.upcoming.activity.startTime),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _venueLabel(exposure),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (_needsVenue(exposure)) ...[
            PSheetSectionLabel(
              label: 'lobbyHub.freeplayExpose.venue'.tr(),
            ),
            HomeGroundField(
              value: _locationId,
              prefixIcon: FLucideIcons.mapPin,
              onChanged: (id) => setState(() {
                _locationId = id.isEmpty ? null : id;
                _freeAddress = null;
              }),
              onFreeAddressChanged: (address) => setState(() {
                _freeAddress = address;
                if (address != null) _locationId = null;
              }),
            ),
          ],
          FTextField(
            label: Text('lobbyHub.freeplayExpose.capacity'.tr()),
            description: Text('lobbyHub.freeplayExpose.capacityHint'.tr()),
            keyboardType: TextInputType.number,
            control: FTextFieldControl.managed(controller: _capacity),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          PSheetSectionLabel(
            label: 'lobbyHub.freeplayExpose.price'.tr(),
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: FTextField(
                  label: Text('freeplay.hostManage.male'.tr()),
                  keyboardType: TextInputType.number,
                  control: FTextFieldControl.managed(controller: _malePrice),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ),
              Expanded(
                child: FTextField(
                  label: Text('freeplay.hostManage.female'.tr()),
                  keyboardType: TextInputType.number,
                  control: FTextFieldControl.managed(controller: _femalePrice),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ),
            ],
          ),
          FTextField(
            label: Text('lobbyHub.freeplayExpose.description'.tr()),
            maxLines: 4,
            control: FTextFieldControl.managed(controller: _description),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          PSheetSectionLabel(
            label: 'freeplay.hostManage.recommendedSkill'.tr(),
          ),
          for (final value in const [
            'beginner',
            'casual',
            'fair',
            'good',
            'advanced',
          ])
            FCheckbox(
              value: _skills.contains(value),
              label: Text('freeplay.skill.$value'.tr()),
              onChange: (selected) => setState(() {
                if (selected) {
                  _skills.add(value);
                } else if (_skills.length > 1) {
                  _skills.remove(value);
                }
              }),
            ),
          Text(
            'lobbyHub.freeplayExpose.lockNotice'.tr(),
            style: context.theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          FButton(
            onPress: _busy ? null : () => _submit(exposure),
            child: Text('lobbyHub.freeplayExpose.submit'.tr()),
          ),
        ],
      ),
    );
  }
}
