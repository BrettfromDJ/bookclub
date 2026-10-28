import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Book Club",
    short_name: "Book Club",
    start_url: "/",
    display: "standalone",
    background_color: "#f7f2e7",
    theme_color: "#f7f2e7",
    icons: [
      { src: "/icon.svg", sizes: "any", type: "image/svg+xml" },
      { src: "/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
  };
}
