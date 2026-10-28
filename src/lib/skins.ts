/**
 * Preset profile skins. Each one sets a handful of CSS variables on the
 * profile page only, so the rest of the app keeps the journal look.
 */
export type Skin = {
  id: string;
  name: string;
  vars: {
    "--skin-bg": string;
    "--skin-card": string;
    "--skin-ink": string;
    "--skin-muted": string;
    "--skin-accent": string;
    "--skin-pattern": string;
  };
  /** Font for profile headings. */
  heading: "serif" | "typewriter" | "sans";
};

const none = "none";
const dots = (c: string) => `radial-gradient(${c} 1px, transparent 1px) 0 0 / 14px 14px`;
const stripes = (c: string) => `repeating-linear-gradient(45deg, ${c} 0 2px, transparent 2px 12px)`;

export const SKINS: Skin[] = [
  { id: "library", name: "Library", heading: "serif", vars: { "--skin-bg": "#f4ecdc", "--skin-card": "#fffaf0", "--skin-ink": "#2a241c", "--skin-muted": "#7a6d5a", "--skin-accent": "#a63d2a", "--skin-pattern": none } },
  { id: "midnight", name: "Midnight Reader", heading: "serif", vars: { "--skin-bg": "#141826", "--skin-card": "#1e2336", "--skin-ink": "#ece6d8", "--skin-muted": "#9aa0b8", "--skin-accent": "#e8b84a", "--skin-pattern": dots("rgb(255 255 255 / 0.08)") } },
  { id: "y2k", name: "Y2K Glitter", heading: "sans", vars: { "--skin-bg": "#ffd6f0", "--skin-card": "#ffffff", "--skin-ink": "#3b1046", "--skin-muted": "#9b5aa8", "--skin-accent": "#ff2fa8", "--skin-pattern": dots("rgb(255 47 168 / 0.25)") } },
  { id: "cottage", name: "Cottagecore", heading: "serif", vars: { "--skin-bg": "#e6eddc", "--skin-card": "#fbfaf2", "--skin-ink": "#2f3a26", "--skin-muted": "#6f7d62", "--skin-accent": "#b5654b", "--skin-pattern": none } },
  { id: "darkacademia", name: "Dark Academia", heading: "serif", vars: { "--skin-bg": "#2b221c", "--skin-card": "#3a2e25", "--skin-ink": "#efe3cf", "--skin-muted": "#b8a58a", "--skin-accent": "#c89b5a", "--skin-pattern": stripes("rgb(255 255 255 / 0.03)") } },
  { id: "typewriter", name: "Typewriter", heading: "typewriter", vars: { "--skin-bg": "#ffffff", "--skin-card": "#f6f6f2", "--skin-ink": "#111111", "--skin-muted": "#666666", "--skin-accent": "#d22f27", "--skin-pattern": none } },
  { id: "ocean", name: "Beach Read", heading: "sans", vars: { "--skin-bg": "#cfeef0", "--skin-card": "#fffdf6", "--skin-ink": "#123c4a", "--skin-muted": "#4f7d88", "--skin-accent": "#f08a4b", "--skin-pattern": stripes("rgb(255 255 255 / 0.35)") } },
  { id: "myspace", name: "Top 8 Classic", heading: "sans", vars: { "--skin-bg": "#003399", "--skin-card": "#ffffff", "--skin-ink": "#1a1a1a", "--skin-muted": "#555555", "--skin-accent": "#ff6600", "--skin-pattern": dots("rgb(255 255 255 / 0.15)") } },
];

export const skinById = (id: string | null | undefined) => SKINS.find((s) => s.id === id) ?? SKINS[0];
