import { OrderItemSnapshot, OrderPricingSnapshot } from "../types/order.types";

/**
 * Service responsible for calculating and verifying order pricing on the trusted backend.
 * Client-submitted price totals are NEVER trusted blindly.
 */
export class PricingService {
  /**
   * Fixed fee constants for MVP (matching customer app OrderPricing constants).
   */
  public static readonly DEFAULT_DELIVERY_FEE = 15.0;
  public static readonly DEFAULT_PLATFORM_FEE = 5.0;

  /**
   * Calculates order pricing breakdown given a validated list of item snapshots.
   */
  public static calculatePricing(
    items: OrderItemSnapshot[],
    deliveryFee: number = PricingService.DEFAULT_DELIVERY_FEE,
    platformFee: number = PricingService.DEFAULT_PLATFORM_FEE
  ): OrderPricingSnapshot {
    const subtotal = items.reduce((sum, item) => sum + item.subtotal, 0);
    const total = subtotal + deliveryFee + platformFee;

    return {
      subtotal: Math.round(subtotal * 100) / 100,
      deliveryFee: Math.round(deliveryFee * 100) / 100,
      platformFee: Math.round(platformFee * 100) / 100,
      total: Math.round(total * 100) / 100,
    };
  }

  /**
   * Fetches official product data from Firestore and constructs trusted item snapshots.
   * This guarantees that prices cannot be tampered with by the client.
   *
   * @param db Firestore database instance
   * @param items List of product IDs and requested quantities from client
   */
  public static async resolveItemSnapshots(
    db: FirebaseFirestore.Firestore,
    shopId: string,
    items: Array<{ productId: string; quantity: number }>
  ): Promise<OrderItemSnapshot[]> {
    if (!items || items.length === 0) {
      throw new Error("Order must contain at least one item.");
    }

    const itemSnapshots: OrderItemSnapshot[] = [];

    for (const item of items) {
      if (!item.productId || typeof item.productId !== "string") {
        throw new Error("Invalid product ID in order items.");
      }
      if (!item.quantity || item.quantity <= 0) {
        throw new Error(`Invalid quantity for product ID ${item.productId}.`);
      }

      const productDoc = await db.collection("products").doc(item.productId).get();
      if (!productDoc.exists) {
        throw new Error(`Product ${item.productId} was not found.`);
      }

      const productData = productDoc.data() || {};
      const productShopId = productData.shopId;
      if (productShopId && productShopId !== shopId) {
        throw new Error(`Product ${item.productId} does not belong to shop ${shopId}.`);
      }

      const name = (productData.name as string) || "Item";
      const price = typeof productData.price === "number" ? productData.price : 0;
      const subtotal = Math.round(price * item.quantity * 100) / 100;

      itemSnapshots.push({
        productId: item.productId,
        name,
        price,
        quantity: item.quantity,
        subtotal,
      });
    }

    return itemSnapshots;
  }
}
