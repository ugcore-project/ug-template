/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

import { lazy, Suspense, useEffect } from "react";
import { Panel } from "@/components/Panel";
import { isEnvBrowser, sendReady } from "@/lib/nui";
import { installMessages } from "@/store/panelStore";

// Dev only: removed from production builds.
const Preview = import.meta.env.DEV ? lazy(() => import("@/dev/Preview")) : null;

export default function App() {
  useEffect(() => {
    const uninstall = installMessages();

    // Lua queues messages until the page says it listens.
    void sendReady();

    return uninstall;
  }, []);

  return (
    <>
      <Panel />
      {Preview && isEnvBrowser() && (
        <Suspense fallback={null}>
          <Preview />
        </Suspense>
      )}
    </>
  );
}
