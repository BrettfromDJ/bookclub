import type { Badge } from "./types";

/**
 * Genre badge categories. Google Books and Open Library tag books with free-form
 * subjects ("Fiction / Fantasy / Epic", "Detective and mystery stories"), so each
 * category lists the words that map a subject onto it. Earlier entries win, which
 * is why the narrow categories (graphic, ya, poetry) come before the broad ones.
 */
export const GENRE_RULES: { code: string; match: RegExp }[] = [
  { code: "graphic", match: /comic|graphic novel|manga/i },
  { code: "ya", match: /young adult|juvenile fiction|teen/i },
  { code: "poetry", match: /poetry|poems/i },
  { code: "biography", match: /biography|autobiography|memoir/i },
  { code: "selfhelp", match: /self-help|self help|personal growth|motivation/i },
  { code: "scifi", match: /science fiction|sci-fi|dystopia|space opera|cyberpunk/i },
  { code: "fantasy", match: /fantasy|dragons|magic|fairy tales/i },
  { code: "horror", match: /horror|ghost|supernatural|vampire/i },
  { code: "thriller", match: /thriller|suspense|espionage/i },
  { code: "mystery", match: /mystery|detective|crime/i },
  { code: "romance", match: /romance|love stories/i },
  { code: "historical", match: /historical/i },
  { code: "classics", match: /classics|classic literature/i },
  { code: "literary", match: /literary|fiction/i },
  { code: "nonfiction", match: /history|science|business|psychology|philosophy|politics|nonfiction|non-fiction|true crime|essays|cooking|travel/i },
];

/** Picks the genre badge a book counts toward, or null if nothing matches. */
export function badgeCategory(subjects: string[]): string | null {
  const text = subjects.join(" | ");
  return GENRE_RULES.find((rule) => rule.match.test(text))?.code ?? null;
}

/** Mirrors the seed rows in supabase/migrations so demo mode and tests have the catalog. */
export const BADGES: Badge[] = [
  { code: "goal:monthly", kind: "goal", name: "Goal Getter", description: "Hit your monthly reading goal", sort: 1 },
  { code: "club:finisher", kind: "club", name: "Club Member", description: "Finished the monthly book club pick", sort: 2 },
  { code: "genre:fantasy", kind: "genre", name: "Dragon Rider", description: "Finished a fantasy book", sort: 10 },
  { code: "genre:scifi", kind: "genre", name: "Star Charter", description: "Finished a science fiction book", sort: 11 },
  { code: "genre:mystery", kind: "genre", name: "Sleuth", description: "Finished a mystery", sort: 12 },
  { code: "genre:thriller", kind: "genre", name: "Edge of Seat", description: "Finished a thriller", sort: 13 },
  { code: "genre:romance", kind: "genre", name: "Hopeless Romantic", description: "Finished a romance", sort: 14 },
  { code: "genre:horror", kind: "genre", name: "Night Owl", description: "Finished a horror book", sort: 15 },
  { code: "genre:historical", kind: "genre", name: "Time Traveler", description: "Finished historical fiction", sort: 16 },
  { code: "genre:literary", kind: "genre", name: "Deep Reader", description: "Finished literary fiction", sort: 17 },
  { code: "genre:classics", kind: "genre", name: "Old Soul", description: "Finished a classic", sort: 18 },
  { code: "genre:ya", kind: "genre", name: "Forever Young", description: "Finished a young adult book", sort: 19 },
  { code: "genre:nonfiction", kind: "genre", name: "Fact Finder", description: "Finished a nonfiction book", sort: 20 },
  { code: "genre:biography", kind: "genre", name: "Life Story", description: "Finished a biography or memoir", sort: 21 },
  { code: "genre:selfhelp", kind: "genre", name: "Glow Up", description: "Finished a self-help book", sort: 22 },
  { code: "genre:poetry", kind: "genre", name: "Verse Keeper", description: "Finished a poetry collection", sort: 23 },
  { code: "genre:graphic", kind: "genre", name: "Panel Pro", description: "Finished a graphic novel or comic", sort: 24 },
  { code: "milestone:1", kind: "milestone", name: "First Chapter", description: "Finished your first book", sort: 30 },
  { code: "milestone:10", kind: "milestone", name: "Full Card", description: "Filled your first punch card (10 books)", sort: 31 },
  { code: "milestone:25", kind: "milestone", name: "Bookworm", description: "Finished 25 books", sort: 32 },
  { code: "milestone:50", kind: "milestone", name: "Shelf Stacker", description: "Finished 50 books", sort: 33 },
  { code: "milestone:100", kind: "milestone", name: "Centurion", description: "Finished 100 books", sort: 34 },
];

export const badgeByCode = (code: string) => BADGES.find((b) => b.code === code);
