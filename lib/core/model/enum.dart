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

/// Post-2025-reform Vietnamese commune-level unit type. Vietnam abolished
/// the district tier (quận/huyện/thị xã/thành phố) nationwide on
/// 2025-07-01, flattening administration to province → ward/commune.
enum WardType {
  ward('phuong', 'Phường'),
  commune('xa', 'Xã');

  final String code;
  final String prefix;

  const WardType(this.code, this.prefix);
}

/// A ward (phường) or commune (xã) — the commune-level administrative unit
/// that replaced the old quận/huyện/thị xã "district" tier in the 2025
/// reform. Kept named `District` (not `Ward`) to match the DB column
/// (`location.district`) and the `district.*` translation namespace.
class District {
  final String id;
  final String name;
  final City city;
  final WardType type;

  /// The pre-2025 quận/huyện/thị xã this unit was carved from. The district
  /// tier no longer exists administratively, but Vietnamese users still
  /// orient by the old name day-to-day — this is a display/grouping label
  /// only, not a functional key (nothing joins on it).
  final String legacyDistrict;

  String getLocalizedFullName(BuildContext context) =>
      '${context.tr('district.${type.name}')} $name';

  String getLocalizedFullNameWithCity(BuildContext context) =>
      '${city.getLocalizedName(context)} - ${context.tr('district.${type.name}')} $name';

  const District({
    required this.id,
    required this.name,
    required this.city,
    required this.type,
    required this.legacyDistrict,
  });

  /// Case/diacritic-insensitive match against this ward's name or its legacy
  /// district — lets users search by either the new ward name or the old
  /// area name they still know. Empty query always matches.
  bool matches(String query) {
    final q = removeDiacritics(query).toLowerCase().trim();
    if (q.isEmpty) return true;
    return removeDiacritics(name).toLowerCase().contains(q) ||
        removeDiacritics(legacyDistrict).toLowerCase().contains(q);
  }

  @override
  String toString() => '${type.prefix} $name';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is District && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Class to manage location data in Vietnam.
///
/// **Scope**: the 2025 reform also merged Ho Chi Minh City with Bình Dương
/// and Bà Rịa–Vũng Tàu provinces (168 new units total). This data is
/// deliberately scoped to the *old* HCMC/Hanoi footprints only — the 102
/// (HCMC) + 126 (Hanoi) wards/communes within the boundaries Passe already
/// serves — not the annexed provinces. Expanding city coverage to match the
/// new provincial boundary is a separate product decision.
///
/// **Stale saved preferences**: old-style ids (`hcm_q1`, `hn_dongda`, …)
/// saved before this conversion no longer resolve via [findDistrictById].
/// Every call site already treats a miss as "unknown"/falls back to showing
/// the raw id rather than crashing (see `FilterState.build()`'s
/// `whereType<District>()` and `location_selection_screen.dart`'s
/// `format` callback) — this is accepted, not handled with a migration.
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

  /// Find a district by ID
  District? findDistrictById(String id) {
    for (var districts in getAllDistricts().values) {
      for (var district in districts) {
        if (district.id == id) return district;
      }
    }
    return null;
  }

  /// Search a city's districts by ward name or legacy district name
  /// (diacritic/case-insensitive substring match). Empty query returns all.
  List<District> searchDistricts(City city, String query) =>
      getDistrictsByCity(city).where((d) => d.matches(query)).toList();

  static District _w(String id, String name, String legacy, City city) =>
      District(
        id: id,
        name: name,
        city: city,
        type: WardType.ward,
        legacyDistrict: legacy,
      );

  static District _x(String id, String name, String legacy, City city) =>
      District(
        id: id,
        name: name,
        city: city,
        type: WardType.commune,
        legacyDistrict: legacy,
      );

  /// Ho Chi Minh City's 102 new wards/communes (78 phường + 24 xã), replacing
  /// its old 273 ward/commune units grouped under 22 legacy quận/huyện +
  /// Thủ Đức. Verified against the official 2025-07-01 reorganization
  /// figures (Nghị quyết 25/NQ-HĐND); source cross-checked via VnExpress'
  /// "Phương án sắp xếp và tên 102 phường, xã mới tại TP HCM".
  static final List<District> _hcmcDistricts = () {
    const c = City.hochiminh;
    return [
      // Quận 1
      _w('hcm_tandinh', 'Tân Định', 'Quận 1', c),
      _w('hcm_benthanh', 'Bến Thành', 'Quận 1', c),
      _w('hcm_saigon', 'Sài Gòn', 'Quận 1', c),
      _w('hcm_cauonglanh', 'Cầu Ông Lãnh', 'Quận 1', c),
      // Quận 3
      _w('hcm_banco', 'Bàn Cờ', 'Quận 3', c),
      _w('hcm_xuanhoa', 'Xuân Hòa', 'Quận 3', c),
      _w('hcm_nhieuloc', 'Nhiêu Lộc', 'Quận 3', c),
      // Quận 4
      _w('hcm_vinhhoi', 'Vĩnh Hội', 'Quận 4', c),
      _w('hcm_khanhhoi', 'Khánh Hội', 'Quận 4', c),
      _w('hcm_xomchieu', 'Xóm Chiếu', 'Quận 4', c),
      // Quận 5
      _w('hcm_choquan', 'Chợ Quán', 'Quận 5', c),
      _w('hcm_andong', 'An Đông', 'Quận 5', c),
      _w('hcm_cholon', 'Chợ Lớn', 'Quận 5', c),
      // Quận 6
      _w('hcm_binhtien', 'Bình Tiên', 'Quận 6', c),
      _w('hcm_binhtay', 'Bình Tây', 'Quận 6', c),
      _w('hcm_binhphu', 'Bình Phú', 'Quận 6', c),
      _w('hcm_phulam', 'Phú Lâm', 'Quận 6', c),
      // Quận 7
      _w('hcm_tanmy', 'Tân Mỹ', 'Quận 7', c),
      _w('hcm_tanhung', 'Tân Hưng', 'Quận 7', c),
      _w('hcm_tanthuan', 'Tân Thuận', 'Quận 7', c),
      _w('hcm_phuthuan', 'Phú Thuận', 'Quận 7', c),
      // Quận 8
      _w('hcm_chanhhung', 'Chánh Hưng', 'Quận 8', c),
      _w('hcm_binhdong', 'Bình Đông', 'Quận 8', c),
      _w('hcm_phudinh', 'Phú Định', 'Quận 8', c),
      // Quận 10
      _w('hcm_vuonlai', 'Vườn Lài', 'Quận 10', c),
      _w('hcm_dienhong', 'Diên Hồng', 'Quận 10', c),
      _w('hcm_hoahung', 'Hòa Hưng', 'Quận 10', c),
      // Quận 11
      _w('hcm_hoabinh', 'Hòa Bình', 'Quận 11', c),
      _w('hcm_phutho', 'Phú Thọ', 'Quận 11', c),
      _w('hcm_binhthoi', 'Bình Thới', 'Quận 11', c),
      _w('hcm_minhphung', 'Minh Phụng', 'Quận 11', c),
      // Quận 12
      _w('hcm_donghungthuan', 'Đông Hưng Thuận', 'Quận 12', c),
      _w('hcm_trungmytay', 'Trung Mỹ Tây', 'Quận 12', c),
      _w('hcm_tanthoihiep', 'Tân Thới Hiệp', 'Quận 12', c),
      _w('hcm_thoian', 'Thới An', 'Quận 12', c),
      _w('hcm_anphudong', 'An Phú Đông', 'Quận 12', c),
      // Quận Bình Thạnh
      _w('hcm_giadinh', 'Gia Định', 'Quận Bình Thạnh', c),
      _w('hcm_binhthanh', 'Bình Thạnh', 'Quận Bình Thạnh', c),
      _w('hcm_binhloitrung', 'Bình Lợi Trung', 'Quận Bình Thạnh', c),
      _w('hcm_thanhmytay', 'Thạnh Mỹ Tây', 'Quận Bình Thạnh', c),
      _w('hcm_binhquoi', 'Bình Quới', 'Quận Bình Thạnh', c),
      // Quận Bình Tân
      _w('hcm_binhtan', 'Bình Tân', 'Quận Bình Tân', c),
      _w('hcm_binhhunghoa', 'Bình Hưng Hòa', 'Quận Bình Tân', c),
      _w('hcm_binhtridong', 'Bình Trị Đông', 'Quận Bình Tân', c),
      _w('hcm_anlac', 'An Lạc', 'Quận Bình Tân', c),
      _w('hcm_tantao', 'Tân Tạo', 'Quận Bình Tân', c),
      // Quận Gò Vấp
      _w('hcm_hanhthong', 'Hạnh Thông', 'Quận Gò Vấp', c),
      _w('hcm_annhon', 'An Nhơn', 'Quận Gò Vấp', c),
      _w('hcm_govap', 'Gò Vấp', 'Quận Gò Vấp', c),
      _w('hcm_thongtayhoi', 'Thông Tây Hội', 'Quận Gò Vấp', c),
      _w('hcm_anhoitay', 'An Hội Tây', 'Quận Gò Vấp', c),
      _w('hcm_anhoidong', 'An Hội Đông', 'Quận Gò Vấp', c),
      // Quận Phú Nhuận
      _w('hcm_ducnhuan', 'Đức Nhuận', 'Quận Phú Nhuận', c),
      _w('hcm_caukieu', 'Cầu Kiệu', 'Quận Phú Nhuận', c),
      _w('hcm_phunhuan', 'Phú Nhuận', 'Quận Phú Nhuận', c),
      // Quận Tân Bình
      _w('hcm_tansonhoa', 'Tân Sơn Hòa', 'Quận Tân Bình', c),
      _w('hcm_tansonnhat', 'Tân Sơn Nhất', 'Quận Tân Bình', c),
      _w('hcm_tanhoa', 'Tân Hòa', 'Quận Tân Bình', c),
      _w('hcm_bayhien', 'Bảy Hiền', 'Quận Tân Bình', c),
      _w('hcm_tanbinh', 'Tân Bình', 'Quận Tân Bình', c),
      _w('hcm_tanson', 'Tân Sơn', 'Quận Tân Bình', c),
      // Quận Tân Phú
      _w('hcm_taythanh', 'Tây Thạnh', 'Quận Tân Phú', c),
      _w('hcm_tansonnhi', 'Tân Sơn Nhì', 'Quận Tân Phú', c),
      _w('hcm_phuthohoa', 'Phú Thọ Hòa', 'Quận Tân Phú', c),
      _w('hcm_phuthanh', 'Phú Thạnh', 'Quận Tân Phú', c),
      _w('hcm_tanphu', 'Tân Phú', 'Quận Tân Phú', c),
      // Thành phố Thủ Đức
      _w('hcm_hiepbinh', 'Hiệp Bình', 'Thành phố Thủ Đức', c),
      _w('hcm_tambinh', 'Tam Bình', 'Thành phố Thủ Đức', c),
      _w('hcm_thuduc', 'Thủ Đức', 'Thành phố Thủ Đức', c),
      _w('hcm_linhxuan', 'Linh Xuân', 'Thành phố Thủ Đức', c),
      _w('hcm_longbinh', 'Long Bình', 'Thành phố Thủ Đức', c),
      _w('hcm_tangnhonphu', 'Tăng Nhơn Phú', 'Thành phố Thủ Đức', c),
      _w('hcm_phuoclong', 'Phước Long', 'Thành phố Thủ Đức', c),
      _w('hcm_longphuoc', 'Long Phước', 'Thành phố Thủ Đức', c),
      _w('hcm_longtruong', 'Long Trường', 'Thành phố Thủ Đức', c),
      _w('hcm_ankhanh', 'An Khánh', 'Thành phố Thủ Đức', c),
      _w('hcm_binhtrung', 'Bình Trưng', 'Thành phố Thủ Đức', c),
      _w('hcm_catlai', 'Cát Lái', 'Thành phố Thủ Đức', c),
      // Huyện Bình Chánh
      _x('hcm_vinhloc', 'Vĩnh Lộc', 'Huyện Bình Chánh', c),
      _x('hcm_tanvinhloc', 'Tân Vĩnh Lộc', 'Huyện Bình Chánh', c),
      _x('hcm_binhloi', 'Bình Lợi', 'Huyện Bình Chánh', c),
      _x('hcm_tannhut', 'Tân Nhựt', 'Huyện Bình Chánh', c),
      _x('hcm_binhchanh', 'Bình Chánh', 'Huyện Bình Chánh', c),
      _x('hcm_hunglong', 'Hưng Long', 'Huyện Bình Chánh', c),
      _x('hcm_binhhung', 'Bình Hưng', 'Huyện Bình Chánh', c),
      // Huyện Củ Chi
      _x('hcm_annhontay', 'An Nhơn Tây', 'Huyện Củ Chi', c),
      _x('hcm_thaimy', 'Thái Mỹ', 'Huyện Củ Chi', c),
      _x('hcm_nhuanduc', 'Nhuận Đức', 'Huyện Củ Chi', c),
      _x('hcm_tananhoi', 'Tân An Hội', 'Huyện Củ Chi', c),
      _x('hcm_cuchi', 'Củ Chi', 'Huyện Củ Chi', c),
      _x('hcm_phuhoadong', 'Phú Hòa Đông', 'Huyện Củ Chi', c),
      _x('hcm_binhmy', 'Bình Mỹ', 'Huyện Củ Chi', c),
      // Huyện Cần Giờ
      _x('hcm_binhkhanh', 'Bình Khánh', 'Huyện Cần Giờ', c),
      _x('hcm_cangio', 'Cần Giờ', 'Huyện Cần Giờ', c),
      _x('hcm_anthoidong', 'An Thới Đông', 'Huyện Cần Giờ', c),
      _x('hcm_thanhan', 'Thạnh An', 'Huyện Cần Giờ', c),
      // Huyện Hóc Môn
      _x('hcm_hocmon', 'Hóc Môn', 'Huyện Hóc Môn', c),
      _x('hcm_badiem', 'Bà Điểm', 'Huyện Hóc Môn', c),
      _x('hcm_xuanthoison', 'Xuân Thới Sơn', 'Huyện Hóc Môn', c),
      _x('hcm_dongthanh', 'Đông Thạnh', 'Huyện Hóc Môn', c),
      // Huyện Nhà Bè
      _x('hcm_nhabe', 'Nhà Bè', 'Huyện Nhà Bè', c),
      _x('hcm_hiepphuoc', 'Hiệp Phước', 'Huyện Nhà Bè', c),
    ];
  }();

  /// Hanoi's 126 new wards/communes (51 phường + 75 xã), replacing its old
  /// ~579 ward/commune units grouped under 30 legacy quận/huyện/thị xã.
  /// Source cross-checked between VnExpress' and the government portal's
  /// (xaydungchinhsach.chinhphu.vn) coverage of the 2025-07-01
  /// reorganization; the `legacyDistrict` groupings below were reconciled
  /// against known commune names where the two sources disagreed, and the
  /// resulting ward/commune split (51/75) matches the official count
  /// exactly. Central-district boundaries are the part most likely to have
  /// a small inaccuracy if this needs re-verifying later.
  static final List<District> _hanoiDistricts = () {
    const c = City.hanoi;
    return [
      // Quận Hoàn Kiếm
      _w('hn_hoankiem', 'Hoàn Kiếm', 'Quận Hoàn Kiếm', c),
      _w('hn_cuanam', 'Cửa Nam', 'Quận Hoàn Kiếm', c),
      // Quận Ba Đình
      _w('hn_badinh', 'Ba Đình', 'Quận Ba Đình', c),
      _w('hn_ngocha', 'Ngọc Hà', 'Quận Ba Đình', c),
      _w('hn_giangvo', 'Giảng Võ', 'Quận Ba Đình', c),
      // Quận Hai Bà Trưng
      _w('hn_haibatrung', 'Hai Bà Trưng', 'Quận Hai Bà Trưng', c),
      _w('hn_vinhtuy', 'Vĩnh Tuy', 'Quận Hai Bà Trưng', c),
      _w('hn_bachmai', 'Bạch Mai', 'Quận Hai Bà Trưng', c),
      // Quận Đống Đa
      _w('hn_dongda', 'Đống Đa', 'Quận Đống Đa', c),
      _w('hn_kimlien', 'Kim Liên', 'Quận Đống Đa', c),
      _w('hn_vanmieu', 'Văn Miếu - Quốc Tử Giám', 'Quận Đống Đa', c),
      _w('hn_lang', 'Láng', 'Quận Đống Đa', c),
      _w('hn_ochodua', 'Ô Chợ Dừa', 'Quận Đống Đa', c),
      // Quận Hoàng Mai
      _w('hn_hongha', 'Hồng Hà', 'Quận Hoàng Mai', c),
      _w('hn_linhnam', 'Lĩnh Nam', 'Quận Hoàng Mai', c),
      _w('hn_hoangmai', 'Hoàng Mai', 'Quận Hoàng Mai', c),
      _w('hn_vinhhung', 'Vĩnh Hưng', 'Quận Hoàng Mai', c),
      _w('hn_tuongmai', 'Tương Mai', 'Quận Hoàng Mai', c),
      _w('hn_dinhcong', 'Định Công', 'Quận Hoàng Mai', c),
      _w('hn_hoangliet', 'Hoàng Liệt', 'Quận Hoàng Mai', c),
      _w('hn_yenso', 'Yên Sở', 'Quận Hoàng Mai', c),
      // Quận Thanh Xuân
      _w('hn_thanhxuan', 'Thanh Xuân', 'Quận Thanh Xuân', c),
      _w('hn_khuongdinh', 'Khương Đình', 'Quận Thanh Xuân', c),
      _w('hn_phuongliet', 'Phương Liệt', 'Quận Thanh Xuân', c),
      // Quận Cầu Giấy
      _w('hn_caugiay', 'Cầu Giấy', 'Quận Cầu Giấy', c),
      _w('hn_nghiado', 'Nghĩa Đô', 'Quận Cầu Giấy', c),
      _w('hn_yenhoa', 'Yên Hòa', 'Quận Cầu Giấy', c),
      // Quận Tây Hồ
      _w('hn_tayho', 'Tây Hồ', 'Quận Tây Hồ', c),
      _w('hn_phuthuong', 'Phú Thượng', 'Quận Tây Hồ', c),
      // Quận Bắc Từ Liêm
      _w('hn_taytuu', 'Tây Tựu', 'Quận Bắc Từ Liêm', c),
      _w('hn_phudien', 'Phú Diễn', 'Quận Bắc Từ Liêm', c),
      _w('hn_xuandinh', 'Xuân Đỉnh', 'Quận Bắc Từ Liêm', c),
      _w('hn_dongngac', 'Đông Ngạc', 'Quận Bắc Từ Liêm', c),
      _w('hn_thuongcat', 'Thượng Cát', 'Quận Bắc Từ Liêm', c),
      _w('hn_tuliem', 'Từ Liêm', 'Quận Bắc Từ Liêm', c),
      // Quận Nam Từ Liêm
      _w('hn_xuanphuong', 'Xuân Phương', 'Quận Nam Từ Liêm', c),
      _w('hn_taymo', 'Tây Mỗ', 'Quận Nam Từ Liêm', c),
      _w('hn_daimo', 'Đại Mỗ', 'Quận Nam Từ Liêm', c),
      // Quận Long Biên
      _w('hn_longbien', 'Long Biên', 'Quận Long Biên', c),
      _w('hn_bode', 'Bồ Đề', 'Quận Long Biên', c),
      _w('hn_viethung', 'Việt Hưng', 'Quận Long Biên', c),
      _w('hn_phucloi', 'Phúc Lợi', 'Quận Long Biên', c),
      // Quận Hà Đông
      _w('hn_hadong', 'Hà Đông', 'Quận Hà Đông', c),
      _w('hn_duongnoi', 'Dương Nội', 'Quận Hà Đông', c),
      _w('hn_yennghia', 'Yên Nghĩa', 'Quận Hà Đông', c),
      _w('hn_phuluong', 'Phú Lương', 'Quận Hà Đông', c),
      _w('hn_kienhung', 'Kiến Hưng', 'Quận Hà Đông', c),
      // Huyện Thanh Trì
      _x('hn_thanhtri', 'Thanh Trì', 'Huyện Thanh Trì', c),
      _x('hn_daithanh', 'Đại Thanh', 'Huyện Thanh Trì', c),
      _x('hn_namphu', 'Nam Phù', 'Huyện Thanh Trì', c),
      _x('hn_ngochoi', 'Ngọc Hồi', 'Huyện Thanh Trì', c),
      _w('hn_thanhliet', 'Thanh Liệt', 'Huyện Thanh Trì', c),
      // Huyện Thường Tín
      _x('hn_thuongphuc', 'Thượng Phúc', 'Huyện Thường Tín', c),
      _x('hn_thuongtin', 'Thường Tín', 'Huyện Thường Tín', c),
      _x('hn_chuongduong', 'Chương Dương', 'Huyện Thường Tín', c),
      _x('hn_hongvan', 'Hồng Vân', 'Huyện Thường Tín', c),
      // Huyện Phú Xuyên
      _x('hn_phuxuyen', 'Phú Xuyên', 'Huyện Phú Xuyên', c),
      _x('hn_phuongduc', 'Phượng Dực', 'Huyện Phú Xuyên', c),
      _x('hn_chuyenmy', 'Chuyên Mỹ', 'Huyện Phú Xuyên', c),
      _x('hn_daixuyen', 'Đại Xuyên', 'Huyện Phú Xuyên', c),
      // Huyện Thanh Oai
      _x('hn_thanhoai', 'Thanh Oai', 'Huyện Thanh Oai', c),
      _x('hn_binhminh', 'Bình Minh', 'Huyện Thanh Oai', c),
      _x('hn_tamhung', 'Tam Hưng', 'Huyện Thanh Oai', c),
      _x('hn_danhoa', 'Dân Hòa', 'Huyện Thanh Oai', c),
      // Huyện Ứng Hòa
      _x('hn_vandinh', 'Vân Đình', 'Huyện Ứng Hòa', c),
      _x('hn_ungthien', 'Ứng Thiên', 'Huyện Ứng Hòa', c),
      _x('hn_hoaxa', 'Hòa Xá', 'Huyện Ứng Hòa', c),
      _x('hn_unghoa', 'Ứng Hòa', 'Huyện Ứng Hòa', c),
      // Huyện Mỹ Đức
      _x('hn_myduc', 'Mỹ Đức', 'Huyện Mỹ Đức', c),
      _x('hn_hongson', 'Hồng Sơn', 'Huyện Mỹ Đức', c),
      _x('hn_phucson', 'Phúc Sơn', 'Huyện Mỹ Đức', c),
      _x('hn_huongson', 'Hương Sơn', 'Huyện Mỹ Đức', c),
      // Huyện Chương Mỹ
      _w('hn_chuongmy', 'Chương Mỹ', 'Huyện Chương Mỹ', c),
      _x('hn_phunghia', 'Phú Nghĩa', 'Huyện Chương Mỹ', c),
      _x('hn_xuanmai', 'Xuân Mai', 'Huyện Chương Mỹ', c),
      _x('hn_tranphu', 'Trần Phú', 'Huyện Chương Mỹ', c),
      _x('hn_hoaphu', 'Hòa Phú', 'Huyện Chương Mỹ', c),
      _x('hn_quangbi', 'Quảng Bị', 'Huyện Chương Mỹ', c),
      _x('hn_minhchau', 'Minh Châu', 'Huyện Chương Mỹ', c),
      // Huyện Ba Vì
      _x('hn_quangoai', 'Quảng Oai', 'Huyện Ba Vì', c),
      _x('hn_vatlai', 'Vật Lại', 'Huyện Ba Vì', c),
      _x('hn_code', 'Cổ Đô', 'Huyện Ba Vì', c),
      _x('hn_batbat', 'Bất Bạt', 'Huyện Ba Vì', c),
      _x('hn_suoihai', 'Suối Hai', 'Huyện Ba Vì', c),
      _x('hn_bavi', 'Ba Vì', 'Huyện Ba Vì', c),
      _x('hn_yenbai', 'Yên Bài', 'Huyện Ba Vì', c),
      // Thị xã Sơn Tây
      _w('hn_sontay', 'Sơn Tây', 'Thị xã Sơn Tây', c),
      _w('hn_tungthien', 'Tùng Thiện', 'Thị xã Sơn Tây', c),
      // Huyện Phúc Thọ
      _x('hn_doaiphuong', 'Đoài Phương', 'Huyện Phúc Thọ', c),
      _x('hn_phuctho', 'Phúc Thọ', 'Huyện Phúc Thọ', c),
      _x('hn_phucloc', 'Phúc Lộc', 'Huyện Phúc Thọ', c),
      _x('hn_hatmon', 'Hát Môn', 'Huyện Phúc Thọ', c),
      // Huyện Thạch Thất
      _x('hn_thachthat', 'Thạch Thất', 'Huyện Thạch Thất', c),
      _x('hn_habang', 'Hạ Bằng', 'Huyện Thạch Thất', c),
      _x('hn_tayphuong', 'Tây Phương', 'Huyện Thạch Thất', c),
      _x('hn_hoalac', 'Hòa Lạc', 'Huyện Thạch Thất', c),
      _x('hn_yenxuan', 'Yên Xuân', 'Huyện Thạch Thất', c),
      // Huyện Quốc Oai
      _x('hn_quocoai', 'Quốc Oai', 'Huyện Quốc Oai', c),
      _x('hn_hungdao', 'Hưng Đạo', 'Huyện Quốc Oai', c),
      _x('hn_kieuphu', 'Kiều Phú', 'Huyện Quốc Oai', c),
      // Huyện Hoài Đức
      _x('hn_phucat', 'Phú Cát', 'Huyện Hoài Đức', c),
      _x('hn_hoaiduc', 'Hoài Đức', 'Huyện Hoài Đức', c),
      _x('hn_duonghoa', 'Dương Hòa', 'Huyện Hoài Đức', c),
      _x('hn_songdong', 'Sơn Đồng', 'Huyện Hoài Đức', c),
      _x('hn_ankhanh', 'An Khánh', 'Huyện Hoài Đức', c),
      // Huyện Đan Phượng
      _x('hn_danphuong', 'Đan Phượng', 'Huyện Đan Phượng', c),
      _x('hn_odien', 'Ô Diên', 'Huyện Đan Phượng', c),
      _x('hn_lienminh', 'Liên Minh', 'Huyện Đan Phượng', c),
      // Huyện Gia Lâm
      _x('hn_gialam', 'Gia Lâm', 'Huyện Gia Lâm', c),
      _x('hn_thuanan', 'Thuận An', 'Huyện Gia Lâm', c),
      _x('hn_battrang', 'Bát Tràng', 'Huyện Gia Lâm', c),
      _x('hn_phudong', 'Phù Đổng', 'Huyện Gia Lâm', c),
      // Huyện Đông Anh
      _x('hn_donganh', 'Đông Anh', 'Huyện Đông Anh', c),
      _x('hn_thulam', 'Thư Lâm', 'Huyện Đông Anh', c),
      _x('hn_phucthinh', 'Phúc Thịnh', 'Huyện Đông Anh', c),
      _x('hn_thienloc', 'Thiên Lộc', 'Huyện Đông Anh', c),
      _x('hn_vinhthanh', 'Vĩnh Thanh', 'Huyện Đông Anh', c),
      // Huyện Mê Linh
      _x('hn_melinh', 'Mê Linh', 'Huyện Mê Linh', c),
      _x('hn_yenlang', 'Yên Lãng', 'Huyện Mê Linh', c),
      _x('hn_tienthang', 'Tiến Thắng', 'Huyện Mê Linh', c),
      _x('hn_quangminh', 'Quang Minh', 'Huyện Mê Linh', c),
      // Huyện Sóc Sơn
      _x('hn_socson', 'Sóc Sơn', 'Huyện Sóc Sơn', c),
      _x('hn_daphuc', 'Đa Phúc', 'Huyện Sóc Sơn', c),
      _x('hn_noibai', 'Nội Bài', 'Huyện Sóc Sơn', c),
      _x('hn_trunggia', 'Trung Giã', 'Huyện Sóc Sơn', c),
      _x('hn_kimanh', 'Kim Anh', 'Huyện Sóc Sơn', c),
    ];
  }();
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
  @JsonValue('forward')
  forward('soccer.position.forward'),
  @JsonValue('midfielder')
  midfielder('soccer.position.midfielder'),
  @JsonValue('defender')
  defender('soccer.position.defender'),
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

  String getLocalizedName(
    BuildContext context, {
    bool withoutDiacritics = false,
  }) {
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

@JsonEnum()
enum ProfessionalRole {
  @JsonValue('coach')
  coach,
  @JsonValue('referee')
  referee;

  String getLocalizedName(BuildContext context) =>
      context.tr('homeTab.professional.role.$name');
}

/// Mirrors the `professional_booking_status` Postgres enum by value.
/// Manually parsed (not JsonSerializable), same convention as [Attendance].
enum ProfessionalBookingStatus {
  requested('requested'),
  confirmed('confirmed'),
  rejected('rejected'),
  cancelledByClient('cancelled_by_client'),
  cancelledByPro('cancelled_by_pro'),
  completed('completed');

  final String value;

  const ProfessionalBookingStatus(this.value);

  static ProfessionalBookingStatus? fromValue(String? value) {
    if (value == null) return null;
    for (final s in ProfessionalBookingStatus.values) {
      if (s.value == value) return s;
    }
    return null;
  }
}

/// A member's RSVP to an activity. Mirrors the `activity_attendance` Postgres
/// enum stored in `activity_confirmation.attendance`. Only [going] counts
/// toward the confirmation threshold.
enum Attendance {
  going('going'),
  maybe('maybe'),
  out('out');

  final String value;

  const Attendance(this.value);

  static Attendance? fromValue(String? value) {
    if (value == null) return null;
    for (final a in Attendance.values) {
      if (a.value == value) return a;
    }
    return null;
  }
}

/// How a candidate challenger lobby stacks up against the context (away) lobby,
/// derived server-side from the away-biased MMR gap. JsonValue strings match the
/// `favorability` text returned by `home_challenger_lobby_data`.
@JsonEnum()
enum ChallengeFavorability {
  @JsonValue('underdog')
  underdog('homeTab.challenger.favorability.underdog'),
  @JsonValue('even')
  even('homeTab.challenger.favorability.even'),
  @JsonValue('favored')
  favored('homeTab.challenger.favorability.favored');

  final String intlKey;
  const ChallengeFavorability(this.intlKey);

  String getLocalizedName(BuildContext context) => context.tr(intlKey);

  static ChallengeFavorability? fromValue(String? value) {
    if (value == null) return null;
    for (final f in ChallengeFavorability.values) {
      if (f.name == value) return f;
    }
    return null;
  }
}
