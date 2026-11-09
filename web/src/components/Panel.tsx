/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

// The example panel: the reward of a point, a countdown and a claim button. Replace it with your own screen.

import { useEffect, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { CheckCircle2, Clock, Gift, X } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Surface } from "@/components/ui/Surface";
import { Text } from "@/components/ui/Text";
import { duration, fill, money } from "@/lib/format";
import { claim, close, usePanel } from "@/store/panelStore";

/** Milliseconds until `readyAt`, ticking every second while above zero. */
function useCountdown(readyAt: number): number {
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    setNow(Date.now());

    if (readyAt <= Date.now()) {
      return undefined;
    }

    const timer = setInterval(() => setNow(Date.now()), 1000);

    return () => clearInterval(timer);
  }, [readyAt]);

  return Math.max(readyAt - now, 0);
}

export function Panel() {
  const { config, open, readyAt, result, busy } = usePanel();
  const left = useCountdown(readyAt);
  const t = (key: string) => config.labels[key] ?? key;

  useEffect(() => {
    if (!open) {
      return undefined;
    }

    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        close();
      }
    };

    window.addEventListener("keydown", onKey);

    return () => window.removeEventListener("keydown", onKey);
  }, [open]);

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          key="panel"
          className="fixed bottom-24 right-8 w-80"
          initial={{ opacity: 0, x: 24, scale: 0.97 }}
          animate={{ opacity: 1, x: 0, scale: 1 }}
          exit={{ opacity: 0, x: 24, scale: 0.97 }}
          transition={{ type: "spring", stiffness: 380, damping: 30 }}
        >
          <Surface variant="glass" padding="lg" className="space-y-5" data-panel={open.point}>
            <div className="flex items-start justify-between gap-3">
              <div className="flex items-center gap-3">
                <span className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/15 text-primary">
                  <Gift className="h-5 w-5" aria-hidden />
                </span>
                <Text variant="h3" className="break-words">
                  {open.label}
                </Text>
              </div>
              <button type="button" aria-label={t("close")} className="rounded-md p-1 text-muted-foreground hover:bg-white/10 hover:text-foreground" onClick={close}>
                <X className="h-4 w-4" aria-hidden />
              </button>
            </div>

            <div className="flex items-end justify-between">
              <Text variant="muted">{t("reward")}</Text>
              <span key={open.amount} className="ug-pop text-2xl font-semibold tabular-nums">
                {money(open.amount, config.locale)}
              </span>
            </div>

            <div className="flex items-center gap-2 text-sm" data-wait={left}>
              {left > 0 ? (
                <>
                  <Clock className="h-4 w-4 text-warning" aria-hidden />
                  <span className="tabular-nums">{fill(t("wait"), { time: duration(left) })}</span>
                </>
              ) : (
                <>
                  <CheckCircle2 className="h-4 w-4 text-success" aria-hidden />
                  <span>{t("ready")}</span>
                </>
              )}
            </div>

            {result && (
              <p role="status" data-result={result.ok ? "ok" : result.error} className={result.ok ? "text-sm text-success" : "text-sm text-destructive"}>
                {result.ok
                  ? fill(t("claimed"), { amount: money(result.amount ?? open.amount, config.locale) })
                  : (config.labels[`error.${result.error}`] ?? t("error.internal_error"))}
              </p>
            )}

            <Button className="w-full" disabled={busy || left > 0} onClick={claim}>
              {t("claim")}
            </Button>
          </Surface>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
