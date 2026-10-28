import { notFound, redirect } from "next/navigation";
import { Page } from "@/components/shell/page";
import { ClubAdminForm } from "@/components/social/club-admin-form";
import { getViewer } from "@/lib/data";

export const metadata = { title: "Club admin" };

/** Set the app-wide book club pick. Admins are flagged in the profiles table by hand. */
export default async function AdminPage() {
  const viewer = await getViewer();
  if (!viewer) redirect("/login");
  if (!viewer.profile.is_admin) notFound();
  return (
    <Page kicker="Admin" title="Book club pick">
      <ClubAdminForm />
    </Page>
  );
}
