import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { PaymentService } from "../services/payment.service";
import { OrderPromotionService } from "../services/promotion.service";

/**
 * HTTPS Webhook handler for Cashfree Payment Gateway callbacks.
 *
 * Security & Design Rules:
 * 1. Validates `x-webhook-signature` using HMAC-SHA256 and `x-webhook-timestamp`.
 * 2. Rejects requests with missing or expired timestamps (replay attack protection).
 * 3. Never trusts unverified payloads or client-supplied amounts.
 * 4. Calls shared `OrderPromotionService` for atomic, idempotent promotion to `orders/{orderId}`.
 * 5. Does not log secrets, authorization headers, or sensitive customer PII.
 */
export const cashfreeWebhook = onRequest(
  {
    cors: false,
    secrets: ["CASHFREE_SECRET_KEY", "CASHFREE_APP_ID", "CASHFREE_ENV"],
  },
  async (req, res) => {
    // 1. Only allow POST method
    if (req.method !== "POST") {
      res.status(405).json({ status: "ERROR", message: "Method Not Allowed" });
      return;
    }

    // 2. Extract Cashfree signature headers
    const signature = (req.headers["x-webhook-signature"] ||
      req.headers["x-webhook-signature".toLowerCase()]) as string | undefined;
    const timestamp = (req.headers["x-webhook-timestamp"] ||
      req.headers["x-webhook-timestamp".toLowerCase()]) as string | undefined;

    if (!signature || !timestamp) {
      console.warn("Cashfree webhook rejected: Missing signature or timestamp headers.");
      res.status(400).json({
        status: "ERROR",
        message: "Missing required webhook signature headers.",
      });
      return;
    }

    // 3. Acquire raw body for signature verification
    // Firebase Functions v2 provides req.rawBody as Buffer
    const rawBody: string | Buffer =
      (req as any).rawBody ||
      (typeof req.body === "string" ? req.body : JSON.stringify(req.body));

    const paymentService = new PaymentService();
    const isValidSignature = paymentService.verifyWebhookSignature(
      rawBody,
      signature,
      timestamp
    );

    if (!isValidSignature) {
      console.warn("Cashfree webhook rejected: Invalid signature.");
      res.status(401).json({
        status: "ERROR",
        message: "Invalid webhook signature.",
      });
      return;
    }

    // 4. Parse JSON payload
    let payload: Record<string, any>;
    try {
      if (typeof req.body === "object" && req.body !== null) {
        payload = req.body;
      } else {
        payload = JSON.parse(rawBody.toString());
      }
    } catch {
      console.error("Cashfree webhook rejected: Malformed JSON payload.");
      res.status(400).json({
        status: "ERROR",
        message: "Malformed webhook payload.",
      });
      return;
    }

    const eventType = payload.type || "";
    const eventData = payload.data || {};
    const orderObj = eventData.order || {};
    const paymentObj = eventData.payment || {};

    const gatewayOrderId: string =
      orderObj.order_id || paymentObj.order_id || "";

    if (!gatewayOrderId) {
      console.error("Cashfree webhook missing order_id in event data.");
      res.status(400).json({
        status: "ERROR",
        message: "Missing order reference in webhook payload.",
      });
      return;
    }

    const db = admin.firestore();

    try {
      // 5. Resolve matching payment intent document
      let intentId = gatewayOrderId;
      let intentDoc = await db.collection("payment_intents").doc(intentId).get();

      if (!intentDoc.exists) {
        // Query by paymentOrderId if doc ID does not match directly
        const querySnap = await db
          .collection("payment_intents")
          .where("paymentOrderId", "==", gatewayOrderId)
          .limit(1)
          .get();

        if (!querySnap.empty) {
          intentDoc = querySnap.docs[0];
          intentId = intentDoc.id;
        } else {
          console.warn(`Payment intent not found for gateway order: ${gatewayOrderId}`);
          res.status(404).json({
            status: "ERROR",
            message: "Payment intent not found.",
          });
          return;
        }
      }

      // 6. Handle event types
      if (
        eventType === "PAYMENT_SUCCESS_WEBHOOK" ||
        paymentObj.payment_status === "SUCCESS"
      ) {
        const paymentAmount =
          typeof paymentObj.payment_amount === "number"
            ? paymentObj.payment_amount
            : parseFloat(paymentObj.payment_amount || orderObj.order_amount);
        const paymentCurrency =
          paymentObj.payment_currency || orderObj.order_currency || "INR";
        const cfPaymentId = paymentObj.cf_payment_id
          ? String(paymentObj.cf_payment_id)
          : undefined;

        let paymentMethod: string | undefined;
        if (typeof paymentObj.payment_group === "string") {
          paymentMethod = paymentObj.payment_group;
        } else if (paymentObj.payment_method) {
          if (typeof paymentObj.payment_method === "string") {
            paymentMethod = paymentObj.payment_method;
          } else if (typeof paymentObj.payment_method === "object") {
            paymentMethod = Object.keys(paymentObj.payment_method)[0];
          }
        }

        const paidAt = paymentObj.payment_time
          ? new Date(paymentObj.payment_time)
          : new Date();

        // 7. Atomic promotion to final order
        const result = await OrderPromotionService.promoteIntentToOrder(
          db,
          intentId,
          {
            paymentId: cfPaymentId,
            paymentMethod,
            paidAt,
            verifiedAmount: paymentAmount,
            verifiedCurrency: paymentCurrency,
          }
        );

        res.status(200).json({
          status: "OK",
          message: result.alreadyPromoted
            ? "Order already processed."
            : "Payment verified and order created successfully.",
          orderId: result.orderId,
        });
        return;
      } else if (
        eventType === "PAYMENT_FAILED_WEBHOOK" ||
        paymentObj.payment_status === "FAILED"
      ) {
        // Mark intent as failed if currently pending
        const currentStatus = intentDoc.data()?.paymentStatus;
        if (currentStatus === "pending") {
          await db.collection("payment_intents").doc(intentId).update({
            paymentStatus: "failed",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        res.status(200).json({
          status: "OK",
          message: "Payment failure recorded.",
        });
        return;
      } else if (
        eventType === "PAYMENT_USER_DROPPED_WEBHOOK" ||
        paymentObj.payment_status === "USER_DROPPED"
      ) {
        const currentStatus = intentDoc.data()?.paymentStatus;
        if (currentStatus === "pending") {
          await db.collection("payment_intents").doc(intentId).update({
            paymentStatus: "cancelled",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        res.status(200).json({
          status: "OK",
          message: "Payment cancellation recorded.",
        });
        return;
      }

      // Other informational events
      res.status(200).json({
        status: "OK",
        message: "Event received.",
      });
    } catch (error) {
      console.error(
        "Error processing Cashfree webhook:",
        (error as Error)?.message || error
      );
      res.status(500).json({
        status: "ERROR",
        message: "Internal error processing payment webhook.",
      });
    }
  }
);
