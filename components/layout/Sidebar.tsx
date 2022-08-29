import Link from "next/link";
import { useCallback, useEffect, useRef } from "react";
import Icon, { IconsNames } from "../ui/Icon";
import WalletConnect from "./WalletConnect";

const PROD = process.env.NODE_ENV == "production";

export type SidebarState = "loading" | "permanent" | "hidden" | "hidden_hovering";

const Sidebar = ({ state, onChange, permanentThreshold }: { state: SidebarState; onChange: (state: SidebarState) => void; permanentThreshold: number }) => {
  const sidebarRef = useRef<HTMLDivElement>(null);

  const handleResize = useCallback(() => {
    if (sidebarRef.current) {
      if (window.innerWidth < permanentThreshold) {
        onChange("hidden");
      } else {
        onChange("permanent");
      }
    }
  }, []);

  const handleEnter = useCallback(() => {
    if (state === "hidden") {
      onChange("hidden_hovering");
    }
  }, [state]);

  const handleLeave = useCallback(() => {
    if (state === "hidden_hovering") {
      onChange("hidden");
    }
  }, [state]);

  const handleToggle = useCallback(() => {
    if (state === "hidden") {
      onChange("hidden_hovering");
    } else {
      onChange("hidden");
    }
  }, [state]);

  useEffect(() => {
    handleResize();
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  return (
    <>
      <input type="checkbox" />
      <div id="Sidebar" ref={sidebarRef} onMouseEnter={handleEnter} onMouseLeave={handleLeave}>
        <div>
          <ul>
            <li>
              <div>
                <Link href="/">
                  <a id="Logo">
                    <div>
                      <div>
                        <Icon icon="uad" />
                      </div>
                      <div>
                        <span>Ubiquity Dollar</span>
                      </div>
                    </div>
                  </a>
                </Link>
              </div>
            </li>

            <Item text="Staking" href="/staking" icon="⛏"></Item>
            <Item text="Credit Operations" href="/credit-operations" icon="💸"></Item>
            {PROD ? null : <Item text="Bonds" href="/bonds" icon="🎉"></Item>}
            <Item text="Primary Markets" href="/primary-markets" icon="🔁"></Item>
            {/* <Item text="Boosted Yield Farming" href="/boosted-yield-farming" icon="🚜"></Item> */}
          </ul>
          <ul>
            <li>
              <SocialLinkItem href="https://twitter.com/UbiquityDAO" alt="Twitter" icon="twitter" />
            </li>
            <li>
              <SocialLinkItem href="https://t.me/ubiquitydao" alt="Telegram" icon="telegram" />
            </li>
            <li>
              <SocialLinkItem href="https://github.com/ubiquity" alt="Github" icon="github" />
            </li>
            <li>
              <SocialLinkItem href="https://discord.gg/SjymJ5maJ4" alt="Discord" icon="discord" />
            </li>
          </ul>
          <ul>
            <Item text="Docs" href="https://dao.ubq.fi/docs" icon="📑"></Item>
            <Item text="DAO" href="https://dao.ubq.fi/" icon="🤝"></Item>
            <Item text="Blog" href="https://medium.com/ubiquity-dao" icon="📰"></Item>
          </ul>
          <ul>
            <li>
              <WalletConnect />
            </li>
          </ul>
        </div>

        {/* Overlay */}

        {state === "hidden_hovering" ? <div onClick={handleToggle}></div> : null}
      </div>
    </>
  );
};

const SocialLinkItem = ({ href, icon, alt }: { href: string; icon: IconsNames; alt: string }) => (
  <a href={href} target="_blank" title={alt}>
    <div>
      <Icon icon={icon} />
    </div>
  </a>
);

const Item = ({ text, href }: { text: string; href: string; icon: string }) => {
  const isExternal = href.startsWith("http");
  return (
    <li>
      <div>
        <Link href={href}>
          <a target={href.match(/https?:\/\//) ? "_blank" : ""}>
            <span>{text}</span>
            <span>{isExternal ? <Icon icon="external" /> : null}</span>
          </a>
        </Link>
      </div>
    </li>
  );
};

export default Sidebar;
