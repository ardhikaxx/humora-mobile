enum UserTier {
  guest,   // Tamu: Belum login
  free,    // User Gratis: Login, belum berlangganan
  premium, // Premium Aktif: Langganan aktif (3 bulan / dsb)
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
  });

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
    );
  }

  bool get isGuest => tier == UserTier.guest;
  bool get isFree => tier == UserTier.free;
  bool get isPremium => tier == UserTier.premium;
  bool get isExpired => tier == UserTier.expired;
}
