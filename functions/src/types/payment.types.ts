import { OrderDeliverySnapshot, OrderItemSnapshot, OrderPricingSnapshot } from "./order.types";

/**
 * Payment lifecycle states, decoupled from order fulfillment status.
 */
export type PaymentStatus =
  | "pending"
  | "paid"
  | "failed"
  | "cancelled"
  | "refunded";

/**
 * Request payload for creating a payment order from the Flutter client.
 */
export interface CreatePaymentOrderRequest {
  shopId: string;
  items: Array<{
    productId: string;
    quantity: number;
  }>;
  deliveryAddress: OrderDeliverySnapshot;
  customerDetails?: {
    name?: string;
    phone?: string;
    email?: string;
  };
}

/**
 * Response returned to the Flutter client after creating a payment session.
 */
export interface CreatePaymentOrderResponse {
  success: boolean;
  orderId: string;
  paymentOrderId: string;
  paymentSessionId?: string;
  amount: number;
  currency: string;
  pricing: OrderPricingSnapshot;
  message?: string;
}

/**
 * Request payload for verifying a payment from the Flutter client.
 */
export interface VerifyPaymentRequest {
  orderId: string;
  paymentOrderId?: string;
}

/**
 * Response returned to the Flutter client after payment verification.
 */
export interface VerifyPaymentResponse {
  success: boolean;
  orderId: string;
  paymentStatus: PaymentStatus;
  paymentId?: string;
  paymentMethod?: string;
  paidAt?: string;
  message?: string;
}

export interface PaymentIntentDocument {
  id: string;
  customerId: string;
  shopId: string;
  shopName: string;
  items: OrderItemSnapshot[];
  delivery: OrderDeliverySnapshot;
  pricing: OrderPricingSnapshot;
  paymentOrderId: string;
  paymentSessionId?: string;
  paymentStatus: PaymentStatus;
  finalOrderId?: string;
  paymentId?: string;
  paymentMethod?: string;
  paidAt?: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp | Date;
  expiresAt?: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp | Date;
  createdAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp | Date;
  updatedAt?: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp | Date;
}

