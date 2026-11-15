/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

import type { HTMLAttributes, ElementType } from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/cn";

const textVariants = cva("", {
  variants: {
    variant: {
      h2: "text-xl font-semibold tracking-tight",
      h3: "text-base font-semibold",
      body: "text-sm",
      small: "text-xs",
      muted: "text-sm text-muted-foreground",
    },
  },
  defaultVariants: {
    variant: "body",
  },
});

const defaultElement: Record<string, ElementType> = {
  h2: "h2",
  h3: "h3",
  body: "p",
  small: "span",
  muted: "p",
};

export interface TextProps extends HTMLAttributes<HTMLElement>, VariantProps<typeof textVariants> {
  as?: ElementType;
}

/** Text sizes and weights for every component. `as` changes the element, not the style. */
export function Text({ className, variant, as, ...props }: TextProps) {
  const Component = as ?? defaultElement[variant ?? "body"] ?? "p";

  return <Component className={cn(textVariants({ variant }), className)} {...props} />;
}
