/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ["class"],
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["var(--ug-font-sans)"],
      },
      boxShadow: {
        "ug-sm": "0 1px 2px 0 rgb(0 0 0 / 0.15)",
        "ug-md": "0 4px 12px -2px rgb(0 0 0 / 0.25), 0 2px 4px -2px rgb(0 0 0 / 0.15)",
        "ug-lg": "0 12px 32px -4px rgb(0 0 0 / 0.35), 0 4px 8px -4px rgb(0 0 0 / 0.2)",
      },
      // HSL variables from src/index.css. Tailwind stays on v3 for FiveM's CEF.
      colors: {
        // `<alpha-value>` makes opacity modifiers such as `bg-card/80` work.
        border: "hsl(var(--ug-border) / <alpha-value>)",
        input: "hsl(var(--ug-input) / <alpha-value>)",
        ring: "hsl(var(--ug-ring) / <alpha-value>)",
        background: "hsl(var(--ug-background) / <alpha-value>)",
        foreground: "hsl(var(--ug-foreground) / <alpha-value>)",
        primary: {
          DEFAULT: "hsl(var(--ug-primary) / <alpha-value>)",
          foreground: "hsl(var(--ug-primary-foreground) / <alpha-value>)",
        },
        secondary: {
          DEFAULT: "hsl(var(--ug-secondary) / <alpha-value>)",
          foreground: "hsl(var(--ug-secondary-foreground) / <alpha-value>)",
        },
        destructive: {
          DEFAULT: "hsl(var(--ug-destructive) / <alpha-value>)",
          foreground: "hsl(var(--ug-destructive-foreground) / <alpha-value>)",
        },
        success: {
          DEFAULT: "hsl(var(--ug-success) / <alpha-value>)",
          foreground: "hsl(var(--ug-success-foreground) / <alpha-value>)",
        },
        warning: {
          DEFAULT: "hsl(var(--ug-warning) / <alpha-value>)",
          foreground: "hsl(var(--ug-warning-foreground) / <alpha-value>)",
        },
        muted: {
          DEFAULT: "hsl(var(--ug-muted) / <alpha-value>)",
          foreground: "hsl(var(--ug-muted-foreground) / <alpha-value>)",
        },
        accent: {
          DEFAULT: "hsl(var(--ug-accent) / <alpha-value>)",
          foreground: "hsl(var(--ug-accent-foreground) / <alpha-value>)",
        },
        card: {
          DEFAULT: "hsl(var(--ug-card) / <alpha-value>)",
          foreground: "hsl(var(--ug-card-foreground) / <alpha-value>)",
        },
        popover: {
          DEFAULT: "hsl(var(--ug-popover) / <alpha-value>)",
          foreground: "hsl(var(--ug-popover-foreground) / <alpha-value>)",
        },
      },
      borderRadius: {
        lg: "var(--ug-radius)",
        md: "calc(var(--ug-radius) - 2px)",
        sm: "calc(var(--ug-radius) - 4px)",
      },
      // "-out" durations MUST match LAYER_EXIT_MS in src/store/layerStore.ts.
      keyframes: {
        "ug-fade-in": { from: { opacity: "0" }, to: { opacity: "1" } },
        "ug-fade-out": { from: { opacity: "1" }, to: { opacity: "0" } },
        "ug-slide-up": { from: { opacity: "0", transform: "translateY(6px)" }, to: { opacity: "1", transform: "translateY(0)" } },
        "ug-slide-down": { from: { opacity: "1", transform: "translateY(0)" }, to: { opacity: "0", transform: "translateY(6px)" } },
        "ug-scale-in": { from: { opacity: "0", transform: "scale(0.96) translateY(4px)" }, to: { opacity: "1", transform: "scale(1) translateY(0)" } },
        "ug-scale-out": { from: { opacity: "1", transform: "scale(1) translateY(0)" }, to: { opacity: "0", transform: "scale(0.96) translateY(4px)" } },
        "ug-rise-in": { from: { opacity: "0", transform: "translateY(16px) scale(0.95)" }, to: { opacity: "1", transform: "translateY(0) scale(1)" } },
        "ug-drop-in": { from: { opacity: "0", transform: "translateY(-16px) scale(0.95)" }, to: { opacity: "1", transform: "translateY(0) scale(1)" } },
      },
      animation: {
        "ug-fade-in": "ug-fade-in 120ms ease-out",
        "ug-fade-out": "ug-fade-out 150ms ease-in forwards",
        "ug-slide-up": "ug-slide-up 150ms ease-out",
        "ug-slide-down": "ug-slide-down 150ms ease-in forwards",
        "ug-scale-in": "ug-scale-in 150ms ease-out",
        "ug-scale-out": "ug-scale-out 150ms ease-in forwards",
        "ug-rise-in": "ug-rise-in 260ms cubic-bezier(0.16, 1, 0.3, 1)",
        "ug-drop-in": "ug-drop-in 260ms cubic-bezier(0.16, 1, 0.3, 1)",
      },
    },
  },
  plugins: [],
};
