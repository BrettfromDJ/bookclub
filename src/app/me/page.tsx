import { redirect } from "next/navigation";
import { getViewer } from "@/lib/data";

export default async function MePage() {
  const viewer = await getViewer();
  redirect(viewer ? `/u/${viewer.profile.username}` : "/login");
}
