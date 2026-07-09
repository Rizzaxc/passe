import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/model/enum.dart';
import '../core/model/user_details.dart';
import '../core/model/user_location.dart';
import '../ui/district_select.dart';
import 'profile_controller.dart';

class LocationSelectionScreen extends ConsumerWidget {
  const LocationSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(profileControllerProvider).details;
    final location = details.location ?? const UserLocation();
    final selectedCity = location.city == City.none ? null : location.city;
    final selectedDistrictIds = location.districts.toSet();

    return FScaffold(
      header: FHeader(
        title: Text('profile.location'.tr()),
        suffixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FSelect<City>.rich(
              label: Text('profile.locationCity'.tr()),
              hint: 'profile.locationCity'.tr(),
              format: (city) => city.getLocalizedName(context),
              autoHide: true,
              control: FSelectControl.lifted(
                value: selectedCity,
                onChange: (city) {
                  ref
                      .read(profileControllerProvider.notifier)
                      .updateDraft(
                        details: details.copyWith(
                          location: UserLocation(
                            city: city ?? City.none,
                            districts: [],
                          ),
                        ),
                      );
                },
              ),
              children: [
                FSelectItem<City>(
                  title: Text(City.hochiminh.getLocalizedName(context)),
                  value: City.hochiminh,
                ),
                FSelectItem<City>(
                  title: Text(City.hanoi.getLocalizedName(context)),
                  value: City.hanoi,
                ),
              ],
            ),
            if (selectedCity != null) ...[
              const SizedBox(height: 16),
              _DistrictSelect(
                key: ValueKey(selectedCity),
                city: selectedCity,
                selectedIds: selectedDistrictIds,
                details: details,
                location: location,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DistrictSelect extends ConsumerWidget {
  final City city;
  final Set<String> selectedIds;
  final UserDetails details;
  final UserLocation location;

  const _DistrictSelect({
    required this.city,
    required this.selectedIds,
    required this.details,
    required this.location,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 102-126 flat wards per city is too long to scroll — .searchBuilder adds
    // a search field, still grouped by legacy quận/huyện via districtSections.
    return FMultiSelect<String>.searchBuilder(
      label: Text('profile.locationDistrict'.tr()),
      hint: Text('profile.locationDistrictHint'.tr()),
      format: (id) {
        final d = VietnamLocationData.instance.findDistrictById(id);
        return d != null ? Text(d.getLocalizedFullName(context)) : Text(id);
      },
      keepHint: false,
      control: FMultiValueControl.managed(
        initial: selectedIds,
        onChange: (selected) {
          final capped = selected.length > 6
              ? selected.take(6).toSet()
              : selected;
          ref
              .read(profileControllerProvider.notifier)
              .updateDraft(
                details: details.copyWith(
                  location: location.copyWith(districts: capped.toList()),
                ),
              );
        },
      ),
      searchFieldProperties: districtSearchFieldProperties(context),
      contentEmptyBuilder: (context, _) => districtEmptyBuilder(context),
      filter: (query) => VietnamLocationData.instance
          .searchDistricts(city, query)
          .map((d) => d.id),
      contentBuilder: (context, query, values) => districtSections<String>(
        context: context,
        values: values,
        toDistrict: (id) => VietnamLocationData.instance.findDistrictById(id)!,
        isSelected: selectedIds.contains,
      ),
    );
  }
}
