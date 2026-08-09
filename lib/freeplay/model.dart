enum FreeplayRequestStatus {
  pending,
  accepted,
  declined,
  cancelled,
  hostCancelled,
  lapsed,
  blocked;

  factory FreeplayRequestStatus.fromDb(String value) => switch (value) {
    'host_cancelled' => hostCancelled,
    _ => FreeplayRequestStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => FreeplayRequestStatus.lapsed,
    ),
  };

  bool get isOpen => this == pending || this == accepted;
  bool get isHistory => !isOpen;
}

double _money(Object? value) => double.tryParse(value?.toString() ?? '') ?? 0;

class FreeplayActivity {
  final String id;
  final String hostId;
  final String hostName;
  final String? hostAvatarUrl;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String venueName;
  final String streetAddress;
  final int capacity;
  final int acceptedCount;
  final int pendingCount;
  final double malePrice;
  final double femalePrice;
  final List<String> recommendedSkills;
  final String? mySkill;
  final String? myRequestId;
  final FreeplayRequestStatus? myRequestStatus;
  final List<FreeplayRosterMember> roster;
  final bool intakeClosed;
  final bool cancelled;

  const FreeplayActivity({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.venueName,
    required this.streetAddress,
    required this.capacity,
    required this.acceptedCount,
    required this.malePrice,
    required this.femalePrice,
    required this.recommendedSkills,
    this.hostAvatarUrl,
    this.mySkill,
    this.myRequestId,
    this.myRequestStatus,
    this.roster = const [],
    this.pendingCount = 0,
    this.intakeClosed = false,
    this.cancelled = false,
  });

  int get seatsLeft => capacity - acceptedCount;
  bool get isFull => seatsLeft <= 0;
  bool get isOngoing =>
      DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);

  factory FreeplayActivity.fromJson(Map<String, dynamic> json) {
    final rosterJson = json['roster'];
    return FreeplayActivity(
      id: (json['activity_id'] ?? json['id']).toString(),
      hostId: (json['host_id'] ?? '').toString(),
      hostName: (json['host_name'] ?? '').toString(),
      hostAvatarUrl: json['host_avatar_url'] as String?,
      description: (json['description'] ?? '').toString(),
      startTime: DateTime.parse(json['start_time'].toString()).toLocal(),
      endTime: DateTime.parse(json['end_time'].toString()).toLocal(),
      venueName: (json['venue_name'] ?? '').toString(),
      streetAddress: (json['street_address'] ?? '').toString(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      acceptedCount: (json['accepted_count'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      malePrice: _money(json['male_price']),
      femalePrice: _money(json['female_price']),
      recommendedSkills: List<String>.from(
        json['recommended_skills'] as List? ?? const [],
      ),
      mySkill: json['my_skill'] as String?,
      myRequestId: json['my_request_id']?.toString(),
      myRequestStatus: json['my_request_status'] == null
          ? null
          : FreeplayRequestStatus.fromDb(json['my_request_status'].toString()),
      roster: rosterJson is List
          ? rosterJson
                .map(
                  (row) => FreeplayRosterMember.fromJson(
                    row as Map<String, dynamic>,
                  ),
                )
                .toList()
          : const [],
      intakeClosed: json['intake_closed'] as bool? ?? false,
      cancelled: json['cancelled'] as bool? ?? false,
    );
  }
}

class FreeplayRosterMember {
  final String id;
  final String username;
  final String? generatedAvatar;
  final String? skill;

  const FreeplayRosterMember({
    required this.id,
    required this.username,
    this.generatedAvatar,
    this.skill,
  });

  factory FreeplayRosterMember.fromJson(Map<String, dynamic> json) =>
      FreeplayRosterMember(
        id: json['id'].toString(),
        username: (json['username'] ?? '').toString(),
        generatedAvatar: json['generatedAvatar'] as String?,
        skill: json['skill'] as String?,
      );
}

class FreeplayHost {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String bio;
  final int completedCount;

  const FreeplayHost({
    required this.id,
    required this.displayName,
    required this.bio,
    this.avatarUrl,
    this.completedCount = 0,
  });

  factory FreeplayHost.fromJson(Map<String, dynamic> json) => FreeplayHost(
    id: json['id'].toString(),
    displayName: (json['display_name'] ?? '').toString(),
    avatarUrl: json['avatar_url'] as String?,
    bio: (json['bio'] ?? '').toString(),
    completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
  );
}

class FreeplayRequestItem {
  final String id;
  final String userId;
  final String username;
  final FreeplayRequestStatus status;
  final String gender;
  final String? skill;
  final double price;
  final DateTime createdAt;

  const FreeplayRequestItem({
    required this.id,
    required this.userId,
    required this.username,
    required this.status,
    required this.gender,
    required this.price,
    required this.createdAt,
    this.skill,
  });

  factory FreeplayRequestItem.fromJson(Map<String, dynamic> json) =>
      FreeplayRequestItem(
        id: json['request_id'].toString(),
        userId: json['user_id'].toString(),
        username: (json['username'] ?? '').toString(),
        status: FreeplayRequestStatus.fromDb(json['status'].toString()),
        gender: (json['gender'] ?? 'male').toString(),
        skill: json['skill'] as String?,
        price: _money(json['price_amount']),
        createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
      );
}

class FreeplayChatMessage {
  final String id;
  final String? senderId;
  final String kind;
  final String? body;
  final DateTime createdAt;
  final String? bankCode;
  final String? bankDisplayName;
  final String? accountNumber;
  final String? accountName;

  const FreeplayChatMessage({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.senderId,
    this.body,
    this.bankCode,
    this.bankDisplayName,
    this.accountNumber,
    this.accountName,
  });

  factory FreeplayChatMessage.fromJson(Map<String, dynamic> json) {
    final payment = json['payment_info'] as Map<String, dynamic>?;
    return FreeplayChatMessage(
      id: json['id'].toString(),
      senderId: json['sender_id']?.toString(),
      kind: json['kind'].toString(),
      body: json['body'] as String?,
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
      bankCode: payment?['bank_id'] as String?,
      bankDisplayName: payment?['bank_display_name'] as String?,
      accountNumber: payment?['value'] as String?,
      accountName: payment?['account_name'] as String?,
    );
  }
}
