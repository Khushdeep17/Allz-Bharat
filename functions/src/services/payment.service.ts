import * as crypto from "crypto";
import {
  CashfreeConfig,
  getCashfreeBaseUrl,
  getCashfreeConfig,
  isCashfreeConfigured,
} from "../config/cashfree.config";
import { PaymentStatus } from "../types/payment.types";

export interface GatewaySessionParams {
  orderId: string;
  orderAmount: number;
  orderCurrency: string;
  customerDetails: {
    customerId: string;
    customerPhone: string;
    customerName?: string;
    customerEmail?: string;
  };
}

export interface GatewaySessionResult {
  paymentOrderId: string;
  paymentSessionId: string;
}

export interface GatewayVerificationResult {
  paymentStatus: PaymentStatus;
  paymentId?: string;
  paymentMethod?: string;
  paidAt?: Date;
  rawResponse?: Record<string, unknown>;
}

/**
 * Service abstracting all interactions with Cashfree Payment Gateway (Sandbox/Production).
 */
export class PaymentService {
  private config: CashfreeConfig;

  constructor(config?: CashfreeConfig) {
    this.config = config || getCashfreeConfig();
  }

  /**
   * Initializes an order with Cashfree Payment Gateway to acquire a valid `payment_session_id`.
   *
   * Calls Cashfree PG Orders API: `POST /pg/orders`
   *
   * SECURITY:
   * - If credentials are missing or invalid, throws an explicit Error.
   * - NEVER returns a mock, fake, or unverified payment session.
   */
  public async createGatewaySession(
    params: GatewaySessionParams
  ): Promise<GatewaySessionResult> {
    if (!isCashfreeConfigured(this.config)) {
      throw new Error("Cashfree payment gateway credentials are not configured.");
    }

    const baseUrl = getCashfreeBaseUrl(this.config.environment);
    const url = `${baseUrl}/orders`;

    const requestBody = {
      order_id: params.orderId,
      order_amount: params.orderAmount,
      order_currency: params.orderCurrency,
      customer_details: {
        customer_id: params.customerDetails.customerId,
        customer_phone: params.customerDetails.customerPhone,
        customer_name: params.customerDetails.customerName || "Customer",
        customer_email:
          params.customerDetails.customerEmail || "customer@allzbharat.com",
      },
      order_meta: {
        return_url:
          "https://www.cashfree.com/devstudio/preview/pg/web/checkout?order_id={order_id}",
      },
    };

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "x-client-id": this.config.appId,
        "x-client-secret": this.config.secretKey,
        "x-api-version": this.config.apiVersion,
        "content-type": "application/json",
      },
      body: JSON.stringify(requestBody),
    });

    const data = (await response.json()) as Record<string, any>;

    if (!response.ok) {
      const errorMessage =
        data?.message || `Cashfree API returned HTTP ${response.status}`;
      throw new Error(`Cashfree order creation failed: ${errorMessage}`);
    }

    if (!data.payment_session_id || typeof data.payment_session_id !== "string") {
      throw new Error("Cashfree API did not return a valid payment_session_id.");
    }

    return {
      paymentOrderId: data.order_id || params.orderId,
      paymentSessionId: data.payment_session_id,
    };
  }

  /**
   * Verifies the status of a payment by querying Cashfree PG API.
   *
   * Queries `GET /pg/orders/{order_id}/payments`
   *
   * SECURITY:
   * - If credentials are missing or invalid, throws an explicit Error.
   * - NEVER returns 'paid' without verifiable gateway confirmation.
   */
  public async verifyGatewayPayment(
    paymentOrderId: string
  ): Promise<GatewayVerificationResult> {
    if (!isCashfreeConfigured(this.config)) {
      throw new Error("Cashfree payment gateway credentials are not configured.");
    }

    const baseUrl = getCashfreeBaseUrl(this.config.environment);
    const url = `${baseUrl}/orders/${paymentOrderId}/payments`;

    const response = await fetch(url, {
      method: "GET",
      headers: {
        "x-client-id": this.config.appId,
        "x-client-secret": this.config.secretKey,
        "x-api-version": this.config.apiVersion,
      },
    });

    if (!response.ok) {
      const errorData = (await response.json().catch(() => null)) as Record<string, any> | null;
      const errorMessage = errorData?.message || `HTTP ${response.status}`;
      throw new Error(`Cashfree payment verification query failed: ${errorMessage}`);
    }

    const payments = (await response.json()) as Array<Record<string, any>>;
    if (!Array.isArray(payments) || payments.length === 0) {
      return {
        paymentStatus: "pending",
      };
    }

    // Find successful payment transaction
    const successPayment = payments.find(
      (p) => p.payment_status === "SUCCESS"
    );

    if (successPayment) {
      return {
        paymentStatus: "paid",
        paymentId: String(successPayment.cf_payment_id || ""),
        paymentMethod: String(
          successPayment.payment_group || successPayment.payment_method || "upi"
        ),
        paidAt: successPayment.payment_completion_time
          ? new Date(successPayment.payment_completion_time)
          : new Date(),
        rawResponse: successPayment,
      };
    }

    const failedPayment = payments.find((p) => p.payment_status === "FAILED");
    if (failedPayment) {
      return {
        paymentStatus: "failed",
        rawResponse: failedPayment,
      };
    }

    return {
      paymentStatus: "pending",
    };
  }

  /**
   * Validates a Cashfree webhook signature to guarantee authentic callbacks.
   *
   * Cashfree Webhook Signature Algorithm:
   * 1. Data = `${timestamp}${rawBody}`
   * 2. Signature = Base64(HMAC-SHA256(Data, secretKey))
   * 3. Comparison = crypto.timingSafeEqual
   *
   * @param rawBody - Raw body buffer or string exactly as received in the HTTP request.
   * @param signature - The signature value from header `x-webhook-signature`.
   * @param timestamp - The timestamp string from header `x-webhook-timestamp`.
   * @param maxAgeMs - Maximum acceptable age of the timestamp in milliseconds (default 5 min).
   */
  public verifyWebhookSignature(
    rawBody: string | Buffer,
    signature: string,
    timestamp: string,
    maxAgeMs: number = 5 * 60 * 1000
  ): boolean {
    if (!signature || !timestamp || !isCashfreeConfigured(this.config)) {
      return false;
    }

    try {
      // 1. Verify timestamp replay freshness
      const tsNum = parseInt(timestamp, 10);
      if (!isNaN(tsNum)) {
        // Timestamp may be in seconds or milliseconds
        const tsMs = tsNum < 1e11 ? tsNum * 1000 : tsNum;
        const now = Date.now();
        // Allow within maxAgeMs in the past and 60 seconds in the future (clock skew)
        if (now - tsMs > maxAgeMs || tsMs - now > 60 * 1000) {
          return false;
        }
      }

      // 2. Compute expected HMAC-SHA256 signature
      const rawBodyStr = Buffer.isBuffer(rawBody) ? rawBody.toString("utf8") : rawBody;
      const payload = `${timestamp}${rawBodyStr}`;
      const expectedSignature = crypto
        .createHmac("sha256", this.config.secretKey)
        .update(payload)
        .digest("base64");

      // 3. Perform timing-safe comparison to prevent timing attacks
      const sigBuffer = Buffer.from(signature, "base64");
      const expectedBuffer = Buffer.from(expectedSignature, "base64");

      if (sigBuffer.length !== expectedBuffer.length) {
        return false;
      }

      return crypto.timingSafeEqual(sigBuffer, expectedBuffer);
    } catch {
      return false;
    }
  }
}

