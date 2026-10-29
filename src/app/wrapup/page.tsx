import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { WrapupReceipt } from "@/components/journal/wrapup-receipt";
import { getMonthlyPicks, getShelf, getViewer } from "@/lib/data";
import { monthStart } from "@/lib/month";
import { SAMPLES, type Sample, buildWrapup, parseMonth, sampleWrapup } from "@/lib/wrapup";

export const metadata: Metadata = { title: "Monthly wrap-up" };

/**
 * `/wrapup` prints this month's receipt and `?month=2026-09` a past month.
 * `?sample=full|one|many|unrated|empty` prints sample data instead (see the
 * Test lab), and `?from=lab` sends Close/Done back there.
 */
export default async function WrapupPage({ searchParams }: { searchParams: Promise<{ month?: string; sample?: string; from?: string }> }) {
  const viewer = await getViewer();
  if (!viewer) redirect("/login");
  const params = await searchParams;
  const month = parseMonth(params.month) ?? monthStart();

  const back = params.from === "lab" ? "/lab" : "/";

  if (params.sample) {
    const sample: Sample = SAMPLES.includes(params.sample as Sample) ? (params.sample as Sample) : "full";
    return <WrapupReceipt wrapup={sampleWrapup(month, sample)} username={viewer.profile.username} back={back} />;
  }

  const [shelf, picks] = await Promise.all([getShelf(viewer.profile.id), getMonthlyPicks(viewer.profile.id)]);
  const pick = picks.find((p) => p.month === month)?.book ?? null;
  return <WrapupReceipt wrapup={buildWrapup(month, shelf, pick)} username={viewer.profile.username} back={back} />;
}
