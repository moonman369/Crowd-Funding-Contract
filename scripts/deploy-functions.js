const { ethers, upgrades } = require("hardhat");

const initialSupply = 1000000000;

const deployDFND = async (deployerAddress, initialSupply) => {
  const deploySigner = await ethers.getSigner(deployerAddress);
  const DFND = await ethers.getContractFactory("DeFundToken");
  console.log("Deploying DFND Contract...");
  const dfnd = await DFND.connect(deploySigner).deploy(initialSupply);
  await dfnd.deployed();
  console.log(
    `DFND token contract was successfully deployed at address: ${dfnd.address}\n`
  );
  return dfnd;
};

const deployCrowdFunding = async (deployerAddress, dfndTokenAddress) => {
  const deploySigner = await ethers.getSigner(deployerAddress);
  const CrowdFunding = await ethers.getContractFactory("CrowdFunding");
  console.log("Deploying CrowdFunding Contract...");
  const crowdFunding = await CrowdFunding.connect(deploySigner).deploy(
    dfndTokenAddress
  );
  await crowdFunding.deployed();
  console.log(
    `CrowdFunding contract was successfully deployed at address: ${crowdFunding.address}\n`
  );
  return crowdFunding;
};

const deployCrowdFundingProxy = async (dfndTokenAddress) => {
  const CFProxy = await ethers.getContractFactory("CrowdFundingUpgradableV1");
  console.log("Deploying CrowdFundingUpgradableV1 proxy contract...");
  const cfProxy = await upgrades.deployProxy(CFProxy, [dfndTokenAddress], {
    initializer: "setTokenAddress",
  });
  await cfProxy.deployed();
  console.log(
    `CrowdFundingUpgradableV1 proxy was deployed at address: ${cfProxy.address}\n`
  );
  return cfProxy;
};

const upgradeCrowdFundingProxy = async (proxyAddress) => {
  const CFProxyV2 = await ethers.getContractFactory("CrowdFundingUpgradableV2");
  console.log("Upgrading CrowdFundingUpgradableV1 proxy...");
  const cfProxyV2 = await upgrades.upgradeProxy(proxyAddress, CFProxyV2);
  console.log(
    `CrowdFundingUpgradableV1 proxy contract at address ${proxyAddress} was successfully upgraded to CrowdFundingUpgradableV2\n`
  );
  return cfProxyV2;
};

module.exports = {
  deployDFND,
  deployCrowdFunding,
  deployCrowdFundingProxy,
  upgradeCrowdFundingProxy,
  initialSupply,
};
