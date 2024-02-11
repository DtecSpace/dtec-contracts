require("hardhat-gas-reporter");
require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

const fs = require('fs');
const path = require('path');

//fs.readdirSync('scripts').forEach(fileName => {
//  require(path.join(__dirname, 'scripts', fileName));
//});

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
        blockNumber: 53043340
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
      url: "https://polygon-mainnet.infura.io/v3/c5e9c17a297d482fb6e3f8f39da0d080",
      accounts: process.env.DEPLOY_PRIVATE_KEY
        ? [process.env.DEPLOY_PRIVATE_KEY]
        : [],
      chainId: 137,
      saveDeployments: true,
      gasPrice: 150000000000,
    },
  },
  namedAccounts: {
    deployer: 0,
    dev: 1,
  },
  etherscan: {
    apiKey: {
      // See https://hardhat.org/plugins/nomiclabs-hardhat-etherscan.html#multiple-api-keys-and-alternative-block-explorers
      polygon: process.env.POLYSCAN_API_KEY,
      polygon_mumbai: process.env.POLYSCAN_API_KEY,
    },
    customChains : [
      {
        network: "polygon_mumbai",
        chainId: 80001,
        urls: {
          apiUrl: "https://api-testnet.polygonscan.com/api",
          browserURL: "https://mumbai.polygonscan.com"
        },
      },
    ],
  },
  gasReporter: {
    enabled: true,
  }
};
