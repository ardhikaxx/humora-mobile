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

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: rawName,
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'Laki-laki',
      memberSince: json['member_since']?.toString() ?? 'Member Humora',
      tier: userTier,
      activePlanName: json['active_plan_name']?.toString(),
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
