"use client";

import { BookCheck, Check, Play, Plus } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";
import { addToShelf, setStatus } from "@/app/actions";
import { Button } from "@/components/ui/button";
import { punchHaptic } from "@/lib/native";
import type { Book, ShelfStatus } from "@/lib/types";

export function ClubActions({ book, status: initial, userBookId: initialId }: { book: Book; status: ShelfStatus | null; userBookId: string | null }) {
  const [status, setLocal] = useState(initial);
  const [id, setId] = useState(initialId);
  const [pending, start] = useTransition();

  const go = (next: ShelfStatus) =>
    start(async () => {
      setLocal(next);
      if (next === "read") void punchHaptic(true);
      const { id: _id, ...candidate } = book;
      void _id;
      const res = id ? await setStatus(id, next) : await addToShelf(candidate, ["physical"], next);
      if (!res.ok) toast(res.error);
      else if (res.data && "id" in res.data) setId(res.data.id);
    });

  if (status === "read")
    return (
      <p className="inline-flex items-center gap-2 font-type text-[13px] text-ribbon">
        <Check className="size-4" /> Finished — stamp earned
      </p>
    );
  return (
    <div className="flex justify-center gap-2">
      {status === null && (
        <Button variant="outline" disabled={pending} onClick={() => go("tbr")}>
          <Plus /> Add to TBR
        </Button>
      )}
      {status !== "reading" && (
        <Button variant="primary" disabled={pending} onClick={() => go("reading")}>
          <Play /> Start reading
        </Button>
      )}
      {status === "reading" && (
        <Button variant="stamp" disabled={pending} onClick={() => go("read")}>
          <BookCheck /> I finished it
        </Button>
      )}
    </div>
  );
}
