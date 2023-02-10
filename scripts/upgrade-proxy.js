const { ethers } = require("hardhat");
const { upgradeCrowdFundingProxy } = require("./deploy-functions");

const main = async () => {
  await upgradeCrowdFundingProxy("0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9");
};

main()
  .catch((error) => console.error(error))
  .then(() => {
    process.exit(0);
  });
