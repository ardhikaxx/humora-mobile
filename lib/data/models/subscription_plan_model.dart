class SubscriptionPlanModel {
  final String id;
  final String code;
  final String name;
  final int durationDays;
  final String durationText;
  final String description;
  final int originalPrice;
  final int price;
  final String formattedPrice;
  final String? formattedOriginalPrice;
  final String? monthlyPriceText;
  final String? badgeText;
  final List<String> benefits;
  final bool isActive;

  const SubscriptionPlanModel({
    required this.id,
    this.code = '',
    required this.name,
    this.durationDays = 30,
    required this.durationText,
    required this.description,
    required this.originalPrice,
    required this.price,
    this.formattedPrice = '',
    this.formattedOriginalPrice,
    this.monthlyPriceText,
    this.badgeText,
    required this.benefits,
    this.isActive = true,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = (json['price'] != null ? (double.tryParse(json['price'].toString()) ?? 0.0) : 0.0).toInt();
    final rawOriginalPrice = (json['original_price'] != null ? (double.tryParse(json['original_price'].toString()) ?? 0.0) : 0.0).toInt();
    final durationDays = json['duration_days'] != null
        ? int.tryParse(json['duration_days'].toString()) ?? 30
        : 30;

    List<String> benefitList = [];
    if (json['benefits'] is List) {
      benefitList = (json['benefits'] as List).map((b) => b.toString()).toList();
    } else {
      benefitList = [
        'Akses semua episode VIP tanpa batas',
        'Tanpa iklan yang mengganggu',
        'Kualitas streaming HD jernih',
      ];
    }

    String durationStr = '$durationDays Hari';
    if (durationDays >= 360) {
      durationStr = '1 Tahun ($durationDays Hari)';
    } else if (durationDays >= 90) {
      durationStr = '3 Bulan ($durationDays Hari)';
    } else if (durationDays >= 30) {
      durationStr = '1 Bulan ($durationDays Hari)';
    }

    return SubscriptionPlanModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Paket VIP',
      durationDays: durationDays,
      durationText: durationStr,
      description: json['description']?.toString() ?? 'Akses penuh sketsa komedi Humora',
      originalPrice: rawOriginalPrice,
      price: rawPrice,
      formattedPrice: json['formatted_price']?.toString() ?? 'Rp ${rawPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
      formattedOriginalPrice: json['formatted_original_price']?.toString(),
      monthlyPriceText: json['monthly_price_text']?.toString(),
      badgeText: json['badge_text']?.toString(),
      benefits: benefitList,
      isActive: json['is_active'] == true,
    );
  }
}
