import 'package:cloud_functions/cloud_functions.dart';

import '../../addresses/models/address.dart';
import '../../cart/models/cart_item.dart';
import '../models/payment_session_result.dart';
import 'payment_repository.dart';

/// Concrete implementation of [PaymentRepository] utilizing Firebase Cloud Functions callable APIs.
class FirebasePaymentRepository implements PaymentRepository {
  final FirebaseFunctions _functions;

  FirebasePaymentRepository([FirebaseFunctions? functions])
      : _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<PaymentSessionResult> createPaymentSession({
    required String shopId,
    required List<CartItem> items,
    required Address deliveryAddress,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    final callable = _functions.httpsCallable('createPaymentOrder');

    final payload = <String, dynamic>{
      'shopId': shopId,
      'items': items
          .map((item) => {
                'productId': item.productId,
                'quantity': item.quantity,
              })
          .toList(),
      'deliveryAddress': {
        'addressId': deliveryAddress.addressId,
        'label': deliveryAddress.label,
        'fullAddress': deliveryAddress.fullAddress,
        'phoneNumber': deliveryAddress.phoneNumber,
      },
    };

    if (customerName != null || customerPhone != null || customerEmail != null) {
      final details = <String, String>{};
      if (customerName != null) details['name'] = customerName;
      if (customerPhone != null) details['phone'] = customerPhone;
      if (customerEmail != null) details['email'] = customerEmail;
      payload['customerDetails'] = details;
    }

    final result = await callable.call<Map<dynamic, dynamic>>(payload);
    final data = Map<String, dynamic>.from(result.data);

    return PaymentSessionResult.fromMap(data);
  }

  @override
  Future<PaymentVerificationResult> verifyPayment({
    required String orderId,
    String? paymentOrderId,
  }) async {
    final callable = _functions.httpsCallable('verifyPayment');

    final payload = <String, dynamic>{
      'orderId': orderId,
    };
    if (paymentOrderId != null) {
      payload['paymentOrderId'] = paymentOrderId;
    }

    final result = await callable.call<Map<dynamic, dynamic>>(payload);
    final data = Map<String, dynamic>.from(result.data);

    return PaymentVerificationResult.fromMap(data);
  }
}
