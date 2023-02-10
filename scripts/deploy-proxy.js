const { ethers, upgrades } = require("hardhat");
const { deployDFND } = require("./deploy");

const deployCrowdFundingProxy = async (dfndTokenAddress) => {
  const CFProxy = await ethers.getContractFactory("CrowdFundingUpgradable");
  const cfProxy = await upgrades.deployProxy(CFProxy, [dfndTokenAddress], {
    initializer: "setTokenAddress",
  });

  await cfProxy.deployed();

  console.log(`CrowdFundingProxy deployed to: ${cfProxy.address}`);
};

const main = async () => {
  const [deployer] = await ethers.getSigners();
  const dfnd = await deployDFND(deployer.address, 1000000);
  await deployCrowdFundingProxy(dfnd.address);
};

main()
  .catch((error) => {
    console.error(error);
  })
  .then(() => {
    process.exit(0);
  });
