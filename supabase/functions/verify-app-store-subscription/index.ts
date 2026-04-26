import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const APP_STORE_PRODUCTION_URL =
  "https://api.storekit.itunes.apple.com/inApps/v1/subscriptions";
const APP_STORE_SANDBOX_URL =
  "https://api.storekit-sandbox.itunes.apple.com/inApps/v1/subscriptions";

const ACTIVE_STATUS = 1;
const BILLING_GRACE_PERIOD_STATUS = 4;

type AppleStatusResponse = {
  environment?: string;
  data?: Array<{
    subscriptionGroupIdentifier?: string;
    lastTransactions?: Array<{
      status?: number;
      signedTransactionInfo?: string;
      signedRenewalInfo?: string;
    }>;
  }>;
  errorCode?: number;
  errorMessage?: string;
};

type DecodedTransaction = {
  environment?: string;
  expiresDate?: number;
  originalPurchaseDate?: number;
  originalTransactionId?: string;
  productId?: string;
  purchaseDate?: number;
  revocationDate?: number;
  signedDate?: number;
  transactionId?: string;
};

type DecodedRenewal = {
  autoRenewProductId?: string;
  autoRenewStatus?: number;
  productId?: string;
  renewalDate?: number;
  signedDate?: number;
};

type FlattenedTransaction = {
  statusCode: number;
  transaction: DecodedTransaction;
  renewal: DecodedRenewal;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!supabaseUrl || !supabaseAnonKey) {
      return jsonResponse(
        { verified: false, error: "Missing Supabase function secrets" },
        500,
      );
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse(
        { verified: false, error: "Missing Authorization header" },
        401,
      );
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: { Authorization: authHeader },
      },
    });

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return jsonResponse(
        { verified: false, error: "Invalid Supabase session" },
        401,
      );
    }

    const body = await req.json();
    const transactionId = normalizeString(body?.transactionId);
    const requestedProductId = normalizeString(body?.productId);

    if (!transactionId) {
      return jsonResponse(
        {
          verified: false,
          error: "transactionId is required for App Store verification",
        },
        400,
      );
    }

    const appStoreToken = await createAppStoreToken();
    const appleResponse = await fetchSubscriptionStatus(
      transactionId,
      appStoreToken,
    );
    const flattened = flattenTransactions(appleResponse, requestedProductId);

    if (flattened.length == 0) {
      return jsonResponse(
        {
          verified: false,
          error: "No subscription status returned for this transaction",
        },
        404,
      );
    }

    const latest = flattened[0];
    const endDateMs =
      latest.transaction.expiresDate ?? latest.renewal.renewalDate;
    const startDateMs =
      latest.transaction.originalPurchaseDate ?? latest.transaction.purchaseDate;
    const verifiedAt = new Date().toISOString();

    const subscription = {
      id: crypto.randomUUID(),
      user_id: user.id,
      product_id:
        latest.transaction.productId ??
        latest.renewal.autoRenewProductId ??
        latest.renewal.productId ??
        requestedProductId,
      start_date: startDateMs
        ? new Date(startDateMs).toISOString()
        : verifiedAt,
      end_date: endDateMs ? new Date(endDateMs).toISOString() : null,
      is_active: isSubscriptionActive(latest.statusCode),
      auto_renew: latest.renewal.autoRenewStatus === 1,
      original_transaction_id:
        latest.transaction.originalTransactionId ?? transactionId,
      latest_transaction_id: latest.transaction.transactionId ?? transactionId,
      app_store_environment:
        latest.transaction.environment ?? appleResponse.environment ?? null,
      status_code: latest.statusCode,
      verification_source: "app_store_server_api",
      verified_at: verifiedAt,
    };

    return jsonResponse({
      verified: true,
      subscription,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse(
      {
        verified: false,
        error: message,
      },
      500,
    );
  }
});

async function fetchSubscriptionStatus(
  transactionId: string,
  token: string,
): Promise<AppleStatusResponse> {
  const productionResponse = await fetchAppleEnvironment(
    APP_STORE_PRODUCTION_URL,
    transactionId,
    token,
  );

  if (productionResponse.ok) {
    return productionResponse.body;
  }

  if (productionResponse.status !== 404) {
    throw new Error(
      productionResponse.body.errorMessage ??
        `App Store production verification failed: ${productionResponse.status}`,
    );
  }

  const sandboxResponse = await fetchAppleEnvironment(
    APP_STORE_SANDBOX_URL,
    transactionId,
    token,
  );

  if (!sandboxResponse.ok) {
    throw new Error(
      sandboxResponse.body.errorMessage ??
        `App Store sandbox verification failed: ${sandboxResponse.status}`,
    );
  }

  return sandboxResponse.body;
}

async function fetchAppleEnvironment(
  baseUrl: string,
  transactionId: string,
  token: string,
): Promise<{ ok: boolean; status: number; body: AppleStatusResponse }> {
  const response = await fetch(`${baseUrl}/${transactionId}`, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  const body = (await response.json()) as AppleStatusResponse;
  return {
    ok: response.ok,
    status: response.status,
    body,
  };
}

function flattenTransactions(
  response: AppleStatusResponse,
  requestedProductId?: string,
): FlattenedTransaction[] {
  const flattened: FlattenedTransaction[] = [];

  for (const group of response.data ?? []) {
    for (const transaction of group.lastTransactions ?? []) {
      if (!transaction.signedTransactionInfo || !transaction.signedRenewalInfo) {
        continue;
      }

      const decodedTransaction = decodeJwsPayload<DecodedTransaction>(
        transaction.signedTransactionInfo,
      );
      const decodedRenewal = decodeJwsPayload<DecodedRenewal>(
        transaction.signedRenewalInfo,
      );

      flattened.push({
        statusCode: transaction.status ?? 0,
        transaction: decodedTransaction,
        renewal: decodedRenewal,
      });
    }
  }

  const filtered = requestedProductId
    ? flattened.filter((entry) {
        return entry.transaction.productId === requestedProductId ||
          entry.renewal.productId === requestedProductId ||
          entry.renewal.autoRenewProductId === requestedProductId;
      })
    : flattened;

  const entriesToSort = filtered.length > 0 ? filtered : flattened;
  entriesToSort.sort((a, b) => sortTimestamp(b) - sortTimestamp(a));

  return entriesToSort;
}

function sortTimestamp(entry: FlattenedTransaction): number {
  return entry.transaction.expiresDate ??
    entry.renewal.renewalDate ??
    entry.transaction.purchaseDate ??
    entry.transaction.signedDate ??
    entry.renewal.signedDate ??
    0;
}

function isSubscriptionActive(statusCode: number): boolean {
  return statusCode === ACTIVE_STATUS ||
    statusCode === BILLING_GRACE_PERIOD_STATUS;
}

function decodeJwsPayload<T>(jws: string): T {
  const parts = jws.split(".");
  if (parts.length < 2) {
    throw new Error("Invalid JWS payload");
  }

  const payload = base64UrlDecode(parts[1]);
  return JSON.parse(payload) as T;
}

async function createAppStoreToken(): Promise<string> {
  const issuerId = requiredSecret("APP_STORE_ISSUER_ID");
  const keyId = requiredSecret("APP_STORE_KEY_ID");
  const bundleId = requiredSecret("APP_STORE_BUNDLE_ID");
  const privateKeyPem = requiredSecret("APP_STORE_PRIVATE_KEY").replaceAll(
    "\\n",
    "\n",
  );

  const nowSeconds = Math.floor(Date.now() / 1000);
  const header = {
    alg: "ES256",
    kid: keyId,
    typ: "JWT",
  };
  const payload = {
    iss: issuerId,
    iat: nowSeconds,
    exp: nowSeconds + 300,
    aud: "appstoreconnect-v1",
    bid: bundleId,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const signature = await signEs256(signingInput, privateKeyPem);

  return `${signingInput}.${signature}`;
}

async function signEs256(
  payload: string,
  privateKeyPem: string,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKeyPem),
    {
      name: "ECDSA",
      namedCurve: "P-256",
    },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(payload),
  );

  return base64UrlEncode(new Uint8Array(signature));
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const cleaned = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replaceAll(/\s+/g, "");

  const binary = atob(cleaned);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }

  return bytes.buffer;
}

function base64UrlEncode(value: string | Uint8Array): string {
  const bytes = typeof value === "string"
    ? new TextEncoder().encode(value)
    : value;

  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll(
    "=",
    "",
  );
}

function base64UrlDecode(value: string): string {
  const normalized = value.replaceAll("-", "+").replaceAll("_", "/");
  const padded = normalized + "=".repeat((4 - normalized.length % 4) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);

  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }

  return new TextDecoder().decode(bytes);
}

function requiredSecret(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing required secret: ${name}`);
  }
  return value;
}

function normalizeString(value: unknown): string | undefined {
  if (typeof value != "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length === 0 ? undefined : trimmed;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
