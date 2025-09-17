// 合约地址配置
export const CONTRACT_ADDRESSES = {
  STAKE_CONTRACT: process.env.NEXT_PUBLIC_STAKE_CONTRACT_ADDRESS as `0x${string}`,
  METANODE_TOKEN: process.env.NEXT_PUBLIC_METANODE_TOKEN_ADDRESS as `0x${string}`,
};

// 验证合约地址是否已配置
export function validateContractAddresses() {
  const missing = [];
  
  if (!CONTRACT_ADDRESSES.STAKE_CONTRACT) {
    missing.push('NEXT_PUBLIC_STAKE_CONTRACT_ADDRESS');
  }
  
  if (!CONTRACT_ADDRESSES.METANODE_TOKEN) {
    missing.push('NEXT_PUBLIC_METANODE_TOKEN_ADDRESS');
  }
  
  if (missing.length > 0) {
    throw new Error(`缺少环境变量: ${missing.join(', ')}`);
  }
}

// 网络配置
export const NETWORK_CONFIG = {
  sepolia: {
    chainId: 11155111,
    name: 'Sepolia',
    rpcUrl: 'https://sepolia.infura.io/v3/',
    blockExplorer: 'https://sepolia.etherscan.io',
    nativeCurrency: {
      name: 'Ethereum',
      symbol: 'ETH',
      decimals: 18,
    },
  },
  hardhat: {
    chainId: 31337,
    name: 'Hardhat',
    rpcUrl: 'http://localhost:8545',
    blockExplorer: '',
    nativeCurrency: {
      name: 'Ethereum',
      symbol: 'ETH',
      decimals: 18,
    },
  },
};