"use client";

import { BookMarked, Library, MessagesSquare, NotebookPen, UserRound } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { cn } from "@/lib/utils";

const TABS = [
  { href: "/", label: "Journal", icon: NotebookPen },
  { href: "/tbr", label: "TBR", icon: Library },
  { href: "/club", label: "Club", icon: BookMarked },
  { href: "/feed", label: "Friends", icon: MessagesSquare },
  { href: "/me", label: "Me", icon: UserRound },
];

export function TabBar() {
  const path = usePathname();
  // Lights up the tapped tab right away instead of after the next screen
  // arrives; it lapses on its own once the path changes.
  const [tapped, setTapped] = useState<{ href: string; from: string } | null>(null);
  if (path.startsWith("/login") || path.startsWith("/auth") || path.startsWith("/wrapup")) return null;
  const pending = tapped?.from === path ? tapped.href : null;
  return (
    <nav className="safe-bottom fixed inset-x-0 bottom-0 z-40 border-t border-line bg-paper/85 backdrop-blur-xl">
      <ul className="mx-auto flex max-w-lg justify-around px-2 pt-1.5">
        {TABS.map(({ href, label, icon: Icon }) => {
          const active = pending ? pending === href : href === "/" ? path === "/" : path.startsWith(href) || (href === "/me" && (path.startsWith("/u/") || path.startsWith("/settings") || path.startsWith("/badges")));
          return (
            <li key={href}>
              <Link href={href} onClick={() => setTapped({ href, from: path })} className={cn("flex w-16 flex-col items-center gap-0.5 pb-1.5 pt-1 text-[10px] font-medium transition-colors", active ? "text-ink" : "text-muted")}>
                <Icon className="size-[22px]" strokeWidth={active ? 2.2 : 1.7} />
                {label}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
