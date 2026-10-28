"use client";

import { Loader2 } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";
import { setClubMonth } from "@/app/actions";
import { BookSearch } from "@/components/books/book-search";
import { Cover } from "@/components/books/cover";
import { Button } from "@/components/ui/button";
import { Input, Textarea } from "@/components/ui/input";
import { monthStart } from "@/lib/month";
import type { BookCandidate } from "@/lib/types";

export function ClubAdminForm() {
  const [month, setMonth] = useState(monthStart().slice(0, 7));
  const [book, setBook] = useState<BookCandidate | null>(null);
  const [searching, setSearching] = useState(false);
  const [fields, setFields] = useState({ blurb: "", partner_name: "", partner_url: "", partner_logo_url: "" });
  const [pending, start] = useTransition();

  return (
    <form
      className="paper space-y-4 p-4"
      onSubmit={(e) => {
        e.preventDefault();
        if (!book) return toast("Choose a book.");
        start(async () => {
          const res = await setClubMonth({ month: `${month}-01`, book, ...fields });
          toast(res.ok ? "Club pick saved" : res.error);
        });
      }}
    >
      <label className="block">
        <span className="label mb-1.5 block">Month</span>
        <Input type="month" value={month} onChange={(e) => setMonth(e.target.value)} required />
      </label>
      <div>
        <span className="label mb-1.5 block">Book</span>
        {book ? (
          <button type="button" onClick={() => setSearching(true)} className="flex items-center gap-3 text-left">
            <Cover book={book} className="w-14" />
            <span>
              <span className="block font-serif text-lg">{book.title}</span>
              <span className="text-[13px] text-muted">{book.authors.join(", ")} · tap to change</span>
            </span>
          </button>
        ) : (
          <Button type="button" variant="outline" onClick={() => setSearching(true)}>
            Choose a book
          </Button>
        )}
      </div>
      <label className="block">
        <span className="label mb-1.5 block">Blurb</span>
        <Textarea rows={3} value={fields.blurb} onChange={(e) => setFields({ ...fields, blurb: e.target.value })} />
      </label>
      <p className="label pt-2">Partner (optional)</p>
      <Input placeholder="Partner name" value={fields.partner_name} onChange={(e) => setFields({ ...fields, partner_name: e.target.value })} />
      <Input placeholder="Partner link (https://…)" type="url" value={fields.partner_url} onChange={(e) => setFields({ ...fields, partner_url: e.target.value })} />
      <Input placeholder="Logo image URL" type="url" value={fields.partner_logo_url} onChange={(e) => setFields({ ...fields, partner_logo_url: e.target.value })} />
      <Button type="submit" variant="primary" size="lg" className="w-full" disabled={pending}>
        {pending && <Loader2 className="animate-spin" />} Save pick
      </Button>
      <BookSearch
        title="Club pick"
        open={searching}
        onOpenChange={setSearching}
        onPick={(b) => {
          setBook(b);
          setSearching(false);
        }}
      />
    </form>
  );
}
