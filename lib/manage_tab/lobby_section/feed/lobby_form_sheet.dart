import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/model/enum.dart';
import '../../../core/model/lobby.dart';
import '../../../core/model/timeslot.dart';
import '../../../ui/main.dart';
import 'home_ground_selector.dart';
import 'lobby_controller.dart';

Future<Lobby?> showLobbyFormSheet({
  required BuildContext context,
  required WidgetRef ref,
  String? lobbyId,
}) {
  return showFSheet<Lobby>(
    context: context,
    side: .btt,
    useSafeArea: true,
    mainAxisMaxRatio: 0.9,
    useRootNavigator: true,
    builder: (context) => LobbyFormSheet(lobbyId: lobbyId),
  );
}

class LobbyFormSheet extends ConsumerStatefulWidget {
  final String? lobbyId;

  const LobbyFormSheet({super.key, this.lobbyId});

  @override
  ConsumerState<LobbyFormSheet> createState() => _LobbyFormSheetState();
}

class _LobbyFormSheetState extends ConsumerState<LobbyFormSheet> {
  final _formKey = GlobalKey<FormState>(debugLabel: 'lobby_form');
  late final TextEditingController _nameController;
  final ScrollController _scrollController = ScrollController();

  DayChunk _pendingDayChunk = DayChunk.night;
  DayOfWeek _pendingDayOfWeek = DayOfWeek.weekend;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(lobbyFormControllerProvider(widget.lobbyId));
    _nameController = TextEditingController(text: formState.lobby.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(lobbyFormControllerProvider(widget.lobbyId));
    final notifier =
        ref.read(lobbyFormControllerProvider(widget.lobbyId).notifier);
    final lobby = formState.lobby;

    return FSheets(
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        decoration: BoxDecoration(
          color: context.theme.colors.background,
          borderRadius: BorderRadius.circular(32),
          border: Border.symmetric(
            horizontal: BorderSide(color: context.theme.colors.border),
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            primary: false,
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Name
                FTextFormField(
                  hint: 'createLobby.lobbyNameHint'.tr(),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  control: FTextFieldControl.managed(
                    controller: _nameController,
                    onChange: (value) =>
                        notifier.updateDraft(name: value.text),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'lobby.nameRequired'.tr();
                    }
                    if (value.length < 3) {
                      return 'lobby.nameTooShort'.tr();
                    }
                    return null;
                  },
                ),


                // Visibility
                PSegmentedButton<LobbyVisibility>(
                  label: Text('createLobby.visibility'.tr()),
                  values: LobbyVisibility.values,
                  selected: lobby.visibility,
                  format: (v) => Text(v.getLocalizedName(context)),
                  description: (v) =>
                      'lobby.visibility.${v.name}Description'.tr(),
                  onChange: (v) {
                    if (v != null) notifier.updateDraft(visibility: v);
                  },
                ),


                // Age Group
                PSegmentedButton<AgeGroup>(
                  label: Text('lobby.ageGroup'.tr()),
                  values: AgeGroup.values,
                  selected: lobby.details?.ageGroup,
                  format: (ag) => FaIcon(switch (ag) {
                    AgeGroup.student => FontAwesomeIcons.graduationCap,
                    AgeGroup.mature => FontAwesomeIcons.briefcase,
                    AgeGroup.middleAge => FontAwesomeIcons.wineGlass,
                  }),
                  description: (ag) => ag.getLocalizedName(context),
                  onChange: (ag) => notifier.updateDetails(ageGroup: ag),
                  deselectable: true,
                ),


                // Home Ground
                HomeGroundField(
                  value: lobby.homeGround,
                  onChanged: (v) => notifier.updateDraft(homeGround: v),
                  onFreeAddressChanged: notifier.updateFreeAddress,
                ),


                // Playtime
                _TimeslotSection(
                  playtime: lobby.playtime ?? [],
                  pendingDayChunk: _pendingDayChunk,
                  pendingDayOfWeek: _pendingDayOfWeek,
                  onDayChunkChanged: (chunk) =>
                      setState(() => _pendingDayChunk = chunk),
                  onDayOfWeekChanged: (day) =>
                      setState(() => _pendingDayOfWeek = day),
                  onAdd: () {
                    final timeslot =
                        Timeslot(_pendingDayOfWeek, _pendingDayChunk);
                    final updated = <Timeslot>[...(lobby.playtime ?? [])];
                    if (!updated.contains(timeslot)) {
                      updated.add(timeslot);
                      notifier.updateDraft(playtime: updated);
                    }
                  },
                  onRemove: (timeslot) {
                    final updated = <Timeslot>[...(lobby.playtime ?? [])];
                    updated.remove(timeslot);
                    notifier.updateDraft(playtime: updated);
                  },
                ),

                // Save button
                FButton(
                  onPress: formState.isSaving ? null : () => _onSave(context),
                  child: formState.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('createLobby.create'.tr()),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSave(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final lobby = await ref
          .read(lobbyFormControllerProvider(widget.lobbyId).notifier)
          .commit();

      if (!context.mounted) return;
      Navigator.of(context).pop(lobby);
    } catch (e) {
      if (!context.mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FIcons.circleX),
        variant: .destructive,
        title: Text('lobby.saveFailed'.tr()),
        description: Text('errorGeneric'.tr()),
        alignment: .bottomCenter,
      );
    }
  }
}

class _TimeslotSection extends StatelessWidget {
  final List<Timeslot> playtime;
  final DayChunk pendingDayChunk;
  final DayOfWeek pendingDayOfWeek;
  final ValueChanged<DayChunk> onDayChunkChanged;
  final ValueChanged<DayOfWeek> onDayOfWeekChanged;
  final VoidCallback onAdd;
  final ValueChanged<Timeslot> onRemove;

  const _TimeslotSection({
    required this.playtime,
    required this.pendingDayChunk,
    required this.pendingDayOfWeek,
    required this.onDayChunkChanged,
    required this.onDayOfWeekChanged,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final fieldStyle = context.theme.multiSelectStyle.fieldStyles.md;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          'createLobby.playtime'.tr(),
          style: context.theme.typography.sm.copyWith(fontWeight: .bold),
        ),

        // Chips container
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.theme.colors.card,
            border: Border.all(
              color: context.theme.colors.border,
              width: context.theme.style.borderWidth,
            ),
            borderRadius: context.theme.style.borderRadius.md,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 8, 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: fieldStyle.spacing,
                  runSpacing: fieldStyle.runSpacing,
                  children: [
                    if (playtime.isEmpty)
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(4, 4, 0, 4),
                        child: Text(
                          'homeTab.filter.any'.tr(),
                          style: context.theme.typography.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      ),
                    for (final timeslot in playtime)
                      GestureDetector(
                        onTap: () => onRemove(timeslot),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            // TODO: check
                            borderRadius: context.theme.style.borderRadius.md,
                            color: context.theme.colors.secondary,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4,
                              children: [
                                Text(
                                  '${timeslot.dayChunk.getShortName(context)} ${timeslot.dayOfWeek.getShortName(context)}',
                                  style: context.theme.typography.sm.copyWith(
                                    color: context
                                        .theme.colors.secondaryForeground,
                                  ),
                                ),
                                IconTheme(
                                  data: IconThemeData(
                                    color:
                                        context.theme.colors.mutedForeground,
                                    size: 15,
                                  ),
                                  child: const Icon(FIcons.x),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Pickers row
        Row(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: FSelect<DayChunk>.rich(
                hint: pendingDayChunk.getFullName(context),
                format: (chunk) => chunk.getFullName(context),
                autoHide: true,
                control: FSelectControl.lifted(
                  value: pendingDayChunk,
                  onChange: (chunk) {
                    if (chunk != null) onDayChunkChanged(chunk);
                  },
                ),
                children: [
                  for (final chunk in DayChunk.values)
                    FSelectItem<DayChunk>(
                      title: Text(chunk.getFullName(context)),
                      value: chunk,
                    ),
                ],
              ),
            ),
            Expanded(
              child: FSelect<DayOfWeek>.rich(
                hint: pendingDayOfWeek.getFullName(context),
                format: (day) => day.getFullName(context),
                autoHide: true,
                control: FSelectControl.lifted(
                  value: pendingDayOfWeek,
                  onChange: (day) {
                    if (day != null) onDayOfWeekChanged(day);
                  },
                ),
                children: [
                  for (final day in DayOfWeek.values)
                    FSelectItem<DayOfWeek>(
                      title: Text(day.getFullName(context)),
                      value: day,
                    ),
                ],
              ),
            ),
            FButton.icon(
              variant: .ghost,
              onPress: onAdd,
              child: const Icon(FIcons.plus),
            ),
          ],
        ),
      ],
    );
  }
}
