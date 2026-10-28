import type { Activity, Book, ClubMonth, EarnedBadge, Profile, UserBook } from "./types";
import { monthStart } from "./month";

/** Sample data shown when Supabase isn't configured, so every screen can be previewed. */
const book = (id: string, title: string, author: string, olCover: number, badge: string | null, year: number): Book => ({
  id,
  source: "openlibrary",
  external_id: `/works/${id}`,
  title,
  authors: [author],
  cover_url: `https://covers.openlibrary.org/b/id/${olCover}-M.jpg`,
  page_count: null,
  published_year: year,
  categories: [],
  badge_category: badge,
});

export const DEMO_BOOKS = {
  piranesi: book("demo-piranesi", "Piranesi", "Susanna Clarke", 10520611, "fantasy", 2020),
  dune: book("demo-dune", "Dune", "Frank Herbert", 11481354, "scifi", 1965),
  rebecca: book("demo-rebecca", "Rebecca", "Daphne du Maurier", 8231994, "mystery", 1938),
  circe: book("demo-circe", "Circe", "Madeline Miller", 8406786, "fantasy", 2018),
  educated: book("demo-educated", "Educated", "Tara Westover", 8314135, "biography", 2018),
  emma: book("demo-emma", "Emma", "Jane Austen", 9278292, "classics", 1815),
  martian: book("demo-martian", "The Martian", "Andy Weir", 11169086, "scifi", 2011),
  secret: book("demo-secret", "The Secret History", "Donna Tartt", 744854, "literary", 1992),
  hailmary: book("demo-hailmary", "Project Hail Mary", "Andy Weir", 10594763, "scifi", 2021),
  tomorrow: book("demo-tomorrow", "Tomorrow, and Tomorrow, and Tomorrow", "Gabrielle Zevin", 12873546, "literary", 2022),
};

export const DEMO_PROFILE: Profile = {
  id: "demo-user",
  username: "demo_reader",
  display_name: "Demo Reader",
  avatar_url: null,
  bio: "Coffee, cardigans and one more chapter.",
  skin: "library",
  song_url: "https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC",
  monthly_goal: 4,
  is_private: false,
  is_admin: true,
  created_at: "2026-01-04T12:00:00Z",
  card_printed_at: "2026-01-04T12:00:00Z",
};

const ub = (b: Book, status: UserBook["status"], position: number, formats: UserBook["formats"], finished_at: string | null = null): UserBook => ({
  id: `ub-${b.id}`,
  user_id: DEMO_PROFILE.id,
  book_id: b.id,
  status,
  formats,
  position,
  started_at: null,
  finished_at,
  rating: finished_at ? 5 : null,
  book: b,
});

const m = monthStart();
const thisMonth = (day: number) => `${m.slice(0, 8)}${String(day).padStart(2, "0")}`;

export const DEMO_SHELF: UserBook[] = [
  ub(DEMO_BOOKS.hailmary, "reading", 0, ["audio"]),
  ub(DEMO_BOOKS.tomorrow, "tbr", 0, ["kindle"]),
  ub(DEMO_BOOKS.secret, "tbr", 1, ["physical"]),
  ub(DEMO_BOOKS.martian, "tbr", 2, ["audio", "kindle"]),
  ub(DEMO_BOOKS.emma, "tbr", 3, ["physical"]),
  ub(DEMO_BOOKS.piranesi, "read", 0, ["physical"], thisMonth(3)),
  ub(DEMO_BOOKS.circe, "read", 0, ["audio"], thisMonth(12)),
  ub(DEMO_BOOKS.dune, "read", 0, ["kindle"], "2026-09-20"),
  ub(DEMO_BOOKS.rebecca, "read", 0, ["physical"], "2026-09-08"),
  ub(DEMO_BOOKS.educated, "read", 0, ["audio"], "2026-08-15"),
];

export const DEMO_BADGES: EarnedBadge[] = [
  { badge_code: "milestone:1", period: "", earned_at: "2026-08-15T00:00:00Z" },
  { badge_code: "genre:biography", period: "", earned_at: "2026-08-15T00:00:00Z" },
  { badge_code: "genre:mystery", period: "", earned_at: "2026-09-08T00:00:00Z" },
  { badge_code: "genre:scifi", period: "", earned_at: "2026-09-20T00:00:00Z" },
  { badge_code: "genre:fantasy", period: "", earned_at: thisMonth(3) + "T00:00:00Z" },
  { badge_code: "club:finisher", period: "2026-09", earned_at: "2026-09-20T00:00:00Z" },
];

export const DEMO_TOP_EIGHT: (Book | null)[] = [DEMO_BOOKS.piranesi, DEMO_BOOKS.circe, DEMO_BOOKS.dune, DEMO_BOOKS.secret, DEMO_BOOKS.rebecca, DEMO_BOOKS.educated, null, null];

export const DEMO_MONTHLY_PICKS = [
  { month: "2026-09-01", book: DEMO_BOOKS.dune, note: "The spice must flow." },
  { month: "2026-08-01", book: DEMO_BOOKS.educated, note: "" },
];

export const DEMO_CLUB: ClubMonth = {
  month: m,
  book: DEMO_BOOKS.piranesi,
  blurb: "A man lives alone in a house of endless halls and tides. Read along with everyone this month.",
  partner_name: null,
  partner_url: null,
  partner_logo_url: null,
};

const friend = (username: string, display_name: string) => ({ username, display_name, avatar_url: null });

export const DEMO_FEED: Activity[] = [
  {
    id: "a1",
    user_id: "f1",
    kind: "finished",
    created_at: new Date(Date.now() - 2 * 3600e3).toISOString(),
    book: DEMO_BOOKS.circe,
    badge_code: null,
    profile: friend("marisol_reads", "Marisol"),
    comments: [{ id: "c1", user_id: "demo-user", body: "The witch of Aiaia!! What did you think of the ending?", created_at: new Date(Date.now() - 3600e3).toISOString(), profile: friend("demo_reader", "Demo Reader") }],
  },
  { id: "a2", user_id: "f2", kind: "badge", created_at: new Date(Date.now() - 26 * 3600e3).toISOString(), book: null, badge_code: "goal:monthly", profile: friend("jules", "Jules"), comments: [] },
  { id: "a3", user_id: "f3", kind: "started", created_at: new Date(Date.now() - 50 * 3600e3).toISOString(), book: DEMO_BOOKS.piranesi, badge_code: null, profile: friend("theo_pages", "Theo"), comments: [] },
];
