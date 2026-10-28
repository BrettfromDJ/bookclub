"use client";

import * as Switch from "@radix-ui/react-switch";
import { Bell, Camera, Check, Loader2, Plus, X } from "lucide-react";
import Link from "next/link";
import { useRef, useState, useTransition } from "react";
import { toast } from "sonner";
import { deleteAccount, setTopBook, signOut, updateProfile, type ProfilePatch } from "@/app/actions";
import { BookSearch } from "@/components/books/book-search";
import { Cover } from "@/components/books/cover";
import { SectionTitle } from "@/components/shell/page";
import { Avatar } from "@/components/social/avatar";
import { Button } from "@/components/ui/button";
import { Input, Textarea } from "@/components/ui/input";
import { isNative, registerForPush } from "@/lib/native";
import { SKINS } from "@/lib/skins";
import { songEmbed } from "@/lib/song";
import { getBrowserSupabase } from "@/lib/supabase/client";
import type { Book, Profile } from "@/lib/types";
import { cn } from "@/lib/utils";

export function SettingsForm({ profile, topEight, demo }: { profile: Profile; topEight: (Book | null)[]; demo: boolean }) {
  const [form, setForm] = useState({
    username: profile.username,
    display_name: profile.display_name,
    bio: profile.bio,
    song_url: profile.song_url ?? "",
    monthly_goal: profile.monthly_goal,
  });
  const [skin, setSkin] = useState(profile.skin);
  const [isPrivate, setPrivate] = useState(profile.is_private);
  const [avatar, setAvatar] = useState(profile.avatar_url);
  const [slots, setSlots] = useState(topEight);
  const [pickingSlot, setPickingSlot] = useState<number | null>(null);
  const [saving, startSave] = useTransition();
  const [, start] = useTransition();
  const fileRef = useRef<HTMLInputElement>(null);

  const save = (patch: ProfilePatch, message = "Saved") =>
    start(async () => {
      const res = await updateProfile(patch);
      toast(res.ok ? message : res.error);
    });

  const uploadAvatar = async (file: File) => {
    const supabase = getBrowserSupabase();
    if (!supabase) return toast("Demo mode — connect Supabase to upload photos.");
    const path = `${profile.id}/avatar`;
    const { error } = await supabase.storage.from("avatars").upload(path, file, { upsert: true, contentType: file.type });
    if (error) return toast(error.message);
    // Cache-bust so the new photo shows right away.
    const url = `${supabase.storage.from("avatars").getPublicUrl(path).data.publicUrl}?v=${Date.now()}`;
    setAvatar(url);
    save({ avatar_url: url }, "Photo updated");
  };

  const songOk = !form.song_url || songEmbed(form.song_url);

  return (
    <div>
      <div className="flex items-center gap-4">
        <button onClick={() => fileRef.current?.click()} className="relative" aria-label="Change photo">
          <Avatar url={avatar} name={form.display_name || form.username} className="size-20 text-3xl" />
          <span className="absolute -bottom-1 -right-1 flex size-8 items-center justify-center rounded-full bg-ink text-paper">
            <Camera className="size-4" />
          </span>
        </button>
        <input ref={fileRef} type="file" accept="image/*" hidden onChange={(e) => e.target.files?.[0] && uploadAvatar(e.target.files[0])} />
        <p className="text-[14px] text-muted">Your photo goes on your library card and profile.</p>
      </div>

      <SectionTitle>About you</SectionTitle>
      <form
        className="paper space-y-3 p-4"
        onSubmit={(e) => {
          e.preventDefault();
          if (!songOk) return toast("Paste a Spotify or Apple Music song link.");
          startSave(async () => {
            const res = await updateProfile({ ...form, song_url: form.song_url || null });
            toast(res.ok ? "Saved" : res.error);
          });
        }}
      >
        <Field label="Name">
          <Input value={form.display_name} maxLength={60} onChange={(e) => setForm({ ...form, display_name: e.target.value })} />
        </Field>
        <Field label="Username">
          <Input value={form.username} maxLength={24} onChange={(e) => setForm({ ...form, username: e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, "") })} />
        </Field>
        <Field label="Bio">
          <Textarea rows={2} maxLength={300} value={form.bio} onChange={(e) => setForm({ ...form, bio: e.target.value })} />
        </Field>
        <Field label="Profile song" hint="Paste a Spotify or Apple Music song link">
          <Input value={form.song_url} placeholder="https://open.spotify.com/track/…" onChange={(e) => setForm({ ...form, song_url: e.target.value })} className={cn(!songOk && "border-stamp")} />
        </Field>
        <Field label="Monthly reading goal">
          <div className="flex items-center gap-3">
            <Button type="button" size="icon-sm" onClick={() => setForm({ ...form, monthly_goal: Math.max(1, form.monthly_goal - 1) })}>
              −
            </Button>
            <span className="w-16 text-center font-serif text-2xl">{form.monthly_goal}</span>
            <Button type="button" size="icon-sm" onClick={() => setForm({ ...form, monthly_goal: Math.min(50, form.monthly_goal + 1) })}>
              +
            </Button>
            <span className="text-[14px] text-muted">books / month</span>
          </div>
        </Field>
        <Button type="submit" variant="primary" className="w-full" disabled={saving}>
          {saving && <Loader2 className="animate-spin" />} Save
        </Button>
      </form>

      <SectionTitle>Profile skin</SectionTitle>
      <div className="grid grid-cols-2 gap-3">
        {SKINS.map((s) => (
          <button
            key={s.id}
            onClick={() => {
              setSkin(s.id);
              save({ skin: s.id }, `Skin: ${s.name}`);
            }}
            className={cn("relative overflow-hidden rounded-2xl border-2 p-3 text-left transition active:scale-[0.98]", skin === s.id ? "border-ink" : "border-transparent")}
            style={{ background: `${s.vars["--skin-pattern"]}, ${s.vars["--skin-bg"]}`, backgroundColor: s.vars["--skin-bg"], color: s.vars["--skin-ink"] }}
          >
            <div className="rounded-lg p-2" style={{ background: s.vars["--skin-card"] }}>
              <div className="h-1.5 w-8 rounded-full" style={{ background: s.vars["--skin-accent"] }} />
              <div className="mt-1.5 h-1.5 w-14 rounded-full opacity-30" style={{ background: s.vars["--skin-ink"] }} />
            </div>
            <p className={cn("mt-2 text-[13px]", s.heading === "serif" ? "font-serif" : s.heading === "typewriter" ? "font-type" : "font-semibold")}>{s.name}</p>
            {skin === s.id && <Check className="absolute right-2 top-2 size-4" />}
          </button>
        ))}
      </div>

      <SectionTitle>Top 8</SectionTitle>
      <div className="paper grid grid-cols-4 gap-3 p-4">
        {slots.map((b, i) => (
          <div key={i} className="relative">
            {b ? (
              <>
                <Cover book={b} />
                <button
                  aria-label={`Remove ${b.title}`}
                  className="absolute -right-1.5 -top-1.5 flex size-6 items-center justify-center rounded-full bg-ink text-paper"
                  onClick={() => {
                    setSlots((s) => s.map((x, j) => (j === i ? null : x)));
                    start(async () => void (await setTopBook(i + 1, null)));
                  }}
                >
                  <X className="size-3.5" />
                </button>
              </>
            ) : (
              <button onClick={() => setPickingSlot(i)} className="flex aspect-[2/3] w-full items-center justify-center rounded-md border-2 border-dashed border-line-strong text-muted" aria-label={`Add book #${i + 1}`}>
                <Plus className="size-5" />
              </button>
            )}
          </div>
        ))}
      </div>
      <BookSearch
        title={`Top 8 · #${(pickingSlot ?? 0) + 1}`}
        open={pickingSlot !== null}
        onOpenChange={(o) => !o && setPickingSlot(null)}
        onPick={(candidate) => {
          const slot = pickingSlot!;
          setPickingSlot(null);
          setSlots((s) => s.map((x, j) => (j === slot ? { ...candidate, id: candidate.external_id } : x)));
          start(async () => {
            const res = await setTopBook(slot + 1, candidate);
            if (!res.ok) toast(res.error);
          });
        }}
      />

      <SectionTitle>Privacy & notifications</SectionTitle>
      <div className="paper divide-y divide-line">
        <label className="flex items-center gap-3 p-4">
          <span className="flex-1">
            <span className="block text-[15px]">Private journal</span>
            <span className="block text-[13px] text-muted">Only approved followers see your shelves and activity. Your top 8 and badges stay visible.</span>
          </span>
          <Switch.Root
            checked={isPrivate}
            onCheckedChange={(v) => {
              setPrivate(v);
              save({ is_private: v }, v ? "Journal is private" : "Journal is public");
            }}
            className="relative h-7 w-12 shrink-0 rounded-full bg-line-strong transition data-[state=checked]:bg-ribbon"
          >
            <Switch.Thumb className="block size-6 translate-x-0.5 rounded-full bg-white shadow transition data-[state=checked]:translate-x-[22px]" />
          </Switch.Root>
        </label>
        {isNative() && (
          <button className="flex w-full items-center gap-3 p-4 text-left" onClick={() => start(async () => void toast((await registerForPush()) ? "Notifications on" : "Notifications are off in Settings"))}>
            <Bell className="size-5 text-muted" />
            <span className="flex-1 text-[15px]">Turn on notifications</span>
          </button>
        )}
      </div>

      <SectionTitle>Account</SectionTitle>
      <div className="space-y-2">
        {profile.is_admin && (
          <Button asChild variant="outline" className="w-full">
            <Link href="/admin">Book club admin</Link>
          </Button>
        )}
        <Button asChild variant="outline" className="w-full">
          <Link href="/privacy">Privacy policy</Link>
        </Button>
        {!demo && (
          <>
            <form action={signOut}>
              <Button type="submit" variant="outline" className="w-full">
                Sign out
              </Button>
            </form>
            <Button
              variant="danger"
              className="w-full"
              onClick={() => {
                if (!confirm("Delete your account and everything in it? This can't be undone.")) return;
                start(async () => {
                  const res = await deleteAccount();
                  if (res && !res.ok) toast(res.error);
                });
              }}
            >
              Delete account
            </Button>
          </>
        )}
      </div>
    </div>
  );
}

function Field({ label, hint, children }: { label: string; hint?: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="label mb-1.5 block">{label}</span>
      {children}
      {hint && <span className="mt-1 block text-[12px] text-muted">{hint}</span>}
    </label>
  );
}
