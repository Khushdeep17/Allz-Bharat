import 'package:customer_app/features/addresses/models/address.dart';
import 'package:customer_app/features/cart/models/cart_item.dart';
import 'package:customer_app/features/orders/data/payment_repository.dart';
import 'package:customer_app/features/orders/models/order_pricing.dart';
import 'package:customer_app/features/orders/models/payment_session_result.dart';
import 'package:customer_app/features/orders/models/payment_status.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePaymentRepository implements PaymentRepository {
  PaymentSessionResult? mockSessionResult;
  PaymentVerificationResult? mockVerificationResult;

  @override
  Future<PaymentSessionResult> createPaymentSession({
    required String shopId,
    required List<CartItem> items,
    required Address deliveryAddress,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    if (mockSessionResult != null) return mockSessionResult!;
    return PaymentSessionResult(
      success: true,
      orderId: 'mock_order_123',
      paymentOrderId: 'order_mock_123_456',
      paymentSessionId: 'session_mock_789',
      amount: 270.0,
      currency: 'INR',
      pricing: const OrderPricing(
        subtotal: 250.0,
        deliveryFee: 15.0,
        platformFee: 5.0,
        total: 270.0,
      ),
      message: 'Session created successfully',
    );
  }

  @override
  Future<PaymentVerificationResult> verifyPayment({
    required String orderId,
    String? paymentOrderId,
  }) async {
    if (mockVerificationResult != null) return mockVerificationResult!;
    return PaymentVerificationResult(
      success: true,
      orderId: orderId,
      paymentStatus: PaymentStatus.paid,
      paymentId: 'cf_pay_999',
      paymentMethod: 'upi',
      paidAt: DateTime(2026, 9, 18, 18, 0, 0),
      message: 'Payment verified',
    );
  }
}

void main() {
  group('Payment Models & Repository Contract Tests', () {
    test('PaymentSessionResult serializes and deserializes cleanly', () {
      final sessionResult = PaymentSessionResult(
        success: true,
        orderId: 'ord_test_001',
        paymentOrderId: 'cf_order_test_001',
        paymentSessionId: 'session_token_xyz',
        amount: 320.0,
        currency: 'INR',
        pricing: const OrderPricing(
          subtotal: 300.0,
          deliveryFee: 15.0,
          platformFee: 5.0,
          total: 320.0,
        ),
        message: 'Ready for SDK',
      );

      final map = sessionResult.toMap();
      expect(map['success'], isTrue);
      expect(map['orderId'], 'ord_test_001');
      expect(map['paymentOrderId'], 'cf_order_test_001');
      expect(map['paymentSessionId'], 'session_token_xyz');
      expect(map['amount'], 320.0);
      expect(map['currency'], 'INR');
      expect((map['pricing'] as Map)['total'], 320.0);
      expect(map['message'], 'Ready for SDK');

      final deserialized = PaymentSessionResult.fromMap(map);
      expect(deserialized.success, isTrue);
      expect(deserialized.orderId, 'ord_test_001');
      expect(deserialized.paymentOrderId, 'cf_order_test_001');
      expect(deserialized.paymentSessionId, 'session_token_xyz');
      expect(deserialized.amount, 320.0);
      expect(deserialized.currency, 'INR');
      expect(deserialized.pricing.total, 320.0);
      expect(deserialized.message, 'Ready for SDK');
    });

    test('PaymentVerificationResult deserializes success and failure states', () {
      final paidMap = {
        'success': true,
        'orderId': 'ord_100',
        'paymentStatus': 'paid',
        'paymentId': 'pay_ref_777',
        'paymentMethod': 'upi',
        'paidAt': '2026-09-18T18:00:00.000Z',
        'message': 'Payment captured',
      };

      final paidResult = PaymentVerificationResult.fromMap(paidMap);
      expect(paidResult.success, isTrue);
      expect(paidResult.orderId, 'ord_100');
      expect(paidResult.paymentStatus, PaymentStatus.paid);
      expect(paidResult.paymentId, 'pay_ref_777');
      expect(paidResult.paymentMethod, 'upi');
      expect(paidResult.paidAt, isNotNull);
      expect(paidResult.message, 'Payment captured');

      final pendingMap = {
        'success': false,
        'orderId': 'ord_100',
        'paymentStatus': 'pending',
      };

      final pendingResult = PaymentVerificationResult.fromMap(pendingMap);
      expect(pendingResult.success, isFalse);
      expect(pendingResult.paymentStatus, PaymentStatus.pending);
      expect(pendingResult.paymentId, isNull);
    });

    test('FakePaymentRepository meets abstract contract requirements', () async {
      final repo = FakePaymentRepository();

      final session = await repo.createPaymentSession(
        shopId: 'shop_1',
        items: [
          const CartItem(
            productId: 'p1',
            shopId: 'shop_1',
            name: 'Milk',
            price: 30.0,
            quantity: 2,
          ),
        ],
        deliveryAddress: const Address(
          addressId: 'addr_1',
          label: 'Home',
          fullAddress: 'Main Street',
          phoneNumber: '9876543210',
          isDefault: true,
        ),
      );

      expect(session.success, isTrue);
      expect(session.orderId, 'mock_order_123');
      expect(session.paymentOrderId, 'order_mock_123_456');
      expect(session.paymentSessionId, isNotNull);

      final verify = await repo.verifyPayment(orderId: session.orderId);
      expect(verify.success, isTrue);
      expect(verify.paymentStatus, PaymentStatus.paid);
    });
  });
}
