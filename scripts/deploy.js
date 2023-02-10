const { ethers } = require("hardhat");
const { deployDFND, deployCrowdFunding } = require("./deploy-functions");

// const deployDFND = async (deployerAddress, initialSupply) => {
//   const deploySigner = await ethers.getSigner(deployerAddress);
//   const DFND = await ethers.getContractFactory("DeFundToken");
//   const dfnd = await DFND.connect(deploySigner).deploy(initialSupply);
//   await dfnd.deployed();
//   console.log(`DFND token contract was deployed at address: ${dfnd.address}`);
//   return dfnd;
// };

// const deployCrowdFunding = async (deployerAddress, dfndTokenAddress) => {
//   const deploySigner = await ethers.getSigner(deployerAddress);
//   const CrowdFunding = await ethers.getContractFactory("CrowdFunding");
//   const crowdFunding = await CrowdFunding.connect(deploySigner).deploy(
//     dfndTokenAddress
//   );
//   await crowdFunding.deployed();
//   console.log(
//     `CrowdFunding contract was deployed at address: ${crowdFunding.address}`
//   );
//   return crowdFunding;
// };

const main = async () => {
  const [deployer] = await ethers.getSigners();

  const initialSupply = 1000000000;
  const dfnd = await deployDFND(deployer.address, initialSupply);

  await deployCrowdFunding(deployer.address, dfnd.address);
};

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => console.error(error));

// module.exports = {
//   deployDFND,
//   deployCrowdFunding,
// };
