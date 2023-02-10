const { ethers } = require("hardhat");
const {
  deployDFND,
  deployCrowdFunding,
  initialSupply,
} = require("./deploy-functions");

const main = async () => {
  const [deployer] = await ethers.getSigners();

  const dfnd = await deployDFND(deployer.address, initialSupply);

  await deployCrowdFunding(deployer.address, dfnd.address);
};

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => console.error(error));
