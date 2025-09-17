require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require("hardhat-deploy");
require("hardhat-contract-sizer");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("dotenv").config();

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "";
const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL || "";
const POLYGON_RPC_URL = process.env.POLYGON_RPC_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY || "";
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || "";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  networks: {
    hardhat: {
      chainId: 31337,
      forking: {
        url: MAINNET_RPC_URL,
        enabled: false,
      },
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: PRIVATE_KEY !== "" ? [PRIVATE_KEY] : [],
      chainId: 11155111,
      blockConfirmations: 6,
    },
    mainnet: {
      url: MAINNET_RPC_URL,
      accounts: PRIVATE_KEY !== "" ? [PRIVATE_KEY] : [],
      chainId: 1,
      blockConfirmations: 6,
    },
    polygon: {
      url: POLYGON_RPC_URL,
      accounts: PRIVATE_KEY !== "" ? [PRIVATE_KEY] : [],
      chainId: 137,
      blockConfirmations: 6,
    },
  },
  etherscan: {
    apiKey: {
      sepolia: ETHERSCAN_API_KEY,
      mainnet: ETHERSCAN_API_KEY,
      polygon: POLYGONSCAN_API_KEY,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    coinmarketcap: COINMARKETCAP_API_KEY,
    outputFile: "gas-report.txt",
    noColors: true,
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    user1: {
      default: 1,
    },
    user2: {
      default: 2,
    },
  },
  mocha: {
    timeout: 300000, // 5 minutes
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
    deploy: "./deploy",
  },
};