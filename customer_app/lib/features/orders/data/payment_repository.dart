import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../addresses/models/address.dart';
import '../../cart/models/cart_item.dart';
import '../models/payment_session_result.dart';
import 'payment_repository_impl.dart';

/// Abstract contract for communicating with payment backend functions.
abstract class PaymentRepository {
  /// Initiates a payment session by calling the trusted backend Cloud Function.
  /// Returns the payment session identifier and server-verified pricing.
  Future<PaymentSessionResult> createPaymentSession({
    required String shopId,
    required List<CartItem> items,
    required Address deliveryAddress,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  });

  /// Requests the trusted backend to verify a payment attempt with Cashfree.
  Future<PaymentVerificationResult> verifyPayment({
    required String orderId,
    String? paymentOrderId,
  });
}

/// Global provider for the PaymentRepository instance.
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return FirebasePaymentRepository();
});
