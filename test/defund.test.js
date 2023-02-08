const { ethers } = require("hardhat");
const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const { BigNumber } = require("ethers");

const expect = chai.expect;
chai.use(chaiAsPromised);

let deployer, creator, donor1, donor2, addrs;
let crowdFunding, dfnd;

const campaignParams = [100, Math.floor(Date.now() / 1000) + 100, "SampleURI"];
const dfndInitialSupply = 10000000;

before(async function () {
  [deployer, creator, donor1, donor2, ...addrs] = await ethers.getSigners();

  const addresses = [creator, donor1, donor2, ...addrs].map(
    (signer) => signer.address
  );

  const DFND = await ethers.getContractFactory("DeFundToken");
  dfnd = await DFND.connect(deployer).deploy(dfndInitialSupply);
  await dfnd.deployed();

  for (let address of addresses) {
    await dfnd.connect(deployer).transfer(address, 10000);
  }

  const CrowdFunding = await ethers.getContractFactory("CrowdFunding");
  crowdFunding = await CrowdFunding.connect(deployer).deploy(dfnd.address);
  await crowdFunding.deployed();
});

describe("I. Creating a campaign", () => {
  it("1. Users should be able to create campaigns with custom specifications", async () => {
    const campaignId = await crowdFunding.callStatic.createCampaign(
      creator.address,
      ...campaignParams
    );

    await expect(
      crowdFunding
        .connect(creator)
        .createCampaign(creator.address, ...campaignParams)
    ).to.eventually.be.fulfilled;

    const { owner, goal, deadline, metadataUri } =
      await crowdFunding.getCampaignById(campaignId);

    expect(owner).to.equal(creator.address);
    expect(goal.toNumber()).to.equal(campaignParams[0]);
    expect(deadline.toNumber()).to.equal(campaignParams[1]);
    expect(metadataUri).to.equal(campaignParams[2]);
  });
});
