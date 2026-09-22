/**
 * Order-related TypeScript types mirroring the Firestore schema and customer app models.
 */

export type OrderFulfillmentStatus =
  | "pending"
  | "confirmed"
  | "preparing"
  | "ready_for_pickup"
  | "out_for_delivery"
  | "delivered"
  | "cancelled"
  | "rejected";

export interface OrderItemSnapshot {
  productId: string;
  name: string;
  price: number;
  quantity: number;
  subtotal: number;
}

export interface OrderDeliverySnapshot {
  addressId?: string;
  label: string;
  fullAddress: string;
  phoneNumber: string;
}

export interface OrderPricingSnapshot {
  subtotal: number;
  deliveryFee: number;
  platformFee: number;
  total: number;
}

export interface OrderDocument {
  orderId?: string;
  customerId: string;
  shopId: string;
  shopName: string;
  items: OrderItemSnapshot[];
  delivery: OrderDeliverySnapshot;
  pricing: OrderPricingSnapshot;
  status: OrderFulfillmentStatus;
  paymentStatus: string;
  paymentOrderId?: string;
  paymentId?: string;
  paymentMethod?: string;
  paidAt?: FirebaseFirestore.Timestamp | Date;
  createdAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp | Date;
  cancelledAt?: FirebaseFirestore.Timestamp | Date;
  cancellationReason?: string;
}
