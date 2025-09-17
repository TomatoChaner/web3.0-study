// 基础类型定义
export interface Address {
  address: `0x${string}`;
}

// 质押池信息（适配直接质押模式）
export interface PoolInfo {
  id: number;
  name: string;
  description: string;
  rewardToken: `0x${string}`;
  totalStaked: bigint;
  rewardRate: bigint;
  minStakeAmount: bigint;
  maxStakeAmount: bigint;
  isActive: boolean;
  apy: number; // 计算得出的APY
}

// 用户质押信息
export interface UserStakeInfo {
  amount: bigint;
  rewardDebt: bigint;
  lastStakeTime: bigint;
  isActive: boolean;
}

// 质押事件
export interface StakeEvent {
  user: `0x${string}`;
  amount: bigint;
  timestamp: bigint;
  transactionHash: string;
}

// 取消质押事件
export interface UnstakeEvent {
  user: `0x${string}`;
  amount: bigint;
  timestamp: bigint;
  transactionHash: string;
}

// 奖励分发事件
export interface RewardDistributedEvent {
  user: `0x${string}`;
  amount: bigint;
  timestamp: bigint;
  transactionHash: string;
}

// API 响应类型
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

// 健康检查响应
export interface HealthCheckResponse {
  status: string;
  timestamp: string;
  version?: string;
  database?: {
    connected: boolean;
    latency?: number;
  };
  blockchain?: {
    connected: boolean;
    network?: string;
    blockNumber?: number;
  };
}

// 统计数据
export interface PlatformStats {
  totalStaked: bigint;
  totalRewardsDistributed: bigint;
  totalUsers: number;
  averageAPY: number;
}

// 用户仪表板数据
export interface UserDashboardData {
  totalStaked: bigint;
  totalRewards: bigint;
  pendingRewards: bigint;
  activeStakes: number;
  avgAPY: number;
  stakingDuration: number;
}

// 交易状态
export type TransactionStatus = 'pending' | 'confirmed' | 'failed';

// 交易信息
export interface TransactionInfo {
  hash: string;
  status: TransactionStatus;
  timestamp: number;
  type: 'stake' | 'unstake' | 'claim';
  amount?: bigint;
}

// 错误类型
export interface ContractError {
  code: string;
  message: string;
  details?: any;
}

// 网络配置
export interface NetworkConfig {
  chainId: number;
  name: string;
  rpcUrl: string;
  blockExplorer: string;
  nativeCurrency: {
    name: string;
    symbol: string;
    decimals: number;
  };
}

// 合约地址配置
export interface ContractAddresses {
  STAKE_CONTRACT: `0x${string}`;
  METANODE_TOKEN: `0x${string}`;
}

// 分页参数
export interface PaginationParams {
  page: number;
  limit: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

// 分页响应
export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}