// Triggered by a Supabase DB trigger on INSERT into `notifications` and
// `admin_broadcasts`. Sends a real OS push notification via OneSignal
// (delivered through Firebase FCM on Android / APNs on iOS), so users get
// notified even when the app is closed or killed.
//
// Required Edge Function secrets (set via `supabase secrets set`):
//   ONESIGNAL_APP_ID          - Homaclo App's OneSignal App ID
//   ONESIGNAL_REST_API_KEY    - Homaclo App's OneSignal REST API Key (secret)
//   PUSH_WEBHOOK_SECRET       - shared secret; must match the header sent by
//                               the DB trigger, so this public endpoint can't
//                               be spammed by outsiders.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-webhook-secret",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  schema: string;
  record: Record<string, unknown> | null;
}

// New-user messages (welcome / welcome bonus / welcome coupon) are created
// while the phone may not be linked to the user in OneSignal yet. For those,
// retry a couple of times in the background.
const RETRY_TYPES = ["welcome", "coupon", "bonus"];
const RETRY_DELAYS_MS = [15000, 30000];

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const webhookSecret = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
  const oneSignalAppId = Deno.env.get("ONESIGNAL_APP_ID") ?? "";
  const oneSignalRestApiKey = Deno.env.get("ONESIGNAL_REST_API_KEY") ?? "";

  if (!oneSignalAppId || !oneSignalRestApiKey) {
    console.error("OneSignal is not configured on the server");
    return json({ error: "Push is not configured on the server" }, 500);
  }

  // Verify the shared secret so random internet traffic can't trigger pushes.
  if (webhookSecret) {
    const provided = request.headers.get("x-webhook-secret") ?? "";
    if (provided !== webhookSecret) {
      return json({ error: "Unauthorized" }, 401);
    }
  }

  try {
    const payload = (await request.json()) as WebhookPayload;
    const record = payload.record;
    if (payload.type !== "INSERT" || !record) {
      return json({ skipped: true });
    }

    const title = String(record.title ?? "Homaclo");
    const body = String(record.body ?? "");
    if (!body) {
      return json({ skipped: true, reason: "empty body" });
    }

    const recordType = String(record.type ?? "");

    // Admin broadcasts insert one `admin_broadcasts` row (pushed to every
    // subscribed device below) plus one in-app `notifications` row per user
    // (type = 'broadcast'). Those per-user rows are only for the in-app list,
    // so skip them here or every user would get the same push twice.
    if (payload.table === "notifications" && recordType === "broadcast") {
      return json({ skipped: true, reason: "broadcast fan-out row" });
    }

    // Broadcasts imported from the OneSignal dashboard were already pushed by
    // OneSignal itself; they are stored only so every user sees them in the
    // in-app list. Never push them a second time.
    if (payload.table === "admin_broadcasts" && record.onesignal_id) {
      return json({ skipped: true, reason: "already pushed by OneSignal" });
    }

    const notificationPayload: Record<string, unknown> = {
      app_id: oneSignalAppId,
      headings: { en: title },
      contents: { en: body },
    };

    const isBroadcast = payload.table === "admin_broadcasts";
    if (isBroadcast) {
      // Broadcast — every subscribed device.
      notificationPayload.included_segments = ["Subscribed Users"];
    } else {
      // Single-user notification — target by Supabase user id, which the
      // app links via OneSignal.login(userId) (external_id) on sign-in.
      const userId = record.user_id;
      if (!userId) {
        return json({ skipped: true, reason: "missing user_id" });
      }
      notificationPayload.include_aliases = { external_id: [String(userId)] };
      notificationPayload.target_channel = "push";
    }

    const send = async () => {
      const response = await fetch("https://api.onesignal.com/notifications", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Key ${oneSignalRestApiKey}`,
        },
        body: JSON.stringify(notificationPayload),
      });
      const result = await response.json();
      return { ok: response.ok, status: response.status, result };
    };

    const first = await send();
    if (!first.ok) {
      console.error("OneSignal send failed", first.status, first.result);
      return json({ error: "Failed to send push", details: first.result }, 502);
    }

    // No recipient yet (device not linked to this user in OneSignal)?
    // Retry in the background for new-user messages only.
    if (!isBroadcast && !first.result.id && RETRY_TYPES.includes(recordType)) {
      const retry = async () => {
        for (const delay of RETRY_DELAYS_MS) {
          await sleep(delay);
          const again = await send();
          if (again.ok && again.result.id) {
            console.log("push delivered on retry", again.result.id);
            return;
          }
        }
        console.log("push not delivered after retries (user has no subscribed device)");
      };
      // deno-lint-ignore no-explicit-any
      const runtime = (globalThis as any).EdgeRuntime;
      if (runtime && typeof runtime.waitUntil === "function") {
        runtime.waitUntil(retry());
      }
    }

    return json({
      success: true,
      id: first.result.id,
      recipients: first.result.recipients,
    });
  } catch (error) {
    console.error("send-push-notification error", error);
    return json({ error: "Invalid request" }, 400);
  }
});
