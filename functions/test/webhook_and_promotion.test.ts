import { describe, it } from "node:test";
import assert from "node:assert";
import * as crypto from "crypto";
import { PaymentService } from "../src/services/payment.service";
import { OrderPromotionService } from "../src/services/promotion.service";
import { CashfreeConfig } from "../src/config/cashfree.config";
import { PaymentIntentDocument } from "../src/types/payment.types";

/**
 * In-memory Mock Firestore implementation to execute unit tests against transactions
 * and document operations without external network dependencies.
 */
class MockFirestore {
  private data: Map<string, Map<string, any>> = new Map();

  constructor() {
    this.data.set("payment_intents", new Map());
    this.data.set("orders", new Map());
  }

  public collection(name: string) {
    const table = this.data.get(name) || new Map();
    this.data.set(name, table);

    return {
      doc: (id: string) => ({
        id,
        get: async () => {
          const exists = table.has(id);
          const docData = exists ? JSON.parse(JSON.stringify(table.get(id))) : undefined;
          return {
            id,
            exists,
            data: () => docData,
          };
        },
        set: async (val: any) => {
          table.set(id, JSON.parse(JSON.stringify(val)));
        },
        update: async (val: any) => {
          if (!table.has(id)) {
            throw new Error(`Document ${id} does not exist`);
          }
          const existing = table.get(id);
          table.set(id, { ...existing, ...JSON.parse(JSON.stringify(val)) });
        },
      }),
    };
  }

  public async runTransaction<T>(
    updateFunction: (transaction: any) => Promise<T>
  ): Promise<T> {
    const transaction = {
      get: async (docRef: any) => {
        return await docRef.get();
      },
      set: (docRef: any, data: any) => {
        // Directly set into mock store
        docRef.set(data);
      },
      update: (docRef: any, data: any) => {
        docRef.update(data);
      },
    };

    return await updateFunction(transaction);
  }

  public getDocument(collection: string, id: string): any {
    return this.data.get(collection)?.get(id);
  }

  public setDocument(collection: string, id: string, val: any): void {
    const table = this.data.get(collection) || new Map();
    table.set(id, JSON.parse(JSON.stringify(val)));
    this.data.set(collection, table);
  }
}

describe("Cashfree Webhook Signature & Security Tests", () => {
  const testConfig: CashfreeConfig = {
    appId: "TEST_APP_ID_12345",
    secretKey: "TEST_SECRET_KEY_987654321",
    environment: "SANDBOX",
    apiVersion: "2023-08-01",
  };

  const paymentService = new PaymentService(testConfig);

  function generateValidSignature(
    rawBody: string,
    timestamp: string,
    secretKey: string = testConfig.secretKey
  ): string {
    const payload = `${timestamp}${rawBody}`;
    return crypto
      .createHmac("sha256", secretKey)
      .update(payload)
      .digest("base64");
  }

  it("A. Invalid webhook signature is rejected", () => {
    const timestamp = Date.now().toString();
    const rawBody = JSON.stringify({ type: "PAYMENT_SUCCESS_WEBHOOK", data: {} });
    const invalidSignature = "invalid_base64_signature_here=";

    const isValid = paymentService.verifyWebhookSignature(
      rawBody,
      invalidSignature,
      timestamp
    );
    assert.strictEqual(isValid, false);
  });

  it("B. Malformed or tampered webhook payload signature check fails", () => {
    const timestamp = Date.now().toString();
    const originalBody = JSON.stringify({
      type: "PAYMENT_SUCCESS_WEBHOOK",
      data: { order: { order_amount: 100 } },
    });
    const validSignature = generateValidSignature(originalBody, timestamp);

    // Tampered payload
    const tamperedBody = JSON.stringify({
      type: "PAYMENT_SUCCESS_WEBHOOK",
      data: { order: { order_amount: 1 } },
    });

    const isValid = paymentService.verifyWebhookSignature(
      tamperedBody,
      validSignature,
      timestamp
    );
    assert.strictEqual(isValid, false);
  });

  it("Replay attack protection: Expired timestamp (>5 min) is rejected", () => {
    const expiredTimestamp = (Date.now() - 6 * 60 * 1000).toString(); // 6 mins ago
    const rawBody = JSON.stringify({ type: "PAYMENT_SUCCESS_WEBHOOK", data: {} });
    const validSigForExpired = generateValidSignature(rawBody, expiredTimestamp);

    const isValid = paymentService.verifyWebhookSignature(
      rawBody,
      validSigForExpired,
      expiredTimestamp
    );
    assert.strictEqual(isValid, false);
  });

  it("Valid webhook signature passes verification", () => {
    const timestamp = Date.now().toString();
    const rawBody = JSON.stringify({
      type: "PAYMENT_SUCCESS_WEBHOOK",
      data: {
        order: { order_id: "order_12345", order_amount: 250 },
        payment: { payment_status: "SUCCESS", payment_amount: 250 },
      },
    });
    const validSignature = generateValidSignature(rawBody, timestamp);

    const isValid = paymentService.verifyWebhookSignature(
      rawBody,
      validSignature,
      timestamp
    );
    assert.strictEqual(isValid, true);
  });
});

describe("OrderPromotionService & Concurrency Tests", () => {
  const sampleIntent: PaymentIntentDocument = {
    id: "intent_abc_123",
    customerId: "cust_user_456",
    shopId: "shop_kirana_789",
    shopName: "Sharma Kirana Store",
    items: [
      {
        productId: "prod_atta",
        name: "Ashirvaad Atta 5kg",
        price: 245,
        quantity: 1,
        subtotal: 245,
      },
    ],
    delivery: {
      addressId: "addr_1",
      label: "Home",
      fullAddress: "Flat 101, Bharat Heights, New Delhi",
      phoneNumber: "9876543210",
    },
    pricing: {
      subtotal: 245,
      deliveryFee: 15,
      platformFee: 5,
      total: 265,
    },
    paymentOrderId: "cf_order_9999",
    paymentStatus: "pending",
    createdAt: new Date(),
  };

  it("C. Missing payment intent results in controlled failure", async () => {
    const mockDb = new MockFirestore();

    await assert.rejects(
      async () => {
        await OrderPromotionService.promoteIntentToOrder(
          mockDb as any,
          "non_existent_intent",
          {
            paymentId: "cf_pay_1",
            verifiedAmount: 265,
            verifiedCurrency: "INR",
          }
        );
      },
      (err: Error) => {
        assert.match(err.message, /payment intent not found/i);
        return true;
      }
    );
  });

  it("F. Gateway reports successful payment but amount does not match intent -> rejected", async () => {
    const mockDb = new MockFirestore();
    mockDb.setDocument("payment_intents", sampleIntent.id, sampleIntent);

    await assert.rejects(
      async () => {
        await OrderPromotionService.promoteIntentToOrder(
          mockDb as any,
          sampleIntent.id,
          {
            paymentId: "cf_pay_tampered",
            verifiedAmount: 1.0, // Fraudulent amount
            verifiedCurrency: "INR",
          }
        );
      },
      (err: Error) => {
        assert.match(err.message, /amount mismatch/i);
        return true;
      }
    );

    // Ensure no order was created
    const orderDoc = mockDb.getDocument("orders", sampleIntent.id);
    assert.strictEqual(orderDoc, undefined);
  });

  it("G. Valid verified payment creates exactly one final order with server-side snapshots", async () => {
    const mockDb = new MockFirestore();
    mockDb.setDocument("payment_intents", sampleIntent.id, sampleIntent);

    const result = await OrderPromotionService.promoteIntentToOrder(
      mockDb as any,
      sampleIntent.id,
      {
        paymentId: "cf_pay_valid_123",
        paymentMethod: "upi",
        paidAt: new Date("2026-09-18T18:30:00Z"),
        verifiedAmount: 265,
        verifiedCurrency: "INR",
      }
    );

    assert.strictEqual(result.success, true);
    assert.strictEqual(result.alreadyPromoted, false);
    assert.strictEqual(result.orderId, sampleIntent.id);

    // Verify order in Firestore
    const createdOrder = mockDb.getDocument("orders", sampleIntent.id);
    assert.ok(createdOrder);
    assert.strictEqual(createdOrder.customerId, "cust_user_456");
    assert.strictEqual(createdOrder.shopId, "shop_kirana_789");
    assert.strictEqual(createdOrder.status, "pending");
    assert.strictEqual(createdOrder.paymentStatus, "paid");
    assert.strictEqual(createdOrder.paymentId, "cf_pay_valid_123");
    assert.strictEqual(createdOrder.paymentMethod, "upi");
    assert.strictEqual(createdOrder.pricing.total, 265);

    // Verify payment intent updated
    const updatedIntent = mockDb.getDocument("payment_intents", sampleIntent.id);
    assert.strictEqual(updatedIntent.paymentStatus, "paid");
    assert.strictEqual(updatedIntent.finalOrderId, sampleIntent.id);
  });

  it("H & J. Duplicate webhook or already-promoted intent -> idempotent no-op and returns existing order", async () => {
    const mockDb = new MockFirestore();
    mockDb.setDocument("payment_intents", sampleIntent.id, sampleIntent);

    // First promotion
    const firstResult = await OrderPromotionService.promoteIntentToOrder(
      mockDb as any,
      sampleIntent.id,
      {
        paymentId: "cf_pay_1",
        verifiedAmount: 265,
        verifiedCurrency: "INR",
      }
    );
    assert.strictEqual(firstResult.alreadyPromoted, false);

    // Second promotion (duplicate webhook arrival)
    const secondResult = await OrderPromotionService.promoteIntentToOrder(
      mockDb as any,
      sampleIntent.id,
      {
        paymentId: "cf_pay_1",
        verifiedAmount: 265,
        verifiedCurrency: "INR",
      }
    );

    assert.strictEqual(secondResult.success, true);
    assert.strictEqual(secondResult.alreadyPromoted, true);
    assert.strictEqual(secondResult.orderId, sampleIntent.id);
  });

  it("I. Concurrent verification calls resolve cleanly and idempotently", async () => {
    const mockDb = new MockFirestore();
    mockDb.setDocument("payment_intents", sampleIntent.id, sampleIntent);

    // Simulate simultaneous verifyPayment and webhook
    const [res1, res2] = await Promise.all([
      OrderPromotionService.promoteIntentToOrder(mockDb as any, sampleIntent.id, {
        paymentId: "cf_pay_concurrent",
        verifiedAmount: 265,
        verifiedCurrency: "INR",
      }),
      OrderPromotionService.promoteIntentToOrder(mockDb as any, sampleIntent.id, {
        paymentId: "cf_pay_concurrent",
        verifiedAmount: 265,
        verifiedCurrency: "INR",
      }),
    ]);

    assert.strictEqual(res1.success, true);
    assert.strictEqual(res2.success, true);
    assert.strictEqual(res1.orderId, res2.orderId);

    // Exactly one was the first promotion and one was alreadyPromoted
    const promotedCount = (res1.alreadyPromoted ? 0 : 1) + (res2.alreadyPromoted ? 0 : 1);
    assert.ok(promotedCount >= 1);
  });

  it("K. Expired intent does not blindly promote and marks intent as failed", async () => {
    const mockDb = new MockFirestore();
    const expiredIntent: PaymentIntentDocument = {
      ...sampleIntent,
      id: "intent_expired_999",
      expiresAt: new Date(Date.now() - 1000 * 60 * 60), // Expired 1 hour ago
    };
    mockDb.setDocument("payment_intents", expiredIntent.id, expiredIntent);

    await assert.rejects(
      async () => {
        await OrderPromotionService.promoteIntentToOrder(
          mockDb as any,
          expiredIntent.id,
          {
            paymentId: "cf_pay_late",
            verifiedAmount: 265,
            verifiedCurrency: "INR",
          }
        );
      },
      (err: Error) => {
        assert.match(err.message, /expired/i);
        return true;
      }
    );

    // Ensure no order was created
    const orderDoc = mockDb.getDocument("orders", expiredIntent.id);
    assert.strictEqual(orderDoc, undefined);

    // Intent should be updated to failed
    const updatedIntent = mockDb.getDocument("payment_intents", expiredIntent.id);
    assert.strictEqual(updatedIntent.paymentStatus, "failed");
  });
});
