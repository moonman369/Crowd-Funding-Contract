require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },
    goerli: {
      url: "https://rpc.ankr.com/eth_goerli",
      chainId: 5,
      addresses: ["Enter Your Private Key Here"],
      saveDeployments: true,
    },
  },
};
