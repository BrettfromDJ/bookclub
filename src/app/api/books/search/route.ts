import { NextResponse } from "next/server";
import { searchBooks } from "@/lib/book-search";

export async function GET(req: Request) {
  const q = new URL(req.url).searchParams.get("q") ?? "";
  if (q.trim().length < 2) return NextResponse.json({ results: [] });
  try {
    return NextResponse.json({ results: await searchBooks(q, req.signal) });
  } catch (e) {
    return NextResponse.json({ results: [], error: e instanceof Error ? e.message : "Search failed" }, { status: 502 });
  }
}
