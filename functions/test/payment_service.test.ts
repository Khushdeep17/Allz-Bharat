import { describe, it } from "node:test";
import assert from "node:assert";
import { PaymentService } from "../src/services/payment.service";
import {
  getCashfreeBaseUrl,
  isCashfreeConfigured,
} from "../src/config/cashfree.config";

describe("Cashfree PaymentService & Config Unit Tests", () => {
  it("detects unconfigured Cashfree credentials correctly", () => {
    assert.strictEqual(
      isCashfreeConfigured({
        appId: "",
        secretKey: "",
        environment: "SANDBOX",
        apiVersion: "2023-08-01",
      }),
      false
    );

    assert.strictEqual(
      isCashfreeConfigured({
        appId: "   ",
        secretKey: "key_123",
        environment: "SANDBOX",
        apiVersion: "2023-08-01",
      }),
      false
    );

    assert.strictEqual(
      isCashfreeConfigured({
        appId: "app_123",
        secretKey: "sec_456",
        environment: "SANDBOX",
        apiVersion: "2023-08-01",
      }),
      true
    );
  });

  it("selects correct base URL for sandbox and production", () => {
    assert.strictEqual(
      getCashfreeBaseUrl("SANDBOX"),
      "https://sandbox.cashfree.com/pg"
    );
    assert.strictEqual(
      getCashfreeBaseUrl("PRODUCTION"),
      "https://api.cashfree.com/pg"
    );
  });

  it("fails explicitly without returning mock sessions when credentials are missing", async () => {
    const unconfiguredService = new PaymentService({
      appId: "",
      secretKey: "",
      environment: "SANDBOX",
      apiVersion: "2023-08-01",
    });

    await assert.rejects(
      async () => {
        await unconfiguredService.createGatewaySession({
          orderId: "test_ord_123",
          orderAmount: 100.0,
          orderCurrency: "INR",
          customerDetails: {
            customerId: "cust_123",
            customerPhone: "9876543210",
          },
        });
      },
      (err: Error) => {
        assert.match(err.message, /credentials are not configured/i);
        // Ensure error doesn't expose any secret
        assert.doesNotMatch(err.message, /secret/i);
        return true;
      }
    );
  });

  it("fails explicitly on verification when credentials are missing and never reports fake paid", async () => {
    const unconfiguredService = new PaymentService({
      appId: "",
      secretKey: "",
      environment: "SANDBOX",
      apiVersion: "2023-08-01",
    });

    await assert.rejects(
      async () => {
        await unconfiguredService.verifyGatewayPayment("test_ord_123");
      },
      (err: Error) => {
        assert.match(err.message, /credentials are not configured/i);
        return true;
      }
    );
  });
});
