class SubscriptionPlanModel {
  final String id;
  final String name;
  final String durationText;
  final String description;
  final int originalPrice;
  final int price;
  final String? monthlyPriceText;
  final String? badgeText;
  final List<String> benefits;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.durationText,
    required this.description,
    required this.originalPrice,
    required this.price,
    this.monthlyPriceText,
    this.badgeText,
    required this.benefits,
  });
}
