/// Payment lifecycle status enum for Allz Bharat orders.
/// Decoupled from fulfillment [OrderStatus].
enum PaymentStatus {
  pending('pending', 'Pending'),
  paid('paid', 'Paid'),
  failed('failed', 'Failed'),
  cancelled('cancelled', 'Cancelled'),
  refunded('refunded', 'Refunded');

  final String value;
  final String displayName;

  const PaymentStatus(this.value, this.displayName);

  /// Safe deserialization with graceful fallback to [PaymentStatus.pending] on unknown/null values.
  static PaymentStatus fromString(String? raw) {
    if (raw == null) return PaymentStatus.pending;
    return PaymentStatus.values.firstWhere(
      (status) => status.value == raw || status.name == raw,
      orElse: () => PaymentStatus.pending,
    );
  }
}
