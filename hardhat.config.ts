import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";
import { node_url, accounts } from './utils/network'
import 'hardhat-deploy';
import "hardhat-deploy-ethers";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    }
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      gas: 5000000,
    },
    polygonTest: {
      url: node_url('polygonTest'),
      accounts: accounts()
    },
    polygon: {
      url: node_url('polygon'),
      accounts: accounts()
    },
    bscTest: {
      url: node_url('bscTest'),
      accounts: accounts()
    },
    bsc: {
      url: node_url('bsc'),
      accounts: accounts()
    },
    goerli: {
      url: node_url('goerli'),
      accounts: accounts(),
      gas: 5000000,
      gasMultiplier: 1.5
    },
  }
};

export default config;
