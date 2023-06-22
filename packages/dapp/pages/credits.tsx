import { FC, useState } from "react";
import DollarPrice from "@/components/redeem/dollar-price";
import UcrRedeem from "@/components/redeem/ucr-redeem";
import UcrNftGenerator from "@/components/redeem/debt-coupon-deposit";
import UcrNftRedeem from "@/components/redeem/ucr-nft-redeem";
import useManagerManaged from "@/components/lib/hooks/contracts/use-manager-managed";
import useEffectAsync from "@/components/lib/hooks/use-effect-async";
// import DisabledBlurredMessage from "@/components/ui/DisabledBlurredMessage";
import dynamic from "next/dynamic";
const WalletConnectionWall = dynamic(() => import("@/components/ui/wallet-connection-wall"), { ssr: false }); //@note Fix: (Hydration Error)

const PriceStabilization: FC = (): JSX.Element => {
  const [twapInteger, setTwapInteger] = useState<number>(0);
  const managedContracts = useManagerManaged();

  useEffectAsync(async () => {
    if (managedContracts) {
      const twapPrice = await managedContracts.dollarTwapOracle.consult(managedContracts.dollarToken.address);
      if (twapPrice) {
        const twapPriceInteger = (twapPrice as unknown as number) / 1e18;
        setTwapInteger(twapPriceInteger);
      }
    }
  }, [managedContracts]);

  return (
    <WalletConnectionWall>
      <div id="CreditOperations" data-twap={twapInteger}>
        <DollarPrice />
        <div id="MintUcr" className="panel">
          <h2>Generate Ubiquity Credit NFTs</h2>
          <aside>When TWAP is below peg</aside>
          <UcrNftGenerator />
        </div>
        <div id="RedeemUcr" className="panel">
          <h2>Redeem Ubiquity Credits</h2>
          <div>
            <UcrRedeem twapInteger={twapInteger} />
            <UcrNftRedeem />
          </div>
        </div>
      </div>
    </WalletConnectionWall>
  );
};

export default PriceStabilization;
