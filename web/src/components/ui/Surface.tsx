/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

import type { HTMLAttributes } from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/cn";

/**
 * Panel container. `glass` is translucent, `solid` stays readable over busy scenes.
 *
 * No backdrop blur: the game is composited behind the NUI surface, so a
 * backdrop filter has nothing to sample and renders a black box.
 */
const surfaceVariants = cva("rounded-lg text-card-foreground transition-shadow", {
  variants: {
    variant: {
      glass: "border border-white/10 bg-card/90 shadow-ug-lg",
      solid: "border border-border bg-card shadow-ug-md",
    },
    padding: {
      none: "p-0",
      sm: "p-2",
      md: "p-4",
      lg: "p-6",
    },
  },
  defaultVariants: {
    variant: "glass",
    padding: "md",
  },
});

export interface SurfaceProps
  extends HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof surfaceVariants> {}

export function Surface({ className, variant, padding, ...props }: SurfaceProps) {
  return <div className={cn(surfaceVariants({ variant, padding }), className)} {...props} />;
}
