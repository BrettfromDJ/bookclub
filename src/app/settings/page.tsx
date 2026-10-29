import { ArrowRight, FlaskConical } from "lucide-react";
import Link from "next/link";
import { redirect } from "next/navigation";
import { Page } from "@/components/shell/page";
import { SettingsForm } from "@/components/social/settings-form";
import { getTopEight, getViewer } from "@/lib/data";

export const metadata = { title: "Settings" };

export default async function SettingsPage() {
  const viewer = await getViewer();
  if (!viewer) redirect("/login");
  const topEight = await getTopEight(viewer.profile.id);
  return (
    <Page kicker="Your profile" title="Settings">
      <SettingsForm profile={viewer.profile} topEight={topEight} demo={viewer.demo} />
      <Link href="/lab" className="paper mt-8 flex items-center gap-3 p-4">
        <FlaskConical className="size-5 text-ink-soft" />
        <span className="min-w-0 flex-1">
          <span className="block text-[15px] font-medium">Test lab</span>
          <span className="block text-[13px] text-muted">Preview the wrap-up receipt and other states</span>
        </span>
        <ArrowRight className="size-4 text-muted" />
      </Link>
    </Page>
  );
}
