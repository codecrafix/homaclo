import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const keyId = Deno.env.get("RAZORPAY_KEY_ID") ?? "";
  const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";
  if (!keyId || !keySecret) {
    return json({ error: "Razorpay is not configured on the server" }, 500);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  // Identify the caller from their own JWT (never trust a client-supplied
  // user id). A payment must always be tied to a real logged-in user so it
  // can be reconciled later. current_uid() resolves the app user id for both
  // Supabase-Auth sessions and Clerk sessions.
  const authHeader = request.headers.get("Authorization") ?? "";
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: callerId } = await userClient.rpc("current_uid");
  if (!callerId) {
    return json({ error: "You must be signed in to pay" }, 401);
  }
  const user = { id: callerId as string };

  try {
    const input = await request.json();
    const amount = Number(input.amount);
    const currency = String(input.currency ?? "INR");
    const receipt = String(input.receipt ?? "");
    // Optional snapshot of the cart (tanks, date, slot, address, total) so
    // a webhook that lands after the client has given up can still create
    // the booking correctly. Never trusted for pricing — only for display /
    // booking-recreation fields.
    const cartSnapshot =
      input.cartSnapshot && typeof input.cartSnapshot === "object"
        ? input.cartSnapshot
        : null;

    if (!Number.isInteger(amount) || amount <= 0 || amount > 100000000) {
      return json({ error: "Invalid payment amount" }, 400);
    }
    if (!/^[A-Z]{3}$/.test(currency) || receipt.length > 40) {
      return json({ error: "Invalid order details" }, 400);
    }

    const auth = btoa(`${keyId}:${keySecret}`);
    const razorpayResponse = await fetch(
      "https://api.razorpay.com/v1/orders",
      {
        method: "POST",
        headers: {
          Authorization: `Basic ${auth}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ amount, currency, receipt }),
      },
    );

    const payload = await razorpayResponse.json();
    if (!razorpayResponse.ok) {
      console.error("Razorpay order creation failed", razorpayResponse.status, JSON.stringify(payload));
      return json({ error: "Could not create payment order" }, 502);
    }

    // Persist the order as PENDING *before* returning it to the client.
    // This is the row a Razorpay webhook (supabase/functions/razorpay-webhook)
    // will reconcile against if the client never gets a success/failure
    // callback — the actual fix for "order already paid" retries.
    if (serviceRoleKey) {
      const adminClient = createClient(supabaseUrl, serviceRoleKey);
      const { error: insertError } = await adminClient.from("payments").upsert(
        {
          user_id: user.id,
          razorpay_order_id: payload.id,
          amount,
          currency,
          status: "PENDING",
          cart_snapshot: cartSnapshot,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "razorpay_order_id" },
      );
      if (insertError) {
        // Don't block checkout on this — but log loudly, since it means the
        // webhook safety net won't have anything to reconcile against for
        // this particular order.
        console.error("Failed to persist PENDING payment row", insertError);
      }
    } else {
      console.error(
        "SUPABASE_SERVICE_ROLE_KEY missing — payments safety net is disabled",
      );
    }

    // Return the server's own key_id alongside the order so the client
    // checkout ALWAYS uses the exact key that created this order. Using a
    // different (e.g. stale hardcoded) key on the client than the one that
    // created the order causes Razorpay to reject every payment attempt
    // with a generic "Payment could not be completed" error, regardless of
    // the payment method tried. The key_id is public and safe to return.
    return json({
      id: payload.id,
      amount: payload.amount,
      currency: payload.currency,
      key: keyId,
    });
  } catch (error) {
    console.error("create-razorpay-order error", error);
    return json({ error: "Invalid request" }, 400);
  }
});
