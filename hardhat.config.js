require("hardhat-gas-reporter");
require("@nomicfoundation/hardhat-toolbox");
const fs = require('fs');
const path = require('path');

fs.readdirSync('scripts').forEach(fileName => {
  require(path.join(__dirname, 'scripts', fileName));
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      forking: {
        url: "https://polygon-rpc.com",
        blockNumber: 50621808
      }
     },
    polygon_mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: process.env.DEPLOY_PRIVATE_KEY
        ? [process.env.DEPLOY_PRIVATE_KEY]
        : [],
      chainId: 80001,
      saveDeployments: true,
    },
    polygon: {
      url: "https://polygon-rpc.com",
      accounts: process.env.DEPLOY_PRIVATE_KEY
        ? [process.env.DEPLOY_PRIVATE_KEY]
        : [],
      chainId: 137,
      saveDeployments: true,
      gasPrice: 120000000000,
    },
  },
  namedAccounts: {
    deployer: 0,
    dev: 1,
  },
  etherscan: {
    apiKey: {
      // See https://hardhat.org/plugins/nomiclabs-hardhat-etherscan.html#multiple-api-keys-and-alternative-block-explorers
      polygon: process.env.SNOWTRACE_API_KEY,
      // polygon_mumbai: process.env.SNOWTRACE_API_KEY,
    },
  },
  gasReporter: {
    enabled: true,
  }
};
