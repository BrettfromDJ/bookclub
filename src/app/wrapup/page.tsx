import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { WrapupReceipt } from "@/components/journal/wrapup-receipt";
import { getMonthlyPicks, getShelf, getViewer } from "@/lib/data";
import { monthStart } from "@/lib/month";
import { buildWrapup, parseMonth, sampleWrapup } from "@/lib/wrapup";

export const metadata: Metadata = { title: "Monthly wrap-up" };

/**
 * `/wrapup` prints this month's receipt, `?month=2026-09` a past month, and
 * `?sample=1` a filled-in sample month for previewing the design.
 */
export default async function WrapupPage({ searchParams }: { searchParams: Promise<{ month?: string; sample?: string }> }) {
  const viewer = await getViewer();
  if (!viewer) redirect("/login");
  const params = await searchParams;
  const month = parseMonth(params.month) ?? monthStart();

  if (params.sample) return <WrapupReceipt wrapup={sampleWrapup(month)} username={viewer.profile.username} />;

  const [shelf, picks] = await Promise.all([getShelf(viewer.profile.id), getMonthlyPicks(viewer.profile.id)]);
  const pick = picks.find((p) => p.month === month)?.book ?? null;
  return <WrapupReceipt wrapup={buildWrapup(month, shelf, pick)} username={viewer.profile.username} />;
}
