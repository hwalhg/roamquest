import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceRoleKey) {
      return jsonResponse({ error: "Missing Supabase function secrets" }, 500);
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing Authorization header" }, 401);
    }

    const body = await req.json().catch(() => ({}));
    if (body?.confirm !== true) {
      return jsonResponse({ error: "Deletion confirmation is required" }, 400);
    }

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return jsonResponse({ error: "Invalid Supabase session" }, 401);
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    const checklistIds = await loadChecklistIds(adminClient, user.id);
    const photoPaths = checklistIds.length > 0
      ? await loadPhotoPaths(adminClient, checklistIds, supabaseUrl)
      : [];

    if (photoPaths.length > 0) {
      const { error: storageError } = await adminClient.storage
        .from("photos")
        .remove(photoPaths);

      if (storageError) {
        console.warn("Failed to delete some account photos", storageError);
      }
    }

    if (checklistIds.length > 0) {
      const { error: checklistError } = await adminClient
        .from("checklists")
        .delete()
        .eq("user_id", user.id);

      if (checklistError) throw checklistError;
    }

    const { error: subscriptionError } = await adminClient
      .from("subscriptions")
      .delete()
      .eq("user_id", user.id);

    if (subscriptionError) throw subscriptionError;

    const { error: profileError } = await adminClient
      .from("profiles")
      .delete()
      .or(`id.eq.${user.id},user_id.eq.${user.id}`);

    if (profileError) throw profileError;

    const { error: deleteUserError } = await adminClient.auth.admin.deleteUser(
      user.id,
      false,
    );

    if (deleteUserError) throw deleteUserError;

    return jsonResponse({
      deleted: true,
      deleted_photo_count: photoPaths.length,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ deleted: false, error: message }, 500);
  }
});

async function loadChecklistIds(
  adminClient: ReturnType<typeof createClient>,
  userId: string,
): Promise<string[]> {
  const { data, error } = await adminClient
    .from("checklists")
    .select("id")
    .eq("user_id", userId);

  if (error) throw error;

  return (data ?? [])
    .map((row) => row.id)
    .filter((id): id is string => typeof id === "string");
}

async function loadPhotoPaths(
  adminClient: ReturnType<typeof createClient>,
  checklistIds: string[],
  supabaseUrl: string,
): Promise<string[]> {
  const { data, error } = await adminClient
    .from("checklist_items")
    .select("checkin_photo_url")
    .in("checklist_id", checklistIds)
    .not("checkin_photo_url", "is", null);

  if (error) throw error;

  const paths = new Set<string>();
  for (const row of data ?? []) {
    const path = extractStoragePath(row.checkin_photo_url, supabaseUrl);
    if (path) paths.add(path);
  }

  return Array.from(paths);
}

function extractStoragePath(url: unknown, supabaseUrl: string): string | null {
  if (typeof url !== "string" || url.length === 0) return null;

  const marker = "/storage/v1/object/public/photos/";
  const markerIndex = url.indexOf(marker);
  if (markerIndex >= 0) {
    return decodeURIComponent(url.slice(markerIndex + marker.length));
  }

  const publicPrefix = `${supabaseUrl}/storage/v1/object/public/photos/`;
  if (url.startsWith(publicPrefix)) {
    return decodeURIComponent(url.slice(publicPrefix.length));
  }

  return null;
}

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
