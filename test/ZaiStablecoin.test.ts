import { expect } from "chai";
import { deployGovernance } from "./fixtures/governance";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import {
  StakingBonus,
  VestedZeroNFT,
  VestedZeroUiHelper,
  ZeroLend,
} from "../types";
import { e18 } from "./fixtures/utils";
import { parseEther, parseUnits } from "ethers";
import { ethers } from "hardhat";

describe("UI Helper tests", () => {
  let ant: SignerWithAddress;
  let deployer: SignerWithAddress;
  let vest: VestedZeroNFT;
  let vestUiHelper: VestedZeroUiHelper;
  let zero: ZeroLend;
  let stakingBonus: StakingBonus;
  let omnichainStaking;

  beforeEach(async () => {
    const deployment = await loadFixture(deployGovernance);
    ant = deployment.ant;
    deployer = deployment.deployer;
    stakingBonus = deployment.stakingBonus;
    vest = deployment.vestedZeroNFT;
    omnichainStaking = deployment.omnichainStaking;

    let vestUiHelperFactory = await ethers.getContractFactory(
      "VestedZeroUiHelper"
    );
    vestUiHelper = await vestUiHelperFactory.deploy();
    await vestUiHelper.initialize(vest.target, omnichainStaking.target);
    zero = deployment.zero;

    await zero.whitelist(stakingBonus.target, true);
    await zero.whitelist(vest.target, true);
    await zero.whitelist(deployment.lockerToken.target, true);
    await zero.whitelist(omnichainStaking.target, true);

    await zero.transfer(omnichainStaking.target, parseEther("100"));
    await omnichainStaking.notifyRewardAmount(parseEther("1"));
  });

  it("Should return an array of all minted nfts for a user", async () => {
    for (let i = 0; i < 10; i++) {
      await vest.mint(
        ant.address,
        e18 * 15n, // 15 ZERO linear vesting
        e18 * 5n, // 5 ZERO upfront
        1000 * (i + 1), // linear duration - 1000 seconds
        500, // cliff duration - 500 seconds
        0, // unlock date
        false, // penalty -> false
        0
      );
    }
    expect((await vestUiHelper.getVestedNFTData(ant.address)).length).to.equal(
      10
    );
  });

  it("Should return the lock details with APR for 1 year", async () => {
    await zero
      .connect(deployer)
      .approve(stakingBonus.target, parseEther("100"));
    await stakingBonus
      .connect(deployer)
      .createLock(parseEther("100"), 51536000n, true);
    const transactionData = await vestUiHelper.getLockDetails(deployer.address);
    expect(transactionData[0].apr).to.closeTo(
      273490790363394216n,
      parseUnits("1", 16)
    );
  });
});
