// Imports messages that were sent from the OneSignal dashboard (to everyone)
// into `admin_broadcasts`, so that every user — including users who sign up or
// log in later — sees them in the in-app notification list as long as the
// message is not deleted from Supabase.
//
// Called every 10 minutes by pg_cron (see migration). Idempotent: rows are
// keyed by the OneSignal notification id, duplicates are ignored.
//
// Uses the same secrets as send-push-notification (PUSH_WEBHOOK_SECRET,
// ONESIGNAL_APP_ID, ONESIGNAL_REST_API_KEY) plus the Supabase-provided
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

// Only messages sent to everybody are imported. Messages aimed at a custom
// segment or a single user stay private to that audience.
const EVERYONE_SEGMENTS = ["Total Subscriptions", "Subscribed Users"];
const MAX_AGE_DAYS = 30;

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const webhookSecret = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
  const appId = Deno.env.get("ONESIGNAL_APP_ID") ?? "";
  const apiKey = Deno.env.get("ONESIGNAL_REST_API_KEY") ?? "";
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!appId || !apiKey || !supabaseUrl || !serviceKey) {
    return json({ error: "Not configured" }, 500);
  }
  if (!webhookSecret ||
      (request.headers.get("x-webhook-secret") ?? "") !== webhookSecret) {
    return json({ error: "Unauthorized" }, 401);
  }

  try {
    // kind=0 -> only messages created from the OneSignal dashboard
    const listRes = await fetch(
      `https://api.onesignal.com/notifications?app_id=${appId}&limit=50&kind=0`,
      { headers: { Authorization: `Key ${apiKey}` } },
    );
    if (!listRes.ok) {
      console.error("OneSignal list failed", listRes.status);
      return json({ error: "OneSignal list failed" }, 502);
    }
    const list = await listRes.json();
    const nowSec = Math.floor(Date.now() / 1000);
    const minSec = nowSec - MAX_AGE_DAYS * 86400;

    // deno-lint-ignore no-explicit-any
    const rows = ((list.notifications ?? []) as any[])
      .filter((n) => {
        if (n.canceled) return false;
        if (!n.id) return false;
        const queuedAt = Number(n.queued_at ?? 0);
        const sendAfter = Number(n.send_after ?? queuedAt);
        if (queuedAt < minSec) return false; // too old
        if (sendAfter > nowSec) return false; // scheduled, not sent yet
        const segs: string[] = Array.isArray(n.included_segments)
          ? n.included_segments
          : [];
        if (!segs.some((s) => EVERYONE_SEGMENTS.includes(s))) return false;
        if (n.include_aliases || n.include_player_ids ||
            n.include_external_user_ids || n.filters) return false;
        const text = n.contents?.en ?? Object.values(n.contents ?? {})[0];
        return Boolean(text);
      })
      .map((n) => ({
        title: String(
          n.headings?.en ?? Object.values(n.headings ?? {})[0] ?? "Homaclo",
        ),
        body: String(n.contents?.en ?? Object.values(n.contents ?? {})[0]),
        onesignal_id: n.id,
        created_at: new Date(Number(n.queued_at) * 1000).toISOString(),
      }));

    if (rows.length === 0) {
      return json({ success: true, imported: 0 });
    }

    const insertRes = await fetch(
      `${supabaseUrl}/rest/v1/admin_broadcasts?on_conflict=onesignal_id`,
      {
        method: "POST",
        headers: {
          apikey: serviceKey,
          Authorization: `Bearer ${serviceKey}`,
          "Content-Type": "application/json",
          Prefer: "resolution=ignore-duplicates,return=representation",
        },
        body: JSON.stringify(rows),
      },
    );
    if (!insertRes.ok) {
      console.error("insert failed", insertRes.status, await insertRes.text());
      return json({ error: "Insert failed" }, 500);
    }
    const inserted = await insertRes.json();
    return json({ success: true, seen: rows.length, imported: inserted.length });
  } catch (error) {
    console.error("sync-onesignal-messages error", error);
    return json({ error: "Sync failed" }, 500);
  }
});
