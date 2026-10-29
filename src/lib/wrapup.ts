import { DEMO_BOOKS } from "./demo";
import type { Book, UserBook } from "./types";

/** Everything printed on a monthly wrap-up receipt. */
export type Wrapup = {
  month: string; // YYYY-MM-01
  books: { book: Book; rating: number | null }[];
  favorite: Book | null;
  pagesRead: number | null;
  averageRating: number | null;
};

const MONTH = /^\d{4}-(0[1-9]|1[0-2])$/;

/** "2026-09" from a query string, or null if it isn't a real month. */
export function parseMonth(value: string | undefined): string | null {
  return value && MONTH.test(value) ? `${value}-01` : null;
}

/** The month before `month` (both YYYY-MM-01). */
export function previousMonth(month: string): string {
  const [y, m] = month.split("-").map(Number);
  const d = new Date(y, m - 2, 1);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-01`;
}

export function buildWrapup(month: string, shelf: UserBook[], pick: Book | null): Wrapup {
  const next = nextMonth(month);
  const read = shelf
    .filter((b) => b.status === "read" && b.finished_at && b.finished_at >= month && b.finished_at < next)
    .sort((a, b) => a.finished_at!.localeCompare(b.finished_at!));
  const rated = read.filter((b) => b.rating != null);
  const pages = read.map((b) => b.book.page_count).filter((p): p is number => p != null);
  const topRated = [...rated].sort((a, b) => b.rating! - a.rating!)[0]?.book ?? null;
  return {
    month,
    books: read.map((b) => ({ book: b.book, rating: b.rating })),
    favorite: pick ?? topRated,
    pagesRead: pages.length ? pages.reduce((a, b) => a + b, 0) : null,
    averageRating: rated.length ? Math.round((rated.reduce((a, b) => a + b.rating!, 0) / rated.length) * 10) / 10 : null,
  };
}

function nextMonth(month: string): string {
  const [y, m] = month.split("-").map(Number);
  const d = new Date(y, m, 1);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-01`;
}

/** A full sample month, for previewing the receipt without any reading history. */
export function sampleWrapup(month: string): Wrapup {
  const books = [
    { book: { ...DEMO_BOOKS.piranesi, page_count: 272 }, rating: 5 },
    { book: { ...DEMO_BOOKS.rebecca, page_count: 410 }, rating: 4 },
    { book: { ...DEMO_BOOKS.circe, page_count: 393 }, rating: 4 },
    { book: { ...DEMO_BOOKS.dune, page_count: 617 }, rating: 3 },
    { book: { ...DEMO_BOOKS.educated, page_count: 334 }, rating: 4 },
  ];
  return { month, books, favorite: books[0].book, pagesRead: 2026, averageRating: 4 };
}
