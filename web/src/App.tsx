/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

import { MotionConfig } from "framer-motion";
import { lazy, Suspense, useEffect } from "react";
import { Panel } from "@/components/Panel";
import { isEnvBrowser, sendReady } from "@/lib/nui";
import { installMessages, usePanel } from "@/store/panelStore";

// Dev and showcase builds only: removed from production builds.
const Preview = import.meta.env.DEV || import.meta.env.MODE === "showcase" ? lazy(() => import("@/dev/Preview")) : null;

export default function App() {
  const animations = usePanel((state) => state.config.layout.animations);

  useEffect(() => {
    const uninstall = installMessages();

    // Lua queues messages until the page says it listens.
    void sendReady();

    return uninstall;
  }, []);

  return (
    // layout.animations = false: framer-motion jumps to the end of every animation.
    <MotionConfig reducedMotion={animations ? "user" : "always"}>
      <Panel />
      {Preview && isEnvBrowser() && (
        <Suspense fallback={null}>
          <Preview />
        </Suspense>
      )}
    </MotionConfig>
  );
}
