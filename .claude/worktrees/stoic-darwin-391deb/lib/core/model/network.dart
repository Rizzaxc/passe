import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enum.dart';

part 'network.freezed.dart';
part 'network.g.dart';


/// Enum for network categories
@JsonEnum()
enum NetworkCategory {
  @JsonValue('high school')
  highSchool,
  @JsonValue('gifted high school')
  giftedHighSchool,
  @JsonValue('university')
  university,
  @JsonValue('company')
  company;

  String getLocalizedName(BuildContext context) {
    return context.tr('networkCategory.$name');
  }

  String get jsonValue {
    switch (this) {
      case NetworkCategory.highSchool:
        return 'high school';
      case NetworkCategory.giftedHighSchool:
        return 'gifted high school';
      case NetworkCategory.university:
        return 'university';
      case NetworkCategory.company:
        return 'company';
    }
  }

  Color get categoryColor {
    switch (this) {
      case NetworkCategory.highSchool:
        return Colors.blue;
      case NetworkCategory.giftedHighSchool:
        return Colors.purple;
      case NetworkCategory.university:
        return Colors.red;
      case NetworkCategory.company:
        return Colors.brown;
    }
  }

  static NetworkCategory fromString(String? value) {
    switch (value) {
      case 'high school':
        return NetworkCategory.highSchool;
      case 'gifted high school':
        return NetworkCategory.giftedHighSchool;
      case 'university':
        return NetworkCategory.university;
      default:
        return NetworkCategory.company;
    }
  }
}


/// Class representing a Network or a UserNetwork
@freezed
abstract class Network with _$Network implements Comparable<Network> {
  const Network._();

  const factory Network({
    required int id,
    required String name,
    // if representing a UserNetwork, can either be true or false.
    // if it's only for a Network, default to false
    required bool isAlumni,
    required NetworkCategory category,
    City? city,
  }) = _Network;

  factory Network.fromJson(Map<String, dynamic> json) => _$NetworkFromJson(json);

  @override
  int compareTo(Network other) => id.compareTo(other.id);

  @override
  String toString() => name;

  String getLocalizedName(BuildContext context) => name;
}