"use client";

import * as Dialog from "@radix-ui/react-dialog";
import { Loader2, Search, X } from "lucide-react";
import { useEffect, useState } from "react";
import { Cover } from "@/components/books/cover";
import { Input } from "@/components/ui/input";
import type { BookCandidate } from "@/lib/types";

/** Bottom-sheet book search (Google Books, falling back to Open Library). */
export function BookSearch({
  open,
  onOpenChange,
  onPick,
  title = "Add a book",
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onPick: (book: BookCandidate) => void;
  title?: string;
}) {
  const [q, setQ] = useState("");
  const [results, setResults] = useState<BookCandidate[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (q.trim().length < 2) {
      setResults([]);
      return;
    }
    const ctrl = new AbortController();
    const t = setTimeout(async () => {
      setLoading(true);
      setError(null);
      try {
        const res = await fetch(`/api/books/search?q=${encodeURIComponent(q)}`, { signal: ctrl.signal });
        const json = (await res.json()) as { results: BookCandidate[]; error?: string };
        setResults(json.results);
        if (json.error) setError(json.error);
      } catch (e) {
        if (!ctrl.signal.aborted) setError(e instanceof Error ? e.message : "Search failed");
      } finally {
        if (!ctrl.signal.aborted) setLoading(false);
      }
    }, 300);
    return () => {
      clearTimeout(t);
      ctrl.abort();
    };
  }, [q]);

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 z-50 bg-ink/30 backdrop-blur-[2px]" />
        <Dialog.Content className="safe-bottom fixed inset-x-0 bottom-0 z-50 mx-auto flex max-h-[88dvh] max-w-lg flex-col rounded-t-3xl bg-paper shadow-2xl outline-none animate-rise">
          <div className="mx-auto mt-2.5 h-1 w-10 rounded-full bg-line-strong" />
          <div className="flex items-center justify-between px-5 pb-3 pt-3">
            <Dialog.Title className="font-serif text-2xl">{title}</Dialog.Title>
            <Dialog.Close className="rounded-full p-2 text-muted hover:bg-paper-2" aria-label="Close">
              <X className="size-5" />
            </Dialog.Close>
          </div>
          <Dialog.Description className="sr-only">Search by title, author or ISBN.</Dialog.Description>
          <div className="relative px-5">
            <Search className="pointer-events-none absolute left-8 top-1/2 size-4 -translate-y-1/2 text-muted" />
            <Input autoFocus value={q} onChange={(e) => setQ(e.target.value)} placeholder="Title, author or ISBN" className="pl-10" />
            {loading && <Loader2 className="absolute right-8 top-1/2 size-4 -translate-y-1/2 animate-spin text-muted" />}
          </div>
          <ul className="mt-3 flex-1 overflow-y-auto px-3 pb-6">
            {error && <li className="px-2 py-3 text-sm text-stamp">{error}</li>}
            {results.map((b) => (
              <li key={`${b.source}:${b.external_id}`}>
                <button
                  onClick={() => {
                    onPick(b);
                    setQ("");
                  }}
                  className="flex w-full items-center gap-3 rounded-2xl p-2 text-left transition hover:bg-paper-2 active:scale-[0.99]"
                >
                  <Cover book={b} className="w-11" />
                  <span className="min-w-0">
                    <span className="line-clamp-2 font-serif text-[16px] leading-snug">{b.title}</span>
                    <span className="line-clamp-1 text-[13px] text-muted">
                      {b.authors.join(", ")}
                      {b.published_year ? ` · ${b.published_year}` : ""}
                    </span>
                  </span>
                </button>
              </li>
            ))}
          </ul>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
