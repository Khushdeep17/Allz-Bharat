import 'order_pricing.dart';
import 'payment_status.dart';

/// Represents the session information returned by the backend to launch the payment SDK.
class PaymentSessionResult {
  final bool success;
  final String orderId;
  final String paymentOrderId;
  final String? paymentSessionId;
  final double amount;
  final String currency;
  final OrderPricing pricing;
  final String? message;

  const PaymentSessionResult({
    required this.success,
    required this.orderId,
    required this.paymentOrderId,
    this.paymentSessionId,
    required this.amount,
    this.currency = 'INR',
    required this.pricing,
    this.message,
  });

  factory PaymentSessionResult.fromMap(Map<String, dynamic> map) {
    final pricingMap = map['pricing'] is Map
        ? Map<String, dynamic>.from(map['pricing'] as Map)
        : <String, dynamic>{};

    return PaymentSessionResult(
      success: (map['success'] as bool?) ?? true,
      orderId: (map['orderId'] ?? '') as String,
      paymentOrderId: (map['paymentOrderId'] ?? '') as String,
      paymentSessionId: map['paymentSessionId'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: (map['currency'] ?? 'INR') as String,
      pricing: OrderPricing.fromMap(pricingMap),
      message: map['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'orderId': orderId,
      'paymentOrderId': paymentOrderId,
      if (paymentSessionId != null) 'paymentSessionId': paymentSessionId,
      'amount': amount,
      'currency': currency,
      'pricing': pricing.toMap(),
      if (message != null) 'message': message,
    };
  }
}

/// Represents the result of backend payment verification.
class PaymentVerificationResult {
  final bool success;
  final String orderId;
  final PaymentStatus paymentStatus;
  final String? paymentId;
  final String? paymentMethod;
  final DateTime? paidAt;
  final String? message;

  const PaymentVerificationResult({
    required this.success,
    required this.orderId,
    required this.paymentStatus,
    this.paymentId,
    this.paymentMethod,
    this.paidAt,
    this.message,
  });

  factory PaymentVerificationResult.fromMap(Map<String, dynamic> map) {
    DateTime? parsedPaidAt;
    final rawPaidAt = map['paidAt'];
    if (rawPaidAt is String) {
      parsedPaidAt = DateTime.tryParse(rawPaidAt);
    }

    return PaymentVerificationResult(
      success: (map['success'] as bool?) ?? false,
      orderId: (map['orderId'] ?? '') as String,
      paymentStatus: PaymentStatus.fromString(map['paymentStatus'] as String?),
      paymentId: map['paymentId'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      paidAt: parsedPaidAt,
      message: map['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'orderId': orderId,
      'paymentStatus': paymentStatus.value,
      if (paymentId != null) 'paymentId': paymentId,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
      if (message != null) 'message': message,
    };
  }
}
