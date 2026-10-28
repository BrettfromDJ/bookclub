import { describe, expect, it } from "vitest";
import { badgeCategory } from "./badges";
import { fromGoogle, fromHardcover, fromOpenLibrary } from "./book-search";
import { punchCard } from "./punch-card";
import { positionAt, positionBetween } from "./ranking";
import { skinById } from "./skins";
import { songEmbed } from "./song";

describe("punchCard", () => {
  it("starts empty", () => expect(punchCard(0)).toMatchObject({ cardNumber: 1, punched: 0, completedCards: 0, toNextCard: 10 }));
  it("punches a hole per book", () => expect(punchCard(3)).toMatchObject({ cardNumber: 1, punched: 3, toNextCard: 7 }));
  it("shows a just-filled card full", () => expect(punchCard(10)).toMatchObject({ cardNumber: 1, punched: 10, completedCards: 1 }));
  it("starts a new card on the next book", () => expect(punchCard(11)).toMatchObject({ cardNumber: 2, punched: 1, completedCards: 1 }));
});

describe("badgeCategory", () => {
  it.each([
    [["Fiction / Fantasy / Epic"], "fantasy"],
    [["Fiction / Science Fiction / Space Opera"], "scifi"],
    [["Detective and mystery stories"], "mystery"],
    [["Young Adult Fiction / Fantasy"], "ya"],
    [["Comics & Graphic Novels / Manga"], "graphic"],
    [["Biography & Autobiography / Personal Memoirs"], "biography"],
    [["Fiction / Literary"], "literary"],
    [["History / Europe"], "nonfiction"],
  ])("%j → %s", (subjects, code) => expect(badgeCategory(subjects)).toBe(code));
  it("returns null for unknown subjects", () => expect(badgeCategory(["Juvenile Nonsense"])).toBeNull());
});

describe("songEmbed", () => {
  it("embeds Spotify tracks", () =>
    expect(songEmbed("https://open.spotify.com/intl-de/track/4uLU6hMCjMI75M1A2tKUQC?si=abc")?.embedUrl).toBe(
      "https://open.spotify.com/embed/track/4uLU6hMCjMI75M1A2tKUQC",
    ));
  it("embeds Apple Music album tracks", () =>
    expect(songEmbed("https://music.apple.com/us/album/blank-space/1440935467?i=1440935808")?.embedUrl).toBe(
      "https://embed.music.apple.com/us/album/x/1440935467?i=1440935808",
    ));
  it("rejects other sites and non-https", () => {
    expect(songEmbed("https://evil.example/track/123")).toBeNull();
    expect(songEmbed("http://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC")).toBeNull();
    expect(songEmbed("not a url")).toBeNull();
    expect(songEmbed("https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M")).toBeNull();
  });
});

describe("ranking", () => {
  it("places between neighbours", () => expect(positionBetween(1, 2)).toBe(1.5));
  it("handles the ends", () => {
    expect(positionBetween(undefined, 5)).toBe(4);
    expect(positionBetween(5, undefined)).toBe(6);
    expect(positionBetween(undefined, undefined)).toBe(0);
  });
  it("computes a drop index", () => expect(positionAt([{ position: 0 }, { position: 1 }], 1)).toBe(0.5));
});

describe("book normalizers", () => {
  it("maps Google volumes", () => {
    const b = fromGoogle({
      id: "abc",
      volumeInfo: { title: "Dune", authors: ["Frank Herbert"], publishedDate: "1965-08-01", categories: ["Fiction / Science Fiction"], imageLinks: { thumbnail: "http://books.google.com/x?id=1&edge=curl" } },
    });
    expect(b).toMatchObject({ source: "google", title: "Dune", published_year: 1965, badge_category: "scifi", cover_url: "https://books.google.com/x?id=1" });
  });
  it("maps Open Library docs", () => {
    const b = fromOpenLibrary({ key: "/works/OL1W", title: "Emma", author_name: ["Jane Austen"], cover_i: 42, subject: ["Classics", "Romance"] });
    expect(b).toMatchObject({ source: "openlibrary", cover_url: "https://covers.openlibrary.org/b/id/42-M.jpg", badge_category: "romance" });
  });
  it("maps Hardcover documents", () => {
    const b = fromHardcover({ id: 312460, title: "Dune", author_names: ["Frank Herbert"], image: { url: "https://assets.hardcover.app/x.jpg" }, pages: 412, release_year: 1965, genres: ["Science fiction"] });
    expect(b).toMatchObject({ source: "hardcover", external_id: "312460", cover_url: "https://assets.hardcover.app/x.jpg", page_count: 412, published_year: 1965, badge_category: "scifi" });
  });
  it("skips untitled results", () => {
    expect(fromGoogle({ id: "x" })).toBeNull();
    expect(fromHardcover({ id: 1 })).toBeNull();
  });
});

it("falls back to the default skin", () => expect(skinById("nope").id).toBe("library"));
