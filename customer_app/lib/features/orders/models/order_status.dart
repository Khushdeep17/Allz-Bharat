/// Order lifecycle status enum for Allz Bharat orders.
enum OrderStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  preparing('preparing', 'Preparing'),
  readyForPickup('ready_for_pickup', 'Ready for Pickup'),
  outForDelivery('out_for_delivery', 'Out for Delivery'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled'),
  rejected('rejected', 'Rejected');

  final String value;
  final String displayName;

  const OrderStatus(this.value, this.displayName);

  static OrderStatus fromString(String? raw) {
    if (raw == null) return OrderStatus.pending;
    return OrderStatus.values.firstWhere(
      (status) => status.value == raw || status.name == raw,
      orElse: () => OrderStatus.pending,
    );
  }
}
