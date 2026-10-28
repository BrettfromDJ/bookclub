export type SongEmbed = { provider: "spotify" | "apple"; embedUrl: string; height: number };

/**
 * Turns a pasted Spotify or Apple Music track link into an embeddable player URL.
 * Anything else returns null so arbitrary URLs never end up in an iframe.
 */
export function songEmbed(raw: string | null | undefined): SongEmbed | null {
  if (!raw) return null;
  let url: URL;
  try {
    url = new URL(raw.trim());
  } catch {
    return null;
  }
  if (url.protocol !== "https:") return null;

  if (url.hostname === "open.spotify.com") {
    // /track/<id> or /intl-xx/track/<id>
    const m = url.pathname.match(/^(?:\/intl-[a-z-]+)?\/track\/([A-Za-z0-9]{10,40})\/?$/);
    return m ? { provider: "spotify", embedUrl: `https://open.spotify.com/embed/track/${m[1]}`, height: 80 } : null;
  }

  if (url.hostname === "music.apple.com") {
    // /<country>/album/<slug>/<albumId>?i=<trackId> or /<country>/song/<slug>/<trackId>
    const album = url.pathname.match(/^\/([a-z]{2})\/album\/[^/]+\/(\d+)\/?$/);
    const track = url.searchParams.get("i");
    if (album && track && /^\d+$/.test(track)) {
      return { provider: "apple", embedUrl: `https://embed.music.apple.com/${album[1]}/album/x/${album[2]}?i=${track}`, height: 175 };
    }
    const song = url.pathname.match(/^\/([a-z]{2})\/song\/[^/]+\/(\d+)\/?$/);
    if (song) return { provider: "apple", embedUrl: `https://embed.music.apple.com/${song[1]}/song/x/${song[2]}`, height: 175 };
    return null;
  }
  return null;
}
