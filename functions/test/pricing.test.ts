import { describe, it } from "node:test";
import assert from "node:assert";
import { PricingService } from "../src/services/pricing.service";
import { OrderItemSnapshot } from "../src/types/order.types";

describe("Backend PricingService Unit Tests", () => {
  it("calculates correct totals with standard default fees", () => {
    const items: OrderItemSnapshot[] = [
      {
        productId: "p1",
        name: "Atta 5kg",
        price: 245.0,
        quantity: 1,
        subtotal: 245.0,
      },
      {
        productId: "p2",
        name: "Salt 1kg",
        price: 28.0,
        quantity: 2,
        subtotal: 56.0,
      },
    ];

    const pricing = PricingService.calculatePricing(items);
    assert.strictEqual(pricing.subtotal, 301.0);
    assert.strictEqual(pricing.deliveryFee, 15.0);
    assert.strictEqual(pricing.platformFee, 5.0);
    assert.strictEqual(pricing.total, 321.0);
  });

  it("calculates empty cart correctly with default fees", () => {
    const pricing = PricingService.calculatePricing([]);
    assert.strictEqual(pricing.subtotal, 0.0);
    assert.strictEqual(pricing.deliveryFee, 15.0);
    assert.strictEqual(pricing.platformFee, 5.0);
    assert.strictEqual(pricing.total, 20.0);
  });
});
