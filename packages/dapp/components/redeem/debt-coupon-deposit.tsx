import { BigNumber } from "ethers";
import { useState } from "react";

import { ensureERC20Allowance } from "@/lib/contracts-shortcuts";
import { formatEther } from "@/lib/format";
import { safeParseEther } from "@/lib/utils";
import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
import useBalances from "../lib/hooks/use-balances";
import useSigner from "../lib/hooks/use-signer";
import useTransactionLogger from "../lib/hooks/use-transaction-logger";
import useWalletAddress from "../lib/hooks/use-wallet-address";
import Button from "../ui/button";
import PositiveNumberInput from "../ui/positive-number-input";

const UcrNftGenerator = () => {
  const [walletAddress] = useWalletAddress();
  const signer = useSigner();
  const [balances, refreshBalances] = useBalances();
  const [, doTransaction, doingTransaction] = useTransactionLogger();
  const protocolContracts = useProtocolContracts();

  const [inputVal, setInputVal] = useState("");
  const [expectedDebtCoupon, setExpectedDebtCoupon] = useState<BigNumber | null>(null);

  if (!walletAddress || !signer) {
    return <span>Connect wallet</span>;
  }

  if (!balances || !protocolContracts) {
    return <span>· · ·</span>;
  }

  const depositDollarForDebtCoupons = async (amount: BigNumber) => {
    const contracts = await protocolContracts;
    // cspell: disable-next-line
    await ensureERC20Allowance("uCR -> CreditNftManagerFacet", contracts.dollarToken, amount, signer, contracts.creditNftManagerFacet!.address);
    await (await contracts.creditNftManagerFacet!.connect(signer).exchangeDollarsForCreditNft(amount)).wait();
    refreshBalances();
  };

  const handleBurn = async () => {
    const amount = extractValidAmount();
    if (amount) {
      // cspell: disable-next-line
      doTransaction("Burning uAD...", async () => {
        setInputVal("");
        await depositDollarForDebtCoupons(amount);
      });
    }
  };

  const handleInput = async (val: string) => {
    const contracts = await protocolContracts;
    setInputVal(val);
    const amount = extractValidAmount(val);
    if (amount) {
      setExpectedDebtCoupon(null);
      setExpectedDebtCoupon(await contracts.creditNftRedemptionCalculatorFacet!.connect(signer).getCreditNftAmount(amount));
    }
  };

  const extractValidAmount = (val: string = inputVal): null | BigNumber => {
    const amount = safeParseEther(val);
    return amount && amount.gt(BigNumber.from(0)) && amount.lte(balances.uad) ? amount : null;
  };

  const submitEnabled = !!(extractValidAmount() && !doingTransaction);

  return (
    <div>
      {/* cspell: disable-next-line */}
      <PositiveNumberInput value={inputVal} onChange={handleInput} placeholder="uAD Amount" />
      <Button onClick={handleBurn} disabled={!submitEnabled}>
        {/* cspell: disable-next-line */}
        Redeem uAD for uCR-NFT
      </Button>
      {expectedDebtCoupon && inputVal && <p>expected uCR-NFT {formatEther(expectedDebtCoupon)}</p>}
    </div>
  );
};

export default UcrNftGenerator;
