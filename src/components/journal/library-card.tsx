import { UserRound } from "lucide-react";
import type { Profile } from "@/lib/types";

/** Library card with the reader's photo and a due-date style stamp. */
export function LibraryCard({ profile, totalRead }: { profile: Profile; totalRead: number }) {
  const since = new Date(profile.created_at).toLocaleDateString("en-US", { month: "short", year: "numeric" });
  // Stable 10-digit card number derived from the user id.
  const digits = [...profile.id].map((c) => c.charCodeAt(0) % 10).join("").slice(-10).padStart(10, "7");
  const cardNo = `${digits.slice(0, 4)} ${digits.slice(4, 7)} ${digits.slice(7)}`;
  return (
    <section className="paper relative overflow-hidden p-5">
      <div className="absolute inset-x-0 top-0 h-2 bg-stamp" />
      <p className="label mt-1">Book Club Public Library</p>
      <div className="mt-4 flex gap-4">
        <div className="size-24 shrink-0 overflow-hidden rounded-md border-4 border-white bg-paper-2 shadow-sm">
          {profile.avatar_url ? (
            // eslint-disable-next-line @next/next/no-img-element -- user-uploaded avatar from Supabase Storage
            <img src={profile.avatar_url} alt="" className="size-full object-cover" />
          ) : (
            <UserRound className="m-auto mt-5 size-12 text-muted" strokeWidth={1.2} />
          )}
        </div>
        <dl className="min-w-0 flex-1 space-y-1.5 font-type text-[12px]">
          <Row k="Name" v={profile.display_name || profile.username} />
          <Row k="Card no." v={cardNo} />
          <Row k="Member" v={since} />
          <Row k="Books" v={String(totalRead)} />
        </dl>
      </div>
      <div className="pointer-events-none absolute bottom-3 right-4 rotate-[-8deg] rounded border-2 border-stamp/70 px-2 py-0.5 font-type text-[11px] font-bold uppercase tracking-widest text-stamp/80">
        @{profile.username}
      </div>
    </section>
  );
}

function Row({ k, v }: { k: string; v: string }) {
  return (
    <div className="flex gap-2 border-b border-dotted border-line-strong pb-1">
      <dt className="w-16 shrink-0 text-muted">{k}</dt>
      <dd className="truncate">{v}</dd>
    </div>
  );
}
