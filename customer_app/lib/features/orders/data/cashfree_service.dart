import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wrapper service managing Cashfree Payment Gateway SDK initialization and callbacks.
class CashfreePaymentService {
  final CFPaymentGatewayService _gatewayService;
  final CFEnvironment environment;

  CashfreePaymentService({
    CFPaymentGatewayService? gatewayService,
    this.environment = CFEnvironment.SANDBOX,
  }) : _gatewayService = gatewayService ?? CFPaymentGatewayService();

  /// Sets up payment result callbacks before triggering payment.
  void setCallbacks({
    required Function(String orderId) onVerify,
    required Function(dynamic errorResponse, String orderId) onError,
  }) {
    _gatewayService.setCallback(onVerify, onError);
  }

  /// Builds a [CFSession] and triggers the Cashfree web/in-app checkout.
  void startPayment({
    required String paymentOrderId,
    required String paymentSessionId,
  }) {
    final session = CFSessionBuilder()
        .setEnvironment(environment)
        .setOrderId(paymentOrderId)
        .setPaymentSessionId(paymentSessionId)
        .build();

    final checkout = CFWebCheckoutPaymentBuilder().setSession(session).build();
    _gatewayService.doPayment(checkout);
  }
}

/// Global provider for the Cashfree payment service.
final cashfreePaymentServiceProvider = Provider<CashfreePaymentService>((ref) {
  return CashfreePaymentService();
});

