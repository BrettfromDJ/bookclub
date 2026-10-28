export type Format = "physical" | "audio" | "kindle";
export const FORMATS: { id: Format; label: string }[] = [
  { id: "physical", label: "Physical" },
  { id: "audio", label: "Audio" },
  { id: "kindle", label: "Kindle" },
];

export type Book = {
  id: string;
  source: "google" | "openlibrary" | "manual";
  external_id: string;
  title: string;
  authors: string[];
  cover_url: string | null;
  page_count: number | null;
  published_year: number | null;
  categories: string[];
  badge_category: string | null;
};

/** A search result that hasn't been saved to the books table yet. */
export type BookCandidate = Omit<Book, "id">;

export type ShelfStatus = "tbr" | "reading" | "read";

export type UserBook = {
  id: string;
  user_id: string;
  book_id: string;
  status: ShelfStatus;
  formats: Format[];
  position: number;
  started_at: string | null;
  finished_at: string | null;
  rating: number | null;
  book: Book;
};

export type Profile = {
  id: string;
  username: string;
  display_name: string;
  avatar_url: string | null;
  bio: string;
  skin: string;
  song_url: string | null;
  monthly_goal: number;
  is_private: boolean;
  is_admin: boolean;
  created_at: string;
};

export type BadgeKind = "genre" | "goal" | "milestone" | "club";
export type Badge = { code: string; kind: BadgeKind; name: string; description: string; sort: number };
export type EarnedBadge = { badge_code: string; period: string; earned_at: string };

export type ActivityKind = "started" | "finished" | "monthly_pick" | "badge";
export type Activity = {
  id: string;
  user_id: string;
  kind: ActivityKind;
  created_at: string;
  book: Book | null;
  badge_code: string | null;
  profile: Pick<Profile, "username" | "display_name" | "avatar_url">;
  comments: Comment[];
};

export type Comment = {
  id: string;
  user_id: string;
  body: string;
  created_at: string;
  profile: Pick<Profile, "username" | "display_name" | "avatar_url">;
};

export type ClubMonth = {
  month: string;
  blurb: string;
  partner_name: string | null;
  partner_url: string | null;
  partner_logo_url: string | null;
  book: Book;
};
