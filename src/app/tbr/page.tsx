import { redirect } from "next/navigation";
import { TbrList } from "@/components/books/tbr-list";
import { Page } from "@/components/shell/page";
import { getShelf, getViewer } from "@/lib/data";

export const metadata = { title: "TBR" };

export default async function TbrPage() {
  const viewer = await getViewer();
  if (!viewer) redirect("/login");
  const shelf = await getShelf(viewer.profile.id);
  return (
    <Page kicker="To be read" title="Up next">
      <TbrList initial={shelf} />
    </Page>
  );
}
