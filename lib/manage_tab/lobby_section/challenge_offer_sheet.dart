import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/format.dart';
import '../../core/model/location.dart';
import '../../ui/main.dart';
import 'challenge_offer_controller.dart';

/// Opens the "Nhận Thách Đấu" terms sheet. Publishing an offer needs a kickoff,
/// a venue and a cost per team; editing a live offer reuses the same sheet and
/// gains a withdraw action.
void showChallengeOfferSheet(BuildContext context, String lobbyId) {
  showPSheet(
    context: context,
    builder: (_) => _ChallengeOfferSheet(lobbyId: lobbyId),
  );
}

// ─── The control ────────────────────────────────────────────────────────────

/// A checkbox that is also a button.
///
/// It reads as a checkbox because its job is to show a persistent on/off state.
/// It behaves as a button because turning it on isn't a flip — the lobby has to
/// publish terms first, so the tap opens [showChallengeOfferSheet] and the box
/// only checks once that succeeds. Turning it *off* lives inside the sheet as a
/// destructive action rather than as a directly-uncheckable box: "edit the
/// terms" and "stop accepting challenges" are different enough outcomes that
/// they shouldn't sit a few pixels apart.
class ChallengeOfferControl extends ConsumerWidget {
  final String lobbyId;
  final bool canManage;

  /// Row form for the lobby info sheet; card form for the activity hero.
  final bool dense;

  const ChallengeOfferControl({
    super.key,
    required this.lobbyId,
    required this.canManage,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canManage) return const SizedBox.shrink();

    final colors = context.theme.colors;
    final offer = ref.watch(challengeOfferControllerProvider(lobbyId)).value;
    final live = offer?.isLive ?? false;

    void open() => showChallengeOfferSheet(context, lobbyId);

    final summary = live
        ? [
            if (offer!.kickoff != null) formatMatchDateTime(offer.kickoff!),
            if (offer.locationName != null) offer.locationName!,
            if (offer.costPerTeam != null)
              '${formatVnd(offer.costPerTeam!)}đ/đội '
                  '(${formatVndWords(offer.costPerTeam!)})',
          ].join(' · ')
        : 'lobbyHub.challenge.summaryPrompt'.tr();

    return FTappable(
      onPress: open,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: dense ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: live ? colors.primary.withValues(alpha: 0.06) : colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: live ? colors.primary : colors.border),
        ),
        child: Row(
          children: [
            Icon(
              live ? FLucideIcons.squareCheckBig : FLucideIcons.square,
              size: 20,
              color: live ? colors.primary : colors.mutedForeground,
            ),
            const SizedBox(width: 12),
            // Every span here is dynamic (venue names and formatted money have
            // no length bound), so the whole group has to be able to shrink.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'lobbyHub.challenge.title'.tr(),
                    style: context.theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.typography.body.xs.copyWith(
                      color: live ? colors.primary : colors.mutedForeground,
                      fontWeight: live ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              FLucideIcons.chevronRight,
              size: 16,
              color: colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── The sheet ──────────────────────────────────────────────────────────────

class _ChallengeOfferSheet extends ConsumerStatefulWidget {
  final String lobbyId;

  const _ChallengeOfferSheet({required this.lobbyId});

  @override
  ConsumerState<_ChallengeOfferSheet> createState() =>
      _ChallengeOfferSheetState();
}

class _ChallengeOfferSheetState extends ConsumerState<_ChallengeOfferSheet> {
  final _costController = TextEditingController();
  DateTime? _kickoff;
  String? _locationId;
  String? _locationName;
  bool _busy = false;
  bool _seeded = false;

  @override
  void dispose() {
    _costController.dispose();
    super.dispose();
  }

  /// Seed from the live offer when editing, else from the lobby's homeground —
  /// the venue a lobby plays at is nearly always the one it offers.
  void _seed(ChallengeOffer? offer) {
    // The row arrives asynchronously; seed off the first non-null read only.
    if (_seeded || offer == null) return;
    _seeded = true;
    if (offer.isLive) {
      _kickoff = offer.kickoff;
      _locationId = offer.locationId;
      _locationName = offer.locationName;
      if (offer.costPerTeam != null) {
        _costController.text = offer.costPerTeam!.round().toString();
      }
    } else {
      _locationId = offer.homegroundId;
      _locationName = offer.homegroundName;
    }
  }

  Future<void> _pickKickoff() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: _kickoff ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: TimeOfDay.fromDateTime(
        _kickoff ?? date.copyWith(hour: 18, minute: 0),
      ),
    );
    if (time == null) return;
    setState(() {
      _kickoff = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _toast(String message, {bool bad = true}) {
    showFToast(
      context: context,
      icon: Icon(bad ? FLucideIcons.circleX : FLucideIcons.swords),
      variant: bad ? FToastVariant.destructive : FToastVariant.primary,
      title: Text(message),
      alignment: .bottomCenter,
    );
  }

  Future<void> _submit() async {
    final kickoff = _kickoff;
    final locationId = _locationId;
    final cost = double.tryParse(
      _costController.text.trim().replaceAll('.', ''),
    );

    if (kickoff == null) return _toast('lobbyHub.challenge.chooseTime'.tr());
    if (!kickoff.isAfter(DateTime.now())) {
      return _toast('lobbyHub.challenge.futureTime'.tr());
    }
    if (locationId == null) {
      return _toast('lobbyHub.challenge.chooseVenue'.tr());
    }
    if (cost == null || cost < 0) {
      return _toast('lobbyHub.challenge.enterCost'.tr());
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(challengeOfferControllerProvider(widget.lobbyId).notifier)
          .publish(kickoff: kickoff, locationId: locationId, costPerTeam: cost);
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast('lobbyHub.challenge.published'.tr(), bad: false);
    } catch (e, st) {
      Talker().handle(e, st, 'publish challenge offer failed');
      if (!mounted) return;
      _toast(challengeOfferErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(challengeOfferControllerProvider(widget.lobbyId).notifier)
          .withdraw();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e, st) {
      Talker().handle(e, st, 'withdraw challenge offer failed');
      if (!mounted) return;
      _toast(challengeOfferErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final offer = ref
        .watch(challengeOfferControllerProvider(widget.lobbyId))
        .value;
    _seed(offer);
    final editing = offer?.isLive ?? false;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: 'lobbyHub.challenge.title'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),

          Text(
            'lobbyHub.challenge.hostInfo'.tr(),
            style: context.theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
              height: 1.45,
            ),
          ),

          _FieldTile(
            icon: FLucideIcons.calendar,
            label: 'lobbyHub.challenge.kickoff'.tr(),
            value: _kickoff == null
                ? 'lobbyHub.challenge.notChosen'.tr()
                : formatMatchDateTime(_kickoff!),
            filled: _kickoff != null,
            onTap: _pickKickoff,
          ),

          _VenuePicker(
            selectedName: _locationName,
            onSelected: (loc) => setState(() {
              _locationId = loc.id;
              _locationName = loc.name;
            }),
          ),

          FTextField(
            label: Text('lobbyHub.challenge.costPerTeam'.tr()),
            hint: 'lobbyHub.challenge.costHint'.tr(),
            description: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _costController,
                  builder: (_, _) {
                    final cost = num.tryParse(
                      _costController.text.trim().replaceAll('.', ''),
                    );
                    return Text(
                      cost == null || cost < 0
                          ? 'lobbyHub.common.enterAmountReading'.tr()
                          : formatVndWords(cost),
                    );
                  },
                ),
                Text('lobbyHub.challenge.refereeExcluded'.tr()),
              ],
            ),
            keyboardType: TextInputType.number,
            control: FTextFieldControl.managed(controller: _costController),
          ),

          FButton(
            onPress: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    editing
                        ? 'lobbyHub.challenge.update'.tr()
                        : 'lobbyHub.challenge.publish'.tr(),
                  ),
          ),

          if (editing)
            FButton(
              variant: .ghost,
              onPress: _busy ? null : _withdraw,
              child: Text(
                'lobbyHub.challenge.withdraw'.tr(),
                style: TextStyle(color: colors.destructive),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool filled;
  final VoidCallback onTap;

  const _FieldTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FTappable(
      onPress: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.secondaryForeground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: context.theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // The value is a formatted date or a venue name — unbounded, so it
            // has to be the side that shrinks.
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: context.theme.typography.body.sm.copyWith(
                  color: filled
                      ? colors.secondaryForeground
                      : colors.mutedForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              FLucideIcons.chevronRight,
              size: 16,
              color: colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

/// Venue picker for the offer. Defaults to the lobby's homeground (seeded by
/// the sheet) and otherwise searches `location` through the same
/// `search_locations` RPC the rest of the app uses.
class _VenuePicker extends StatefulWidget {
  final String? selectedName;
  final ValueChanged<Location> onSelected;

  const _VenuePicker({required this.selectedName, required this.onSelected});

  @override
  State<_VenuePicker> createState() => _VenuePickerState();
}

class _VenuePickerState extends State<_VenuePicker> {
  final _searchController = TextEditingController();
  bool _changing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Location>> _search(String query) async {
    if (query.trim().length < 3) return [];
    final response = await Supabase.instance.client
        .rpc('search_locations', params: {'search_term': query})
        .timeout(const Duration(seconds: 5));
    return (response as List)
        .map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.selectedName;

    if (_changing || name == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            'lobbyHub.challenge.venue'.tr(),
            style: context.theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          PSearchField<Location>(
            hint: 'lobbyHub.challenge.venueSearch'.tr(),
            controller: _searchController,
            suggestionsBuilder: _search,
            displayStringForOption: (loc) => loc.fullAddress ?? loc.name,
            onSuggestionSelected: (loc) {
              widget.onSelected(loc);
              setState(() => _changing = false);
            },
            onChange: (_) {},
            formatSuggestion: (context, loc) =>
                Text(loc.fullAddress ?? loc.name),
          ),
        ],
      );
    }

    return _FieldTile(
      icon: FLucideIcons.mapPin,
      label: 'lobbyHub.challenge.venue'.tr(),
      value: name,
      filled: true,
      onTap: () => setState(() => _changing = true),
    );
  }
}
