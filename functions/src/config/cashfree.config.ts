/**
 * Configuration module for Cashfree Payment Gateway.
 *
 * SECURITY NOTICE:
 * - Real API credentials must NEVER be hardcoded in source files or logged.
 * - Credentials must only be read from server-side environment variables or Secret Manager.
 * - Production credentials cannot be used in SANDBOX environment and vice versa.
 */

export interface CashfreeConfig {
  appId: string;
  secretKey: string;
  environment: "SANDBOX" | "PRODUCTION";
  apiVersion: string;
}

/**
 * Validates the Cashfree configuration integrity.
 */
export function isCashfreeConfigured(config: CashfreeConfig): boolean {
  return (
    typeof config.appId === "string" &&
    config.appId.trim().length > 0 &&
    typeof config.secretKey === "string" &&
    config.secretKey.trim().length > 0
  );
}

/**
 * Retrieves the current Cashfree configuration from environment variables or Secret Manager.
 */
export function getCashfreeConfig(): CashfreeConfig {
  const env = process.env.CASHFREE_ENV === "PRODUCTION" ? "PRODUCTION" : "SANDBOX";

  return {
    appId: process.env.CASHFREE_APP_ID?.trim() || "",
    secretKey: process.env.CASHFREE_SECRET_KEY?.trim() || "",
    environment: env,
    apiVersion: "2023-08-01",
  };
}

/**
 * Returns the base URL for Cashfree API requests depending on the environment.
 */
export function getCashfreeBaseUrl(environment: "SANDBOX" | "PRODUCTION"): string {
  if (environment === "PRODUCTION") {
    return "https://api.cashfree.com/pg";
  }
  return "https://sandbox.cashfree.com/pg";
}
