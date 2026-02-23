import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/enum.dart';
import '../../core/model/lobby.dart';
import '../../core/model/timeslot.dart';
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
    mainAxisMaxRatio: 3/4,
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
    final notifier = ref.read(lobbyFormControllerProvider(widget.lobbyId).notifier);
    final lobby = formState.lobby;

    return FSheets(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        decoration: BoxDecoration(
          color: context.theme.colors.background,
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
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  formState.isNew ? 'lobby.create'.tr() : 'lobby.edit'.tr(),
                  style: context.theme.typography.xl.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Row 1: Name + Sport
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      flex: 2,
                      child: FTextFormField(
                        label: Text('lobby.name'.tr()),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        control: FTextFieldControl.managed(
                          controller: _nameController,
                          onChange: (value) => notifier.updateDraft(name: value.text),
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
                    ),
                    Expanded(
                      child: FSelectMenuTile<Sport>.fromMap(
                        {
                          for (var sport in Sport.values.where((s) => s != Sport.others))
                            sport.getLocalizedName(context): sport,
                        },
                        title: Text(lobby.sport.getLocalizedName(context)),
                        label: Text('lobby.sport'.tr()),
                        selectControl: FMultiValueControl.lifted(
                          value: {lobby.sport},
                          onChange: (sports) {
                            if (sports.isEmpty) return;
                            notifier.updateDraft(sport: sports.last);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Row 2: Visibility
                FSlider(
                  label: Text('lobby.visibility.label'.tr()),
                  description: Text(
                    'lobby.visibility.${lobby.visibility.name}.description'.tr(),
                  ),
                  tooltipControls: const FSliderTooltipControls.disabled(),
                  control: FSliderControl.managedDiscrete(
                    initial: FSliderValue(max: lobby.visibility.index / (LobbyVisibility.values.length - 1)),
                    onChange: (value) {
                      final index = (value.max * (LobbyVisibility.values.length - 1)).round();
                      notifier.updateDraft(visibility: LobbyVisibility.values[index]);
                    },
                  ),
                  marks: [
                    for (var i = 0; i < LobbyVisibility.values.length; i++)
                      FSliderMark(
                        value: i / (LobbyVisibility.values.length - 1),
                        label: Text(
                          LobbyVisibility.values[i].getLocalizedName(context),
                          style: context.theme.typography.sm,
                        ),
                      ),
                  ],
                ),

                // Row 3: Skill (stub) + Age Group
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: FTile(
                        title: Text('lobby.skill'.tr()),
                        subtitle: Text('lobby.skillStub'.tr()),
                        enabled: false,
                      ),
                    ),
                    Expanded(
                      child: FSelectMenuTile<AgeGroup>.fromMap(
                        {
                          for (var ageGroup in AgeGroup.values)
                            ageGroup.getLocalizedName(context): ageGroup,
                        },
                        title: Text(
                          lobby.details?.ageGroup?.getLocalizedName(context) ??
                              'lobby.anyAgeGroup'.tr(),
                        ),
                        label: Text('lobby.ageGroup'.tr()),
                        selectControl: FMultiValueControl.lifted(
                          value: lobby.details?.ageGroup != null
                              ? {lobby.details!.ageGroup!}
                              : {},
                          onChange: (ageGroups) {
                            notifier.updateDetails(
                              ageGroup: ageGroups.isEmpty ? null : ageGroups.last,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Row 4: Timeslot selection
                _TimeslotSection(
                  playtime: lobby.playtime ?? [],
                  pendingDayChunk: _pendingDayChunk,
                  pendingDayOfWeek: _pendingDayOfWeek,
                  onDayChunkChanged: (chunk) => setState(() => _pendingDayChunk = chunk),
                  onDayOfWeekChanged: (day) => setState(() => _pendingDayOfWeek = day),
                  onAdd: () {
                    final timeslot = Timeslot(_pendingDayOfWeek, _pendingDayChunk);
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

                // Row 5: Home ground (stub for now)
                FTile(
                  title: Text('lobby.homeGround'.tr()),
                  subtitle: Text(
                    lobby.homeGround ?? 'lobby.homeGroundStub'.tr(),
                  ),
                  suffix: const Icon(FIcons.mapPin),
                  enabled: false,
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
                      : Text(
                          formState.isNew
                              ? 'lobby.createButton'.tr()
                              : 'lobby.saveButton'.tr(),
                        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          spacing: 2,
          crossAxisAlignment: .end,
          children: [
            const Icon(FIcons.calendarDays),
            Text(
              'lobby.playtime'.tr(),
              style: context.theme.typography.base.copyWith(
                fontWeight: FontWeight.bold,
                color: context.theme.colors.primary,
              ),
            ),
          ],
        ),
        if (playtime.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final timeslot in playtime)
                GestureDetector(
                  onTap: () => onRemove(timeslot),
                  child: FBadge(
                    variant: .secondary,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Text(
                          '${timeslot.dayChunk.getShortName(context)} ${timeslot.dayOfWeek.getShortName(context)}',
                          style: context.theme.typography.base,
                        ),
                        Icon(
                          FIcons.x,
                          size: 12,
                          color: context.theme.colors.mutedForeground,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: FSelectMenuTile<DayChunk>.fromMap(
                {
                  for (var chunk in DayChunk.values)
                    chunk.getFullName(context): chunk,
                },
                title: Text(pendingDayChunk.getFullName(context)),
                selectControl: FMultiValueControl.lifted(
                  value: {pendingDayChunk},
                  onChange: (chunks) {
                    if (chunks.isEmpty) return;
                    onDayChunkChanged(chunks.last);
                  },
                ),
              ),
            ),
            Expanded(
              child: FSelectMenuTile<DayOfWeek>.fromMap(
                {
                  for (var day in DayOfWeek.values)
                    day.getFullName(context): day,
                },
                maxHeight: 200,
                title: Text(pendingDayOfWeek.getFullName(context)),
                selectControl: FMultiValueControl.lifted(
                  value: {pendingDayOfWeek},
                  onChange: (days) {
                    if (days.isEmpty) return;
                    onDayOfWeekChanged(days.last);
                  },
                ),
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
