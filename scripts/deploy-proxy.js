const { ethers } = require("hardhat");
const {
  deployDFND,
  deployCrowdFundingProxy,
  initialSupply,
} = require("./deploy-functions");

const main = async () => {
  const [deployer] = await ethers.getSigners();
  const dfnd = await deployDFND(deployer.address, 1000000);
  await deployCrowdFundingProxy(dfnd.address);
  console.log();
};

main()
  .catch((error) => {
    console.error(error);
  })
  .then(() => {
    process.exit(0);
  });
