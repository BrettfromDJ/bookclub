/** Cloth colours for books without a cover image, and for spines on the goal shelf. */
export const CLOTH_COLORS = ["#2f5d50", "#8c3a2b", "#2b3f5c", "#6b4a2b", "#4a3a5c", "#3f5a2e", "#7a5a1e"] as const;

function hash(text: string): number {
  let h = 0;
  for (let i = 0; i < text.length; i++) h = (h * 31 + text.charCodeAt(i)) >>> 0;
  return h;
}

/** A stable cloth colour for a book, so it looks the same everywhere. */
export function clothColor(title: string): string {
  return CLOTH_COLORS[hash(title) % CLOTH_COLORS.length];
}

/** Stable spine size for the shelf: width in px and height as a % of the shelf. */
export function spineSize(title: string): { width: number; height: number } {
  const h = hash(title);
  return { width: 18 + (h % 9), height: 72 + ((h >>> 4) % 24) };
}
