const { ethers } = require("hardhat");
const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const { BigNumber } = require("ethers");

const expect = chai.expect;
chai.use(chaiAsPromised);

global.sleep = async (seconds) => {
  return new Promise((res, rej) => {
    setTimeout(() => {
      res();
    }, seconds * 1000);
  });
};

global.blockTimestamp = ({ offset: offset }) => {
  return Math.floor(Date.now() / 1000) + offset;
};

let deployer, creator, donor1, donor2, addrs;
let crowdFunding, dfnd;

const campaignParams = [500, Math.floor(Date.now() / 1000) + 100, "SampleURI"];
const dfndInitialSupply = 10000000;
const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";

before(async () => {
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

  it("2. Appropriate event SHOULD be emitted on successful campaign creation", async () => {
    const campaignId = await crowdFunding.callStatic.createCampaign(
      creator.address,
      ...campaignParams
    );

    const tx = await crowdFunding
      .connect(creator)
      .createCampaign(creator.address, ...campaignParams);
    const { events } = await tx.wait();
    // console.log(events[0].eventSignature, events[0].args.id);
    expect(events[0].eventSignature).to.equal(
      "CampaignCreation(uint256,address)"
    );
    expect(events[0].args.id).to.eql(campaignId);
    expect(events[0].args.owner).to.equal(creator.address);
  });

  it("3. Users SHOULD NOT be able to create campaign with null address as owner", async () => {
    await expect(
      crowdFunding
        .connect(creator)
        .createCampaign(NULL_ADDRESS, ...campaignParams)
    ).to.eventually.be.rejectedWith("DeFund: Owner cannot be null address.");
  });

  it("4. Users SHOULD NOT be able to create campaign with a deadline before current timestamp.", async () => {
    await expect(
      crowdFunding
        .connect(creator)
        .createCampaign(
          creator.address,
          campaignParams[0],
          Math.floor(Date.now() / 1000) - 10,
          campaignParams[2]
        )
    ).to.eventually.be.rejectedWith(
      "DeFund: Deadline should be after the current timestamp."
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

  it("2. Appropriate event SHOULD be emitted on successful donation.", async () => {
    const tx = await crowdFunding
      .connect(donor1)
      .donateToCampaign(campaignId, donationAmount);
    // const res = await tx.wait();
    const { events } = await tx.wait();

    // console.log(res);

    expect(events[2].eventSignature).to.equal("Donation(uint256,uint256)");
    expect(events[2].args.id).to.eql(campaignId);
    expect(events[2].args.amount.toNumber()).to.equal(donationAmount);
  });

  it("3. Users SHOULD NOT be able to donate to a campaign with invalid campaign id.", async () => {
    const latestCount = await crowdFunding.campaignCount();
    await expect(
      crowdFunding
        .connect(donor1)
        .donateToCampaign(latestCount + 1, donationAmount)
    ).to.eventually.be.rejectedWith(
      "DeFund: Campaign with passed id doesn't exist."
    );

    await expect(
      crowdFunding.connect(donor1).donateToCampaign(-1, donationAmount)
    ).to.eventually.be.rejectedWith(
      `value out-of-bounds (argument="_id", value=-1, code=INVALID_ARGUMENT, version=abi/5.7.0)`
    );
  });

  // it("4.", async () => {
  //   const tx = await crowdFunding
  //     .connect(creator)
  //     .createCampaign(creator.address, ...campaignParams);
  //   const res = await tx.wait();
  //   // console.log(res.events[0]);
  // });

  // it("5. Users SHOULD NOT be able to donate to a campaign after its deadline has passed.", async () => {
  //   const campaignId2 = await crowdFunding.callStatic.createCampaign(
  //     creator.address,
  //     ...campaignParams
  //   );

  //   // console.log(Math.floor(Date.now() / 1000));

  //   await crowdFunding
  //     .connect(creator)
  //     .createCampaign(
  //       creator.address,
  //       100,
  //       Math.floor(Date.now() / 1000) + 40,
  //       "SampleURI2"
  //     );

  //   // console.log(
  //   //   (await crowdFunding.getCampaignById(campaignId)).deadline.toNumber() -
  //   //     Math.floor(Date.now() / 1000)
  //   // );

  //   await sleep(10);

  //   await expect(
  //     crowdFunding
  //       .connect(creator)
  //       .donateToCampaign(campaignId2, donationAmount)
  //   ).to.eventually.be.rejectedWith(
  //     "DeFund: Cannot fund campaign after deadline."
  //   );
  // });

  it("6. Users SHOULD NOT be able to donate an amount less than the minimum donation amount (10 DFND).", async () => {
    await expect(
      crowdFunding.connect(donor1).donateToCampaign(campaignId, 9)
    ).to.eventually.be.rejectedWith(
      "DeFund: Minimum donation amount is 10 DFND."
    );
  });
});

describe("III. Withdrawing collected funds (in case campaign goal was met)", () => {
  let campaignId;
  beforeEach(async () => {
    // campaignId = await crowdFunding.callStatic.createCampaign(
    //   creator.address,
    //   100,
    //   Math.floor(Date.now() / 1000) + 40,
    //   "SampleURI2"
    // );

    const blockTimestamp = await crowdFunding.getCurrentTimestamp();

    const tx = await crowdFunding
      .connect(creator)
      .createCampaign(
        creator.address,
        100,
        blockTimestamp.add(10),
        "SampleURI2"
      );

    campaignId = (await tx.wait()).events[0].args.id.toNumber();

    // console.log(res.events);

    await dfnd.connect(donor1).approve(crowdFunding.address, 200);
    await dfnd.connect(donor2).approve(crowdFunding.address, 200);
  });

  it("1. Owner SHOULD BE able to withdraw collected funds from a campaign.", async () => {
    // console.log(Math.floor(Date.now() / 1000));
    // console.log(await crowdFunding.getCampaignById(campaignId));
    await crowdFunding.connect(donor1).donateToCampaign(campaignId, 50);
    await crowdFunding.connect(donor2).donateToCampaign(campaignId, 50);

    await sleep(10);

    const initCreatorBalance = await dfnd.balanceOf(creator.address);

    await expect(
      crowdFunding.connect(creator).withdrawCollectedFunds(campaignId)
    ).to.eventually.be.fulfilled;

    expect(await dfnd.balanceOf(creator.address)).to.eql(
      initCreatorBalance.add(100)
    );
  });

  it("2. Owner SHOULD NOT be able to withdraw funds if invalid campaign is passed", async () => {
    const latestCampaignCount = await crowdFunding.campaignCount();

    await expect(
      crowdFunding
        .connect(creator)
        .withdrawCollectedFunds(latestCampaignCount.add(100))
    ).to.eventually.be.rejectedWith(
      "DeFund: Campaign with passed id doesn't exist."
    );
  });

  it("3. Owner SHOULD NOT be able to withdraw collected funds before deadline.", async () => {
    await crowdFunding.connect(donor1).donateToCampaign(campaignId, 50);
    await crowdFunding.connect(donor2).donateToCampaign(campaignId, 50);

    await expect(
      crowdFunding.connect(creator).withdrawCollectedFunds(campaignId)
    ).to.eventually.be.rejectedWith(
      "DeFund: Cannot withdraw funds before deadline."
    );
  });
});
