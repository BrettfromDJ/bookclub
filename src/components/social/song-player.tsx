import { Music } from "lucide-react";
import { songEmbed } from "@/lib/song";

/** Profile song: Spotify or Apple Music's own embedded player (tap to play). */
export function SongPlayer({ url }: { url: string }) {
  const embed = songEmbed(url);
  if (!embed) return null;
  return (
    <section className="mt-6 overflow-hidden rounded-[20px] shadow-sm" style={{ background: "var(--skin-card)" }}>
      <p className="flex items-center gap-1.5 px-4 pt-3 font-type text-[11px] uppercase tracking-[0.14em]" style={{ color: "var(--skin-accent)" }}>
        <Music className="size-3.5" /> Now playing
      </p>
      <iframe
        title="Profile song"
        src={embed.embedUrl}
        height={embed.height}
        className="mt-2 w-full border-0"
        allow="autoplay *; encrypted-media *; clipboard-write"
        sandbox="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox allow-storage-access-by-user-activation"
        loading="lazy"
      />
    </section>
  );
}
