import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ui/sheet.dart';

enum _MapDirectionsApp { googleMaps, appleMaps }

/// A valid Apple Maps turn-by-turn URL.
///
/// Keep this to directions-only parameters. Combining `daddr` with the search
/// parameter `q` can make Apple Maps open without resolving a route.
Uri appleMapsDirectionsUri({required String destination}) =>
    Uri.https('maps.apple.com', '/', {'daddr': destination, 'dirflg': 'd'});

/// Google Maps' native iOS directions URL.
Uri googleMapsAppDirectionsUri({required String destination}) {
  final query = Uri(
    queryParameters: {'daddr': destination, 'directionsmode': 'driving'},
  ).query;
  return Uri.parse('comgooglemaps://?$query');
}

/// Google Maps universal web URL, which also acts as the no-app fallback.
Uri googleMapsWebDirectionsUri({required String destination}) => Uri.https(
  'www.google.com',
  '/maps/dir/',
  {'api': '1', 'destination': destination, 'travelmode': 'driving'},
);

/// Resolves the most precise usable destination, falling back from a complete
/// coordinate pair to a custom address and finally the location name.
String? mapDirectionsDestination({
  double? lat,
  double? lon,
  String? address,
  String? label,
}) {
  if (lat != null && lon != null) return '$lat,$lon';
  for (final candidate in [address, label]) {
    final value = candidate?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

/// Android's generic maps intent. Android presents its native app chooser
/// when the user has not already selected a default maps app.
Uri androidGeoDirectionsUri({
  double? lat,
  double? lon,
  required String destination,
  String? label,
}) {
  final hasCoordinates = lat != null && lon != null;
  final coordinates = hasCoordinates ? '$lat,$lon' : null;
  final trimmedLabel = label?.trim();
  final queryValue = coordinates != null && trimmedLabel?.isNotEmpty == true
      ? '$coordinates($trimmedLabel)'
      : destination;
  final query = Uri.encodeQueryComponent(queryValue);
  return Uri.parse('geo:${coordinates ?? '0,0'}?q=$query');
}

/// Opens directions with a platform-appropriate map app.
///
/// iOS has no system maps-app chooser, so Passe presents Google Maps first
/// and Apple Maps second. Google Maps falls back to its directions website if
/// the native app is not installed. Android continues through the native
/// `geo:` chooser, with the same Google web fallback.
Future<void> openMapDirections(
  BuildContext context, {
  double? lat,
  double? lon,
  String? address,
  required String label,
}) async {
  final destination = mapDirectionsDestination(
    lat: lat,
    lon: lon,
    address: address,
    label: label,
  );
  if (destination == null) {
    _showLaunchFailed(context);
    return;
  }

  var launched = false;

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final choice = await showPSheet<_MapDirectionsApp>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(label: 'homeTab.location.chooseMapApp'.tr()),
          FButton(
            prefix: const Icon(FLucideIcons.mapPinned),
            onPress: () =>
                Navigator.of(sheetContext).pop(_MapDirectionsApp.googleMaps),
            child: Text('homeTab.location.googleMaps'.tr()),
          ),
          FButton(
            variant: .outline,
            prefix: const Icon(FLucideIcons.map),
            onPress: () =>
                Navigator.of(sheetContext).pop(_MapDirectionsApp.appleMaps),
            child: Text('homeTab.location.appleMaps'.tr()),
          ),
        ],
      ),
    );
    if (choice == null) return;

    launched = switch (choice) {
      _MapDirectionsApp.googleMaps => await _launchGoogleMaps(destination),
      _MapDirectionsApp.appleMaps => await _launchAppleMaps(destination),
    };
  } else {
    launched = await _launchAndroidMaps(
      destination,
      lat: lat,
      lon: lon,
      label: label,
    );
  }

  if (!launched && context.mounted) _showLaunchFailed(context);
}

void _showLaunchFailed(BuildContext context) {
  if (!context.mounted) return;
  showFToast(
    context: context,
    icon: const Icon(FLucideIcons.circleX),
    variant: .destructive,
    title: Text('homeTab.location.directionsFailed'.tr()),
    alignment: .bottomCenter,
  );
}

Future<bool> _launchGoogleMaps(String destination) async {
  final appUri = googleMapsAppDirectionsUri(destination: destination);
  final webUri = googleMapsWebDirectionsUri(destination: destination);
  try {
    if (await canLaunchUrl(appUri) &&
        await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    return await launchUrl(webUri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<bool> _launchAppleMaps(String destination) async {
  try {
    if (await launchUrl(
      appleMapsDirectionsUri(destination: destination),
      mode: LaunchMode.externalApplication,
    )) {
      return true;
    }
    return await launchUrl(
      googleMapsWebDirectionsUri(destination: destination),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}

Future<bool> _launchAndroidMaps(
  String destination, {
  double? lat,
  double? lon,
  required String label,
}) async {
  final geoUri = androidGeoDirectionsUri(
    lat: lat,
    lon: lon,
    destination: destination,
    label: label,
  );
  try {
    if (await canLaunchUrl(geoUri) &&
        await launchUrl(geoUri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    return await launchUrl(
      googleMapsWebDirectionsUri(destination: destination),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}
