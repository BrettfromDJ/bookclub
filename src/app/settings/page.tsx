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
    </Page>
  );
}
