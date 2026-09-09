import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/model/location.dart';
import '../../../ui/main.dart';

/// Form primitives shared by both challenge-offer forms — the refereed one
/// (`challenge_offer_sheet.dart`) and the friendly one
/// (`friendly_offer_sheet.dart`). Extracted rather than duplicated: they are
/// the same control, and a venue picker that behaves differently between two
/// forms for the same concept is a bug waiting to happen.

/// A tappable "label … value ›" row. The value is a formatted date or a venue
/// name — unbounded — so it is the side that shrinks.
class ChallengeFieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool filled;
  final VoidCallback onTap;

  const ChallengeFieldTile({
    super.key,
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

/// Venue picker for an offer. Seeded with the lobby's homeground by its caller
/// and otherwise searching `location` through the same `search_locations` RPC
/// the rest of the app uses.
class ChallengeVenuePicker extends StatefulWidget {
  final String? selectedName;
  final ValueChanged<Location> onSelected;

  const ChallengeVenuePicker({
    super.key,
    required this.selectedName,
    required this.onSelected,
  });

  @override
  State<ChallengeVenuePicker> createState() => _ChallengeVenuePickerState();
}

class _ChallengeVenuePickerState extends State<ChallengeVenuePicker> {
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

    return ChallengeFieldTile(
      icon: FLucideIcons.mapPin,
      label: 'lobbyHub.challenge.venue'.tr(),
      value: name,
      filled: true,
      onTap: () => setState(() => _changing = true),
    );
  }
}
