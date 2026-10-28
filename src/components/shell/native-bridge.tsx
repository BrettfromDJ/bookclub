"use client";

import { useEffect } from "react";
import { isNative } from "@/lib/native";

/** iOS-only setup: dark status bar text on the paper background. */
export function NativeBridge() {
  useEffect(() => {
    if (!isNative()) return;
    void import("@capacitor/status-bar").then(({ StatusBar, Style }) => StatusBar.setStyle({ style: Style.Light }));
  }, []);
  return null;
}
