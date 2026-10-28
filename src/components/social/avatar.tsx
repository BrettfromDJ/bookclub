import { cn } from "@/lib/utils";

export function Avatar({ url, name, className }: { url: string | null; name: string; className?: string }) {
  return (
    <span className={cn("flex size-10 shrink-0 items-center justify-center overflow-hidden rounded-full bg-paper-2 font-serif text-ink-soft", className)}>
      {url ? (
        // eslint-disable-next-line @next/next/no-img-element -- user avatar from Supabase Storage
        <img src={url} alt="" className="size-full object-cover" />
      ) : (
        (name[0] ?? "?").toUpperCase()
      )}
    </span>
  );
}
