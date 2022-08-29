import React, { useEffect, useState } from "react";
import { ErrorBoundary } from "react-error-boundary";

import Icon from "../ui/Icon";
import Inventory from "./Inventory";
import Sidebar, { SidebarState } from "./Sidebar";
import TransactionsDisplay from "./TransactionsDisplay";

type LayoutProps = {
  children: React.ReactNode;
};

function ErrorHandler({ error }: { error: Error }) {
  return (
    <div className="panel">
      <div>
        <div>
          <Icon icon="warning" />
          <div>Error</div>
        </div>
        <div>{error.message}</div>
      </div>
    </div>
  );
}

export default function Layout({ children }: LayoutProps) {
  const [sidebarState, setSidebarState] = useState<SidebarState>("loading");

  useEffect(() => {
    const { ethereum } = window;
    if (ethereum) {
      ethereum.on("accountsChanged", window.location.reload);
      ethereum.on("chainChanged", window.location.reload);
    }
  }, []);

  return (
    <div id="Foreground">
      <Sidebar permanentThreshold={1024} state={sidebarState} onChange={setSidebarState} />
      <div id="MainContent">
        <div>
          <TransactionsDisplay />
          <div id="Content">
            {sidebarState !== "loading" ? (
              <>
                <div>
                  <div>
                    <ErrorBoundary FallbackComponent={ErrorHandler} resetKeys={[children]}>
                      {children}
                    </ErrorBoundary>
                  </div>
                </div>
              </>
            ) : null}
          </div>
        </div>

        <div>
          <Inventory />
        </div>
      </div>
    </div>
  );
}
