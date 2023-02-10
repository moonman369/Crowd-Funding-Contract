const { ethers } = require("hardhat");
const prompt = require("prompt");
const { upgradeCrowdFundingProxy } = require("./deploy-functions");

// const main = async () => {

//   const cf2 = await upgradeCrowdFundingProxy(
//     "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"
//   );
// };

// main()
//   .catch((error) => console.error(error))
//   .then(() => {
//     process.exit(0);
//   });

prompt.start();

console.log("Please enter valid Crowdfunding Proxy Contract Address...");

prompt.get(["proxyAddress"], async (error, result) => {
  const proxy = result.proxyAddress.toString();
  if (ethers.utils.isAddress(proxy)) {
    await upgradeCrowdFundingProxy(proxy);
    return;
  }
  console.log("Invalid Proxy Address! Try again!");
});
