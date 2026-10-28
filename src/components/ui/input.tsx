import * as React from "react";
import { cn } from "@/lib/utils";

export const Input = React.forwardRef<HTMLInputElement, React.InputHTMLAttributes<HTMLInputElement>>(({ className, ...props }, ref) => (
  <input
    ref={ref}
    className={cn(
      "h-11 w-full rounded-xl border border-line-strong bg-card px-3.5 text-[15px] text-ink outline-none transition placeholder:text-muted focus:border-ink/40 focus:ring-4 focus:ring-ink/5",
      className,
    )}
    {...props}
  />
));
Input.displayName = "Input";

export const Textarea = React.forwardRef<HTMLTextAreaElement, React.TextareaHTMLAttributes<HTMLTextAreaElement>>(({ className, ...props }, ref) => (
  <textarea
    ref={ref}
    className={cn(
      "w-full rounded-xl border border-line-strong bg-card px-3.5 py-2.5 text-[15px] text-ink outline-none transition placeholder:text-muted focus:border-ink/40 focus:ring-4 focus:ring-ink/5",
      className,
    )}
    {...props}
  />
));
Textarea.displayName = "Textarea";
