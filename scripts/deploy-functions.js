const { ethers, upgrades } = require("hardhat");

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
  const CFProxy = await ethers.getContractFactory("CrowdFundingUpgradable");
  const cfProxy = await upgrades.deployProxy(CFProxy, [dfndTokenAddress], {
    initializer: "setTokenAddress",
  });

  await cfProxy.deployed();

  console.log(`CrowdFundingProxy deployed to: ${cfProxy.address}`);

  return cfProxy.address;
};

module.exports = {
  deployDFND,
  deployCrowdFunding,
  deployCrowdFundingProxy,
};
