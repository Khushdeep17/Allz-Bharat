import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { VerifyPaymentRequest, VerifyPaymentResponse } from "../types/payment.types";
import { PaymentService } from "../services/payment.service";
import { OrderPromotionService } from "../services/promotion.service";

/**
 * Callable Firebase Cloud Function to verify a payment status.
 *
 * Security & Design Rules:
 * 1. Requires valid Firebase Authentication context.
 * 2. Confirms that the caller is the owner of the order/payment intent.
 * 3. Inquires with PaymentService (Cashfree PG) for genuine gateway status.
 * 4. NEVER returns 'paid' without verifiable gateway confirmation.
 * 5. Uses shared `OrderPromotionService` to atomically and idempotently promote intent to `orders/{orderId}`.
 * 6. Never trusts client-supplied payment methods, amounts, or status flags.
 */
export const verifyPayment = onCall<VerifyPaymentRequest, Promise<VerifyPaymentResponse>>(
  {
    cors: true,
    secrets: ["CASHFREE_SECRET_KEY", "CASHFREE_APP_ID", "CASHFREE_ENV"],
  },
  async (request) => {
    // 1. Authentication check
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to verify a payment."
      );
    }

    const customerId = request.auth.uid;
    const data = request.data;

    if (!data || !data.orderId || typeof data.orderId !== "string" || data.orderId.trim() === "") {
      throw new HttpsError("invalid-argument", "Valid order ID is required.");
    }

    const { orderId, paymentOrderId } = data;
    const db = admin.firestore();

    try {
      // 2. Check existence of payment intent or existing order
      const intentDoc = await db.collection("payment_intents").doc(orderId).get();
      const orderDoc = await db.collection("orders").doc(orderId).get();

      if (!intentDoc.exists && !orderDoc.exists) {
        throw new HttpsError("not-found", "Order or payment intent not found.");
      }

      const intentData = intentDoc.exists ? intentDoc.data() : null;
      const orderData = orderDoc.exists ? orderDoc.data() : null;

      const recordCustomerId = intentData?.customerId || orderData?.customerId;
      if (recordCustomerId !== customerId) {
        throw new HttpsError(
          "permission-denied",
          "You are not authorized to verify this payment."
        );
      }

      // If final order already exists in orders collection, return it idempotently
      if (orderDoc.exists && orderData) {
        return {
          success: orderData.paymentStatus === "paid",
          orderId,
          paymentStatus: (orderData.paymentStatus as any) || "paid",
          paymentId: orderData.paymentId,
          paymentMethod: orderData.paymentMethod,
          paidAt: orderData.paidAt
            ? (orderData.paidAt instanceof admin.firestore.Timestamp
                ? orderData.paidAt.toDate().toISOString()
                : new Date(orderData.paidAt).toISOString())
            : undefined,
          message: "Order already verified and created.",
        };
      }

      const activePaymentOrderId =
        paymentOrderId || intentData?.paymentOrderId || orderId;

      // 3. Query gateway verification through PaymentService abstraction
      const paymentService = new PaymentService();
      const verificationResult = await paymentService.verifyGatewayPayment(activePaymentOrderId);

      // 4. If gateway confirms payment is SUCCESS / paid, promote intent to final order
      if (verificationResult.paymentStatus === "paid" && intentData) {
        const promotionResult = await OrderPromotionService.promoteIntentToOrder(
          db,
          orderId,
          {
            paymentId: verificationResult.paymentId,
            paymentMethod: verificationResult.paymentMethod,
            paidAt: verificationResult.paidAt,
          }
        );

        return {
          success: true,
          orderId: promotionResult.orderId,
          paymentStatus: "paid",
          paymentId: verificationResult.paymentId,
          paymentMethod: verificationResult.paymentMethod,
          paidAt: verificationResult.paidAt?.toISOString(),
          message: "Payment verified successfully.",
        };
      }

      // If gateway reports failed, record in intent if still pending
      if (verificationResult.paymentStatus === "failed" && intentData?.paymentStatus === "pending") {
        await db.collection("payment_intents").doc(orderId).update({
          paymentStatus: "failed",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return {
        success: false,
        orderId,
        paymentStatus: verificationResult.paymentStatus,
        paymentId: verificationResult.paymentId,
        paymentMethod: verificationResult.paymentMethod,
        paidAt: verificationResult.paidAt?.toISOString(),
        message:
          verificationResult.paymentStatus === "failed"
            ? "Payment was not successful."
            : "Payment is pending gateway completion.",
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }

      const errMessage = (error as Error)?.message || "";
      if (errMessage.includes("credentials are not configured")) {
        console.error("Payment Gateway verification configuration error: credentials missing.");
        throw new HttpsError(
          "failed-precondition",
          "Payment gateway verification is currently unavailable. Please try again later."
        );
      }

      console.error("Error verifying payment:", errMessage);
      throw new HttpsError(
        "internal",
        "Failed to verify payment. Please try again."
      );
    }
  }
);
