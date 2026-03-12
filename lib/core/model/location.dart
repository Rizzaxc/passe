import 'package:freezed_annotation/freezed_annotation.dart';

part 'location.freezed.dart';
part 'location.g.dart';

String? _streetNumberFromJson(dynamic val) => val?.toString();

@freezed
abstract class Location with _$Location {
  const factory Location({
    required String id,
    required String name,
    @JsonKey(name: 'full_address') String? fullAddress,
    @JsonKey(name: 'street_number', fromJson: _streetNumberFromJson) String? streetNumber,
    @JsonKey(name: 'street_name') String? streetName,
    String? district,
    String? city,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
}
