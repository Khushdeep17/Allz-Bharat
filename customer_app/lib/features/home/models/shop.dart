class Shop {
  final String id;
  final String name;
  final double rating;
  final String distance;
  final String deliveryTime;
  final bool isOpen;
  final String tag;
  final String badgeText;
  final String locality;

  const Shop({
    required this.id,
    required this.name,
    required this.rating,
    required this.distance,
    required this.deliveryTime,
    this.isOpen = true,
    required this.tag,
    required this.badgeText,
    required this.locality,
  });
}
