import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const DEEPSEEK_URL = "https://api.deepseek.com/v1/chat/completions";
const DEEPSEEK_MODEL = "deepseek-chat";
const VALID_CATEGORIES = new Set(["landmark", "food", "experience", "hidden"]);

type ChecklistItemPayload = {
  attraction_id?: number;
  title: string;
  location: string;
  category: string;
  sort_order?: number;
  is_free?: boolean;
  source?: string;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const deepSeekApiKey = Deno.env.get("DEEPSEEK_API_KEY");

    if (!supabaseUrl || !supabaseAnonKey || !deepSeekApiKey) {
      return jsonResponse(
        { error: "Missing Supabase or DeepSeek function secrets" },
        500,
      );
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing Authorization header" }, 401);
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return jsonResponse({ error: "Invalid Supabase session" }, 401);
    }

    const body = await req.json();
    const city = normalizeString(body?.city);
    const country = normalizeString(body?.country);
    const language = normalizeString(body?.language) ?? "en";
    const cityId = normalizeInteger(body?.city_id);

    if (!city || !country) {
      return jsonResponse({ error: "city and country are required" }, 400);
    }

    const prompt = generateChecklistPrompt(city, country, language);
    const deepSeekResponse = await fetch(DEEPSEEK_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${deepSeekApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: DEEPSEEK_MODEL,
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
        max_tokens: 2048,
      }),
    });

    const deepSeekBody = await deepSeekResponse.json().catch(() => null);
    if (!deepSeekResponse.ok) {
      return jsonResponse(
        {
          error:
            deepSeekBody?.error?.message ??
            `DeepSeek request failed: ${deepSeekResponse.status}`,
        },
        502,
      );
    }

    const content = deepSeekBody?.choices?.[0]?.message?.content;
    if (typeof content !== "string") {
      return jsonResponse({ error: "DeepSeek response is missing content" }, 502);
    }

    const jsonText = extractJson(content);
    if (!jsonText) {
      return jsonResponse({ error: "Failed to parse DeepSeek JSON response" }, 502);
    }

    const parsed = JSON.parse(jsonText);
    const items = validateItems(parsed?.items);
    if (items.length === 0) {
      return jsonResponse({ error: "DeepSeek returned no valid checklist items" }, 502);
    }

    const itemsWithAccess = markFreeItems(items);
    const savedItems = cityId && supabaseServiceRoleKey
      ? await saveAttractions({
        supabaseUrl,
        supabaseServiceRoleKey,
        cityId,
        language,
        items: itemsWithAccess,
      })
      : itemsWithAccess;

    return jsonResponse({ items: savedItems });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ error: message }, 500);
  }
});

function generateChecklistPrompt(
  city: string,
  country: string,
  language: string,
): string {
  const lang = language === "zh" ? "Chinese" : "English";

  return `
You are a local travel expert. Generate a list of must-do things in ${city}, ${country}.

Include following categories:
- Famous landmarks/attractions
- Local food/dishes to try
- Cultural experiences
- Hidden gems/secret spots (lesser-known, authentic local places)

Requirements:
- Generate as many items as appropriate for the city (not all cities have the same number of attractions)
- Each title: maximum 8 words
- Each location: specific name of the place
- Make it exciting and actionable
- Avoid overly touristy traps when possible
- Mix of free and paid activities
- Only include REAL attractions that actually exist in this city

Language: ${lang}

Output ONLY valid JSON in this exact format:
{
  "items": [
    {"title": "Visit the Eiffel Tower", "location": "Eiffel Tower", "category": "landmark"},
    {"title": "Try authentic croissants", "location": "Du Pain et des Idées", "category": "food"},
    {"title": "Take a Seine river cruise", "location": "Seine River", "category": "experience"},
    {"title": "Explore covered passages", "location": "Passages couverts", "category": "hidden"}
  ]
}

Return as many items as are genuinely relevant for this city.
`;
}

function extractJson(text: string): string | null {
  const match = text.match(/\{[\s\S]*\}/);
  return match?.[0] ?? null;
}

function validateItems(items: unknown): ChecklistItemPayload[] {
  if (!Array.isArray(items)) return [];

  return items.flatMap((item, index) => {
    if (!item || typeof item !== "object") return [];

    const record = item as Record<string, unknown>;
    const title = normalizeString(record.title);
    const location = normalizeString(record.location);
    const category = normalizeString(record.category);

    if (!title || !location || !category || !VALID_CATEGORIES.has(category)) {
      return [];
    }

    return [{ title, location, category, sort_order: index }];
  });
}

function markFreeItems(items: ChecklistItemPayload[]): ChecklistItemPayload[] {
  const freeItemsPerCategory = 1;
  const categoryCount = new Map<string, number>();

  return items.map((item, index) => {
    const count = categoryCount.get(item.category) ?? 0;
    categoryCount.set(item.category, count + 1);

    return {
      ...item,
      sort_order: item.sort_order ?? index,
      is_free: count < freeItemsPerCategory,
      source: "official",
    };
  });
}

async function saveAttractions({
  supabaseUrl,
  supabaseServiceRoleKey,
  cityId,
  language,
  items,
}: {
  supabaseUrl: string;
  supabaseServiceRoleKey: string;
  cityId: number;
  language: string;
  items: ChecklistItemPayload[];
}): Promise<ChecklistItemPayload[]> {
  const serviceClient = createClient(supabaseUrl, supabaseServiceRoleKey);

  const { data: existing, error: existingError } = await serviceClient
    .from("attractions")
    .select("id,title,location,category,sort_order,is_free")
    .eq("city_id", cityId)
    .eq("language", language)
    .eq("is_active", true)
    .order("sort_order", { ascending: true });

  if (existingError) throw existingError;

  if (existing && existing.length > 0) {
    return existing.map((item) => ({
      attraction_id: item.id,
      title: item.title,
      location: item.location,
      category: item.category,
      sort_order: item.sort_order ?? 0,
      is_free: item.is_free ?? false,
      source: "official",
    }));
  }

  const rows = items.map((item, index) => ({
    city_id: cityId,
    title: item.title,
    location: item.location,
    category: item.category,
    language,
    is_active: true,
    is_free: item.is_free ?? false,
    sort_order: item.sort_order ?? index,
  }));

  const { data: inserted, error: insertError } = await serviceClient
    .from("attractions")
    .insert(rows)
    .select("id,title,location,category,sort_order,is_free");

  if (insertError) throw insertError;

  return (inserted ?? []).map((item) => ({
    attraction_id: item.id,
    title: item.title,
    location: item.location,
    category: item.category,
    sort_order: item.sort_order ?? 0,
    is_free: item.is_free ?? false,
    source: "official",
  }));
}

function normalizeString(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function normalizeInteger(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isInteger(value) && value > 0) {
    return value;
  }

  if (typeof value !== "string") return undefined;
  const parsed = Number.parseInt(value, 10);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : undefined;
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
