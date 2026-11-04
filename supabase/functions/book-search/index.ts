// Book search for the Plot Twist iPhone app, backed by Hardcover.
//
// Runs on Supabase so the Hardcover token stays on the server: it's a personal
// access token for your Hardcover account and must never ship inside the app.
// Set it once with:  Supabase dashboard → Edge Functions → Secrets → HARDCOVER_API_KEY
//
// GET /functions/v1/book-search?q=silent%20shadows
// → { results: BookCandidate[] }  (same shape the app's BookCandidate decodes)

const HARDCOVER_URL = "https://api.hardcover.app/v1/graphql";
const SEARCH = `query Search($q: String!) {
  search(query: $q, query_type: "Book", per_page: 25, page: 1) { results }
}`;

type HardcoverDoc = {
  id: string | number;
  title?: string;
  author_names?: string[];
  image?: { url?: string | null } | null;
  pages?: number | null;
  release_year?: number | null;
  genres?: string[];
};

const cors = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, apikey, content-type, x-client-info",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "content-type": "application/json" } });
}

/** Hardcover stores some names with extra spaces ("Katie   West"). */
const tidy = (s: string) => s.replace(/\s+/g, " ").trim();

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });

  const q = (new URL(req.url).searchParams.get("q") ?? "").trim();
  if (q.length < 2) return json({ results: [] });

  const raw = Deno.env.get("HARDCOVER_API_KEY")?.trim();
  if (!raw) {
    console.error("HARDCOVER_API_KEY is not set");
    return json({ results: [], error: "Hardcover isn't set up yet" }, 500);
  }
  // Hardcover shows tokens with "Bearer " in front; accept them either way.
  const authorization = raw.startsWith("Bearer ") ? raw : `Bearer ${raw}`;

  const res = await fetch(HARDCOVER_URL, {
    method: "POST",
    headers: { "content-type": "application/json", authorization, "user-agent": "PlotTwist/1.0" },
    body: JSON.stringify({ query: SEARCH, variables: { q } }),
  });
  if (!res.ok) {
    // Logged so an expired token shows up in the function's logs instead of books silently going missing.
    console.error(`Hardcover search failed: ${res.status} ${await res.text()}`);
    return json({ results: [], error: `Hardcover search failed (${res.status})` }, 502);
  }

  const body = (await res.json()) as { data?: { search?: { results?: { hits?: { document: HardcoverDoc }[] } } } };
  const results = (body.data?.search?.results?.hits ?? [])
    .map((h) => h.document)
    .filter((d) => d.title)
    .map((d) => ({
      source: "hardcover",
      external_id: String(d.id),
      title: tidy(d.title!),
      authors: (d.author_names ?? []).map(tidy),
      cover_url: d.image?.url ?? null,
      page_count: d.pages ?? null,
      published_year: d.release_year ?? null,
      categories: d.genres ?? [],
      badge_category: null, // the app works this out from the genres
    }));

  return json({ results });
});
