const { ethers } = require("hardhat");
const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const { BigNumber } = require("ethers");

const expect = chai.expect;
chai.use(chaiAsPromised);

let deployer, creator, donor1, donor2, addrs;
let crowdFunding, dfnd;

const campaignParams = [500, Math.floor(Date.now() / 1000) + 100, "SampleURI"];
const dfndInitialSupply = 10000000;
const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";

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
  it("1. Users SHOULD be able to create campaigns with custom specifications", async () => {
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

  it("2. Users SHOULD NOT be able to create campaign with null address as owner", async () => {
    await expect(
      crowdFunding
        .connect(creator)
        .createCampaign(NULL_ADDRESS, ...campaignParams)
    ).to.eventually.be.rejectedWith("DeFund: Owner cannot be null address.");
  });

  it("3. Users SHOULD NOT be able to create campaign with a deadline of less than 1 minute from current timestamp.", async () => {
    await expect(
      crowdFunding
        .connect(creator)
        .createCampaign(
          creator.address,
          campaignParams[0],
          Math.floor(Date.now() / 1000) + 40,
          campaignParams[2]
        )
    ).to.eventually.be.rejectedWith(
      "DeFund: Deadline should be atleast 1 minute from current timestamp."
    );
  });
});

describe("II. Donating to a campaign", () => {
  const donationAmount = 50;
  let campaignId;
  beforeEach(async () => {
    campaignId = await crowdFunding.callStatic.createCampaign(
      creator.address,
      ...campaignParams
    );
    await crowdFunding
      .connect(creator)
      .createCampaign(creator.address, ...campaignParams);

    await dfnd.connect(donor1).approve(crowdFunding.address, donationAmount);
    await dfnd.connect(donor2).approve(crowdFunding.address, donationAmount);
  });

  it("1. Multiple users SHOULD be able to donate funds to a particular campaign", async () => {
    await expect(
      crowdFunding.connect(donor1).donateToCampaign(campaignId, donationAmount)
    ).to.eventually.be.fulfilled;

    await expect(
      crowdFunding.connect(donor2).donateToCampaign(campaignId, donationAmount)
    ).to.eventually.be.fulfilled;
  });
});
