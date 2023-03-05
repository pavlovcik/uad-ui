import Link from "next/link";
import Icon, { IconsNames } from "../ui/Icon";
import BuildInfo from "./BuildInfo";
import WalletConnect from "./WalletConnect";

const PROD = process.env.NODE_ENV == "production";

const Sidebar = () => {
  return (
    <>
      <input type="checkbox" />
      <div id="Sidebar">
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
                        <span>Ubiquity Dollar (Beta)</span>
                      </div>
                    </div>
                  </a>
                </Link>
              </div>
            </li>

            <Item text="Staking" href="/staking" icon="⛏"></Item>
            <Item text="Credits" href="/credits" icon="💸"></Item>
            <Item text="Markets" href="/markets" icon="🔁"></Item>
            {PROD ? null : <Item text="Bonds" href="/bonds" icon="🎉"></Item>}
          </ul>

          <ul>
            <Item text="Docs" href="https://github.com/ubiquity/ubiquity-dollar/wiki" icon="📑"></Item>
            <Item text="Blog" href="https://dao.ubq.fi/" icon="📰"></Item>
            <Item text="Security" href="https://dao.ubq.fi/security-bounty-program" icon="🚨"></Item>
          </ul>
          <ul>
            <li>
              <SocialLinkItem href="https://twitter.com/UbiquityDAO" alt="Twitter" icon="twitter" />
            </li>
            <li>
              <SocialLinkItem href="https://t.me/UbiquityDAO" alt="Telegram" icon="telegram" />
            </li>
            <li>
              <SocialLinkItem href="https://github.com/ubiquity" alt="Github" icon="github" />
            </li>
            <li>
              <SocialLinkItem href="https://discord.gg/SjymJ5maJ4" alt="Discord" icon="discord" />
            </li>
          </ul>
          <ul>
            <li>
              <WalletConnect />
            </li>
            <li>
              <BuildInfo />
            </li>
          </ul>
        </div>
      </div>
    </>
  );
};

const SocialLinkItem = ({ href, icon, alt }: { href: string; icon: IconsNames; alt: string }) => (
  <a href={href} target="_blank" rel="noopener noreferrer" title={alt}>
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
