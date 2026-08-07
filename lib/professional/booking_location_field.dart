import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/model/location.dart';
import '../ui/main.dart';
import '../ui/search_field.dart';

part 'booking_location_field.g.dart';

/// A coach's declared courts (set out-of-app — see
/// `schema/professional_preferred_location.sql`), for the student to pick a
/// session venue from.
@riverpod
Future<List<Location>> preferredCourts(Ref ref, String professionalId) async {
  final response = await Supabase.instance.client
      .from('professional_preferred_location')
      .select('location(*)')
      .eq('professional_id', professionalId)
      .timeout(const Duration(seconds: 5));

  return (response as List)
      .map(
        (e) => Location.fromJson(
          (e as Map<String, dynamic>)['location'] as Map<String, dynamic>,
        ),
      )
      .toList();
}

Future<List<Location>> _searchLocations(String query) async {
  if (query.length < 8) return [];
  final response = await Supabase.instance.client
      .rpc('search_locations', params: {'search_term': query})
      .timeout(const Duration(seconds: 5));
  return (response as List)
      .map((e) => Location.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Required location picker for a coach booking: pick one of the coach's
/// preferred courts, suggest an existing venue, or provide a booking-scoped
/// free-text location. Free text is stored on the booking instead of inserting
/// an incomplete row into the global `location` directory. Deliberately does
/// *not* reuse `HomeGroundField` — that widget
/// is bound to the lobby home-ground's single-value contract and its own
/// form controller; duplicating its full structured-address UI here would
/// be a lot of surface for a field that mostly just needs "pick one of
/// these known courts."
class BookingLocationField extends ConsumerStatefulWidget {
  final String professionalId;
  final String? locationId;
  final String? customLocationName;
  final void Function(String? locationId, String? customLocationName) onChanged;

  const BookingLocationField({
    super.key,
    required this.professionalId,
    required this.locationId,
    required this.customLocationName,
    required this.onChanged,
  });

  @override
  ConsumerState<BookingLocationField> createState() =>
      _BookingLocationFieldState();
}

class _BookingLocationFieldState extends ConsumerState<BookingLocationField> {
  bool _suggestingOther = false;
  final _searchController = TextEditingController();
  final _newNameController = TextEditingController();
  Location? _selectedOther;
  String? _customLocationName;

  @override
  void initState() {
    super.initState();
    _customLocationName = widget.customLocationName;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newNameController.dispose();
    super.dispose();
  }

  void _useFreeTextLocation() {
    final name = _newNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _selectedOther = null;
      _customLocationName = name;
    });
    widget.onChanged(null, name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final courtsAsync = ref.watch(
      preferredCourtsProvider(widget.professionalId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          children: [
            Text(
              'Địa điểm',
              style: context.theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            FButton(
              variant: .ghost,
              onPress: () =>
                  setState(() => _suggestingOther = !_suggestingOther),
              child: Text(
                _suggestingOther ? 'Chọn sân của HLV' : 'Đề xuất địa chỉ khác',
              ),
            ),
          ],
        ),
        if (_suggestingOther) ...[
          if (_selectedOther != null || _customLocationName != null)
            FTileGroup(
              children: [
                FTile(
                  title: Text(_selectedOther?.name ?? _customLocationName!),
                  subtitle: _selectedOther?.displayAddress.isNotEmpty == true
                      ? Text(_selectedOther!.displayAddress)
                      : null,
                  suffix: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedOther = null;
                        _customLocationName = null;
                      });
                      widget.onChanged(null, null);
                    },
                    child: const Icon(FLucideIcons.x, size: 16),
                  ),
                ),
              ],
            )
          else ...[
            PSearchField<Location>(
              hint: 'Tìm địa điểm...',
              controller: _searchController,
              suggestionsBuilder: _searchLocations,
              displayStringForOption: (loc) => loc.fullAddress ?? loc.name,
              onSuggestionSelected: (loc) {
                setState(() {
                  _selectedOther = loc;
                  _customLocationName = null;
                });
                widget.onChanged(loc.id, null);
              },
              onChange: (_) {},
              formatSuggestion: (context, loc) =>
                  Text(loc.fullAddress ?? loc.name),
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FTextField(
                    hint: 'Hoặc nhập tên địa điểm mới',
                    control: FTextFieldControl.managed(
                      controller: _newNameController,
                    ),
                  ),
                ),
                FButton(
                  variant: .outline,
                  onPress: _useFreeTextLocation,
                  child: const Text('Thêm'),
                ),
              ],
            ),
          ],
        ] else
          courtsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(
              'Không tải được danh sách sân',
              style: context.theme.typography.body.sm.copyWith(
                color: colors.mutedForeground,
              ),
            ),
            data: (courts) {
              if (courts.isEmpty) {
                return Text(
                  'HLV chưa khai báo sân. Vui lòng đề xuất một địa chỉ.',
                  style: context.theme.typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                );
              }
              return Column(
                spacing: 8,
                children: [
                  for (final court in courts)
                    FTappable(
                      onPress: () {
                        setState(() {
                          _selectedOther = null;
                          _customLocationName = null;
                        });
                        widget.onChanged(court.id, null);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: widget.locationId == court.id
                              ? colors.primary.withValues(alpha: 0.08)
                              : colors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.locationId == court.id
                                ? colors.primary
                                : colors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.locationId == court.id
                                  ? FLucideIcons.circleCheck
                                  : FLucideIcons.circle,
                              size: 18,
                              color: widget.locationId == court.id
                                  ? colors.primary
                                  : colors.mutedForeground,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    court.name,
                                    style: context.theme.typography.body.sm
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  if (court.displayAddress.isNotEmpty)
                                    Text(
                                      court.displayAddress,
                                      style: context.theme.typography.body.xs
                                          .copyWith(
                                            color: colors.mutedForeground,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
