import * as admin from "firebase-admin";

// Initialize the Firebase Admin SDK once for the functions environment
if (!admin.apps.length) {
  admin.initializeApp();
}

// Export callable functions for payment flow
export { createPaymentOrder } from "./handlers/createPaymentOrder";
export { verifyPayment } from "./handlers/verifyPayment";

// Export HTTPS webhook handler for Cashfree PG callbacks
export { cashfreeWebhook } from "./handlers/cashfreeWebhook";
