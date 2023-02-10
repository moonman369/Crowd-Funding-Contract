const { ethers, upgrades } = require("hardhat");

const initialSupply = 1000000000;

const deployDFND = async (deployerAddress, initialSupply) => {
  const deploySigner = await ethers.getSigner(deployerAddress);
  const DFND = await ethers.getContractFactory("DeFundToken");
  const dfnd = await DFND.connect(deploySigner).deploy(initialSupply);
  await dfnd.deployed();
  console.log(`DFND token contract was deployed at address: ${dfnd.address}`);
  return dfnd;
};

const deployCrowdFunding = async (deployerAddress, dfndTokenAddress) => {
  const deploySigner = await ethers.getSigner(deployerAddress);
  const CrowdFunding = await ethers.getContractFactory("CrowdFunding");
  const crowdFunding = await CrowdFunding.connect(deploySigner).deploy(
    dfndTokenAddress
  );
  await crowdFunding.deployed();
  console.log(
    `CrowdFunding contract was deployed at address: ${crowdFunding.address}`
  );
  return crowdFunding;
};

const deployCrowdFundingProxy = async (dfndTokenAddress) => {
  const CFProxy = await ethers.getContractFactory("CrowdFundingUpgradableV1");
  const cfProxy = await upgrades.deployProxy(CFProxy, [dfndTokenAddress], {
    initializer: "setTokenAddress",
  });

  await cfProxy.deployed();

  console.log(`CrowdFundingProxy was deployed at address: ${cfProxy.address}`);

  return cfProxy.address;
};

const upgradeCrowdFundingProxy = async (proxyAddress) => {
  const CFProxyV2 = await ethers.getContractFactory("CrowdFundingUpgradableV2");

  const cfProxyV2 = await upgrades.upgradeProxy(proxyAddress, CFProxyV2);

  console.log("Upgrade Successful");

  return cfProxyV2.address;
};

module.exports = {
  deployDFND,
  deployCrowdFunding,
  deployCrowdFundingProxy,
  upgradeCrowdFundingProxy,
  initialSupply,
};
