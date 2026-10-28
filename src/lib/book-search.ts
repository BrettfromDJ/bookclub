import { badgeCategory } from "./badges";
import type { BookCandidate } from "./types";

type GoogleVolume = {
  id: string;
  volumeInfo?: {
    title?: string;
    subtitle?: string;
    authors?: string[];
    pageCount?: number;
    publishedDate?: string;
    categories?: string[];
    imageLinks?: { thumbnail?: string; smallThumbnail?: string };
  };
};

/** A book document from Hardcover's search (a Typesense hit). */
type HardcoverDoc = {
  id: string | number;
  title?: string;
  author_names?: string[];
  image?: { url?: string | null } | null;
  pages?: number | null;
  release_year?: number | null;
  genres?: string[];
};

type OpenLibraryDoc = {
  key: string;
  title?: string;
  author_name?: string[];
  cover_i?: number;
  number_of_pages_median?: number;
  first_publish_year?: number;
  subject?: string[];
};

export function fromGoogle(v: GoogleVolume): BookCandidate | null {
  const info = v.volumeInfo;
  if (!info?.title) return null;
  const cover = info.imageLinks?.thumbnail ?? info.imageLinks?.smallThumbnail;
  const categories = info.categories ?? [];
  return {
    source: "google",
    external_id: v.id,
    title: info.title,
    authors: info.authors ?? [],
    // Google serves http thumbnails with a page curl; https + no curl looks cleaner.
    cover_url: cover ? cover.replace(/^http:/, "https:").replace("&edge=curl", "") : null,
    page_count: info.pageCount ?? null,
    published_year: info.publishedDate ? Number(info.publishedDate.slice(0, 4)) || null : null,
    categories,
    badge_category: badgeCategory(categories),
  };
}

export function fromHardcover(d: HardcoverDoc): BookCandidate | null {
  if (!d.title) return null;
  const genres = d.genres ?? [];
  return {
    source: "hardcover",
    external_id: String(d.id),
    title: d.title,
    authors: d.author_names ?? [],
    cover_url: d.image?.url ?? null,
    page_count: d.pages ?? null,
    published_year: d.release_year ?? null,
    categories: genres,
    badge_category: badgeCategory(genres),
  };
}

const HARDCOVER_SEARCH = `query Search($q: String!) {
  search(query: $q, query_type: "Book", per_page: 20, page: 1) { results }
}`;

/** Hardcover book search. Needs HARDCOVER_API_KEY (server-only); returns [] without it. */
async function searchHardcover(q: string, signal?: AbortSignal): Promise<BookCandidate[]> {
  const key = process.env.HARDCOVER_API_KEY?.trim();
  if (!key) return [];
  const res = await fetch("https://api.hardcover.app/v1/graphql", {
    method: "POST",
    // Hardcover shows the token with "Bearer " already in front; accept it either way.
    headers: { "content-type": "application/json", authorization: key.startsWith("Bearer ") ? key : `Bearer ${key}`, "user-agent": "BookClub/1.0" },
    body: JSON.stringify({ query: HARDCOVER_SEARCH, variables: { q } }),
    signal,
    cache: "no-store",
  });
  if (!res.ok) return [];
  const json = (await res.json()) as { data?: { search?: { results?: { hits?: { document: HardcoverDoc }[] } } } };
  return (json.data?.search?.results?.hits ?? []).map((h) => fromHardcover(h.document)).filter((b): b is BookCandidate => b !== null);
}

export function fromOpenLibrary(d: OpenLibraryDoc): BookCandidate | null {
  if (!d.title) return null;
  const subjects = (d.subject ?? []).slice(0, 12);
  return {
    source: "openlibrary",
    external_id: d.key,
    title: d.title,
    authors: d.author_name ?? [],
    cover_url: d.cover_i ? `https://covers.openlibrary.org/b/id/${d.cover_i}-M.jpg` : null,
    page_count: d.number_of_pages_median ?? null,
    published_year: d.first_publish_year ?? null,
    categories: subjects,
    badge_category: badgeCategory(subjects),
  };
}

/**
 * Searches Hardcover first (better covers), then Google Books, then Open
 * Library, moving on whenever one fails or finds nothing.
 */
export async function searchBooks(query: string, signal?: AbortSignal): Promise<BookCandidate[]> {
  const q = query.trim();
  if (!q) return [];

  try {
    const books = await searchHardcover(q, signal);
    if (books.length) return books;
  } catch {
    // fall through to Google Books
  }

  try {
    const key = process.env.GOOGLE_BOOKS_API_KEY;
    const url = `https://www.googleapis.com/books/v1/volumes?q=${encodeURIComponent(q)}&maxResults=20&printType=books${key ? `&key=${key}` : ""}`;
    const res = await fetch(url, { signal, next: { revalidate: 86400 } });
    if (res.ok) {
      const json = (await res.json()) as { items?: GoogleVolume[] };
      const books = (json.items ?? []).map(fromGoogle).filter((b): b is BookCandidate => b !== null);
      if (books.length) return books;
    }
  } catch {
    // fall through to Open Library
  }

  const fields = "key,title,author_name,cover_i,number_of_pages_median,first_publish_year,subject";
  const res = await fetch(`https://openlibrary.org/search.json?q=${encodeURIComponent(q)}&limit=20&fields=${fields}`, { signal, next: { revalidate: 86400 } });
  if (!res.ok) throw new Error(`Book search failed (${res.status})`);
  const json = (await res.json()) as { docs?: OpenLibraryDoc[] };
  return (json.docs ?? []).map(fromOpenLibrary).filter((b): b is BookCandidate => b !== null);
}
