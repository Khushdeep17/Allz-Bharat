import * as admin from "firebase-admin";
import { PaymentIntentDocument } from "../types/payment.types";
import { OrderDocument } from "../types/order.types";

export interface VerifiedPaymentDetails {
  paymentId?: string;
  paymentMethod?: string;
  paidAt?: Date;
  verifiedAmount?: number;
  verifiedCurrency?: string;
}

export interface PromotionResult {
  success: boolean;
  alreadyPromoted: boolean;
  orderId: string;
  order?: OrderDocument | Record<string, any>;
  message?: string;
}

/**
 * Shared promotion service responsible for atomic, idempotent conversion of a verified
 * payment intent into a permanent order document in Firestore.
 *
 * Concurrency & Idempotency Guarantee:
 * - Runs inside a Firestore transaction.
 * - Handles simultaneous webhook delivery and client verifyPayment calls safely.
 * - If already promoted, returns existing order without creating duplicates.
 * - Rejects promotion if amount mismatches or intent is expired.
 * - Preserves server-calculated pricing snapshots from the payment intent.
 */
export class OrderPromotionService {
  /**
   * Atomically promotes a payment intent to a final order if verified and eligible.
   *
   * @param db - Firestore instance.
   * @param intentId - Document ID in payment_intents collection.
   * @param details - Gateway-verified payment metadata.
   */
  public static async promoteIntentToOrder(
    db: FirebaseFirestore.Firestore,
    intentId: string,
    details: VerifiedPaymentDetails
  ): Promise<PromotionResult> {
    return await db.runTransaction<PromotionResult>(async (transaction) => {
      const intentRef = db.collection("payment_intents").doc(intentId);
      const intentSnap = await transaction.get(intentRef);

      if (!intentSnap.exists) {
        throw new Error(`Payment intent not found: ${intentId}`);
      }

      const intentData = intentSnap.data() as PaymentIntentDocument;

      // 1. Idempotency check: Already marked as promoted with finalOrderId
      if (intentData.finalOrderId) {
        const existingOrderRef = db.collection("orders").doc(intentData.finalOrderId);
        const existingOrderSnap = await transaction.get(existingOrderRef);
        if (existingOrderSnap.exists) {
          return {
            success: true,
            alreadyPromoted: true,
            orderId: intentData.finalOrderId,
            order: existingOrderSnap.data() as OrderDocument,
            message: "Order already promoted.",
          };
        }
      }

      // 2. Idempotency check: Order with intentId already exists
      const targetOrderRef = db.collection("orders").doc(intentId);
      const targetOrderSnap = await transaction.get(targetOrderRef);
      if (targetOrderSnap.exists) {
        return {
          success: true,
          alreadyPromoted: true,
          orderId: intentId,
          order: targetOrderSnap.data() as OrderDocument,
          message: "Order already exists.",
        };
      }

      // 3. Expiration verification
      if (intentData.expiresAt) {
        let expiresAtTime = 0;
        if (typeof (intentData.expiresAt as any)?.toMillis === "function") {
          expiresAtTime = (intentData.expiresAt as any).toMillis();
        } else if (intentData.expiresAt instanceof Date) {
          expiresAtTime = intentData.expiresAt.getTime();
        } else if (typeof intentData.expiresAt === "string" || typeof intentData.expiresAt === "number") {
          expiresAtTime = new Date(intentData.expiresAt).getTime();
        }

        if (expiresAtTime > 0 && expiresAtTime < Date.now()) {
          // Intent expired: update status to failed if still pending
          if (intentData.paymentStatus === "pending") {
            transaction.update(intentRef, {
              paymentStatus: "failed",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
          throw new Error("Payment intent has expired.");
        }
      }

      // 4. Amount & Currency integrity check
      if (
        details.verifiedAmount !== undefined &&
        Math.abs(details.verifiedAmount - intentData.pricing.total) > 0.01
      ) {
        throw new Error(
          `Payment amount mismatch: Gateway reported ${details.verifiedAmount} but intent total is ${intentData.pricing.total}`
        );
      }

      if (
        details.verifiedCurrency !== undefined &&
        details.verifiedCurrency.toUpperCase() !== "INR"
      ) {
        throw new Error(`Unsupported currency: ${details.verifiedCurrency}`);
      }

      // 5. Construct final order from server-calculated intent snapshot
      const finalOrderData: OrderDocument = {
        customerId: intentData.customerId,
        shopId: intentData.shopId,
        shopName: intentData.shopName,
        items: intentData.items,
        delivery: intentData.delivery,
        pricing: intentData.pricing,
        status: "pending", // Order fulfillment status starts as pending
        paymentStatus: "paid", // Verified payment
        paymentOrderId: intentData.paymentOrderId,
        paymentId: details.paymentId || undefined,
        paymentMethod: details.paymentMethod || undefined,
        paidAt: details.paidAt || new Date(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // 6. Write final order and update intent atomically
      transaction.set(targetOrderRef, finalOrderData);

      transaction.update(intentRef, {
        paymentStatus: "paid",
        finalOrderId: intentId,
        paymentId: details.paymentId || null,
        paymentMethod: details.paymentMethod || null,
        paidAt: details.paidAt
          ? admin.firestore.Timestamp.fromDate(details.paidAt)
          : admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        alreadyPromoted: false,
        orderId: intentId,
        order: finalOrderData,
        message: "Order promoted successfully.",
      };
    });
  }
}
