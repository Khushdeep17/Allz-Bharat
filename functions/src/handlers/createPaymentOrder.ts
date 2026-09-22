import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { CreatePaymentOrderRequest, CreatePaymentOrderResponse } from "../types/payment.types";
import { PricingService } from "../services/pricing.service";
import { PaymentService } from "../services/payment.service";

/**
 * Callable Firebase Cloud Function to initialize a secure payment session.
 *
 * Security & Design Rules:
 * 1. Requires valid Firebase Authentication context (caller must be signed in).
 * 2. Recalculates product prices directly from Firestore to prevent client-side price tampering.
 * 3. Communicates with PaymentService (Cashfree PG) using server-side credentials.
 * 4. Prepares a payment intent in Firestore ONLY IF Cashfree session creation succeeds.
 * 5. If credentials or gateway calls fail, throws a safe HttpsError; NO mock session and NO payable intent is created.
 */
export const createPaymentOrder = onCall<CreatePaymentOrderRequest, Promise<CreatePaymentOrderResponse>>(
  {
    cors: true,
    secrets: ["CASHFREE_SECRET_KEY", "CASHFREE_APP_ID", "CASHFREE_ENV"],
  },
  async (request) => {
    // 1. Authentication check
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to create a payment order."
      );
    }

    const customerId = request.auth.uid;
    const data = request.data;

    // 2. Input validation
    if (!data) {
      throw new HttpsError("invalid-argument", "Missing request payload.");
    }

    const { shopId, items, deliveryAddress, customerDetails } = data;

    if (!shopId || typeof shopId !== "string" || shopId.trim() === "") {
      throw new HttpsError("invalid-argument", "Valid shop ID is required.");
    }

    if (!items || !Array.isArray(items) || items.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "Order must contain at least one item."
      );
    }

    if (!deliveryAddress || !deliveryAddress.fullAddress || !deliveryAddress.phoneNumber) {
      throw new HttpsError(
        "invalid-argument",
        "Complete delivery address with phone number is required."
      );
    }

    const db = admin.firestore();

    try {
      // 3. Verify shop existence
      const shopDoc = await db.collection("shops").doc(shopId).get();
      if (!shopDoc.exists) {
        throw new HttpsError("not-found", `Shop ${shopId} does not exist.`);
      }
      const shopName = (shopDoc.data()?.name as string) || "Kirana Store";

      // 4. Server-side price recalculation from trusted Firestore product data
      const itemSnapshots = await PricingService.resolveItemSnapshots(
        db,
        shopId,
        items
      );
      const pricing = PricingService.calculatePricing(itemSnapshots);

      // 5. Generate unique internal order reference ID
      const orderRef = db.collection("orders").doc();
      const orderId = orderRef.id;
      const paymentOrderId = `order_${orderId.substring(0, 12)}_${Date.now()}`;

      // 6. Request gateway session via PaymentService abstraction
      const paymentService = new PaymentService();
      const gatewayResult = await paymentService.createGatewaySession({
        orderId: paymentOrderId,
        orderAmount: pricing.total,
        orderCurrency: "INR",
        customerDetails: {
          customerId: customerId,
          customerPhone: deliveryAddress.phoneNumber,
          customerName: customerDetails?.name || "Customer",
          customerEmail: customerDetails?.email || "customer@allzbharat.com",
        },
      });

      // 7. Store draft payment intent in Firestore ONLY after gateway session is successfully acquired
      await db.collection("payment_intents").doc(orderId).set({
        id: orderId,
        customerId,
        shopId,
        shopName,
        items: itemSnapshots,
        delivery: deliveryAddress,
        pricing,
        paymentOrderId: gatewayResult.paymentOrderId,
        paymentSessionId: gatewayResult.paymentSessionId,
        paymentStatus: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        orderId,
        paymentOrderId: gatewayResult.paymentOrderId,
        paymentSessionId: gatewayResult.paymentSessionId,
        amount: pricing.total,
        currency: "INR",
        pricing,
        message: "Payment session initialized successfully.",
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      
      const errMessage = (error as Error)?.message || "";
      if (errMessage.includes("credentials are not configured")) {
        console.error("Payment Gateway configuration error: credentials missing on server.");
        throw new HttpsError(
          "failed-precondition",
          "Payment gateway is currently unavailable. Please try again later."
        );
      }

      console.error("Error creating payment order:", errMessage);
      throw new HttpsError(
        "internal",
        "Failed to initialize payment session. Please try again."
      );
    }
  }
);
