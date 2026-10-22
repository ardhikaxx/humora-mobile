class SubscriptionPlanModel {
  final String id;
  final String code;
  final String planType; // 'weekly', 'addon', 'full'
  final String name;
  final int durationDays;
  final String durationText;
  final int? videoQuota;
  final String formattedQuota;
  final String description;
  final int originalPrice;
  final int price;
  final String formattedPrice;
  final String? formattedOriginalPrice;
  final String? monthlyPriceText;
  final String? badgeText;
  final List<String> benefits;
  final bool isAddon;
  final bool requiresWeekly;
  final bool canPurchase;
  final bool isActive;

  const SubscriptionPlanModel({
    required this.id,
    this.code = '',
    this.planType = 'weekly',
    required this.name,
    this.durationDays = 7,
    required this.durationText,
    this.videoQuota,
    this.formattedQuota = '',
    required this.description,
    required this.originalPrice,
    required this.price,
    this.formattedPrice = '',
    this.formattedOriginalPrice,
    this.monthlyPriceText,
    this.badgeText,
    required this.benefits,
    this.isAddon = false,
    this.requiresWeekly = false,
    this.canPurchase = true,
    this.isActive = true,
  });

  bool get isWeekly => planType == 'weekly';
  bool get isFullAccess => planType == 'full';

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = (json['price'] != null ? (double.tryParse(json['price'].toString()) ?? 0.0) : 0.0).toInt();
    final rawOriginalPrice = (json['original_price'] != null ? (double.tryParse(json['original_price'].toString()) ?? 0.0) : 0.0).toInt();
    final durationDays = json['duration_days'] != null
        ? int.tryParse(json['duration_days'].toString()) ?? 7
        : 7;

    final planType = json['plan_type']?.toString() ?? (json['is_addon'] == true ? 'addon' : 'weekly');
    final videoQuota = json['video_quota'] != null ? int.tryParse(json['video_quota'].toString()) : null;
    final isAddon = json['is_addon'] == true || planType == 'addon';
    final requiresWeekly = json['requires_weekly'] == true || isAddon;
    final canPurchase = json['can_purchase'] != false;

    List<String> benefitList = [];
    if (json['benefits'] is List) {
      benefitList = (json['benefits'] as List).map((b) => b.toString()).toList();
    } else {
      benefitList = [
        'Akses video serial sketsa komedi',
        'Streaming kualitas HD tanpa buffering',
        'Bebas nonton ulang selama masa aktif',
      ];
    }

    String durationStr = '$durationDays Hari';
    if (isAddon) {
      durationStr = 'Mengikuti paket mingguan';
    } else if (durationDays == 7) {
      durationStr = '7 Hari';
    } else if (durationDays >= 30) {
      durationStr = '30 Hari (1 Bulan)';
    }

    String quotaStr = json['formatted_quota']?.toString() ?? '';
    if (quotaStr.isEmpty) {
      if (videoQuota != null) {
        quotaStr = '$videoQuota Video';
      } else if (planType == 'full') {
        quotaStr = 'Seluruh Katalog (~68 Video)';
      }
    }

    return SubscriptionPlanModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      planType: planType,
      name: json['name']?.toString() ?? 'Paket VIP',
      durationDays: durationDays,
      durationText: durationStr,
      videoQuota: videoQuota,
      formattedQuota: quotaStr,
      description: json['description']?.toString() ?? 'Akses sketsa komedi Humora',
      originalPrice: rawOriginalPrice,
      price: rawPrice,
      formattedPrice: json['formatted_price']?.toString() ?? 'Rp ${rawPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
      formattedOriginalPrice: json['formatted_original_price']?.toString(),
      monthlyPriceText: json['monthly_price_text']?.toString(),
      badgeText: json['badge_text']?.toString(),
      benefits: benefitList,
      isAddon: isAddon,
      requiresWeekly: requiresWeekly,
      canPurchase: canPurchase,
      isActive: json['is_active'] == true || json['is_active'] == null,
    );
  }
}
