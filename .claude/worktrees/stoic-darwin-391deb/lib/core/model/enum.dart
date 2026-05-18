// follow database ID
import 'package:diacritic/diacritic.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:json_annotation/json_annotation.dart';

import '../icon/main.dart';

enum Sport {
  others(null),
  soccer(HealthWorkoutActivityType.SOCCER),
  basketball(HealthWorkoutActivityType.BASKETBALL),
  badminton(HealthWorkoutActivityType.BADMINTON),
  tennis(HealthWorkoutActivityType.TENNIS),
  pickleball(HealthWorkoutActivityType.PICKLEBALL);

  final HealthWorkoutActivityType? healthWorkoutType;

  const Sport(this.healthWorkoutType);

  String getLocalizedName(BuildContext context) {
    return context.tr('sport.$name');
  }

  Widget getIcon({double size = 12}) => switch (this) {
        Sport.soccer => SportIcons.soccer(size: size),
        Sport.basketball => SportIcons.basketball(size: size),
        Sport.badminton => SportIcons.badminton(size: size),
        Sport.tennis => SportIcons.tennis(size: size),
        Sport.pickleball => SportIcons.pickleball(size: size),
        Sport.others => Icon(Icons.question_mark, size: size),
      };

  static List<String> getAllLocalizedNames(BuildContext context) {
    return Sport.values.map((e) => e.getLocalizedName(context)).toList();
  }

  /// Convert from HealthWorkoutActivityType to Sport.
  /// Returns [Sport.others] if no matching sport is found.
  static Sport fromHealthWorkoutType(HealthWorkoutActivityType? type) {
    if (type == null) return Sport.others;
    for (final sport in Sport.values) {
      if (sport.healthWorkoutType == type) {
        return sport;
      }
    }
    return Sport.others;
  }
}

@JsonEnum()
enum DayChunk {
  @JsonValue('early')
  early, // 4am-9am
  @JsonValue('midday')
  midday, // 9am-2pm
  @JsonValue('noon')
  noon, // 2pm-6pm
  @JsonValue('night')
  night; // 6pm-12pm

  static String getLocalizedEnumLabel(BuildContext context) {
    return context.tr('timeslot.dayChunk.label');
  }

  String getShortName(BuildContext context) {
    return context.tr('timeslot.dayChunk.shortName.$name');
  }

  String getFullName(BuildContext context) {
    return context.tr('timeslot.dayChunk.$name');
  }
}

@JsonEnum()
enum DayOfWeek {
  @JsonValue('all')
  everyday,
  @JsonValue('mon')
  monday,
  @JsonValue('tue')
  tuesday,
  @JsonValue('wed')
  wednesday,
  @JsonValue('thu')
  thursday,
  @JsonValue('fri')
  friday,
  @JsonValue('sat')
  saturday,
  @JsonValue('sun')
  sunday,
  @JsonValue('mwf')
  even, // mon wed fri
  @JsonValue('tts')
  odd, // tue thu sat
  @JsonValue('wkn')
  weekend; // sat sun

  static String getLocalizedEnumLabel(BuildContext context) {
    return context.tr('timeslot.dayOfWeek.label');
  }

  static List<String> getAllLocalizedName(BuildContext context) {
    return Gender.values.map((each) => each.getLocalizedName(context)).toList();
  }

  String getShortName(BuildContext context) {
    return context.tr('timeslot.dayOfWeek.shortName.$name');

  }

  String getFullName(BuildContext context) {
    return context.tr('timeslot.dayOfWeek.$name');
  }
}

@JsonEnum()
enum StakeUnit {
  @JsonValue('game')
  game,
  @JsonValue('set')
  set,
  @JsonValue('goal')
  goal,
}

enum City {
  @JsonValue(0)
  none('none', '', 0),
  @JsonValue(1)
  hochiminh('hcm', 'hochiminh', 1),
  @JsonValue(2)
  hanoi('hn', 'hanoi', 2);

  final String shorthand;
  final String name;
  final int dbIndex;

  const City(this.shorthand, this.name, this.dbIndex);

  String getLocalizedName(BuildContext context) {
    return context.tr('city.$name');
  }

  factory City.fromShorthand(String shorthand) {
    switch (shorthand.toLowerCase()) {
      case 'none':
        return City.none;
      case 'hn':
        return City.hanoi;
      case 'hcm':
        return City.hochiminh;
      default:
        throw ArgumentError('Invalid city shorthand: $shorthand');
    }
  }
}

/// Enum representing district types in Vietnam
enum VietnamDistrictType {
  urban('quan', 'Quận'),
  rural('huyen', 'Huyện'),
  township('thixa', 'Thị xã'),
  city('thanhpho', 'Thành phố');

  final String code;
  final String prefix;

  const VietnamDistrictType(this.code, this.prefix);
}

/// Class representing a district in Vietnam
class District {
  final String id;
  final String name;
  final City city;
  final VietnamDistrictType type;
  final String? code;

  /// Full name with prefix (e.g., "Quận 1")
  String get fullName => '$name ${type.prefix}';

  String getLocalizedFullName(BuildContext context) => '${context.tr('district.${type.name}')} $name';

  /// Full name with city (e.g., "Tp Hồ Chí Minh - Quận 1")
  String get fullNameWithCity => '${city.name} - $name ${type.prefix}';

  String getLocalizedFullNameWithCity(BuildContext context) =>
      '${city.getLocalizedName(context)} - ${context.tr('district.${type.name}')} $name';

  const District({
    required this.id,
    required this.name,
    required this.city,
    required this.type,
    this.code,
  });

  @override
  String toString() => fullName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is District && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Class to manage location data in Vietnam
class VietnamLocationData {
  VietnamLocationData._();

  /// Singleton instance
  static final VietnamLocationData instance = VietnamLocationData._();

  /// Get all districts by city
  Map<City, List<District>> getAllDistricts() {
    return {City.hochiminh: _hcmcDistricts, City.hanoi: _hanoiDistricts};
  }

  /// Get districts for a specific city
  List<District> getDistrictsByCity(City city) {
    switch (city) {
      case City.none:
        return [];
      case City.hochiminh:
        return _hcmcDistricts;
      case City.hanoi:
        return _hanoiDistricts;
    }
  }

  /// Get districts by type for a specific city
  List<District> getDistrictsByType(City city, VietnamDistrictType type) {
    return getDistrictsByCity(
      city,
    ).where((district) => district.type == type).toList();
  }

  /// Find a district by ID
  District? findDistrictById(String id) {
    for (var districts in getAllDistricts().values) {
      for (var district in districts) {
        if (district.id == id) return district;
      }
    }
    return null;
  }

  /// Find districts by a search term (case insensitive, partial match)
  List<District> searchDistricts(String term) {
    final searchTerm = term.toLowerCase();
    final result = <District>[];

    for (var districts in getAllDistricts().values) {
      for (var district in districts) {
        if (district.name.toLowerCase().contains(searchTerm) ||
            district.fullName.toLowerCase().contains(searchTerm)) {
          result.add(district);
        }
      }
    }

    return result;
  }

  /// Ho Chi Minh City districts list
  static final List<District> _hcmcDistricts = [
    // Urban districts
    District(
      id: 'hcm_q1',
      name: '1',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'D1',
    ),
    District(
      id: 'hcm_q3',
      name: '3',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'D3',
    ),
    District(
      id: 'hcm_q4',
      name: '4',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'D4',
    ),
    District(
      id: 'hcm_q5',
      name: '5',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'D5',
    ),
    District(
      id: 'hcm_q6',
      name: '6',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'D6',
    ),
    District(
      id: 'hcm_q7',
      name: '7',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'D7',
    ),
    District(
      id: 'hcm_q8',
      name: '8',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'D8',
    ),
    District(
      id: 'hcm_q10',
      name: '10',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'D10',
    ),
    District(
      id: 'hcm_q11',
      name: '11',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'D11',
    ),
    District(
      id: 'hcm_q12',
      name: '12',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'D12',
    ),
    District(
      id: 'hcm_binhthanh',
      name: 'Bình Thạnh',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'BTH',
    ),
    District(
      id: 'hcm_binhtan',
      name: 'Bình Tân',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'BTN',
    ),
    District(
      id: 'hcm_govap',
      name: 'Gò Vấp',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'GV',
    ),
    District(
      id: 'hcm_phunhuan',
      name: 'Phú Nhuận',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'PN',
    ),
    District(
      id: 'hcm_tanbinh',
      name: 'Tân Bình',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'TB',
    ),
    District(
      id: 'hcm_tanphu',
      name: 'Tân Phú',
      city: City.hochiminh,
      type: VietnamDistrictType.urban,
      code: 'TP',
    ),

    // City inside Ho Chi Minh City
    District(
      id: 'hcm_thuduc',
      name: 'Thủ Đức',
      city: City.hochiminh,
      type: VietnamDistrictType.city,
      code: 'TD',
    ),

    // Rural districts
    District(
      id: 'hcm_binhchanh',
      name: 'Bình Chánh',
      city: City.hochiminh,
      type: VietnamDistrictType.rural,
      code: 'BC',
    ),
    District(
      id: 'hcm_cuchi',
      name: 'Củ Chi',
      city: City.hochiminh,
      type: VietnamDistrictType.rural,
      code: 'CC',
    ),
    District(
      id: 'hcm_cangio',
      name: 'Cần Giờ',
      city: City.hochiminh,
      type: VietnamDistrictType.rural,
      code: 'CG',
    ),
    District(
      id: 'hcm_hocmon',
      name: 'Hóc Môn',
      city: City.hochiminh,
      type: VietnamDistrictType.rural,
      code: 'HM',
    ),
    District(
      id: 'hcm_nhabe',
      name: 'Nhà Bè',
      city: City.hochiminh,
      type: VietnamDistrictType.rural,
      code: 'NB',
    ),
  ];

  /// Hanoi districts list
  static final List<District> _hanoiDistricts = [
    // Urban districts
    District(
      id: 'hn_badinh',
      name: 'Ba Đình',
      city: City.hanoi,
      type: VietnamDistrictType.urban,
      code: 'BD',
    ),
    District(
      id: 'hn_hoankiem',
      name: 'Hoàn Kiếm',
      city: City.hanoi,
      type: VietnamDistrictType.urban,
      code: 'HK',
    ),
    District(
      id: 'hn_tayho',
      name: 'Tây Hồ',
      city: City.hanoi,
      type: VietnamDistrictType.urban,
      code: 'TH',
    ),
    District(
      id: 'hn_longbien',
      name: 'Long Biên',
      city: City.hanoi,
      type: VietnamDistrictType.urban,
      code: 'LB',
    ),
    District(
      id: 'hn_caugiay',
      name: 'Cầu Giấy',
      city: City.hanoi,
      type: VietnamDistrictType.urban,
      code: 'CG',
    ),
    District(
      id: 'hn_dongda',
      name: 'Đống Đa',
      city: City.hanoi,
      type: VietnamDistrictType.urban,
      code: 'DD',
    ),
    District(
      id: 'hn_haibatrung',
      name: 'Hai Bà Trưng',
      city: City.hanoi,
      type: VietnamDistrictType.urban,
      code: 'HBT',
    ),
    District(
      id: 'hn_hoangmai',
      name: 'Hoàng Mai',
      city: City.hanoi,
      type: VietnamDistrictType.urban,
      code: 'HM',
    ),
    District(
      id: 'hn_thanhxuan',
      name: 'Thanh Xuân',
      city: City.hanoi,
      type: VietnamDistrictType.urban,
      code: 'TX',
    ),
    District(
      id: 'hn_namtuliem',
      name: 'Nam Từ Liêm',
      city: City.hanoi,
      type: VietnamDistrictType.urban,
      code: 'NTL',
    ),
    District(
      id: 'hn_bactuliem',
      name: 'Bắc Từ Liêm',
      city: City.hanoi,
      type: VietnamDistrictType.urban,
      code: 'BTL',
    ),
    District(
      id: 'hn_hadong',
      name: 'Hà Đông',
      city: City.hanoi,
      type: VietnamDistrictType.urban,
      code: 'HD',
    ),

    // Rural districts
    District(
      id: 'hn_socson',
      name: 'Sóc Sơn',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'SS',
    ),
    District(
      id: 'hn_donganh',
      name: 'Đông Anh',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'DA',
    ),
    District(
      id: 'hn_gialâm',
      name: 'Gia Lâm',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'GL',
    ),
    District(
      id: 'hn_thanhtri',
      name: 'Thanh Trì',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'TT',
    ),
    District(
      id: 'hn_melinh',
      name: 'Mê Linh',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'ML',
    ),
    District(
      id: 'hn_bavi',
      name: 'Ba Vì',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'BV',
    ),
    District(
      id: 'hn_phuctho',
      name: 'Phúc Thọ',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'PT',
    ),
    District(
      id: 'hn_danphuong',
      name: 'Đan Phượng',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'DP',
    ),
    District(
      id: 'hn_hoaiduc',
      name: 'Hoài Đức',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'HD',
    ),
    District(
      id: 'hn_quocoai',
      name: 'Quốc Oai',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'QO',
    ),
    District(
      id: 'hn_thachthat',
      name: 'Thạch Thất',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'TT',
    ),
    District(
      id: 'hn_chuongmy',
      name: 'Chương Mỹ',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'CM',
    ),
    District(
      id: 'hn_thanhoai',
      name: 'Thanh Oai',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'TO',
    ),
    District(
      id: 'hn_thuongtin',
      name: 'Thường Tín',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'TT',
    ),
    District(
      id: 'hn_phuxuyen',
      name: 'Phú Xuyên',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'PX',
    ),
    District(
      id: 'hn_unghoa',
      name: 'Ứng Hòa',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'UH',
    ),
    District(
      id: 'hn_myduc',
      name: 'Mỹ Đức',
      city: City.hanoi,
      type: VietnamDistrictType.rural,
      code: 'MD',
    ),

    // Township
    District(
      id: 'hn_sontay',
      name: 'Sơn Tây',
      city: City.hanoi,
      type: VietnamDistrictType.township,
      code: 'ST',
    ),
  ];
}

@JsonEnum()
enum AgeGroup {
  @JsonValue('student')
  student,
  @JsonValue('mature')
  mature,
  @JsonValue('middleAge')
  middleAge;

  String getLocalizedName(BuildContext context) {
    return context.tr('ageGroup.$name');
  }

  static List<String> getAllLocalizedName(BuildContext context) {
    return AgeGroup.values
        .map((each) => each.getLocalizedName(context))
        .toList();
  }
}

@JsonEnum()
enum Gender {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female;

  String getLocalizedName(BuildContext context) {
    return context.tr('gender.$name');
  }

  static List<String> getAllLocalizedName(BuildContext context) {
    return Gender.values.map((each) => each.getLocalizedName(context)).toList();
  }
}

@JsonEnum()
enum SoccerPosition {
  @JsonValue('outfield')
  outfield('soccer.position.outfield'),
  @JsonValue('keeper')
  keeper('soccer.position.keeper');

  final String intlKey;
  const SoccerPosition(this.intlKey);
  String getLocalizedName(BuildContext context) => context.tr(intlKey);
}

@JsonEnum()
enum SoccerPitch {
  @JsonValue('futsal')
  futsal('soccer.pitch.futsal'),
  @JsonValue('5v5')
  fiveASide('soccer.pitch.5v5'),
  @JsonValue('7v7')
  sevenASide('soccer.pitch.7v7');

  final String intlKey;
  const SoccerPitch(this.intlKey);
  String getLocalizedName(BuildContext context) => context.tr(intlKey);
}

@JsonEnum()
enum DominantHand {
  @JsonValue('left')
  left('racketSport.dominantHand.left'),
  @JsonValue('right')
  right('racketSport.dominantHand.right');

  final String intlKey;
  const DominantHand(this.intlKey);
  String getLocalizedName(BuildContext context) => context.tr(intlKey);
}

@JsonEnum()
enum RacketDiscipline {
  @JsonValue('singles')
  singles('racketSport.discipline.singles'),
  @JsonValue('doubles')
  doubles('racketSport.discipline.doubles');

  final String intlKey;
  const RacketDiscipline(this.intlKey);
  String getLocalizedName(BuildContext context) => context.tr(intlKey);
}

@JsonEnum()
enum BasketballPosition {
  @JsonValue('guard')
  guard('basketball.position.guard'),
  @JsonValue('forward')
  forward('basketball.position.forward'),
  @JsonValue('center')
  center('basketball.position.center');

  final String intlKey;
  const BasketballPosition(this.intlKey);
  String getLocalizedName(BuildContext context) => context.tr(intlKey);
}

@JsonEnum()
enum BasketballPitch {
  @JsonValue('indoor')
  indoor('basketball.pitch.indoor'),
  @JsonValue('outdoor')
  outdoor('basketball.pitch.outdoor');

  final String intlKey;
  const BasketballPitch(this.intlKey);
  String getLocalizedName(BuildContext context) => context.tr(intlKey);
}

@JsonEnum()
enum EloSeed {
  @JsonValue('beginner')
  beginner('eloSeed.beginner'),
  @JsonValue('casual')
  casual('eloSeed.casual'),
  @JsonValue('tryhard')
  tryhard('eloSeed.tryhard');

  final String intlKey;
  const EloSeed(this.intlKey);
  String getLocalizedName(BuildContext context) => context.tr(intlKey);
}

// Do not change order
@JsonEnum()
enum Industry {
  agriculture,
  construction,
  culinaryTourism,
  educationAcademia,
  energy,
  entertainmentContentCreation,
  fashionBeauty,
  financeConsulting,
  government,
  healthcare,
  legalServices,
  manufacturing,
  mediaCommunications,
  nonprofitCharity,
  realEstate,
  retailOnlineCommerce,
  technology,
  transportation;

  String getLocalizedName(BuildContext context, {bool withoutDiacritics = false}) {
    final localizedName = context.tr('industry.$name');
    if (withoutDiacritics) return removeDiacritics(localizedName);
    return localizedName;
  }

  static List<String> getAllLocalizedName(BuildContext context) {
    return Industry.values
        .map((each) => each.getLocalizedName(context))
        .toList();
  }
}
