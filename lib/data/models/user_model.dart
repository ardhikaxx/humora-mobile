enum UserTier {
  guest,   // Tamu: Belum login
  free,    // User Gratis: Login, belum berlangganan
  premium, // Premium Aktif: Langganan aktif
  expired, // Expired: Masa langganan kedaluwarsa
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String gender;
  final String memberSince;
  final UserTier tier;
  final String? activePlanName;
  final String? planType; // 'weekly', 'addon', 'full'
  final bool hasFullAccess;
  final bool hasWeeklyActive;
  final bool canPurchaseAddon;
  final List<int> accessibleEpisodeIds;
  final int accessibleEpisodesCount;
  final String? validUntil;
  final int? remainingDays;
  final String? initials;
  final String status;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.memberSince,
    required this.tier,
    this.activePlanName,
    this.planType,
    this.hasFullAccess = false,
    this.hasWeeklyActive = false,
    this.canPurchaseAddon = false,
    this.accessibleEpisodeIds = const [],
    this.accessibleEpisodesCount = 0,
    this.validUntil,
    this.remainingDays,
    this.initials,
    this.status = 'active',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Map effective_tier from backend
    final effectiveTierStr = (json['effective_tier'] ?? json['tier'] ?? 'free').toString().toLowerCase();
    UserTier userTier;
    switch (effectiveTierStr) {
      case 'premium':
        userTier = UserTier.premium;
        break;
      case 'expired':
        userTier = UserTier.expired;
        break;
      case 'guest':
        userTier = UserTier.guest;
        break;
      case 'free':
      default:
        userTier = UserTier.free;
        break;
    }

    final rawName = json['name']?.toString() ?? 'Pengguna Humora';
    final computedInitials = json['initials']?.toString() ?? _computeInitials(rawName);

    List<int> epIds = [];
    if (json['accessible_episode_ids'] is List) {
      epIds = (json['accessible_episode_ids'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((id) => id > 0)
          .toList();
    }

    final bool hasFull = json['has_full_access'] == true;
    final bool hasWeekly = json['has_weekly_active'] == true;
    final bool canAddon = json['can_purchase_addon'] == true || hasWeekly;

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: rawName,
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'Laki-laki',
      memberSince: json['member_since']?.toString() ?? 'Member Humora',
      tier: userTier,
      activePlanName: json['active_plan_name']?.toString(),
      planType: json['plan_type']?.toString(),
      hasFullAccess: hasFull,
      hasWeeklyActive: hasWeekly,
      canPurchaseAddon: canAddon,
      accessibleEpisodeIds: epIds,
      accessibleEpisodesCount: json['accessible_episodes_count'] != null
          ? int.tryParse(json['accessible_episodes_count'].toString()) ?? epIds.length
          : epIds.length,
      validUntil: json['valid_until']?.toString(),
      remainingDays: json['remaining_days'] != null
          ? int.tryParse(json['remaining_days'].toString()) ?? 0
          : 0,
      initials: computedInitials,
      status: json['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'member_since': memberSince,
      'tier': tier.name,
      'active_plan_name': activePlanName,
      'plan_type': planType,
      'has_full_access': hasFullAccess,
      'has_weekly_active': hasWeeklyActive,
      'can_purchase_addon': canPurchaseAddon,
      'accessible_episode_ids': accessibleEpisodeIds,
      'accessible_episodes_count': accessibleEpisodesCount,
      'valid_until': validUntil,
      'remaining_days': remainingDays,
      'initials': initials,
      'status': status,
    };
  }

  static String _computeInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'HU';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  String get displayInitials => (initials != null && initials!.isNotEmpty)
      ? initials!
      : _computeInitials(name);

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? gender,
    String? memberSince,
    UserTier? tier,
    String? activePlanName,
    String? planType,
    bool? hasFullAccess,
    bool? hasWeeklyActive,
    bool? canPurchaseAddon,
    List<int>? accessibleEpisodeIds,
    int? accessibleEpisodesCount,
    String? validUntil,
    int? remainingDays,
    String? initials,
    String? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      memberSince: memberSince ?? this.memberSince,
      tier: tier ?? this.tier,
      activePlanName: activePlanName ?? this.activePlanName,
      planType: planType ?? this.planType,
      hasFullAccess: hasFullAccess ?? this.hasFullAccess,
      hasWeeklyActive: hasWeeklyActive ?? this.hasWeeklyActive,
      canPurchaseAddon: canPurchaseAddon ?? this.canPurchaseAddon,
      accessibleEpisodeIds: accessibleEpisodeIds ?? this.accessibleEpisodeIds,
      accessibleEpisodesCount: accessibleEpisodesCount ?? this.accessibleEpisodesCount,
      validUntil: validUntil ?? this.validUntil,
      remainingDays: remainingDays ?? this.remainingDays,
      initials: initials ?? this.initials,
      status: status ?? this.status,
    );
  }

  bool get isGuest => tier == UserTier.guest;
  bool get isFree => tier == UserTier.free;
  bool get isPremium => tier == UserTier.premium;
  bool get isExpired => tier == UserTier.expired;
}
