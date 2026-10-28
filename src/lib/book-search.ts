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

/** Searches Google Books, falling back to Open Library if Google fails or finds nothing. */
export async function searchBooks(query: string, signal?: AbortSignal): Promise<BookCandidate[]> {
  const q = query.trim();
  if (!q) return [];

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
